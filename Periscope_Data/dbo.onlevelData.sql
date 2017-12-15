USE [Periscope_Data]
GO

/****** Object:  StoredProcedure [dbo].[onlevelData]    Script Date: 12/15/2017 4:40:10 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

create procedure [dbo].[onlevelData] @programs varchar(100), @quarters integer
as
	declare @progCount integer, @progLoop integer, @replaceLoop integer, @program varchar(100), @quarterStart date, @quarterEnd date, @quarterLoop integer;
	declare @tableMonthLabel varchar(10), @tableName varchar(100), @SQL varchar(5000);
	declare @b2_cut_off date, @asOfDate date;
	declare @programsTable table(idx int identity(1,1), program varchar(12));
	declare @quartersTable table(idx int identity(1,1), startDate date, endDate date);
	declare @progCursor CURSOR, @quarterCursor CURSOR;
set @tableMonthLabel = format(dateadd(mm,-1,getdate()),'yyyyMM');
set @b2_cut_off = '2016-12-13';
if object_id('RATE_FILING_TEMP','U') is not null
	begin
	drop table RATE_FILING_TEMP;
	end;
create table RATE_FILING_TEMP
(RPT_START_DATE date, RPT_END_DATE date, POLICY_NUM VARCHAR(20), VEH_NUM INTEGER, POLICY_EFF DATE,/*POLICY_INCEPTION DATE,  POLICY_EXP DATE,*/
PIP_WP DECIMAL(10,2), PD_WP DECIMAL(10,2), BI_WP DECIMAL(10,2), CMP_WP DECIMAL(10,2), COL_WP DECIMAL(10,2),
PIP_EP DECIMAL(10,2), PD_EP DECIMAL(10,2), BI_EP DECIMAL(10,2), CMP_EP DECIMAL(10,2), COL_EP DECIMAL(10,2),
PIP_EXP DECIMAL(10,4), PD_EXP DECIMAL(10,4), BI_EXP DECIMAL(10,4), CMP_EXP DECIMAL(10,4), COL_EXP DECIMAL(10,4),
PIP_CLAIM DECIMAL(10,2), PD_CLAIM DECIMAL(10,2), BI_CLAIM DECIMAL(10,2), CMP_CLAIM DECIMAL(10,2), COL_CLAIM DECIMAL(10,2),
PIP_ALAE DECIMAL(10,2), PD_ALAE DECIMAL(10,2), BI_ALAE DECIMAL(10,2), CMP_ALAE DECIMAL(10,2), COL_ALAE DECIMAL(10,2),
PIP_LOSS_COUNT INTEGER, PD_LOSS_COUNT INTEGER, BI_LOSS_COUNT INTEGER, CMP_LOSS_COUNT INTEGER, COL_LOSS_COUNT INTEGER,
PIP_CWIP_COUNT INTEGER, PD_CWIP_COUNT INTEGER, BI_CWIP_COUNT INTEGER, CMP_CWIP_COUNT INTEGER, COL_CWIP_COUNT INTEGER,
PIP_CRLEP DECIMAL(10,2), PD_CRLEP DECIMAL(10,2), BI_CRLEP DECIMAL(10,2), CMP_CRLEP DECIMAL(10,2), COL_CRLEP DECIMAL(10,2),
PRIMARY KEY (RPT_START_DATE, RPT_END_DATE, POLICY_NUM, VEH_NUM, POLICY_EFF));

set @progCount = len(@programs)-len(replace(@programs,',',''));
set @progLoop = @progCount
while @progLoop >= 0
begin
	set @replaceLoop = @progLoop;
	set @program = @programs;
	while @replaceLoop > 0
	begin
		set @program = substring(@program,charindex(',',@program)+1,99999);
		set @replaceLoop = @replaceLoop - 1;
	end;
	set @program = case when @progLoop = @progCount then @program else substring(@program,0,charindex(',',@program)) end;
	insert into @programsTable(program)
	values(ltrim(rtrim(@program)));
	set @progLoop = @progLoop - 1;
