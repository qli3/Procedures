USE [Periscope_Data]
GO

/****** Object:  StoredProcedure [dbo].[HUDDLE_DATA_BY_DAY]    Script Date: 12/15/2017 4:39:01 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[HUDDLE_DATA_BY_DAY]
as
	declare @default_date date, @min_data date, @reg_date date, @reg_date2 date, @b2_cut_off date;

	/*
	drop table  Periscope_Data.dbo.HUDDLE_DATA;
	create table Periscope_Data.dbo.HUDDLE_DATA
	(DATA_DATE date, HUDDLE_METRIC varchar(50), METRIC_NUMBER decimal(25,5), STATE varchar(20),
	primary key (DATA_DATE, HUDDLE_METRIC, STATE));
	*/
set @b2_cut_off = convert(date,'2016-12-31');
set @default_date = convert(date,'2015-09-17');


set @min_data = (select coalesce(dateadd(day,1,max(DATA_DATE)),@default_date) from Periscope_Data.dbo.HUDDLE_DATA where HUDDLE_METRIC = 'PIF');

set @reg_date = @min_data;
while @reg_date < convert(date,getdate())
begin
	insert into Periscope_Data.dbo.HUDDLE_DATA
	select @reg_date, 'PIF', count(distinct(policyNum)), ProgState
	from Windhaven_Report.dbo.policy
	left join [Periscope_Data].dbo.ProgramNum on ProgNum = ratingProgram
	where left(policyNum,1) <> 'Q'
		and convert(date,boundDate) <= @reg_date
		and  convert(date,effectiveDate) <= @reg_date
		and  convert(date,expirationDate) > @reg_date
		and  (convert(date,cancelledDate) > @reg_date or cancelledDate is null)
	group by ProgState;
	set @reg_date = dateadd(day,1,@reg_date);
end;


set @min_data = (select coalesce(dateadd(day,1,max(DATA_DATE)),@default_date) from Periscope_Data.dbo.HUDDLE_DATA where HUDDLE_METRIC = 'PIF Increase');

insert into Periscope_Data.dbo.HUDDLE_DATA
select a.DATA_DATE, 'PIF Increase', sum(a.METRIC_NUMBER) - coalesce(sum(b.METRIC_NUMBER),0), a.STATE
from Periscope_Data.dbo.HUDDLE_DATA a
join Periscope_Data.dbo.HUDDLE_DATA b on a.HUDDLE_METRIC = b.HUDDLE_METRIC
	and a.DATA_DATE = dateadd(day,1,b.DATA_DATE) and a.STATE = b.STATE
where a.HUDDLE_METRIC = 'PIF'
	and a.DATA_DATE between @min_data and dateadd(day,-1,convert(date,getdate()))
group by a.DATA_DATE, a.STATE;

	

set @min_data = (select coalesce(dateadd(day,1,max(DATA_DATE)),@default_date) from Periscope_Data.dbo.HUDDLE_DATA where HUDDLE_METRIC in ('Sales','Policies Renewed','NB Premium','RN Premium'));

insert into Periscope_Data.dbo.HUDDLE_DATA
select Date,
type,
sum(case type when 'Sales' then NumberOfNB
when 'Policies Renewed' then NumberOfRN
when 'NB Premium' then NB_WP
when 'RN Premium' then RN_WP end), ProgState
from (select
count(distinct(case when p.isRenewal = 0 then c.policyID end)) as NumberOfNB,
count(distinct(case when p.isRenewal > 0 then c.policyID end)) as NumberOfRN,
sum(case when p.isRenewal = 0 then changeInTPD end) as NB_WP,
SUM(case when p.isRenewal > 0 then changeInTPD end) as RN_WP,
convert(date, boundDate) as Date, ProgState
from windhaven_report.dbo.CoveragePremium c
join windhaven_report.dbo.policy p on c.policyId = p.policyId
	left join [Periscope_Data].dbo.ProgramNum on ProgNum = ratingProgram
where p.Status not in (4,6,99)
and left (p.policynum,1) != 'Q'
and  convert(date,p.bounddate) < convert(date,getdate())
and convert(date,p.bounddate) >= @min_data
and c.changeType =1
group by convert(date, boundDate), ProgState) b
join (select 'Sales' as type union all select 'Policies Renewed' as type
	union all select 'NB Premium' as type union all select 'RN Premium' as type) a on 1 = 1
group by DAte, type, ProgState;

merge Periscope_Data.dbo.HUDDLE_DATA as Target
using (select date, type, 0 as metric, progState
from (select convert(date,dateadd(day,idx,@min_data)) as date
from Periscope_Data.dbo.DUMMY
where idx < datediff(day,@min_data,convert(date,getdate()))) a
join (select 'Sales' as type union all select 'Policies Renewed' as type
	union all select 'NB Premium' as type union all select 'RN Premium' as type) b on 1 = 1
join (select distinct STATE as progState from Periscope_Data.dbo.HUDDLE_DATA) c on 1 = 1) as Source
on DATA_DATE = date and HUDDLE_METRIC = type and STATE = ProgState
when not matched by Target then
insert (DATA_DATE, HUDDLE_METRIC, METRIC_NUMBER, STATE)
values (date, type, metric, ProgState);



