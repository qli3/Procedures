USE [Periscope_Data]
GO

/****** Object:  StoredProcedure [dbo].[prem_losses]    Script Date: 12/15/2017 4:40:18 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

create procedure [dbo].[prem_losses] @reg_date date
as
	declare @reg_date2 date, @temp_date date;
	set @reg_date2 = eomonth(dateadd(month,-1,@reg_date));
	declare @treaty_assign varchar(max), @treaty_assign_receiv varchar(max),
		@sqlCode nvarchar(max);
	declare @i integer, @j integer;
	declare @metrics table(idx int identity(1,1), metric_name varchar(50),
		policy_eff varchar(max), tran_date varchar(max), tables varchar(max),
		equation varchar(max), group_by varchar(max), coverage varchar(max), where_statement varchar(max), loss_year varchar(max),
		primary key(idx));
	declare @metric_name varchar(max), @policy_eff varchar(max), @tran_date varchar(max),
		@tables varchar(max), @equation varchar(max), @group_by varchar(max), @treaty_sql varchar(max), @coverage varchar(max), @where_statement varchar(max),
		@loss_year varchar(max);
	delete from Periscope_Data.dbo.exhibit_prem_losses
	where Register = @reg_date;
	/*
	drop table Periscope_Data.dbo.exhibit_prem_losses;
	create table Periscope_Data.dbo.exhibit_prem_losses
	(Register date, STATE varchar(15), PROGRAM INTEGER, 
	TREATY decimal(3,1), COVERAGE varchar(7), LOSS_YEAR integer,
	METRIC varchar(50),
	MTD decimal(25,5), ITD decimal(25,5),
	primary key (Register, STATE, METRIC, PROGRAM, TREATY, COVERAGE, LOSS_YEAR));
	*/

