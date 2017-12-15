USE [Periscope_Data]
GO

/****** Object:  StoredProcedure [dbo].[cessionsReport]    Script Date: 12/15/2017 4:37:26 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

create procedure [dbo].[cessionsReport]
	@dateUsed date
as
	declare @monthStart date,
		@priorMonth date;

	set @monthStart = DATEFROMPARTS(year(@dateUsed),month(@dateUsed),1);
	set @priorMonth = dateadd(day,-1,@monthStart);

	if object_id('dbo.cessionsCurrentRegister', 'U') is not null
		drop table dbo.cessionsCurrentRegister;


	create table dbo.cessionsCurrentRegister
	(RegisterDate date, ProgNum integer, Treaty integer, Subtreaty integer,
		WrittenPremium decimal(15,2) default 0, EarnedPremium decimal(15,2) default 0,
		PolicyFee decimal(15,2) default 0, SR22Fee decimal(15,2) default 0,
		ATPFee decimal(15,2) default 0, ConvFee decimal(15,2) default 0,
		ClubFee decimal(15,2) default 0, CancFee decimal(15,2) default 0,
		BillFee decimal(15,2) default 0, 
		GrossCollected decimal(15,2) default 0, Collected decimal(15,2) default 0,
		PriorReceivables decimal(15,2) default 0, CurrentReceivables decimal(15,2) default 0,
		NetReceivables decimal(15,2) default 0,
		PaidClaims decimal(15,2) default 0, Recoveries decimal(15,2) default 0,
		OSLegal decimal(15,2) default 0, IME_EUO_INT decimal(15,2) default 0,
		ClaimReserves decimal(15,2) default 0, ExpenseReserves decimal(15,2) default 0,
		IncurredLosses decimal(15,2) default 0,
		ULAE decimal(15,2) default 0, CededTotal decimal(15,2) default 0,
		QSTotal decimal(15,2) default 0, Retained decimal(15,2) default 0, 
		primary key (RegisterDate, ProgNum, Treaty, Subtreaty));

	-- WRITTEN PREMIUM

	insert into dbo.cessionsCurrentRegister
	(RegisterDate,ProgNum,Treaty,Subtreaty,WrittenPremium)
	select @dateUsed, ratingProgram, 
	coalesce(Treaty,0) as TREATY,
	coalesce(Subtreaty,0) as SUBTREATY,
	sum(changeInTPD) as WrittenPremium
	from [Windhaven_Report].dbo.CoveragePremium
	join [Windhaven_Report].dbo.Policy on Policy.policyID = CoveragePremium.policyId
	left join dbo.Treaties on MGA = case when ratingProgram = 16 then 'WU' when ratingProgram in (22,23,24) then 'WS' end
		and (invEnd is null or convert(date,transactionDate) < invEnd)
		and ((convert(date,effectiveDate) between effStart and effEnd) 
		or (convert(date,transactionDate) >= invStart and convert(date,effectiveDate) <= effend))
	where transactionDate between @monthStart and @dateUsed
	group by ratingProgram,coalesce(Treaty,0),coalesce(Subtreaty,0);

	-- EARNED PREMIUM	

	merge dbo.cessionsCurrentRegister as Target
	using (select @dateUsed as RegisterDate, ratingProgram as ProgNum, 
	coalesce(Treaty,0) as Treaty,
	coalesce(Subtreaty,0) as Subtreaty,
	sum(coalesce(round(changeInTPD*
			case when transactionDate > @dateUsed or dateeffective > @dateUsed then null
			else
				coalesce(round(cast((1 + datediff(day,dateeffective,
					case when @dateUsed >expirationDate 
				then expirationDate else @dateUsed end
				)) as decimal)/cast(nullif((1+datediff(day,dateeffective,expirationDate)),0) as decimal),4),1) end,2),0))
	-
	sum(coalesce(round(changeInTPD*
			case when transactionDate > @priorMonth or dateeffective > @priorMonth then null
			else
				coalesce(round(cast((1 + datediff(day,dateeffective,
					case when @priorMonth >expirationDate 
				then expirationDate else @priorMonth end
				)) as decimal)/cast(nullif((1+datediff(day,dateeffective,expirationDate)),0) as decimal),4),1) end,2),0)) as EarnedPremium
	from [Windhaven_Report].dbo.CoveragePremium
	join [Windhaven_Report].dbo.Policy on Policy.policyID = CoveragePremium.policyId
	left join dbo.Treaties on MGA = case when ratingProgram = 16 then 'WU' when ratingProgram in (22,23,24) then 'WS' end
		and (invEnd is null or convert(date,transactionDate) < invEnd)
		and ((convert(date,effectiveDate) between effStart and effEnd) 
		or (convert(date,transactionDate) >= invStart and convert(date,effectiveDate) <= effend))
	where transactionDate <= @dateUsed
	group by ratingProgram,coalesce(Treaty,0),coalesce(Subtreaty,0)) as Source
	on (Target.RegisterDate = Source.RegisterDate and Target.ProgNum = Source.ProgNum
		and Target.Treaty = Source.Treaty and Target.Subtreaty = Source.Subtreaty)
	when matched then
		update set Target.EarnedPremium = Source.EarnedPremium
	when not matched by Target then
		insert (RegisterDate, ProgNum, Treaty, Subtreaty, EarnedPremium)
		values (Source.RegisterDate, Source.ProgNum, Source.Treaty, Source.Subtreaty,
			Source.EarnedPremium);
	
	-- CLAIMS AMOUNTS
	
	merge dbo.cessionsCurrentRegister as Target
	using (select @dateUsed as RegisterDate, ratingProgram as ProgNum, 
	coalesce(Treaty,0) as Treaty,
	coalesce(Subtreaty,0) as Subtreaty,
sum(paidAMount) as paidAmount,
sum(reserveAmount) as reserveAmount,
sum(recoveryAmount) as recoveryAmount,
sum(legalExpense) as legalExpense,
sum(otherExpense) as otherExpense,
sum(expenseReserve) as expenseReserve
from (
select a.claimLogId, a.claimId, a.dateChanged,ratingProgram, Treaty, Subtreaty,
a.lossPaid - case when
lag(a.claimId) over (order by a.claimId, a.dateChanged) = a.claimId
then
lag(a.lossPaid) over (order by a.claimId, a.dateChanged)
else 0 end AS paidAmount,
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
lag(claimId) over (order by a.claimId, a.dateChanged) = a.claimId
then
lag(((a.legalExpenseReserve-a.legalExpensePaid)+(a.expenseReserve-a.expensePaid))) over (order by a.claimId, a.dateChanged)
else 0 end AS expenseReserve
from Windhaven_Report.dbo.ClaimLog a
join Windhaven_Report.dbo.ClaimIncident on a.claimIncidentID = ClaimIncident.claimIncidentID
join Windhaven_Report.dbo.policy on policy.policyID = ClaimIncident.policyId
left join Periscope_Data.dbo.Treaties on MGA = case when ratingProgram = 16 then 'WU' when ratingProgram in (22,23,24) then 'WS' end
	and (invEnd is null or convert(date,dateOfLoss) < invEnd)
	and ((convert(date,effectiveDate) between effStart and effEnd) 
	or (convert(date,dateOfLoss) >= invStart and convert(date,effectiveDate) <= effend))) b
where convert(date,dateChanged) between @monthStart and @dateUsed
group by ratingProgram,coalesce(Treaty,0),coalesce(Subtreaty,0)) as Source
	on (Target.RegisterDate = Source.RegisterDate and Target.ProgNum = Source.ProgNum
		and Target.Treaty = Source.Treaty and Target.Subtreaty = Source.Subtreaty)
	when matched then
		update set Target.PaidClaims = Source.paidAmount,
			Target.ClaimReserves = Source.reserveAmount,
			Target.Recoveries = Source.recoveryAmount,
			Target.OSLegal = Source.legalExpense,
			Target.IME_EUO_INT = Source.otherExpense,
			Target.ExpenseReserves = Source.expenseReserve
	when not matched by Target then
	insert (RegisterDate, ProgNum, Treaty, Subtreaty, 
		PaidClaims,ClaimReserves,Recoveries,
		OSLegal, IME_EUO_INT, ExpenseReserves)
	values (Source.RegisterDate, Source.ProgNum, Source.Treaty, Source.Subtreaty,
		Source.paidAmount,Source.reserveAmount,Source.recoveryAmount,
		Source.legalExpense,Source.otherExpense,Source.expenseReserve);

	-- FEES

	-- COLLECTED

	merge dbo.cessionsCurrentRegister as Target
	using (select @dateUsed as RegisterDate, ratingProgram as ProgNum, 
	coalesce(Treaty,0) as Treaty,
	coalesce(Subtreaty,0) as Subtreaty,
	sum(amount) as Collected
	from [Windhaven_Report].dbo.Trans
	join [Windhaven_Report].dbo.Policy on Policy.policyID = trans.policyId
	left join dbo.Treaties on MGA = case when ratingProgram = 16 then 'WU' when ratingProgram in (22,23,24) then 'WS' end
		and (invEnd is null or convert(date,transDate) < invEnd)
		and ((convert(date,effectiveDate) between effStart and effEnd) 
		or (convert(date,transDate) >= invStart and convert(date,effectiveDate) <= effend))
	where transDate between @monthStart and @dateUsed and transType = 0
	group by ratingProgram,coalesce(Treaty,0),coalesce(Subtreaty,0)) as Source
	on (Target.RegisterDate = Source.RegisterDate and Target.ProgNum = Source.ProgNum
		and Target.Treaty = Source.Treaty and Target.Subtreaty = Source.Subtreaty)
	when matched then
		update set Target.Collected = Source.Collected
	when not matched by Target then
	insert (RegisterDate, ProgNum, Treaty, Subtreaty, Collected)
	values (Source.RegisterDate, Source.ProgNum, Source.Treaty, Source.Subtreaty,
		Source.Collected);

GO