set @min_data = (select coalesce(dateadd(day,1,max(DATA_DATE)),@default_date) from Periscope_Data.dbo.HUDDLE_DATA where HUDDLE_METRIC in ('APEX-STD Sales',
'APEX-LTD Sales',
'EDGE-STD Sales',
'EDGE-LTD Sales',
'PLUS-STD Sales',
'WIN Sales',
'OPT Sales',
'SEL Sales',
'ICN Sales'));

insert into Periscope_Data.dbo.HUDDLE_DATA
select convert(date,boundDate) as date, 
concat(quoteName,' Sales') as type,
count(distinct(policyId)), ProgSTate
from Windhaven_Report.dbo.policy
join Periscope_Data.dbo.ProgramNum on progNum = ratingProgram
where status not in (4,6,99)
and left (policynum,1) != 'Q'
and convert(date,bounddate) < convert(date,getdate())
and convert(date,bounddate) >= @min_data
and isRenewal = 0
group by convert(date,boundDate), quoteName, ProgState;

merge Periscope_Data.dbo.HUDDLE_DATA as Target
using (select date, type, 0 as metric, progState
from (select convert(date,dateadd(day,idx,@min_data)) as date
from Periscope_Data.dbo.DUMMY
where idx < datediff(day,@min_data,convert(date,getdate()))) a
join (select 'APEX-LTD Sales' as type union all select 'EDGE-STD Sales' as type
	union all select 'APEX-STD Sales' as type union all select 'EDGE-LTD Sales' as type union all select 'PLUS-STD Sales' as type union all select 'WIN Sales' as type union all select 'SEL Sales' as type union all select 'OPT Sales' as type union all select 'ICN Sales' as type) b on 1 = 1
join (select distinct STATE as progState from Periscope_Data.dbo.HUDDLE_DATA) c on 1 = 1) as Source
on DATA_DATE = date and HUDDLE_METRIC = type and STATE = ProgState
when not matched by Target then
insert (DATA_DATE, HUDDLE_METRIC, METRIC_NUMBER, STATE)
values (date, type, metric, ProgState);

	
set @min_data = (select coalesce(dateadd(day,1,max(DATA_DATE)),@default_date) from Periscope_Data.dbo.HUDDLE_DATA where HUDDLE_METRIC like 'Loss Count - %');

insert into Periscope_Data.dbo.HUDDLE_DATA
select convert(date,openDate), concat('Loss Count - ',cov), count(*), progState
from (
select claimNum, cov,progState, min(dateChanged) as openDate
from (
select claim.claimNum,
case when claim.coverageNotConfirmed in (2,4) then 'NC' else
case a.policyCoveragesId when 20 then 'COL' when 19 then 'CMP' when 11 then 'BI' when 12 then 'PD' when 22 then 'PIP'
	when 15 then 'UMPD' when 14 then 'UMBI' when 27 then 'RENT' when 24 then 'TOW' when 18 then 'UNPD'when 36 then 'UNBI' when 51 then 'CDW'
end
end as cov,
 a.dateOpened as dateChanged, progState
from Windhaven_Report.dbo.ClaimLog a
join Windhaven_Report.dbo.claim on a.claimID = claim.claimID
join Windhaven_Report.dbo.claimincident on claim.claimincidentId = claimincident.claimincidentId
join [Windhaven_Report].dbo.policy on policy.policyId = claimincident.policyId
join Periscope_Data.dbo.ProgramNum on progNum = ratingProgram
union all 
select ClaimNumber as claimNum,
replace(Coverage,'COM','CMP') as cov, TranDate as dateChanged, 'TX' as state
from Periscope_Data.B2_Data.Claims_Trans) b
where cov <> '*'
group by claimNum, cov, progState) b
where convert(date,openDate) >= @min_data
	and convert(date,openDate) < convert(date,getdate())
group by convert(date,openDate), concat('Loss Count - ',cov), progState;

merge Periscope_Data.dbo.HUDDLE_DATA as Target
using (select date, type, 0 as metric, progState
from (select convert(date,dateadd(day,idx,@min_data)) as date
from Periscope_Data.dbo.DUMMY
where idx < datediff(day,@min_data,convert(date,getdate()))) a
join (select 'Loss Count - PIP' as type union all select 'Loss Count - PD' as type
union all select 'Loss Count - BI' as type union all select 'Loss Count - CMP' as type
union all select 'Loss Count - COL' as type union all select 'Loss Count - UMBI' as type
union all select 'Loss Count - UMPD' as type) b on 1 = 1
join (select distinct STATE as progState from Periscope_Data.dbo.HUDDLE_DATA) c on 1 = 1) as Source
on DATA_DATE = date and HUDDLE_METRIC = type and STATE = ProgState
when not matched by Target then
insert (DATA_DATE, HUDDLE_METRIC, METRIC_NUMBER, STATE)
values (date, type, metric, ProgState);
	
set @min_data = (select coalesce(dateadd(day,1,max(DATA_DATE)),'2017-01-01') from Periscope_Data.dbo.HUDDLE_DATA where HUDDLE_METRIC like 'EXP - %');