insert into @metrics(metric_name, policy_eff, tran_date, tables, equation, group_by, coverage, where_statement, loss_year)
	values
		-- written premium
		(concat(char(39),'Written Premium',char(39)), -- metric_name
		'cast(convert(char(8),convert(date,effectiveDate),112) as int)', -- policy_eff
		'cast(convert(char(8),convert(date,transactionDate),112) as int)', -- tran_date
		'	from [Windhaven_Report].dbo.CoveragePremium 
			join [Windhaven_Report].dbo.Policy on Policy.policyID = CoveragePremium.policyId', -- tables
		'sum(changeInTPD)', -- equation
		', coverage', -- group_by
		'coverage', -- coverage
		'', -- where_statement
		'0' -- loss_year
		),
		-- earned premium
		(concat(char(39),'Earned Premium',char(39)), -- metric_name
		'cast(convert(char(8),convert(date,effectiveDate),112) as int)', -- policy_eff
		'cast(convert(char(8),convert(date,transactionDate),112) as int)', -- tran_date
		'	from [Windhaven_Report].dbo.CoveragePremium T1
			join [Windhaven_Report].dbo.Policy T2 on T2.policyID = T1.policyId
			left join Windhaven_Report.options.Options T5 ON T5.ptsValue = T1.changeType AND T5.typesID = 2', -- tables
		concat('sum(  (CASE
						WHEN T1.changeInTPD = 0 THEN 0
						ELSE CASE
							WHEN T5.longName = ',char(39),'Activiation',char(39),' THEN (T1.changeInTPD / (DATEDIFF(D, T2.effectiveDate, T2.expirationDate)))
							ELSE (T1.changeInTPD / (DATEDIFF(D, T1.dateEffective, T2.expirationDate)))
						  END
					  END)
					  *
					  (    CASE
						WHEN CAST(T1.dateEffective AS date) > @reg_date OR CAST(T2.effectiveDate AS DATE)> @reg_date THEN 0 -- when after date range then 0    
						ELSE CASE
							WHEN CAST(T2.expirationDate AS date) > @reg_date THEN CASE
								WHEN T5.longName = ',char(39),'Activiation',char(39),' THEN (1 + DATEDIFF(D, T2.effectiveDate, @reg_date))
								ELSE (1 + DATEDIFF(D, T1.dateEffective, @reg_date))
								END
							ELSE CASE
								WHEN T5.longName = ',char(39),'Activiation',char(39),' THEN (1 + DATEDIFF(D, T2.effectiveDate, T2.expirationDate))
								ELSE (1 + DATEDIFF(D, T1.dateEffective, T2.expirationDate))
								 END 
							END 
					   END ))'), -- equation
		', coverage', -- group_by
		'coverage', -- coverage
		'', -- where_statement
		'0' -- loss_year
		),
		-- fees
		('grouping', -- metric_name
		'cast(convert(char(8),convert(date,policy.effectiveDate),112) as int)', -- policy_eff
		'cast(convert(char(8),convert(date,transDate),112) as int)', -- tran_date
		concat('	from [Windhaven_Report].dbo.Trans 
			join [Windhaven_Report].dbo.Policy on Policy.policyID = trans.policyId
			Left join [Windhaven_Report].dbo.Payment on Payment.paymentID=trans.paymentID
			join (select ',char(39),'Collected Premium',char(39),' as grouping, 0 as groupTrans, 0 as groupSub
			union all select ',char(39),'SR-22 Fees',char(39),' as grouping, 6 as groupTrans, 2 as groupSub
			union all select ',char(39),'Policy Fees',char(39),' as grouping, 2 as groupTrans, 0 as groupSub
			union all select ',char(39),'Bill + SENL Fees',char(39),' as grouping, 5 as groupTrans, 0 as groupSub
			union all select ',char(39),'Bill + SENL Fees',char(39),' as grouping, 25 as groupTrans, 0 as groupSub
			union all select ',char(39),'Bill + SENL Fees',char(39),' as grouping, 1 as groupTrans, 0 as groupSub
				) b on 1 = 1'), -- tables
		'sum(case when transType = groupTrans and transSubType = groupSub then Trans.amount end)', -- equation
		', grouping ', -- group_by
		concat(char(39),char(39)), -- coverage
		'And Payment.paymentType NOT IN (28,31)', -- where_statement
		'0' -- loss_year
		),
		-- claims
		('grouping', -- metric_name
		'cast(convert(char(8),convert(date,policyEffectiveDate),112) as int)', -- policy_eff
		'cast(convert(char(8),convert(date,TranDate),112) as int)', -- tran_date
		concat('		from (
		select ClaimNumber, ratingProgram, Coverage, TranDate, dateOpened, Loss_Date, policyEffectiveDate, source, rowNum,
		lossPaid - coalesce(lag(lossPaid) over(partition by ClaimNumber, Coverage order by TranDate, rowNum),0) as paidAmount,
		lossReserve - coalesce(lag(lossReserve) over(partition by ClaimNumber, Coverage order by TranDate, rowNum),0) as reserveAmount,
		recovery - coalesce(lag(recovery) over(partition by ClaimNumber, Coverage order by TranDate, rowNum),0) as recoveryAmount,
		legal - coalesce(lag(legal) over(partition by ClaimNumber, Coverage order by TranDate, rowNum),0) as legalAmount,
		ExpensesPaid - coalesce(lag(ExpensesPaid) over(partition by ClaimNumber, Coverage order by TranDate, rowNum),0) as expenseAmount,
		ExpenseReserve - coalesce(lag(ExpenseReserve) over(partition by ClaimNumber, Coverage order by TranDate, rowNum),0) as expenseReserveAmount,
		ime_euo - coalesce(lag(ime_euo) over(partition by ClaimNumber, Coverage order by TranDate, rowNum),0) as imeeuoAmount
		from (select a.*,
		row_number() over(order by ClaimNumber, Coverage, TranDate) as rowNum
		from (select ClaimNumber, ratingProgram, Coverage, TranDate,TranDate as dateOpened, Loss_Date, policyEffectiveDate,
		 sum(Amount) over(partition by ClaimNumber, Coverage order by TranDate asc, rowNum asc ) as lossPaid,
		 sum(Reserve) over(partition by ClaimNumber, Coverage order by TranDate asc, rowNum asc ) as lossReserve,
		0 as recovery, 0 as Legal, 0 as ExpensesPaid, 0 as ExpenseReserve, 0 as ime_euo, ',char(39),'B2',char(39),' as source
		from (
		select ClaimNumber, ratingProgram,Coverage, TranDate, Loss_Date, policy.effectiveDate as policyEffectiveDate, case when TranType = ',char(39),'Payment',char(39),' then Amount else 0 end as Amount,
		case when TranType = ',char(39),'Reserve',char(39),' then Amount else 0 end as Reserve,
		row_number() over(order by ClaimNumber, Coverage, TranDate) as rowNum
		from Periscope_Data.B2_Data.Claims_Trans 
		left join Windhaven_Report.dbo.policy on left(ClaimNumber,19) = policyNum) b
		union all
		select a.claimNum, ratingProgram,
		case a.policyCoveragesId when 20 then ',char(39),'COL',char(39),' when 19 then ',char(39),'CMP',char(39),' when 11 then '
			,char(39),'BI',char(39),' when 12 then ',char(39),'PD',char(39),' when 22 then ',char(39),'PIP',char(39),'
			when 15 then ',char(39),'UMPD',char(39),' when 14 then ',char(39),'UMBI',char(39),' when 27 then '
			,char(39),'RENT',char(39),' when 24 then ',char(39),'TOW',char(39),' when 18 then '
			,char(39),'UNPD',char(39),'when 36 then ',char(39),'UNBI',char(39),' when 51 then ',char(39),'CDW',char(39),'
		end,
		a.dateChanged, a.dateOpened, dateOfLoss, policy.effectiveDate,
		a.lossPaid, 
		case when a.lossReserve-a.lossPaid < 0 then 0 else a.lossReserve-a.lossPaid end as Reserve, 
		a.salvagePaid+a.subrogationPaid as recovery,
		a.legalExpensePaid as legal,
		a.legalExpensePaid+a.expensePaid as expensesPaid,
		case when a.expenseReserve-a.expensePaid < 0 then 0 else a.expenseReserve-a.expensePaid end
		+case when a.legalExpenseReserve-a.legalExpensePaid < 0 then 0 else a.legalExpenseReserve-a.legalExpensePaid end as ExpenseReserve,
		a.expensePaid as ime_euo,',char(39),'SV',char(39),'
		from Windhaven_Report.dbo.ClaimLog a
		join Windhaven_Report.dbo.claim on a.claimID = claim.claimID
		join Windhaven_Report.dbo.claimincident on claim.claimincidentId = claimincident.claimincidentId
		join Windhaven_Report.dbo.policy on policy.policyId = claimincident.policyId
		where a.claimNum <> ',char(39),'0',char(39),') a) a) b
		join (select ',char(39),'Claim Paid',char(39),' as grouping, 0 as metricUsed
			union all select ',char(39),'Claim Reserve',char(39),' as grouping, 1 as metricUsed
			union all select ',char(39),'Recoveries',char(39),' as grouping, 2 as metricUsed
			union all select ',char(39),'Legal',char(39),' as grouping, 3 as metricUsed
			union all select ',char(39),'IME-EUO-INT',char(39),' as grouping, 4 as metricUsed
			union all select ',char(39),'Expenses Paid',char(39),' as grouping, 5 as metricUsed
			union all select ',char(39),'Expense Reserve',char(39),' as grouping, 6 as metricUsed) c on 1 = 1'), -- tables
		'sum(case when metricUsed = 0 then paidAmount
				  when metricUsed = 1 then reserveAmount
				  when metricUsed = 2 then recoveryAmount
				  when metricUsed = 3 then legalAmount
				  when metricUsed = 4 then expenseAmount
				  when metricUsed = 5 then expenseReserveAmount
				  when metricUsed = 6 then imeeuoAmount end)', -- equation
		', grouping, coverage, year(Loss_Date) ', -- group_by
		'coverage', -- coverage
		'', -- where_statement
		'year(Loss_Date)' -- loss_year
		),
		-- receivables
		-- written premium advance booking
		(concat(char(39),'Written Premium Advance Booking',char(39)), -- metric_name
		'cast(convert(char(8),convert(date,effectiveDate),112) as int)', -- policy_eff
		'cast(convert(char(8),convert(date,transactionDate),112) as int)', -- tran_date
		'	from [Windhaven_Report].dbo.CoveragePremium 
			join [Windhaven_Report].dbo.Policy on Policy.policyID = CoveragePremium.policyId', -- tables
		'sum(changeInTPD)', -- equation
		', coverage', -- group_by
		'coverage', -- coverage
		' and convert(date,effectiveDate) <= @reg_date ', -- where_statement
		'0' -- loss_year
		),
		-- policy fee advance booking
		
		(concat(char(39),'Policy Fee Advance Premium',char(39)), -- metric_name
		'cast(convert(char(8),convert(date,policy.effectiveDate),112) as int)', -- policy_eff
		'cast(convert(char(8),convert(date,transDate),112) as int)', -- tran_date
		'	from [Windhaven_Report].dbo.Trans 
			join [Windhaven_Report].dbo.Policy on Policy.policyID = trans.policyId', -- tables
		'sum(amount)', -- equation
		' ', -- group_by
		concat(char(39),char(39)), -- coverage
		' and convert(date,effectiveDate) <= @reg_date and transType = 2 and transSubType = 0', -- where_statement
		'0' -- loss_year
		),
		-- other fees advance booking
		
		(concat('concat(grouping,',char(39),' Advance Premium',char(39),')'), -- metric_name
		'cast(convert(char(8),convert(date,case when transDate < policy.effectiveDate then transDate else policy.effectiveDate end),112) as int)', -- policy_eff
		'cast(convert(char(8),convert(date,transDate),112) as int)', -- tran_date
		concat('	from [Windhaven_Report].dbo.Trans 
			join [Windhaven_Report].dbo.Policy on Policy.policyID = trans.policyId
			Left join [Windhaven_Report].dbo.Payment on Payment.paymentID=trans.paymentID
			join (select ',char(39),'Collected Premium',char(39),' as grouping, 0 as groupTrans, 0 as groupSub
			union all select ',char(39),'SR-22 Fees',char(39),' as grouping, 6 as groupTrans, 2 as groupSub
			union all select ',char(39),'Bill + SENL Fees',char(39),' as grouping, 5 as groupTrans, 0 as groupSub
			union all select ',char(39),'Bill + SENL Fees',char(39),' as grouping, 25 as groupTrans, 0 as groupSub
			union all select ',char(39),'Bill + SENL Fees',char(39),' as grouping, 1 as groupTrans, 0 as groupSub
				) b on 1 = 1'), -- tables
		'sum(case when transType = groupTrans and transSubType = groupSub then Trans.amount end)', -- equation
		', grouping ', -- group_by
		concat(char(39),char(39)), -- coverage
		'And Payment.paymentType NOT IN (28,31) ', -- where_statement
		'0' -- loss_year
		)
		;

	
set @treaty_assign = '
case 
when PROGRAM_NUMBER = 6 then
	case 
	when (POLICY_EFFECTIVE <= 20070331) or @reg_date <= 20070331 then 1.1
	when (POLICY_EFFECTIVE between 20070401 and 20071031 and TRAN_DATE < 20071101) or @reg_date <= 20071031 then 1.2
	when (POLICY_EFFECTIVE between 20071101 and 20080930 or (TRAN_DATE >= 20071101 and POLICY_EFFECTIVE <= 20080930)) 
			or @reg_date <= 20080930 then 2.1
	when (POLICY_EFFECTIVE between 20081001 and 20090930) or @reg_date <= 20090930 then 3.1
	when (POLICY_EFFECTIVE between 20091001 and 20100930) or @reg_date <= 20100930 then 3.2
	when (POLICY_EFFECTIVE between 20101001 and 20110331 and TRAN_DATE < 20110401) or @reg_date <= 20110331 then 3.3
	when ((POLICY_EFFECTIVE between 20110401 and 20110930 and TRAN_DATE < 20111001) 
			or (TRAN_DATE between 20110401 and 20110930 and POLICY_EFFECTIVE <= 20110930))
			or @reg_date <= 20110930 then 4.1
	when (POLICY_EFFECTIVE between 20111001 and 20111231 or (TRAN_DATE >= 20111001 and POLICY_EFFECTIVE <= 20111231))
			or @reg_date <= 20111231 then 4.2
	when (POLICY_EFFECTIVE between 20120101 and 20120930) or @reg_date <= 20120930 then 4.3
	when (POLICY_EFFECTIVE between 20121001 and 20121130) or @reg_date <= 20121130 then 5.1
	when (POLICY_EFFECTIVE between 20121201 and 20130930) or @reg_date <= 20130930 then 5.2
	when (POLICY_EFFECTIVE between 20131001 and 20140630) or @reg_date <= 20140630 then 5.3
	when (POLICY_EFFECTIVE between 20140701 and 20150630) or @reg_date <= 20150630 then 6.1
	when (POLICY_EFFECTIVE between 20150701 and 20160630) or @reg_date <= 20160630 then 6.2
	when (POLICY_EFFECTIVE between 20160701 and 20170630) or @reg_date <= 20170630 then 6.3
	when (POLICY_EFFECTIVE between 20170701 and 20180630) or @reg_date <= 20180630 then 7.1
	end
when PROGRAM_NUMBER in (7,8,9) THEN
	case
	when (POLICY_EFFECTIVE <= 20120930) or @reg_date <= 20120930 then 1.1
	when (POLICY_EFFECTIVE between 20121001 and 20121130) or @reg_date <= 20121130 then 2.1
	when (POLICY_EFFECTIVE between 20121201 and 20130930) or @reg_date <= 20130930 then 2.2
	when (POLICY_EFFECTIVE between 20131001 and 20140630) or @reg_date <= 20140630 then 2.3
	when (POLICY_EFFECTIVE between 20140701 and 20150630) or @reg_date <= 20150630 then 3.1
	when (POLICY_EFFECTIVE between 20150701 and 20160630) or @reg_date <= 20160630 then 3.2
	when (POLICY_EFFECTIVE between 20160701 and 20170630) or @reg_date <= 20170630 then 3.3
	when (POLICY_EFFECTIVE between 20170701 and 20180630) or @reg_date <= 20180630 then 4.1
	end
when PROGRAM_NUMBER=0 Then


Case 

    when (POLICY_EFFECTIVE between 20150701 and 20160630) or @reg_date <= 20160630 then 1.0
	when (POLICY_EFFECTIVE between 20160701 and 20170630) or @reg_date <= 20170630 then 2.0
	when (POLICY_EFFECTIVE between 20170701 and 20180630) or @reg_date <= 20180630 then 3.0
	End

	when PROGRAM_NUMBER =1 Then
	Case 

    when (POLICY_EFFECTIVE between 20150701 and 20160630) or @reg_date <= 20160630 then 1.1
	when (POLICY_EFFECTIVE between 20160701 and 20170630) or @reg_date <= 20170630 then 2.1
	when (POLICY_EFFECTIVE between 20170701 and 20180630) or @reg_date <= 20180630 then 3.1
	End
	when PROGRAM_NUMBER =2 Then
	Case 

    when (POLICY_EFFECTIVE between 20150701 and 20160630) or @reg_date <= 20160630 then 1.2
	when (POLICY_EFFECTIVE between 20160701 and 20170630) or @reg_date <= 20170630 then 2.2
	when (POLICY_EFFECTIVE between 20170701 and 20180630) or @reg_date <= 20180630 then 3.2
	End
	when PROGRAM_NUMBER =3 Then
	Case 

    when (POLICY_EFFECTIVE between 20150701 and 20160630) or @reg_date <= 20160630 then 1.3
	when (POLICY_EFFECTIVE between 20160701 and 20170630) or @reg_date <= 20170630 then 2.3
	when (POLICY_EFFECTIVE between 20170701 and 20180630) or @reg_date <= 20180630 then 3.3
	End
	when PROGRAM_NUMBER =4 Then
	Case 

    when (POLICY_EFFECTIVE between 20150701 and 20160630) or @reg_date <= 20160630 then 1.4
	when (POLICY_EFFECTIVE between 20160701 and 20170630) or @reg_date <= 20170630 then 2.4
	when (POLICY_EFFECTIVE between 20170701 and 20180630) or @reg_date <= 20180630 then 3.4
	End

	when PROGRAM_NUMBER =5 Then
	Case 

    when (POLICY_EFFECTIVE between 20150701 and 20160630) or @reg_date <= 20160630 then 1.5
	when (POLICY_EFFECTIVE between 20160701 and 20170630) or @reg_date <= 20170630 then 2.5
	when (POLICY_EFFECTIVE between 20170701 and 20180630) or @reg_date <= 20180630 then 3.5
	End

else
	case 
	when (POLICY_EFFECTIVE <= 20080930) or @reg_date <= 20080930 then 1.1
	when (POLICY_EFFECTIVE between 20081001 and 20090930) or @reg_date <= 20090930 then 2.1
	when (POLICY_EFFECTIVE between 20091001 and 20100930) or @reg_date <= 20100930 then 2.2
	when (POLICY_EFFECTIVE between 20101001 and 20110228) or @reg_date <= 20110228 then 2.3
	when (POLICY_EFFECTIVE between 20110301 and 20110930) or @reg_date <= 20110930 then 3.1
	when (POLICY_EFFECTIVE between 20111001 and 20120930) or @reg_date <= 20120930 then 3.2
	when (POLICY_EFFECTIVE between 20121001 and 20130930) or @reg_date <= 20130930 then 3.3
	when POLICY_EFFECTIVE >= 20131001 then 3.4
	end
end';

SET @treaty_assign_receiv = 
	replace(replace(replace(replace(replace(
	@treaty_assign,' and TRAN_DATE < 20071101',''),
	' or (TRAN_DATE >= 20071101 and POLICY_EFFECTIVE <= 20080930)',''),
	'(POLICY_EFFECTIVE between 20110401 and 20110930 and TRAN_DATE < 20111001) 
			or (TRAN_DATE between 20110401 and 20110930 and POLICY_EFFECTIVE <= 20110930)','POLICY_EFFECTIVE between 20110401 and 20110930'),
	' or (TRAN_DATE >= 20111001 and POLICY_EFFECTIVE <= 20111231)',''),
	' and TRAN_DATE < 20110401','');
set @j = 1;
while (@j <= (select count(*) from @metrics))
begin
	set @metric_name = (select metric_name from @metrics where idx = @j);
	set @policy_eff = (select policy_eff from @metrics where idx = @j);
	set @tran_date = (select tran_date from @metrics where idx = @j);
	set @tables = (select tables from @metrics where idx = @j);
	set @equation = (select equation from @metrics where idx = @j);
	set @group_by = (select group_by from @metrics where idx = @j);
	set @coverage = (select coverage from @metrics where idx = @j);
	set @where_statement = (select where_statement from @metrics where idx = @j);
	set @loss_year = (select loss_year from @metrics where idx = @j);

	set @i = 0;
	while @i <= 1
	begin
		set @temp_date = case when @i = 0 then @reg_date when @i = 1 then @reg_date2 end;
		set @treaty_sql = replace(replace(replace(@treaty_assign,
					'POLICY_EFFECTIVE',@policy_eff),'TRAN_DATE',@tran_date),
					'PROGRAM_NUMBER','ratingProgram');
			set @sqlCode = concat('merge Periscope_Data.dbo.exhibit_prem_losses as Target
			using (select ',char(39),@reg_date,char(39),' as Register,
				case when ratingProgram in (0,1,2,3,4,5) then ',char(39),'TX',char(39),'
				else ',char(39),'FL',char(39),' end as STATE,
				COALESCE(ratingProgram,0) as PROGRAM,
				COALESCE(',@treaty_sql,',0) as TREATY,
				COALESCE(',@coverage,',',char(39),char(39),') as coverage,
				COALESCE(',@loss_year,',0) as lossYear,
				',@metric_name,' as METRIC,
				',case when @i = 0 then '' else '-' end,@equation,' as MTD
				',case when @i = 0 then concat(', ',@equation,' as ITD') else '' end,'
				',@tables,'
				where ',@tran_date,' <= @reg_date ',@where_statement,'
				group by ',@treaty_sql,', ratingProgram',@group_by,'
				) as Source
			on Target.Register = Source.Register and Target.STATE = Source.STATE
				and Target.METRIC = Source.METRIC and Target.PROGRAM = Source.PROGRAM
				and Target.TREATY = Source.TREATY and Target.Coverage = Source.Coverage
				and Target.LOSS_YEAR = Source.lossYear
			when matched then update set Target.MTD = coalesce(Target.MTD,0) + coalesce(Source.MTD,0)',
				case when @i = 0 then ', Target.ITD = Source.ITD ' else '' end,'
			when not matched by Target then
			insert (Register, STATE, METRIC, PROGRAM, TREATY, COVERAGE, LOSS_YEAR, MTD',case when @i = 0 then ',ITD' else '' end,')
			values (Source.Register, Source.STATE, Source.METRIC, Source.PROGRAM, Source.TREATY, Source.COVERAGE, Source.lossYear, Source.MTD
				',case when @i = 0 then ',Source.ITD' else '' end,');');
			set @sqlCode = replace(@sqlCode,'@reg_date',concat(char(39),cast(convert(char(8),convert(date,@temp_date),112) as int),char(39)));

			EXEC sp_executesql @sqlCode;
		set @i = @i + 1;
	end;
	set @j = @j + 1;
end;
GO

