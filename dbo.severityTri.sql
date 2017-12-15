USE [Periscope_Data]
GO

/****** Object:  StoredProcedure [dbo].[severityTri]    Script Date: 12/15/2017 4:40:46 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[severityTri]
as
	declare @i integer, @j integer, @k integer;
	declare @types table(idx int identity(1,1), type varchar(15));
	declare @counties table(idx int identity(1,1), county varchar(15));
	declare @type varchar(15), @county varchar(15);
	-- drop temp table if exists
	if object_id('Periscope_Data.dbo.sevTemp','U') is not null
		drop table Periscope_Data.dbo.sevTemp;
	create table Periscope_Data.dbo.sevTemp
	(PROGRAM varchar(7), COVERAGE varchar(20),
		REPORT_TIME varchar(7), LAG_TIME integer, COUNTY varchar(50) DEFAULT '',
		REPORTED_COUNT INTEGER DEFAULT 0,
		CLAIM_PAID DECIMAL(15,2) DEFAULT 0,
		CLAIM_RES DECIMAL(15,2) DEFAULT 0,
		EXP_PAID DECIMAL(15,2) DEFAULT 0,
		EXP_RES DECIMAL(15,2) DEFAULT 0,
		RECOV_PAID DECIMAL(15,2) DEFAULT 0,
		RECOV_RES DECIMAL(15,2) DEFAULT 0,
		LIT_CLAIM_PAID DECIMAL(15,2) DEFAULT 0,
		LIT_CLAIM_RES DECIMAL(15,2) DEFAULT 0,
		LIT_EXP_PAID DECIMAL(15,2) DEFAULT 0,
		LIT_EXP_RES DECIMAL(15,2) DEFAULT 0,
		LIT_RECOV_PAID DECIMAL(15,2) DEFAULT 0,
		LIT_RECOV_RES DECIMAL(15,2) DEFAULT 0,
		EC_REPORTED INTEGER DEFAULT 0,
		EC_CLAIM_PAID DECIMAL(15,2) DEFAULT 0,
		EC_EXP_PAID DECIMAL(15,2) DEFAULT 0,
		EC_RECOV_PAID DECIMAL(15,2) DEFAULT 0,
		CWOP_COUNT INTEGER DEFAULT 0,
		OPEN_COUNT INTEGER DEFAULT 0,
		CWA_COUNT INTEGER DEFAULT 0,
		BILLS_COUNT INTEGER DEFAULT 0,
	primary key (PROGRAM,COVERAGE,REPORT_TIME,LAG_TIME,COUNTY));
	DECLARE @sqlCode nvarchar(max);
-- use values for different date types, and county or no county
insert into @types values('month'); --,('week');
insert into @counties values('');--,('_county');

set @i = 1;
-- loop through month and week
while (@i <= (select count(*) from @types))
begin
	set @j = 1;
	-- loop through county and no county
	while (@j <= (select count(*) from @counties))
	begin
		set @type = (select type from @types where idx = @i);
		set @county = (select county from @counties where idx = @j);
		delete from  Periscope_Data.dbo.sevTemp;


		-- SILVERVINE CLAIMS VALUES

		merge Periscope_Data.dbo.sevTemp as Target
		using (
		select PROGRAM, COVERAGE, REPORT_TIME, LAG_TIME, COUNTY,
		sum(CLAIM_PAID) as CLAIM_PAID,
		sum(reserveAmount) as RESERVE_AMOUNT,
		sum(recoveryAmount) as RECOVERY_AMOUNT,
		sum(legalExpense) as LEGAL_EXPENSE,
		sum(otherExpense) as OTHER_EXPENSE,
		sum(expenseReserve) as EXPENSE_RESERVE
		from (
		select coalesce(ProgName,'') as PROGRAM, 
		case claim.policyCoveragesId
			when 22 then 'PIP' when 12 then 'PD' when 11 then 'BI' when 19 then 'CMP' when 20 then 'COL' end as COVERAGE,
		case @type when 'month' then convert(char(7), min(a.dateOpened) over(partition by a.claimNum,cov),121)
			when 'week' then concat('Week of ',
			dateadd(day,-((datepart(dw,
			min(a.dateOpened) over(partition by a.claimNum,cov)
			)+(7-datepart(dw,getdate())))%7),
			min(a.dateOpened) over(partition by a.claimNum,cov)
			)) end as REPORT_TIME, 
		case @type when 'month' then datediff(month,min(a.dateOpened) over(partition by a.claimNum,cov),a.dateChanged)
			when 'week' then 
			datediff(week,
			dateadd(day,-((datepart(dw,
			min(a.dateOpened) over(partition by a.claimNum,cov)
			)+(7-datepart(dw,getdate())))%7),
			min(a.dateOpened) over(partition by a.claimNum,cov)
			),
			dateadd(day,-((datepart(dw,
			a.dateChanged
			)+(7-datepart(dw,getdate())))%7),
			a.dateChanged
			)
			) end as LAG_TIME,
		case @county when '' then '' else coalesce(texasCounty,address.county,'') end as COUNTY,
		a.lossPaid - case when
		lag(a.claimId) over (order by a.claimId, a.dateChanged, a.claimlogid) = a.claimId
		then
		lag(a.lossPaid) over (order by a.claimId, a.dateChanged, a.claimlogid)
		else 0 end AS CLAIM_PAID,
		(case when a.lossReserve-a.lossPaid < 0 then 0 else a.lossReserve-a.lossPaid end) - case when
		lag(a.claimId) over (order by a.claimId, a.dateChanged, a.claimlogid) = a.claimId
		then
		lag((case when a.lossReserve-a.lossPaid < 0 then 0 else a.lossReserve-a.lossPaid end)) over (order by a.claimId, a.dateChanged, a.claimlogid)
		else 0 end AS reserveAmount,
		(a.salvagePaid+a.subrogationPaid) - case when
		lag(a.claimId) over (order by a.claimId, a.dateChanged, a.claimlogid) = a.claimId
		then
		lag((a.salvagePaid+a.subrogationPaid)) over (order by a.claimId, a.dateChanged, a.claimlogid)
		else 0 end AS recoveryAmount,
		(a.legalExpensePaid) - case when
		lag(a.claimId) over (order by a.claimId, a.dateChanged, a.claimlogid) = a.claimId
		then
		lag((a.legalExpensePaid)) over (order by a.claimId, a.dateChanged, a.claimlogid)
		else 0 end AS legalExpense,
		(a.expensePaid) - case when
		lag(a.claimId) over (order by a.claimId, a.dateChanged, a.claimlogid) = a.claimId
		then
		lag((a.expensePaid)) over (order by a.claimId, a.dateChanged, a.claimlogid)
		else 0 end AS otherExpense,
		(case when (a.legalExpenseReserve-a.legalExpensePaid)+(a.expenseReserve-a.expensePaid) < 0 then 0
			else (a.legalExpenseReserve-a.legalExpensePaid)+(a.expenseReserve-a.expensePaid) end) - case when
		lag(a.claimId) over (order by a.claimId, a.dateChanged, a.claimlogid) = a.claimId
		then
		lag((case when (a.legalExpenseReserve-a.legalExpensePaid)+(a.expenseReserve-a.expensePaid) < 0 then 0
			else (a.legalExpenseReserve-a.legalExpensePaid)+(a.expenseReserve-a.expensePaid) end)) over (order by a.claimId, a.dateChanged, a.claimlogid)
		else 0 end AS expenseReserve
		from (select claimlogid, claimNum, dateopened, dateChanged, claimId, expensePaid, expenseReserve, legalExpensePaid, legalExpenseReserve,
		salvagePaid, subrogationPaid, lossReserve, lossPaid,
		case policyCoveragesId when 20 then 'COL' when 19 then 'CMP' when 11 then 'BI' when 12 then 'PD' when 22 then 'PIP'
				when 15 then 'UMPD' when 14 then 'UMBI' when 27 then 'RENT' when 24 then 'TOW' when 18 then 'UNPD'when 36 then 'UNBI' when 51 then 'CDW'
			end as cov
		from Windhaven_Report.dbo.ClaimLog
		where claimNum <> '0'
		union all
		select null, ClaimNumber as claimNum,
		TranDate,TranDate, null, null, null, null, null,
		null, null, null, null,
		replace(Coverage,'COM','CMP') as cov
		from Periscope_Data.B2_Data.Claims_Trans) a
		left join [Windhaven_Report].dbo.claim on  a.claimID = claim.claimID
		left join [Windhaven_Report].dbo.claimincident on claim.claimincidentId = claimincident.claimincidentId
		left join [Windhaven_Report].dbo.policy on policy.policyId = claimincident.policyId
		 left join [Windhaven_Report].dbo.producer on policy.producerId = producer.producerId
		 left join (select vehicle.policyId, min(vehicleNumber) as minVeh
			from [Windhaven_Report].dbo.vehicle
			group by policyId) veh on veh.policyId = policy.policyId
		 left join [Windhaven_Report].dbo.vehicle on vehicle.policyId = policy.policyId and vehicleNumber = minVeh
		 left join [Windhaven_Report].dbo.address on vehicle.garagingAddressId = address.id
		left join [Windhaven_Report].dbo.insured on policy.insuredID = insured.insuredId
		left join [Periscope_Data].dbo.ProgramNum on ProgNum = ratingProgram
		left join Periscope_Data.B2_Data.TxZips on texasZip = address.zipcode and coalesce(address.county,'') = ''
		where claim.policyCoveragesId in (22,12,11,20,19)) b
		WHERE REPORT_TIME IS NOT NULL -- EXCLUDE DUMMY CLAIMS WITHOUT A REPORT TIME
		group by PROGRAM, COVERAGE, REPORT_TIME, LAG_TIME, COUNTY
		) as Source
		on (Target.PROGRAM = Source.PROGRAM and Target.COVERAGE = Source.COVERAGE
			and Target.REPORT_TIME = Source.REPORT_TIME and Target.LAG_TIME = Source.LAG_TIME
			and Target.COUNTY = Source.COUNTY)
		when matched then
			update set Target.CLAIM_PAID = Source.CLAIM_PAID,
			Target.CLAIM_RES = Source.RESERVE_AMOUNT,
			Target.EXP_PAID = coalesce(Source.LEGAL_EXPENSE,0) + coalesce(Source.OTHER_EXPENSE,0),
			Target.EXP_RES = Source.EXPENSE_RESERVE ,
			Target.RECOV_PAID = Source.RECOVERY_AMOUNT,
			Target.LIT_EXP_PAID = Source.LEGAL_EXPENSE
		when not matched by Target then
		insert (PROGRAM, COVERAGE, REPORT_TIME, LAG_TIME, COUNTY,
			CLAIM_PAID, CLAIM_RES, EXP_PAID, EXP_RES, RECOV_PAID, LIT_EXP_PAID)
		values (Source.PROGRAM, Source.COVERAGE, Source.REPORT_TIME,
				Source.LAG_TIME, Source.County, 
				Source.CLAIM_PAID, Source.RESERVE_AMOUNT,
				coalesce(Source.LEGAL_EXPENSE,0) + coalesce(Source.OTHER_EXPENSE,0),
				Source.EXPENSE_RESERVE, Source.RECOVERY_AMOUNT, Source.LEGAL_EXPENSE);

		-- B2 CLAIMS VALUES

		merge Periscope_Data.dbo.sevTemp as Target
		using (
		select Program, Cov, REPORT_TIME, LAG_TIME, county,
		sum(PaidAmount) as PaidAmount, sum(ReserveAmount) as ReserveAmount
		from (select concat(left(ClaimNumber,1),substring(ClaimNumber,5,1)) as Program,
		case when Coverage = 'COM' then 'CMP' else Coverage end as Cov,
		case @type when 'month' then convert(char(7), min(TranDate) over(partition by ClaimNumber, Coverage),121)
		when 'week' then concat('Week of ',
			dateadd(day,-((datepart(dw,
			min(TranDate) over(partition by ClaimNumber, Coverage)
			)+(7-datepart(dw,getdate())))%7),
			min(TranDate) over(partition by ClaimNumber, Coverage)
			)) end as REPORT_TIME, 
		case @type when 'month' then datediff(month,min(TranDate) over(partition by ClaimNumber, Coverage),TranDate)
		when 'week' then datediff(week,
			dateadd(day,-((datepart(dw,
			min(TranDate) over(partition by ClaimNumber,  Coverage)
			)+(7-datepart(dw,getdate())))%7),
			min(TranDate) over(partition by ClaimNumber,  Coverage)
			),
			dateadd(day,-((datepart(dw,
			TranDate
			)+(7-datepart(dw,getdate())))%7),
			TranDate
			)
			) end as LAG_TIME,
		'' as county,
		case when TranType = 'Payment' then Amount else 0 end as PaidAmount,
		case when TranType = 'Reserve' then Amount  else 0 end as ReserveAmount
		 from Periscope_Data.B2_Data.Claims_Trans) b
		 group by Program, Cov, REPORT_TIME, LAG_TIME, county
		 ) as Source
		 on (Target.PROGRAM = Source.Program and Target.COVERAGE = Source.Cov
			and Target.REPORT_TIME = Source.REPORT_TIME and Target.LAG_TIME = Source.LAG_TIME
			and Target.COUNTY = Source.county)
		when matched then
			update set Target.CLAIM_PAID = coalesce(Target.CLAIM_PAID,0) + coalesce(Source.PaidAmount,0),
				Target.CLAIM_RES = coalesce(Target.CLAIM_RES,0) + coalesce(Source.ReserveAmount,0)
		when not matched by Target then
		insert (PROGRAM, COVERAGE, REPORT_TIME, LAG_TIME, COUNTY,
			CLAIM_PAID, CLAIM_RES)
		VALUES (Source.Program, Source.Cov, Source.REPORT_TIME, Source.LAG_TIME, Source.county,
			Source.PaidAmount, Source.ReserveAmount);


		-- opened and closed counts

		set @k = 0;
		while @k <= case @type when 'month' then 
			case when 72 < datediff(month,'2015-01-01',getdate()) then 72 else datediff(month,'2015-01-01',getdate()) end
		when 'week' then 
			case when 312 < datediff(week,'2015-01-01',getdate()) then 312 else datediff(week,'2015-01-01',getdate()) end
		end
		begin
					merge Periscope_Data.dbo.sevTemp as Target
		using (
select coalesce(ProgName,'') as PROGRAM, 
		cov as COVERAGE,
		case @type when 'month' then convert(char(7), claim.dateopened,121)
		when 'week' then concat('Week of ',
			dateadd(day,-((datepart(dw,
			claim.dateopened
			)+(7-datepart(dw,getdate())))%7),
			claim.dateopened
			)) end as REPORT_TIME, @k as LAG_TIME,
		case @county when '' then '' else coalesce(texasCounty,address.county,'') end as COUNTY,
		count(case when reserve > 0 then 1 end) as openClaim,
		count(case when reserve <= 0 and paid > 0 then 1 end) as cwa,
		count(case when reserve <= 0 and paid <= 0 then 1 end) as cwop
from (select claimNum, cov, max(claimincidentid) as claimincidentId, 
max(reserve) as reserve, 
max(paid) as paid, min(dateopened) as dateopened
from (select claimNum, cov,claimincidentid,
dateChanged,
min(dateOpened) over(partition by claimNum, cov) as dateopened,
last_value(reserve) over(partition by claimNum, cov order by dateChanged, claimlogid rows between unbounded preceding and unbounded following) as reserve,
last_value(lossPaid) over(partition by claimNum, cov order by dateChanged, claimlogid rows between unbounded preceding and unbounded following) as paid,
last_value(system) over(partition by claimNum, cov order by dateChanged, claimlogid rows between unbounded preceding and unbounded following) as system
from (
select claimlogid, claimNum, cov, claimincidentId,
dateChanged,
min(dateOpened) over(partition by claimNum, cov) as dateopened,
reserve, lossPaid, system
from (
select claimlogid, claimNum, dateChanged, dateopened, claimincidentId, lossReserve - lossPaid as reserve, lossPaid,
		case policyCoveragesId when 20 then 'COL' when 19 then 'CMP' when 11 then 'BI' when 12 then 'PD' when 22 then 'PIP'
				when 15 then 'UMPD' when 14 then 'UMBI' when 27 then 'RENT' when 24 then 'TOW' when 18 then 'UNPD'when 36 then 'UNBI' when 51 then 'CDW'
			end as cov, 'sv' as system
		from Windhaven_Report.dbo.ClaimLog
		where claimNum <> '0'
		
		union all
		select null, ClaimNumber as claimNum,
		TranDate, TranDate, claimincidentid, sum(reserve) 
			over (partition by ClaimNumber, coverage order by TranDate rows between unbounded preceding and 0 preceding), 
			sum(paid) over(partition by ClaimNumber, coverage order by TranDate rows between unbounded preceding and 0 preceding), 
		replace(Coverage,'COM','CMP') as cov, 'b2' as system
		from (select ClaimNumber, coverage, TranDate, 
		sum(case when TranType = 'Reserve' then Amount else 0 end) as reserve,
		sum(case when TranType = 'Payment' then Amount else 0 end) as paid
		from Periscope_Data.B2_Data.Claims_Trans
		group by ClaimNumber,coverage, TranDate) b2_data
		left join Windhaven_Report.dbo.claim on ClaimNumber = claimNum
		 )
		
		 b) b
where case when @type = 'month' then format(dateChanged,'yyyyMM')
when @type = 'week' then format(dateadd(day,-((datepart(dw,
			dateChanged
			)+(7-datepart(dw,getdate())))%7),
			dateChanged
			),'yyyyMMdd') end <= 
case when @type = 'month' then format(dateadd(month,@k,dateOpened),'yyyyMM')
when @type = 'week' then format(dateadd(week,@k,dateadd(day,-((datepart(dw,
			dateOpened
			)+(7-datepart(dw,getdate())))%7),
			dateOpened
			)),'yyyyMMdd') end) b
group by claimNum, cov) claim
join [Windhaven_Report].dbo.claimincident on claim.claimincidentId = claimincident.claimincidentId
		join [Windhaven_Report].dbo.policy on policy.policyId = claimincident.policyId
		 join [Windhaven_Report].dbo.producer on policy.producerId = producer.producerId
		 join (select vehicle.policyId, min(vehicleNumber) as minVeh
			from [Windhaven_Report].dbo.vehicle
			group by policyId) veh on veh.policyId = policy.policyId
		 join [Windhaven_Report].dbo.vehicle on vehicle.policyId = policy.policyId and vehicleNumber = minVeh
		 left join [Windhaven_Report].dbo.address on vehicle.garagingAddressId = address.id
		join [Windhaven_Report].dbo.insured on policy.insuredID = insured.insuredId
		join [Periscope_Data].dbo.ProgramNum on ProgNum = ratingProgram
		left join Periscope_Data.B2_Data.TxZips on texasZip = address.zipcode and coalesce(address.county,'') = ''

		where cov in ('PIP','PD','BI','CMP','COL')
		group by coalesce(ProgName,''), 
		cov,
		case @type when 'month' then convert(char(7), claim.dateopened,121)
		when 'week' then concat('Week of ',
			dateadd(day,-((datepart(dw,
			claim.dateopened
			)+(7-datepart(dw,getdate())))%7),
			claim.dateopened
			)) end,
		case @county when '' then '' else coalesce(texasCounty,address.county,'') end) as Source
		on (Target.PROGRAM = Source.PROGRAM and Target.COVERAGE = Source.COVERAGE
			and Target.REPORT_TIME = Source.REPORT_TIME
			and Target.COUNTY = Source.COUNTY
			and Target.LAG_TIME = Source.LAG_TIME)
		when matched then
			update set Target.OPEN_COUNT = Source.openClaim,
			Target.CWA_COUNT = Source.cwa, Target.CWOP_COUNT = Source.cwop
		when not matched by Target then
		insert (PROGRAM, COVERAGE, REPORT_TIME, LAG_TIME, COUNTY,OPEN_COUNT, CWA_COUNT, CWOP_COUNT)
		values (Source.PROGRAM, Source.COVERAGE, Source.REPORT_TIME,
				Source.LAG_TIME, Source.County, Source.openClaim, Source.cwa, Source.cwop);
			set @k = @k + 1;
		end;



		
		-- REPORTED COUNT

		merge Periscope_Data.dbo.sevTemp as Target
		using (select coalesce(ProgName,'') as PROGRAM, 
		cov as COVERAGE,
		case @type when 'month' then convert(char(7), claim.dateopened,121)
		when 'week' then concat('Week of ',
			dateadd(day,-((datepart(dw,
			claim.dateopened
			)+(7-datepart(dw,getdate())))%7),
			claim.dateopened
			)) end as REPORT_TIME, 0 as LAG_TIME,
		case @county when '' then '' else coalesce(texasCounty,address.county,'') end as COUNTY,
		count(*) as REPORTED_COUNT
		 from 
		(select claimNum, cov, min(dateChanged) as dateopened, min(claimincidentid) as claimincidentid
			from (
			select claim.claimNum, claim.claimincidentId,
			case a.policyCoveragesId when 20 then 'COL' when 19 then 'CMP' when 11 then 'BI' when 12 then 'PD' when 22 then 'PIP'
				when 15 then 'UMPD' when 14 then 'UMBI' when 27 then 'RENT' when 24 then 'TOW' when 18 then 'UNPD'when 36 then 'UNBI' when 51 then 'CDW'
			end as cov,
			a.dateopened as dateChanged
			from Windhaven_Report.dbo.ClaimLog a
			join Windhaven_Report.dbo.claim on a.claimID = claim.claimID
			join Windhaven_Report.dbo.claimincident on claim.claimincidentId = claimincident.claimincidentId
			where a.claimNum <> '0'
			union all 
			select ClaimNumber as claimNum, claimincidentid,
			replace(Coverage,'COM','CMP') as cov, TranDate as dateChanged
			from Periscope_Data.B2_Data.Claims_Trans
			left join Windhaven_Report.dbo.claim on ClaimNumber = claimNum 
			) b
			where cov <> '*'
			group by claimNum, cov) claim
		join [Windhaven_Report].dbo.claimincident on claim.claimincidentId = claimincident.claimincidentId
		join [Windhaven_Report].dbo.policy on policy.policyId = claimincident.policyId
		 join [Windhaven_Report].dbo.producer on policy.producerId = producer.producerId
		 join (select vehicle.policyId, min(vehicleNumber) as minVeh
			from [Windhaven_Report].dbo.vehicle
			group by policyId) veh on veh.policyId = policy.policyId
		 join [Windhaven_Report].dbo.vehicle on vehicle.policyId = policy.policyId and vehicleNumber = minVeh
		 left join [Windhaven_Report].dbo.address on vehicle.garagingAddressId = address.id
		join [Windhaven_Report].dbo.insured on policy.insuredID = insured.insuredId
		join [Periscope_Data].dbo.ProgramNum on ProgNum = ratingProgram
		left join Periscope_Data.B2_Data.TxZips on texasZip = address.zipcode and coalesce(address.county,'') = ''
		where cov in ('PIP','PD','BI','CMP','COL')
		AND claim.dateopened IS NOT NULL -- EXCLUDE DUMMY CLAIMS WITHOUT A REPORT TIME
		group by coalesce(ProgName,''), 
		cov,
		case @type when 'month' then convert(char(7), claim.dateopened,121)
		when 'week' then concat('Week of ',
			dateadd(day,-((datepart(dw,
			claim.dateopened
			)+(7-datepart(dw,getdate())))%7),
			claim.dateopened
			)) end,
		case @county when '' then '' else coalesce(texasCounty,address.county,'') end
		) as Source
		on (Target.PROGRAM = Source.PROGRAM and Target.COVERAGE = Source.COVERAGE
			and Target.REPORT_TIME = Source.REPORT_TIME
			and Target.COUNTY = Source.COUNTY)
		when matched then
			update set Target.REPORTED_COUNT = Source.REPORTED_COUNT
		when not matched by Target then
		insert (PROGRAM, COVERAGE, REPORT_TIME, LAG_TIME, COUNTY,REPORTED_COUNT)
		values (Source.PROGRAM, Source.COVERAGE, Source.REPORT_TIME,
				Source.LAG_TIME, Source.County, Source.REPORTED_COUNT);

		SET @sqlCode = concat('delete from Periscope_Data.dbo.SEVERITY_TRIANGLES_',@type,@county);
		EXEC sp_executesql @sqlCode;

		set @sqlCode = concat('insert into Periscope_Data.dbo.SEVERITY_TRIANGLES_',@type,@county,'
			select PROGRAM, COVERAGE,
		REPORT_TIME, LAG_TIME, ',case when @county = '' then '' else 'COUNTY,' end,'
		REPORTED_COUNT,CLAIM_PAID,CLAIM_RES,EXP_PAID,EXP_RES,
		RECOV_PAID,RECOV_RES,LIT_CLAIM_PAID,LIT_CLAIM_RES,
		LIT_EXP_PAID,LIT_EXP_RES,LIT_RECOV_PAID,LIT_RECOV_RES,
		EC_REPORTED,EC_CLAIM_PAID,EC_EXP_PAID,EC_RECOV_PAID,
		CWOP_COUNT,OPEN_COUNT,CWA_COUNT,BILLS_COUNT
		from Periscope_Data.dbo.sevTemp;');
		EXEC sp_executesql @sqlCode;


		set @j = @j + 1;
	end;
	set @i = @i + 1;
end;


if object_id('Periscope_Data.dbo.sevTemp','U') is not null
	drop table Periscope_Data.dbo.sevTemp;
GO