set @reg_date = @min_data;
while @reg_date < convert(date,getdate())
begin
	set @reg_date2 = dateadd(day,-1,@reg_date);
	insert into Periscope_Data.dbo.HUDDLE_DATA
	select @reg_date, concat('EXP - ',case coverage when 'COLL' then 'COL' when 'COMP' then 'CMP' when 'OTC' then 'CMP' else coverage end),

	sum(
		coalesce(round(expAmount*
			case when transactionDate > 
				case when left(policyNum,1) <> 'T' and @reg_date < @b2_cut_off then @b2_cut_off else @reg_date end
				or dateeffective > case when left(policyNum,1) <> 'T' and @reg_date < @b2_cut_off then @b2_cut_off else @reg_date end then null
			else
				cast((1 + datediff(day,dateeffective,
					case when case when left(policyNum,1) <> 'T' and @reg_date < @b2_cut_off then @b2_cut_off else @reg_date end >expirationDate 
				then expirationDate else case when left(policyNum,1) <> 'T' and @reg_date < @b2_cut_off then @b2_cut_off else @reg_date end end
				)) as decimal)/cast(nullif((1+datediff(day,dateeffective,expirationDate)),0) as decimal) end,4),0))

	-
		sum(
		coalesce(round(expAmount*
			case when transactionDate > 
				case when left(policyNum,1) <> 'T' and @reg_date2 < @b2_cut_off then @b2_cut_off else @reg_date2 end
				or dateeffective > case when left(policyNum,1) <> 'T' and @reg_date2 < @b2_cut_off then @b2_cut_off else @reg_date2 end then null
			else
				cast((1 + datediff(day,dateeffective,
					case when case when left(policyNum,1) <> 'T' and @reg_date2 < @b2_cut_off then @b2_cut_off else @reg_date2 end >expirationDate 
				then expirationDate else case when left(policyNum,1) <> 'T' and @reg_date2 < @b2_cut_off then @b2_cut_off else @reg_date2 end end
				)) as decimal)/cast(nullif((1+datediff(day,dateeffective,expirationDate)),0) as decimal) end,4),0)) as exp_amount, progState
	from (
	select policyNum, coverage, changeType, progState, cast(datediff(day,dateEffective,expirationDAte) as decimal)/365*case when (fullTermPremium > 0 and priorAmount = 0 and changeType not in (3,5)) or changeType in (1,6) then 1
		when (fullTermPremium = 0 and priorAmount > 0) or (changeType in (3,5) and (priorAmount > 0)) then -1 else 0 end as expAmount, 
		transactionDate, dateeffective, expirationDate
	from (
	select policyNum, a.policyId, a.objectId, coverage,  a.changeType, progState,
	transactionDate, case when changeType = 1 then policy.effectiveDate else dateeffective end as dateEffective, fullTermPremium,
	changeInFullTermPremium,
	case when
			lag(concat(a.policyId, a.objectId, coverage)) over (order by a.policyId, a.objectId, coverage, transactionDate, coveragePremiumId) = concat(a.policyId, a.objectId, coverage)
			then
			lag(fullTermPremium) over (order by a.policyId, a.objectId, coverage, transactionDate, coveragePremiumId)
			else 0 end AS priorAmount,
	expirationDate
	 from windhaven_report.dbo.coveragepremium a
	join [Windhaven_Report].dbo.Policy on Policy.policyID = a.policyId
	join Periscope_Data.dbo.ProgramNum on progNum = ratingProgram) b
	where (convert(date,dateEffective) >= @reg_date2 or convert(date,expirationDate) >= @reg_date2 or convert(date,transactionDate) >= @reg_date2)
		and convert(date,transactionDate) <= @reg_date) b
	group by concat('EXP - ',case coverage when 'COLL' then 'COL' when 'COMP' then 'CMP' when 'OTC' then 'CMP' else coverage end), progState;

	set @reg_date = dateadd(day,1,@reg_date);
end;


	
set @min_data = (select coalesce(dateadd(day,1,max(DATA_DATE)),convert(date,'2017-01-01')) from Periscope_Data.dbo.HUDDLE_DATA where HUDDLE_METRIC like 'EP - %');