end;
set @quarterLoop = @quarters;
set @quarterEnd =  dateadd(dd,-1,dateadd(qq,datediff(qq,0,getdate()),0));
set @asOfDate = @quarterEnd;
while @quarterLoop > 0
begin	
	set @quarterEnd =  dateadd(dd,-1,dateadd(qq,datediff(qq,0,getdate()) - (@quarterLoop - 1),0));
	set @quarterStart =  dateadd(qq,datediff(qq,0,getdate()) - @quarterLoop,0);
	insert into @quartersTable(startDate,endDate)
	values(@quarterStart,@quarterEnd);
	set @quarterLoop = @quarterLoop - 1;
end;
	set @progCursor = CURSOR for select program from @programsTable;
	open @progCursor
	fetch next from @progCursor into @program
	while @@FETCH_STATUS = 0
	begin
		delete from RATE_FILING_TEMP;
		set @quarterCursor = CURSOR for select startDate, endDate from @quartersTable;
		open @quarterCursor
		fetch next from @quarterCursor into @quarterStart, @quarterEnd
		while @@FETCH_STATUS = 0
		begin

			-- earned premium values
			merge RATE_FILING_TEMP Target
			using (select @quarterStart as reportStart, @quarterEnd as reportEnd, 
			policyNum,  objectId, effecDate,
			sum(case when coverage = 'PIP' then written end) as pipWritten,
			sum(case when coverage = 'PD' then written end) as pdWritten,
			sum(case when coverage = 'BI' then written end) as biWritten,
			sum(case when coverage = 'OTC' then written end) as cmpWritten,
			sum(case when coverage = 'COLL' then written end) as colWritten, 
			sum(case when coverage = 'PIP' then Earned end) as pipEarned,
			sum(case when coverage = 'PD' then Earned end) as pdEarned,
			sum(case when coverage = 'BI' then Earned end) as biEarned,
			sum(case when coverage = 'OTC' then Earned end) as cmpEarned,
			sum(case when coverage = 'COLL' then Earned end) as colEarned
			from (
			select policyNum, CoveragePremium.objectId, convert(date,policy.effectiveDate) as effecDate,
			coverage,
			sum(case when convert(date,transactionDate) between @quarterStart and @quarterEnd 
				and convert(date,transactionDate) > @b2_cut_off 
				then changeInTPD end) as written,
			coalesce(sum(
			coalesce(round(changeInTPD*
				case when transactionDate > 
					case when left(policyNum,1) <> 'T' and @quarterEnd < @b2_cut_off then @b2_cut_off else @quarterEnd end
					or dateeffective > case when left(policyNum,1) <> 'T' and @quarterEnd < @b2_cut_off then @b2_cut_off else @quarterEnd end then null
				else
					cast((1 + datediff(day,dateeffective,
						case when case when left(policyNum,1) <> 'T' and @quarterEnd < @b2_cut_off then @b2_cut_off else @quarterEnd end >expirationDate 
					then expirationDate else case when left(policyNum,1) <> 'T' and @quarterEnd < @b2_cut_off then @b2_cut_off else @quarterEnd end end
					)) as decimal)/cast(nullif((1+datediff(day,dateeffective,expirationDate)),0) as decimal) end,2),0)),0)
			-
						coalesce(sum(
			coalesce(round(changeInTPD*
				case when transactionDate > 
					case when left(policyNum,1) <> 'T' and dateadd(dd,-1,@quarterStart) < @b2_cut_off then @b2_cut_off else dateadd(dd,-1,@quarterStart)  end
					or dateeffective > case when left(policyNum,1) <> 'T' and dateadd(dd,-1,@quarterStart)  < @b2_cut_off then @b2_cut_off else dateadd(dd,-1,@quarterStart)  end then null
				else
					cast((1 + datediff(day,dateeffective,
						case when case when left(policyNum,1) <> 'T' and dateadd(dd,-1,@quarterStart)  < @b2_cut_off then @b2_cut_off else dateadd(dd,-1,@quarterStart)  end >expirationDate 
					then expirationDate else case when left(policyNum,1) <> 'T' and dateadd(dd,-1,@quarterStart)  < @b2_cut_off then @b2_cut_off else dateadd(dd,-1,@quarterStart)  end end
					)) as decimal)/cast(nullif((1+datediff(day,dateeffective,expirationDate)),0) as decimal) end,2),0)),0) as Earned
				from [Windhaven_Report].dbo.CoveragePremium
				join [Windhaven_Report].dbo.Policy on Policy.policyID = CoveragePremium.policyId
				join [Periscope_Data].dbo.ProgramNum on ProgNum = ratingProgram and ProgName = @program
				group by policyNum, coverage,  CoveragePremium.objectId, convert(date,policy.effectiveDate)) b
				where Earned <> 0 or written <> 0
				group by policyNum,  objectId, effecDate) as Source
				on Source.reportStart = Target.RPT_START_DATE
				and Source.reportEnd = Target.RPT_END_DATE
				and Source.policyNum = Target.POLICY_NUM
				and Source.objectId = Target.VEH_NUM
				and Source.effecDate = Target.POLICY_EFF

				when matched then 
					update set Target.PIP_WP = Source.pipWritten,
							Target.PD_WP = Source.pdWritten,
							Target.BI_WP = Source.biWritten,
							Target.CMP_WP = Source.cmpWritten,
							Target.COL_WP = Source.colWritten,
							Target.PIP_EP = Source.pipEarned,
							Target.PD_EP = Source.pdEarned,
							Target.BI_EP = Source.biEarned,
							Target.CMP_EP = Source.cmpEarned,
							Target.COL_EP = Source.colEarned
				when not matched by Target then
				insert (RPT_START_DATE, RPT_END_DATE, POLICY_NUM, VEH_NUM, POLICY_EFF,
					PIP_WP, PD_WP, BI_WP, CMP_WP, COL_WP, 
					PIP_EP, PD_EP, BI_EP, CMP_EP, COL_EP)
				VALUES (Source.reportStart, Source.reportEnd, Source.policyNum, Source.objectId, Source.effecDate,
					Source.pipWritten, Source.pdWritten, Source.biWritten,
					Source.cmpWritten, Source.colWritten,
					Source.pipEarned, Source.pdEarned, Source.biEarned,
					Source.cmpEarned, Source.colEarned);

			-- claim amount numbers
						merge RATE_FILING_TEMP Target
				using (select @quarterStart as reportStart, @quarterEnd as reportEnd, 
				policyNum, objectId, effecDate,
				sum(case when COVERAGE = 'PIP' then coalesce(CLAIM_PAID,0)+coalesce(reserveAmount,0)+coalesce(recoveryAmount,0) end) as PIP_INCUR,
				sum(case when COVERAGE = 'PD' then coalesce(CLAIM_PAID,0)+coalesce(reserveAmount,0)+coalesce(recoveryAmount,0) end) as PD_INCUR,
				sum(case when COVERAGE = 'BI' then coalesce(CLAIM_PAID,0)+coalesce(reserveAmount,0)+coalesce(recoveryAmount,0) end) as BI_INCUR,
				sum(case when COVERAGE = 'CMP' then coalesce(CLAIM_PAID,0)+coalesce(reserveAmount,0)+coalesce(recoveryAmount,0) end) as CMP_INCUR,
				sum(case when COVERAGE = 'COL' then coalesce(CLAIM_PAID,0)+coalesce(reserveAmount,0)+coalesce(recoveryAmount,0) end) as COL_INCUR,
				sum(case when COVERAGE = 'PIP' then coalesce(legalExpense,0)+coalesce(otherExpense,0)
					+coalesce(expenseReserve,0) end) as PIP_EXPEN,
				sum(case when COVERAGE = 'PD' then coalesce(legalExpense,0)+coalesce(otherExpense,0)
					+coalesce(expenseReserve,0) end) as PD_EXPEN,
				sum(case when COVERAGE = 'BI' then coalesce(legalExpense,0)+coalesce(otherExpense,0)
					+coalesce(expenseReserve,0) end) as BI_EXPEN,
				sum(case when COVERAGE = 'CMP' then coalesce(legalExpense,0)+coalesce(otherExpense,0)
					+coalesce(expenseReserve,0) end) as CMP_EXPEN,
				sum(case when COVERAGE = 'COL' then coalesce(legalExpense,0)+coalesce(otherExpense,0)
					+coalesce(expenseReserve,0) end) as COL_EXPEN
				from (select policyNum, 
				 vehicleId as objectId, convert(date,policy.effectiveDate) as effecDate,
				case claim.policyCoveragesId
				when 22 then 'PIP' when 12 then 'PD' when 11 then 'BI' when 20 then 'CMP' when 19 then 'COL' end as COVERAGE,
				a.lossPaid - case when
				lag(a.claimId) over (order by a.claimId, a.dateChanged) = a.claimId
				then
				lag(a.lossPaid) over (order by a.claimId, a.dateChanged)
				else 0 end AS CLAIM_PAID,
				(a.lossReserve-a.lossPaid) - case when
				lag(a.claimId) over (order by a.claimId, a.dateChanged) = a.claimId
				then
				lag((a.lossReserve-a.lossPaid)) over (order by a.claimId, a.dateChanged)
				else 0 end AS reserveAmount,
				(a.salvagePaid+a.subrogationPaid) - case when
				lag(a.claimId) over (order by a.claimId, a.dateChanged) = a.claimId
				then
				lag((a.salvagePaid+a.subrogationPaid)) over (order by a.claimId, a.dateChanged)
				else 0 end AS recoveryAmount,
				(a.legalExpensePaid) - case when
				lag(a.claimId) over (order by a.claimId, a.dateChanged) = a.claimId
				then
				lag((a.legalExpensePaid)) over (order by a.claimId, a.dateChanged)
				else 0 end AS legalExpense,
				(a.expensePaid) - case when
				lag(a.claimId) over (order by a.claimId, a.dateChanged) = a.claimId
				then
				lag((a.expensePaid)) over (order by a.claimId, a.dateChanged)
				else 0 end AS otherExpense,
				((a.legalExpenseReserve-a.legalExpensePaid)+(a.expenseReserve-a.expensePaid)) - case when
				lag(a.claimId) over (order by a.claimId, a.dateChanged) = a.claimId
				then
				lag(((a.legalExpenseReserve-a.legalExpensePaid)+(a.expenseReserve-a.expensePaid))) over (order by a.claimId, a.dateChanged)
				else 0 end AS expenseReserve
				from Windhaven_Report.dbo.ClaimLog a
				join [Windhaven_Report].dbo.claim on a.claimIncidentID = claim.claimIncidentID
				join [Windhaven_Report].dbo.claimincident on claim.claimincidentId = claimincident.claimincidentId
				join [Windhaven_Report].dbo.claimincidentauto on claimincidentAuto.claimincidentId = claimincident.claimincidentId
				join [Windhaven_Report].dbo.policy on policy.policyId = claimincident.policyId
				where convert(date,dateOfLoss) between @quarterStart and @quarterEnd
				and convert(date,claim.dateOpened) <= @asOfDate
				and convert(date,a.dateChanged) <= @asOfDate) b
				group by policyNum, objectId, effecDate
				) as Source
				on Source.reportStart = Target.RPT_START_DATE
				and Source.reportEnd = Target.RPT_END_DATE
				and Source.policyNum = Target.POLICY_NUM
				and Source.objectId = Target.VEH_NUM
				and Source.effecDate = Target.POLICY_EFF
	
				when matched then 
					update set Target.PIP_CLAIM = Source.PIP_INCUR,
						Target.PD_CLAIM = Source.PD_INCUR,
						Target.BI_CLAIM = Source.BI_INCUR,
						Target.CMP_CLAIM = Source.CMP_INCUR,
						Target.COL_CLAIM = Source.COL_INCUR,
						Target.PIP_ALAE = Source.PIP_EXPEN,
						Target.PD_ALAE = Source.PD_EXPEN,
						Target.BI_ALAE = Source.BI_EXPEN,
						Target.CMP_ALAE = Source.CMP_EXPEN,
						Target.COL_ALAE = Source.COL_EXPEN
				when not matched by Target then
				insert (RPT_START_DATE, RPT_END_DATE, POLICY_NUM, VEH_NUM, POLICY_EFF,
					PIP_CLAIM, PD_CLAIM, BI_CLAIM, CMP_CLAIM, COL_CLAIM,
					PIP_ALAE, PD_ALAE, BI_ALAE, CMP_ALAE, COL_ALAE )
				VALUES (Source.reportStart, Source.reportEnd, Source.policyNum,  Source.objectId, Source.effecDate,
					Source.PIP_INCUR, Source.PD_INCUR, Source.BI_INCUR, Source.CMP_INCUR, Source.COL_INCUR,
					Source.PIP_EXPEN, Source.PD_EXPEN, Source.BI_EXPEN, Source.CMP_EXPEN, Source.COL_EXPEN
					);
			-- cwip count

			-- loss count
						merge RATE_FILING_TEMP Target
			using (select @quarterStart as reportStart, @quarterEnd as reportEnd, 
			policyNum, vehicleId as objectId, convert(date,policy.effectiveDate) as effecDate,
			count(case when policyCoveragesId = 22 then 1 end) as pipLossCount,
			count(case when policyCoveragesId = 12 then 1 end) as pdLossCount,
			count(case when policyCoveragesId = 11 then 1 end) as biLossCount,
			count(case when policyCoveragesId = 20 then 1 end) as cmpLossCount,
			count(case when policyCoveragesId = 19 then 1 end) as colLossCount
			from [Windhaven_Report].dbo.claim
			join [Windhaven_Report].dbo.claimincident on claim.claimincidentId = claimincident.claimincidentId
			join [Windhaven_Report].dbo.claimincidentauto on claimincidentAuto.claimincidentId = claimincident.claimincidentId
			join [Windhaven_Report].dbo.policy on policy.policyId = claimincident.policyId
			where convert(date,dateOfLoss) between @quarterStart and @quarterEnd
			 and convert(date,claim.dateOpened) <= @asOfDate
				group by policyNum, vehicleId, convert(date,policy.effectiveDate)) as Source
				on Source.reportStart = Target.RPT_START_DATE
				and Source.reportEnd = Target.RPT_END_DATE
				and Source.policyNum = Target.POLICY_NUM
				and Source.objectId = Target.VEH_NUM
				and Source.effecDate = Target.POLICY_EFF
	
				when matched then 
					update set Target.PIP_LOSS_COUNT = Source.pipLossCount,
						Target.PD_LOSS_COUNT = Source.pdLossCount,
						Target.BI_LOSS_COUNT = Source.biLossCount,
						Target.CMP_LOSS_COUNT = Source.cmpLossCount,
						Target.COL_LOSS_COUNT = Source.colLossCount
				when not matched by Target then
				insert (RPT_START_DATE, RPT_END_DATE, POLICY_NUM, VEH_NUM, POLICY_EFF,
					PIP_LOSS_COUNT, PD_LOSS_COUNT, BI_LOSS_COUNT, CMP_LOSS_COUNT, COL_LOSS_COUNT )
				VALUES (Source.reportStart, Source.reportEnd, Source.policyNum,  Source.objectId, Source.effecDate,
					Source.pipLossCount, Source.pdLossCount, Source.biLossCount, Source.cmpLossCount, Source.colLossCount);
			-- crlep
			fetch next from @quarterCursor into @quarterStart, @quarterEnd
		end;

		set @tableName = concat('Periscope_Data.dbo.RATE_FILING_',@program,'_',@tableMonthLabel);
		if object_id(@tableName, 'U') is not null
			begin
			set @SQL = concat('drop table ',@tableName);
			exec(@SQL);
			end;
		set @SQL = concat('select * into ',@tableName,' from RATE_FILING_TEMP;');
		exec(@SQL); 


		fetch next from @progCursor into @program
	end;
	close @progCursor;
	deallocate @progCursor;
GO