set @reg_date = @min_data;
while @reg_date < convert(date,getdate())
begin
	set @reg_date2 = dateadd(day,-1,@reg_date);
	insert into Periscope_Data.dbo.HUDDLE_DATA
	select @reg_date, concat('EP - ',case coverage when 'COLL' then 'COL' when 'COMP' then 'CMP' when 'OTC' then 'CMP' else coverage end),

	sum(
		coalesce(round(changeInTPD*
			case when transactionDate > 
				case when left(policyNum,1) <> 'T' and @reg_date < @b2_cut_off then @b2_cut_off else @reg_date end
				or case when changeType = 1 then policy.effectiveDate else dateeffective end > case when left(policyNum,1) <> 'T' and @reg_date < @b2_cut_off then @b2_cut_off else @reg_date end then null
			else
				cast((1 + datediff(day,case when changeType = 1 then policy.effectiveDate else dateeffective end,
					case when case when left(policyNum,1) <> 'T' and @reg_date < @b2_cut_off then @b2_cut_off else @reg_date end >expirationDate 
				then expirationDate else case when left(policyNum,1) <> 'T' and @reg_date < @b2_cut_off then @b2_cut_off else @reg_date end end
				)) as decimal)/cast(nullif((1+datediff(day,case when changeType = 1 then policy.effectiveDate else dateeffective end,expirationDate)),0) as decimal) end,4),0))

	-
		sum(
		coalesce(round(changeInTPD*
			case when transactionDate > 
				case when left(policyNum,1) <> 'T' and @reg_date2 < @b2_cut_off then @b2_cut_off else @reg_date2 end
				or case when changeType = 1 then policy.effectiveDate else dateeffective end > case when left(policyNum,1) <> 'T' and @reg_date2 < @b2_cut_off then @b2_cut_off else @reg_date2 end then null
			else
				cast((1 + datediff(day,case when changeType = 1 then policy.effectiveDate else dateeffective end,
					case when case when left(policyNum,1) <> 'T' and @reg_date2 < @b2_cut_off then @b2_cut_off else @reg_date2 end >expirationDate 
				then expirationDate else case when left(policyNum,1) <> 'T' and @reg_date2 < @b2_cut_off then @b2_cut_off else @reg_date2 end end
				)) as decimal)/cast(nullif((1+datediff(day,case when changeType = 1 then policy.effectiveDate else dateeffective end,expirationDate)),0) as decimal) end,4),0)) as exp_amount, progState

	 from windhaven_report.dbo.coveragepremium a
	join [Windhaven_Report].dbo.Policy on Policy.policyID = a.policyId
	join Periscope_Data.dbo.ProgramNum on progNum = ratingProgram
	group by concat('EP - ',case coverage when 'COLL' then 'COL' when 'COMP' then 'CMP' when 'OTC' then 'CMP' else coverage end),progState;

	set @reg_date = dateadd(day,1,@reg_date);
end;

	
set @min_data = (select coalesce(dateadd(day,1,max(DATA_DATE)),@default_date) from Periscope_Data.dbo.HUDDLE_DATA where HUDDLE_METRIC IN ('Inventory','Claim Closures'));

set @reg_date = @min_data;
while @reg_date < convert(date,getdate())
begin
	insert into Periscope_Data.dbo.HUDDLE_DATA
	SELECT @reg_date, metric, count(case when (metric = 'Claim Closures' and convert(date,closeDate) = @reg_date)
			or (metric = 'Inventory' and endingReserve > 0 ) then 1 end), progState
	FROM (select claimNum, cov, progState,
min(case when reserve <= 0 and priorReserve > 0 then dateChanged end) as closeDate,
max(CASE WHEN type <> 'B2' OR @reg_date < @b2_cut_off THEN endingReserve END) as endingReserve

from (select claimNum, cov, progState, type,
dateChanged, 
reserve,
case when
		lag(concat(claimNum,cov)) over (order by claimNum,cov, dateChanged, coalesce(claimLogId,0)) = concat(claimNum,cov)
		then
		lag(reserve) over (order by claimNum,cov, dateChanged, coalesce(claimLogId,0))
		else null end as priorReserve,
last_value(reserve) over(partition by claimNum, cov order by dateChanged, coalesce(claimLogId,0)
		rows between unbounded preceding and unbounded following) as endingReserve
from (
select a.claimLogId, a.claimnum, case a.policyCoveragesId when 20 then 'COL' when 19 then 'CMP' when 11 then 'BI' when 12 then 'PD' when 22 then 'PIP'
	when 15 then 'UMPD' when 14 then 'UMBI' when 27 then 'RENT' when 24 then 'TOW' when 18 then 'UNPD'when 36 then 'UNBI' when 51 then 'CDW'
end as cov, a.dateChanged, a.lossReserve- a.lossPaid as reserve, 'SilverVine' as type, progState
from Windhaven_Report.dbo.ClaimLog a
join Windhaven_Report.dbo.claim on a.claimID = claim.claimID
join Windhaven_Report.dbo.claimincident on claim.claimincidentId = claimincident.claimincidentId
join [Windhaven_Report].dbo.policy on policy.policyId = claimincident.policyId
join Periscope_Data.dbo.ProgramNum on progNum = ratingProgram
union all
select null, claimNum,
cov,
tranDate, 
sum(Amount) over (partition by claimNum, cov order by TranDate rows between unbounded preceding and 0 preceding),
type, progState
from (
select ClaimNumber as claimNum, 
replace(Coverage,'COM','CMP') as cov, tranDate, sum(Amount) as Amount , 'B2' as Type, 'TX' as progState
from Periscope_Data.B2_Data.Claims_Trans where TranType IN ('Reserve')
group by ClaimNumber, replace(Coverage,'COM','CMP'), TranDate) b
) b
where convert(date,dateChanged) <= @reg_date
) b
group by claimNum, cov, progState) b
	JOIN (SELECT 'Claim Closures' as metric union all select 'Inventory' as metric) a on 1 = 1
	group by metric, progState
	;
	set @reg_date = dateadd(day,1,@reg_date);
end;


	
set @min_data = (select coalesce(dateadd(day,1,max(DATA_DATE)),@default_date) from Periscope_Data.dbo.HUDDLE_DATA where HUDDLE_METRIC IN ('Refunds'));
insert into Periscope_Data.dbo.HUDDLE_DATA
select refunded_dt, 'Refunds', count(*), progState
from Periscope_Data.dbo.wh_refund_pol_policy_processing_v
join [Windhaven_Report].dbo.policy on policy.policyId = wh_refund_pol_policy_processing_v.policyId
join Periscope_Data.dbo.ProgramNum on progNum = ratingProgram
where refunded_dt >= @min_data and refunded_dt < convert(date,getdate())
group by refunded_dt, progState;

merge Periscope_Data.dbo.HUDDLE_DATA as Target
using (select date, type, 0 as metric, progState
from (select convert(date,dateadd(day,idx,@min_data)) as date
from Periscope_Data.dbo.DUMMY
where idx < datediff(day,@min_data,convert(date,getdate()))) a
join (select 'Refunds' as type) b on 1 = 1
join (select distinct STATE as progState from Periscope_Data.dbo.HUDDLE_DATA) c on 1 = 1) as Source
on DATA_DATE = date and HUDDLE_METRIC = type and STATE = ProgState
when not matched by Target then
insert (DATA_DATE, HUDDLE_METRIC, METRIC_NUMBER, STATE)
values (date, type, metric, ProgState);
	
set @min_data = (select coalesce(dateadd(day,1,max(DATA_DATE)),@default_date) from Periscope_Data.dbo.HUDDLE_DATA where HUDDLE_METRIC IN ('Late Payments'));
insert into Periscope_Data.dbo.HUDDLE_DATA
select late_payment_date, 'Late Payments', count(*), progState
from Periscope_Data.dbo.wh_late_payments_policy_processing_v
join [Windhaven_Report].dbo.policy on policy.policyId = wh_late_payments_policy_processing_v.policyId
join Periscope_Data.dbo.ProgramNum on progNum = ratingProgram
where late_payment_date >= @min_data and late_payment_date < convert(date,getdate())
group by late_payment_date, progState;

merge Periscope_Data.dbo.HUDDLE_DATA as Target
using (select date, type, 0 as metric, progState
from (select convert(date,dateadd(day,idx,@min_data)) as date
from Periscope_Data.dbo.DUMMY
where idx < datediff(day,@min_data,convert(date,getdate()))) a
join (select 'Late Payments' as type) b on 1 = 1
join (select distinct STATE as progState from Periscope_Data.dbo.HUDDLE_DATA) c on 1 = 1) as Source
on DATA_DATE = date and HUDDLE_METRIC = type and STATE = ProgState
when not matched by Target then
insert (DATA_DATE, HUDDLE_METRIC, METRIC_NUMBER, STATE)
values (date, type, metric, ProgState);
	

set @min_data = (select coalesce(dateadd(day,1,max(DATA_DATE)),@default_date) from Periscope_Data.dbo.HUDDLE_DATA where HUDDLE_METRIC IN ('Cancellations for Non-Payment'));

insert into Periscope_Data.dbo.HUDDLE_DATA
select cancelled_dt, 'Cancellations for Non-Payment', count(*), progState
from Periscope_Data.dbo.wh_non_pay_cancel_pol_policy_processing_v
join [Windhaven_Report].dbo.policy on policy.policyId = wh_non_pay_cancel_pol_policy_processing_v.policy_Id
join Periscope_Data.dbo.ProgramNum on progNum = ratingProgram
where cancelled_dt >= @min_data and cancelled_dt < convert(date,getdate())
group by cancelled_dt, progState;
	
merge Periscope_Data.dbo.HUDDLE_DATA as Target
using (select date, type, 0 as metric, progState
from (select convert(date,dateadd(day,idx,@min_data)) as date
from Periscope_Data.dbo.DUMMY
where idx < datediff(day,@min_data,convert(date,getdate()))) a
join (select 'Cancellations for Non-Payment' as type) b on 1 = 1
join (select distinct STATE as progState from Periscope_Data.dbo.HUDDLE_DATA) c on 1 = 1) as Source
on DATA_DATE = date and HUDDLE_METRIC = type and STATE = ProgState
when not matched by Target then
insert (DATA_DATE, HUDDLE_METRIC, METRIC_NUMBER, STATE)
values (date, type, metric, ProgState);

set @min_data = (select coalesce(dateadd(day,1,max(DATA_DATE)),@default_date) from Periscope_Data.dbo.HUDDLE_DATA where HUDDLE_METRIC IN ('Reinstatements'));

insert into Periscope_Data.dbo.HUDDLE_DATA
select Reinstated_date, 'Reinstatements', count(*), progState
from Periscope_Data.dbo.wh_reinstated_pol_policy_processing_v
join [Windhaven_Report].dbo.policy on policy.policyId = wh_reinstated_pol_policy_processing_v.policyId
join Periscope_Data.dbo.ProgramNum on progNum = ratingProgram
where Reinstated_date >= @min_data and Reinstated_date < convert(date,getdate())
group by Reinstated_date, progState;

merge Periscope_Data.dbo.HUDDLE_DATA as Target
using (select date, type, 0 as metric, progState
from (select convert(date,dateadd(day,idx,@min_data)) as date
from Periscope_Data.dbo.DUMMY
where idx < datediff(day,@min_data,convert(date,getdate()))) a
join (select 'Reinstatements' as type) b on 1 = 1
join (select distinct STATE as progState from Periscope_Data.dbo.HUDDLE_DATA) c on 1 = 1) as Source
on DATA_DATE = date and HUDDLE_METRIC = type and STATE = ProgState
when not matched by Target then
insert (DATA_DATE, HUDDLE_METRIC, METRIC_NUMBER, STATE)
values (date, type, metric, ProgState);

set @min_data = (select coalesce(dateadd(day,1,max(DATA_DATE)),@default_date) from Periscope_Data.dbo.HUDDLE_DATA where HUDDLE_METRIC IN ('Bank Payments'));

insert into Periscope_Data.dbo.HUDDLE_DATA
select bc_payment_dt , 'Bank Payments', count(*), progState
from Periscope_Data.dbo.wh_bank_payment_policy_processing_v
join [Windhaven_Report].dbo.policy on policy.policyId = wh_bank_payment_policy_processing_v.policyId
join Periscope_Data.dbo.ProgramNum on progNum = ratingProgram
where bc_payment_dt  >= @min_data and bc_payment_dt < convert(date,getdate())
group by bc_payment_dt, progState ;

merge Periscope_Data.dbo.HUDDLE_DATA as Target
using (select date, type, 0 as metric, progState
from (select convert(date,dateadd(day,idx,@min_data)) as date
from Periscope_Data.dbo.DUMMY
where idx < datediff(day,@min_data,convert(date,getdate()))) a
join (select 'Bank Payments' as type) b on 1 = 1
join (select distinct STATE as progState from Periscope_Data.dbo.HUDDLE_DATA) c on 1 = 1) as Source
on DATA_DATE = date and HUDDLE_METRIC = type and STATE = ProgState
when not matched by Target then
insert (DATA_DATE, HUDDLE_METRIC, METRIC_NUMBER, STATE)
values (date, type, metric, ProgState);

set @min_data = (select coalesce(dateadd(day,1,max(DATA_DATE)),@default_date) from Periscope_Data.dbo.HUDDLE_DATA where HUDDLE_METRIC IN ('CC Payments'));

insert into Periscope_Data.dbo.HUDDLE_DATA
select cc_payment_dt , 'CC Payments', count(*), progState
from Periscope_Data.dbo.wh_cc_payment_policy_processing_v
join [Windhaven_Report].dbo.policy on policy.policyId = wh_cc_payment_policy_processing_v.policyId
join Periscope_Data.dbo.ProgramNum on progNum = ratingProgram
where cc_payment_dt  >= @min_data and cc_payment_dt < convert(date,getdate())
group by cc_payment_dt, progState ;

merge Periscope_Data.dbo.HUDDLE_DATA as Target
using (select date, type, 0 as metric, progState
from (select convert(date,dateadd(day,idx,@min_data)) as date
from Periscope_Data.dbo.DUMMY
where idx < datediff(day,@min_data,convert(date,getdate()))) a
join (select 'CC Payments' as type) b on 1 = 1
join (select distinct STATE as progState from Periscope_Data.dbo.HUDDLE_DATA) c on 1 = 1) as Source
on DATA_DATE = date and HUDDLE_METRIC = type and STATE = ProgState
when not matched by Target then
insert (DATA_DATE, HUDDLE_METRIC, METRIC_NUMBER, STATE)
values (date, type, metric, ProgState);

set @min_data = (select coalesce(dateadd(day,1,max(DATA_DATE)),@default_date) from Periscope_Data.dbo.HUDDLE_DATA where HUDDLE_METRIC IN ('NSFs'));

insert into Periscope_Data.dbo.HUDDLE_DATA
select nsfd_date , 'NSFs', count(*), progState
from Periscope_Data.dbo.wh_nsfd_pol_policy_processing_v
join [Windhaven_Report].dbo.policy on policy.policyId = wh_nsfd_pol_policy_processing_v.policy_Id
join Periscope_Data.dbo.ProgramNum on progNum = ratingProgram
where nsfd_date  >= @min_data and nsfd_date < convert(date,getdate())
group by nsfd_date, progState ;


merge Periscope_Data.dbo.HUDDLE_DATA as Target
using (select date, type, 0 as metric, progState
from (select convert(date,dateadd(day,idx,@min_data)) as date
from Periscope_Data.dbo.DUMMY
where idx < datediff(day,@min_data,convert(date,getdate()))) a
join (select 'NSFs' as type) b on 1 = 1
join (select distinct STATE as progState from Periscope_Data.dbo.HUDDLE_DATA) c on 1 = 1) as Source
on DATA_DATE = date and HUDDLE_METRIC = type and STATE = ProgState
when not matched by Target then
insert (DATA_DATE, HUDDLE_METRIC, METRIC_NUMBER, STATE)
values (date, type, metric, ProgState);



set @min_data = (select coalesce(dateadd(day,1,max(DATA_DATE)),@default_date) from Periscope_Data.dbo.HUDDLE_DATA 
	where HUDDLE_METRIC in ('Possible Retained Policies','Retained Policies'));

set @reg_date = @min_data;
while @reg_date < convert(date,getdate())
begin
	insert into Periscope_Data.dbo.HUDDLE_DATA
	select @reg_date, type,
	case when type = 'Retained Policies' then 
		count(distinct(case when datediff(day,inceptDate,endDate) >= 185 then policy end))
	when type = 'Possible Retained Policies' then
		count(distinct(policy))
	end, progState
	from (
	select left(policyNum,len(policyNum)-3) as policy,
	min(convert(date,effectiveDate)) as inceptDAte,
	convert(date,coalesce(min(cancelledDAte),max(expirationDate))) as endDate, progState
	from Windhaven_Report.dbo.policy
	join Periscope_Data.dbo.ProgramNum on progNum = ratingProgram
	where left(policyNum,1) <> 'Q'
	and policyTerm = 6
	group by left(policyNum,len(policyNum)-3), progState
	having min(convert(date,effectiveDate)) = dateadd(day,-203,@reg_date)) b
	join (select 'Retained Policies' as type union all select 'Possible Retained Policies' as type) a on 1 = 1
	group by type, progState;
	set @reg_date = dateadd(day,1,@reg_date);
end;


set @min_data = (select coalesce(dateadd(day,1,max(DATA_DATE)),'2017-04-01') from Periscope_Data.dbo.HUDDLE_DATA 
	where HUDDLE_METRIC like 'Daily % Severity');
set @reg_date = @min_data;
while @reg_date < convert(date,getdate())
begin
	insert into Periscope_Data.dbo.HUDDLE_DATA
		select @reg_date, concat('Daily ',coverage,' Severity'), sum(coalesce(paidAmount,0)/coalesce(lossCount,0)), progState
		from (
		select convert(date,minDate) as minDate, coverage, progState,
		sum(paidAmount) as paidAmount, count(*) as lossCount
		from (
		select ClaimNumber, Coverage, min(dateOpened) as minDate, progState,
		sum(case when convert(date,TranDate) between @reg_date and @reg_date then paidAmount end) as paidAmount

		from (
		select ClaimNumber, Coverage, TranDate, dateOpened, Loss_Date, source, rowNum, progState,
		lossPaid - coalesce(lag(lossPaid) over(partition by ClaimNumber, Coverage order by TranDate, rowNum),0) as paidAmount,
		lossPaid
		from (
		select a.*,
		row_number() over(order by ClaimNumber, Coverage, TranDate) as rowNum

		from (
		select ClaimNumber, Coverage, TranDate,TranDate as dateOpened, Loss_Date, progState,
		 sum(Amount) over(partition by ClaimNumber, Coverage order by TranDate asc, rowNum asc ) as lossPaid, 'B2' as source
		from (
		select ClaimNumber, Coverage, TranDate, Loss_Date, case when TranType = 'Payment' then Amount else 0 end as Amount,
		row_number() over(order by ClaimNumber, Coverage, TranDate) as rowNum, 'TX' as progState
		from Periscope_Data.B2_Data.Claims_Trans) b
		union all
		select 
		a.claimNum,
		case a.policyCoveragesId when 20 then 'COL' when 19 then 'CMP' when 11 then 'BI' when 12 then 'PD' when 22 then 'PIP'
			when 15 then 'UMPD' when 14 then 'UMBI' when 27 then 'RENT' when 24 then 'TOW' when 18 then 'UNPD'when 36 then 'UNBI' when 51 then 'CDW'
		end,
		a.dateChanged, a.dateOpened, dateOfLoss, progState,
		a.lossPaid+a.salvagePaid+a.subrogationPaid, 'SV'
		from Windhaven_Report.dbo.ClaimLog a
		join Windhaven_Report.dbo.claim on a.claimID = claim.claimID
		join Windhaven_Report.dbo.claimincident on claim.claimincidentId = claimincident.claimincidentId
		join [Windhaven_Report].dbo.policy on policy.policyId = claimincident.policyId
		join Periscope_Data.dbo.ProgramNum on progNum = ratingProgram
		where a.claimNum <> '0') a) a) a
		group by ClaimNumber, Coverage, progState
		having min(dateOpened) between dateadd(month,-72,@reg_date) and @reg_date) a
		where datepart(dw,minDate) not in (1,7)
		group by convert(date,minDate) , Coverage, progState) a
		where datepart(dw,@reg_date) not in (1,7)
		group by coverage, progState;

	set @reg_date = dateadd(day,1,@reg_date);
end;


set @min_data = (select coalesce(dateadd(day,1,max(DATA_DATE)),'2017-04-01') from Periscope_Data.dbo.HUDDLE_DATA 
	where HUDDLE_METRIC like 'Weekly % Severity');
set @reg_date = @min_data;
while @reg_date < convert(date,getdate())
begin
	insert into Periscope_Data.dbo.HUDDLE_DATA
		select @reg_date, concat('Weekly ',coverage,' Severity'), sum(coalesce(paidAmount,0)/coalesce(lossCount,0)), progState
		from (
		select dateadd(day,-(case when datepart(dw,minDate) = 1 then 6 else datepart(dw,minDate)-2 end),convert(date,minDate)) as minDate, coverage,
		sum(paidAmount) as paidAmount, count(*) as lossCount, progState
		from (
		select ClaimNumber, Coverage, min(dateOpened) as minDate,
		sum(case when convert(date,TranDate) between dateadd(day,-6,@reg_date) and @reg_date then paidAmount end) as paidAmount, progState

		from (
		select ClaimNumber, Coverage, TranDate, dateOpened, Loss_Date, source, rowNum, progState,
		lossPaid - coalesce(lag(lossPaid) over(partition by ClaimNumber, Coverage order by TranDate, rowNum),0) as paidAmount,
		lossPaid
		from (
		select a.*,
		row_number() over(order by ClaimNumber, Coverage, TranDate) as rowNum

		from (
		select ClaimNumber, Coverage, TranDate,TranDate as dateOpened, Loss_Date, progState,
		 sum(Amount) over(partition by ClaimNumber, Coverage order by TranDate asc, rowNum asc ) as lossPaid, 'B2' as source
		from (
		select ClaimNumber, Coverage, TranDate, Loss_Date, case when TranType = 'Payment' then Amount else 0 end as Amount,
		row_number() over(order by ClaimNumber, Coverage, TranDate) as rowNum, 'TX' as progState
		from Periscope_Data.B2_Data.Claims_Trans) b
		union all
		select 
		a.claimNum,
		case a.policyCoveragesId when 20 then 'COL' when 19 then 'CMP' when 11 then 'BI' when 12 then 'PD' when 22 then 'PIP'
			when 15 then 'UMPD' when 14 then 'UMBI' when 27 then 'RENT' when 24 then 'TOW' when 18 then 'UNPD'when 36 then 'UNBI' when 51 then 'CDW'
		end,
		a.dateChanged, a.dateOpened, dateOfLoss,progState,
		a.lossPaid+a.salvagePaid+a.subrogationPaid, 'SV'
		from Windhaven_Report.dbo.ClaimLog a
		join Windhaven_Report.dbo.claim on a.claimID = claim.claimID
		join Windhaven_Report.dbo.claimincident on claim.claimincidentId = claimincident.claimincidentId
		join [Windhaven_Report].dbo.policy on policy.policyId = claimincident.policyId
		join Periscope_Data.dbo.ProgramNum on progNum = ratingProgram
		where a.claimNum <> '0') a) a) a
		group by ClaimNumber, Coverage, progState
		having min(dateOpened) between dateadd(month,-72,@reg_date) and @reg_date) a
		group by dateadd(day,-(case when datepart(dw,minDate) = 1 then 6 else datepart(dw,minDate)-2 end),convert(date,minDate)) , Coverage, progState) a
		where datepart(dw,@reg_date) = 2
		group by coverage, progState;

	set @reg_date = dateadd(day,1,@reg_date);
end;


set @min_data = (select coalesce(dateadd(day,1,max(DATA_DATE)),'2017-04-01') from Periscope_Data.dbo.HUDDLE_DATA 
	where HUDDLE_METRIC like 'Monthly % Severity');
set @reg_date = @min_data;
while @reg_date < convert(date,getdate())
begin
	insert into Periscope_Data.dbo.HUDDLE_DATA
		select @reg_date, concat('Monthly ',coverage,' Severity'), sum(coalesce(paidAmount,0)/coalesce(lossCount,0)), progState
		from (
		select dateadd(day,-(datepart(dy,minDate)%28),convert(date,minDate)) as minDate, coverage,
		sum(paidAmount) as paidAmount, count(*) as lossCount, progState
		from (
		select ClaimNumber, Coverage, min(dateOpened) as minDate,
		sum(case when convert(date,TranDate) between dateadd(day,-27,@reg_date) and @reg_date then paidAmount end) as paidAmount, progState

		from (
		select ClaimNumber, Coverage, TranDate, dateOpened, Loss_Date, source, rowNum, progState,
		lossPaid - coalesce(lag(lossPaid) over(partition by ClaimNumber, Coverage order by TranDate, rowNum),0) as paidAmount,
		lossPaid
		from (
		select a.*,
		row_number() over(order by ClaimNumber, Coverage, TranDate) as rowNum

		from (
		select ClaimNumber, Coverage, TranDate,TranDate as dateOpened, Loss_Date, progState,
		 sum(Amount) over(partition by ClaimNumber, Coverage order by TranDate asc, rowNum asc ) as lossPaid, 'B2' as source
		from (
		select ClaimNumber, Coverage, TranDate, Loss_Date, case when TranType = 'Payment' then Amount else 0 end as Amount,
		row_number() over(order by ClaimNumber, Coverage, TranDate) as rowNum, 'TX' as progState
		from Periscope_Data.B2_Data.Claims_Trans) b
		union all
		select 
		a.claimNum,
		case a.policyCoveragesId when 20 then 'COL' when 19 then 'CMP' when 11 then 'BI' when 12 then 'PD' when 22 then 'PIP'
			when 15 then 'UMPD' when 14 then 'UMBI' when 27 then 'RENT' when 24 then 'TOW' when 18 then 'UNPD'when 36 then 'UNBI' when 51 then 'CDW'
		end,
		a.dateChanged, a.dateOpened, dateOfLoss, progState,
		a.lossPaid+a.salvagePaid+a.subrogationPaid, 'SV'
		from Windhaven_Report.dbo.ClaimLog a
		join Windhaven_Report.dbo.claim on a.claimID = claim.claimID
		join Windhaven_Report.dbo.claimincident on claim.claimincidentId = claimincident.claimincidentId
		join [Windhaven_Report].dbo.policy on policy.policyId = claimincident.policyId
		join Periscope_Data.dbo.ProgramNum on progNum = ratingProgram
		where a.claimNum <> '0') a) a) a
		group by ClaimNumber, Coverage, progState
		having min(dateOpened) between dateadd(month,-72,@reg_date) and @reg_date) a
		group by dateadd(day,-(datepart(dy,minDate)%28),convert(date,minDate)) , Coverage, progState) a
		where datepart(dw,@reg_date) = 2
		group by coverage, progState;

	set @reg_date = dateadd(day,1,@reg_date);
end;

GO

