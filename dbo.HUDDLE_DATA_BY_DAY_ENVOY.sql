USE [Periscope_Data]
GO

/****** Object:  StoredProcedure [dbo].[HUDDLE_DATA_BY_DAY_ENVOY]    Script Date: 12/15/2017 4:39:10 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

create procedure [dbo].[HUDDLE_DATA_BY_DAY_ENVOY]
as
	declare @default_date date, @min_data date, @reg_date date, @reg_date2 date, @b2_cut_off date;

	/*
	create table Periscope_Data.dbo.HUDDLE_DATA_ENVOY
	(DATA_DATE date, HUDDLE_METRIC varchar(50), METRIC_NUMBER decimal(25,5),
	primary key (DATA_DATE, HUDDLE_METRIC));
	*/
set @b2_cut_off = convert(date,'2016-12-31');
set @default_date = convert(date,'2017-06-18');

-------
set @min_data = (select coalesce(dateadd(day,1,max(DATA_DATE)),@default_date) from Periscope_Data.dbo.HUDDLE_DATA_ENVOY where HUDDLE_METRIC = 'PIF');

set @reg_date = @min_data;
while @reg_date < convert(date,getdate())
begin
	insert into Periscope_Data.dbo.HUDDLE_DATA_ENVOY
	select @reg_date, 'PIF', count(distinct(policyNum))
	from Windhaven_Report.dbo.policy
	where left(policyNum,1) <> 'Q'
		and convert(date,boundDate) <= @reg_date
		and  convert(date,effectiveDate) <= @reg_date
		and  convert(date,expirationDate) > @reg_date
		and  (convert(date,cancelledDate) > @reg_date or cancelledDate is null)
		-- Envoy only
		and ratingProgram = 5;
	set @reg_date = dateadd(day,1,@reg_date);
end;


set @min_data = (select coalesce(dateadd(day,1,max(DATA_DATE)),@default_date) from Periscope_Data.dbo.HUDDLE_DATA_ENVOY where HUDDLE_METRIC = 'PIF Increase');

insert into Periscope_Data.dbo.HUDDLE_DATA_ENVOY
select a.DATA_DATE, 'PIF Increase', sum(a.METRIC_NUMBER) - coalesce(sum(b.METRIC_NUMBER),0)
from Periscope_Data.dbo.HUDDLE_DATA_ENVOY a
join Periscope_Data.dbo.HUDDLE_DATA_ENVOY b on a.HUDDLE_METRIC = b.HUDDLE_METRIC
	and a.DATA_DATE = dateadd(day,1,b.DATA_DATE)
where a.HUDDLE_METRIC = 'PIF'
	and a.DATA_DATE between @min_data and dateadd(day,-1,convert(date,getdate()))
group by a.DATA_DATE;


set @min_data = (select coalesce(dateadd(day,1,max(DATA_DATE)),@default_date) from Periscope_Data.dbo.HUDDLE_DATA_ENVOY where HUDDLE_METRIC in ('Sales','Policies Renewed','NB Premium','RN Premium'));

insert into Periscope_Data.dbo.HUDDLE_DATA_ENVOY
select Date,
type,
sum(case type when 'Sales' then NumberOfNB
when 'Policies Renewed' then NumberOfRN
when 'NB Premium' then NB_WP
when 'RN Premium' then RN_WP end)
from (select
count(distinct(case when p.isRenewal = 0 then c.policyID end)) as NumberOfNB,
count(distinct(case when p.isRenewal > 0 then c.policyID end)) as NumberOfRN,
sum(case when p.isRenewal = 0 then changeInTPD end) as NB_WP,
SUM(case when p.isRenewal > 0 then changeInTPD end) as RN_WP,
convert(date, boundDate) as Date
from windhaven_report.dbo.CoveragePremium c
join windhaven_report.dbo.policy p on c.policyId = p.policyId
where p.Status not in (4,6,99)
and left (p.policynum,1) != 'Q'
and  convert(date,p.bounddate) < convert(date,getdate())
and convert(date,p.bounddate) >= @min_data
and c.changeType =1
--ENVOY ONLY
and p.ratingProgram = 5
group by convert(date, boundDate)) b
join (select 'Sales' as type union all select 'Policies Renewed' as type
	union all select 'NB Premium' as type union all select 'RN Premium' as type) a on 1 = 1
group by DAte, type;

merge Periscope_Data.dbo.HUDDLE_DATA_ENVOY as Target
using (select date, type, 0 as metric
from (select convert(date,dateadd(day,idx,@min_data)) as date
from Periscope_Data.dbo.DUMMY
where idx < datediff(day,@min_data,convert(date,getdate()))) a
join (select 'Sales' as type union all select 'Policies Renewed' as type
	union all select 'NB Premium' as type union all select 'RN Premium' as type) b on 1 = 1) as Source
on DATA_DATE = date and HUDDLE_METRIC = type
when not matched by Target then
insert (DATA_DATE, HUDDLE_METRIC, METRIC_NUMBER)
values (date, type, metric);

	
set @min_data = (select coalesce(dateadd(day,1,max(DATA_DATE)),@default_date) from Periscope_Data.dbo.HUDDLE_DATA_ENVOY where HUDDLE_METRIC like 'Loss Count - %');

insert into Periscope_Data.dbo.HUDDLE_DATA_ENVOY
select convert(date,openDate), concat('Loss Count - ',cov), count(*)
from (
select claimNum, cov, min(dateChanged) as openDate
from (
select claim.claimNum,
case a.policyCoveragesId when 20 then 'COL' when 19 then 'CMP' when 11 then 'BI' when 12 then 'PD' when 22 then 'PIP'
	when 15 then 'UMPD' when 14 then 'UMBI' when 27 then 'RENT' when 24 then 'TOW' when 18 then 'UNPD'when 36 then 'UNBI' when 51 then 'CDW'
end as cov,
 a.dateOpened as dateChanged
from Windhaven_Report.dbo.ClaimLog a
join Windhaven_Report.dbo.claim on a.claimID = claim.claimID
join Windhaven_Report.dbo.claimincident on claim.claimincidentId = claimincident.claimincidentId
-- joining policy table to pick ENVOY
join Windhaven_Report.dbo.Policy on ClaimIncident.policyID = Policy.policyID
where policy.ratingProgram = 5
union all 
select concat(ClaimNumber,'-',right('00'+cast(ClaimNumber as varchar(2)),2)) as claimNum,
replace(Coverage,'COM','CMP') as cov, TranDate as dateChanged
from Periscope_Data.B2_Data.Claims_Trans) b
where cov <> '*'
group by claimNum, cov) b
where convert(date,openDate) >= @min_data
	and convert(date,openDate) < convert(date,getdate())
group by convert(date,openDate), concat('Loss Count - ',cov);

merge Periscope_Data.dbo.HUDDLE_DATA_ENVOY as Target
using (select date, type, 0 as metric
from (select convert(date,dateadd(day,idx,@min_data)) as date
from Periscope_Data.dbo.DUMMY
where idx < datediff(day,@min_data,convert(date,getdate()))) a
join (select 'Loss Count - PIP' as type union all select 'Loss Count - PD' as type
union all select 'Loss Count - BI' as type union all select 'Loss Count - CMP' as type
union all select 'Loss Count - COL' as type union all select 'Loss Count - UMBI' as type
union all select 'Loss Count - UMPD' as type) b on 1 = 1) as Source
on DATA_DATE = date and HUDDLE_METRIC = type
when not matched by Target then
insert (DATA_DATE, HUDDLE_METRIC, METRIC_NUMBER)
values (date, type, metric);
	
set @min_data = (select coalesce(dateadd(day,1,max(DATA_DATE)),@default_date) from Periscope_Data.dbo.HUDDLE_DATA_ENVOY where HUDDLE_METRIC like 'EXP - %');

set @reg_date = @min_data;
while @reg_date < convert(date,getdate())
begin
	set @reg_date2 = dateadd(day,-1,@reg_date);
	insert into Periscope_Data.dbo.HUDDLE_DATA_ENVOY
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
				)) as decimal)/cast(nullif((1+datediff(day,dateeffective,expirationDate)),0) as decimal) end,4),0)) as exp_amount
	from (
	select policyNum, coverage, cast(datediff(day,dateEffective,expirationDAte) as decimal)/365*case when fullTermPremium > 0 and priorAmount = 0 then 1
		when fullTermPremium = 0 and priorAmount > 0 then -1 else 0 end as expAmount, 
		transactionDate, dateeffective, expirationDate
	from (
	select policyNum, a.policyId, a.objectId, coverage, ratingProgram, -- added rating program
	transactionDate, dateEffective, fullTermPremium,
	changeInFullTermPremium,
	case when
			lag(concat(a.policyId, a.objectId, coverage)) over (order by a.policyId, a.objectId, coverage, transactionDate) = concat(a.policyId, a.objectId, coverage)
			then
			lag(fullTermPremium) over (order by a.policyId, a.objectId, coverage, transactionDate)
			else 0 end AS priorAmount,
	expirationDate
	 from windhaven_report.dbo.coveragepremium a
	join [Windhaven_Report].dbo.Policy on Policy.policyID = a.policyId) b
	where (convert(date,dateEffective) >= @reg_date2 or convert(date,expirationDate) >= @reg_date2 or convert(date,transactionDate) >= @reg_date2)
		and convert(date,transactionDate) <= @reg_date
		--ENVOY ONLY
		and ratingProgram = 5 ) b
	group by concat('EXP - ',case coverage when 'COLL' then 'COL' when 'COMP' then 'CMP' when 'OTC' then 'CMP' else coverage end);

	set @reg_date = dateadd(day,1,@reg_date);
end;

	
set @min_data = (select coalesce(dateadd(day,1,max(DATA_DATE)),@default_date) from Periscope_Data.dbo.HUDDLE_DATA_ENVOY where HUDDLE_METRIC IN ('Inventory','Claim Closures'));

set @reg_date = @min_data;
while @reg_date < convert(date,getdate())
begin
	insert into Periscope_Data.dbo.HUDDLE_DATA_ENVOY
	SELECT @reg_date, metric, count(case when (metric = 'Claim Closures' and convert(date,closeDate) = @reg_date)
			or (metric = 'Inventory' and endingReserve > 0 ) then 1 end)
	FROM (select claimNum, cov,
min(case when reserve <= 0 and priorReserve > 0 then dateChanged end) as closeDate,
max(CASE WHEN type <> 'B2' OR @reg_date < @b2_cut_off THEN endingReserve END) as endingReserve

from (select claimNum, cov, type,
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
end as cov, a.dateChanged, a.lossReserve- a.lossPaid as reserve, 'SilverVine' as type
from Windhaven_Report.dbo.ClaimLog a
join Windhaven_Report.dbo.claim on a.claimID = claim.claimID
join Windhaven_Report.dbo.claimincident on claim.claimincidentId = claimincident.claimincidentId
-- joining policy table to include ENVOY claims only
join Windhaven_Report.dbo.Policy on ClaimIncident.policyID = Policy.policyID
where policy.ratingProgram = 5
union all
select null, claimNum,
cov,
tranDate, 
sum(Amount) over (partition by claimNum, cov order by TranDate rows between unbounded preceding and 0 preceding),
type
from (
select concat(ClaimNumber,'-',right('00'+cast(ClaimNumber as varchar(2)),2)) as claimNum, 
replace(Coverage,'COM','CMP') as cov, tranDate, sum(Amount*CASE WHEN TranType = 'DEDUCTIBLE' THEN -1 ELSE 1 END) as Amount , 'B2' as Type
from Periscope_Data.B2_Data.Claims_Trans where TranType IN ('RESERVE','DEDUCTIBLE')
group by concat(ClaimNumber,'-',right('00'+cast(ClaimNumber as varchar(2)),2)), replace(Coverage,'COM','CMP'), TranDate) b
) b
where convert(date,dateChanged) <= @reg_date
) b
group by claimNum, cov) b
	JOIN (SELECT 'Claim Closures' as metric union all select 'Inventory' as metric) a on 1 = 1
	group by metric
	;
	set @reg_date = dateadd(day,1,@reg_date);
end;


	
set @min_data = (select coalesce(dateadd(day,1,max(DATA_DATE)),@default_date) from Periscope_Data.dbo.HUDDLE_DATA_ENVOY where HUDDLE_METRIC IN ('Refunds'));
insert into Periscope_Data.dbo.HUDDLE_DATA_ENVOY
select refunded_dt, 'Refunds', count(*)
from Periscope_Data.dbo.wh_refund_pol_policy_processing_v
--adding Envoy only
join Windhaven_Report.dbo.Policy on wh_refund_pol_policy_processing_v.policyID = Policy.policyID
where refunded_dt >= @min_data and refunded_dt < convert(date,getdate())
and policy.ratingProgram = 5
group by refunded_dt;

merge Periscope_Data.dbo.HUDDLE_DATA_ENVOY as Target
using (select date, type, 0 as metric
from (select convert(date,dateadd(day,idx,@min_data)) as date
from Periscope_Data.dbo.DUMMY
where idx < datediff(day,@min_data,convert(date,getdate()))) a
join (select 'Refunds' as type) b on 1 = 1) as Source
on DATA_DATE = date and HUDDLE_METRIC = type
when not matched by Target then
insert (DATA_DATE, HUDDLE_METRIC, METRIC_NUMBER)
values (date, type, metric);
	
set @min_data = (select coalesce(dateadd(day,1,max(DATA_DATE)),@default_date) from Periscope_Data.dbo.HUDDLE_DATA_ENVOY where HUDDLE_METRIC IN ('Late Payments'));
insert into Periscope_Data.dbo.HUDDLE_DATA_ENVOY
select late_payment_date, 'Late Payments', count(*)
from Periscope_Data.dbo.wh_late_payments_policy_processing_v
--adding Envoy only
join Windhaven_Report.dbo.Policy on wh_late_payments_policy_processing_v.policyID = Policy.policyID
where late_payment_date >= @min_data and late_payment_date < convert(date,getdate())
and policy.ratingProgram = 5
group by late_payment_date;

merge Periscope_Data.dbo.HUDDLE_DATA_ENVOY as Target
using (select date, type, 0 as metric
from (select convert(date,dateadd(day,idx,@min_data)) as date
from Periscope_Data.dbo.DUMMY
where idx < datediff(day,@min_data,convert(date,getdate()))) a
join (select 'Late Payments' as type) b on 1 = 1) as Source
on DATA_DATE = date and HUDDLE_METRIC = type
when not matched by Target then
insert (DATA_DATE, HUDDLE_METRIC, METRIC_NUMBER)
values (date, type, metric);
	

set @min_data = (select coalesce(dateadd(day,1,max(DATA_DATE)),@default_date) from Periscope_Data.dbo.HUDDLE_DATA_ENVOY where HUDDLE_METRIC IN ('Cancellations for Non-Payment'));

insert into Periscope_Data.dbo.HUDDLE_DATA_ENVOY
select cancelled_dt, 'Cancellations for Non-Payment', count(*)
from Periscope_Data.dbo.wh_non_pay_cancel_pol_policy_processing_v
--adding Envoy only
join Windhaven_Report.dbo.Policy on wh_non_pay_cancel_pol_policy_processing_v.policy_Id = Policy.policyID
where cancelled_dt >= @min_data and cancelled_dt < convert(date,getdate())
and policy.ratingProgram = 5
group by cancelled_dt;
	
merge Periscope_Data.dbo.HUDDLE_DATA_ENVOY as Target
using (select date, type, 0 as metric
from (select convert(date,dateadd(day,idx,@min_data)) as date
from Periscope_Data.dbo.DUMMY
where idx < datediff(day,@min_data,convert(date,getdate()))) a
join (select'Cancellations for Non-Payment' as type) b on 1 = 1) as Source
on DATA_DATE = date and HUDDLE_METRIC = type
when not matched by Target then
insert (DATA_DATE, HUDDLE_METRIC, METRIC_NUMBER)
values (date, type, metric);

set @min_data = (select coalesce(dateadd(day,1,max(DATA_DATE)),@default_date) from Periscope_Data.dbo.HUDDLE_DATA_ENVOY where HUDDLE_METRIC IN ('Reinstatements'));

insert into Periscope_Data.dbo.HUDDLE_DATA_ENVOY
select Reinstated_date, 'Reinstatements', count(*)
from Periscope_Data.dbo.wh_reinstated_pol_policy_processing_v
--adding Envoy only
join Windhaven_Report.dbo.Policy on wh_reinstated_pol_policy_processing_v.policyId = Policy.policyID
where Reinstated_date >= @min_data and Reinstated_date < convert(date,getdate())
and policy.ratingProgram = 5
group by Reinstated_date;

merge Periscope_Data.dbo.HUDDLE_DATA_ENVOY as Target
using (select date, type, 0 as metric
from (select convert(date,dateadd(day,idx,@min_data)) as date
from Periscope_Data.dbo.DUMMY
where idx < datediff(day,@min_data,convert(date,getdate()))) a
join (select 'Reinstatements' as type) b on 1 = 1) as Source
on DATA_DATE = date and HUDDLE_METRIC = type
when not matched by Target then
insert (DATA_DATE, HUDDLE_METRIC, METRIC_NUMBER)
values (date, type, metric);

set @min_data = (select coalesce(dateadd(day,1,max(DATA_DATE)),@default_date) from Periscope_Data.dbo.HUDDLE_DATA_ENVOY where HUDDLE_METRIC IN ('Bank Payments'));

insert into Periscope_Data.dbo.HUDDLE_DATA_ENVOY
select bc_payment_dt , 'Bank Payments', count(*)
from Periscope_Data.dbo.wh_bank_payment_policy_processing_v
--adding Envoy only
join Windhaven_Report.dbo.Policy on wh_bank_payment_policy_processing_v.policyId = Policy.policyID
where bc_payment_dt  >= @min_data and bc_payment_dt < convert(date,getdate())
and policy.ratingProgram = 5
group by bc_payment_dt ;

merge Periscope_Data.dbo.HUDDLE_DATA_ENVOY as Target
using (select date, type, 0 as metric
from (select convert(date,dateadd(day,idx,@min_data)) as date
from Periscope_Data.dbo.DUMMY
where idx < datediff(day,@min_data,convert(date,getdate()))) a
join (select 'Bank Payments' as type) b on 1 = 1) as Source
on DATA_DATE = date and HUDDLE_METRIC = type
when not matched by Target then
insert (DATA_DATE, HUDDLE_METRIC, METRIC_NUMBER)
values (date, type, metric);

set @min_data = (select coalesce(dateadd(day,1,max(DATA_DATE)),@default_date) from Periscope_Data.dbo.HUDDLE_DATA_ENVOY where HUDDLE_METRIC IN ('CC Payments'));

insert into Periscope_Data.dbo.HUDDLE_DATA_ENVOY
select cc_payment_dt , 'CC Payments', count(*)
from Periscope_Data.dbo.wh_cc_payment_policy_processing_v
--adding Envoy only
join Windhaven_Report.dbo.Policy on wh_cc_payment_policy_processing_v.policyId = Policy.policyID
where cc_payment_dt  >= @min_data and cc_payment_dt < convert(date,getdate())
and policy.ratingProgram = 5
group by cc_payment_dt ;

merge Periscope_Data.dbo.HUDDLE_DATA_ENVOY as Target
using (select date, type, 0 as metric
from (select convert(date,dateadd(day,idx,@min_data)) as date
from Periscope_Data.dbo.DUMMY
where idx < datediff(day,@min_data,convert(date,getdate()))) a
join (select 'CC Payments' as type) b on 1 = 1) as Source
on DATA_DATE = date and HUDDLE_METRIC = type
when not matched by Target then
insert (DATA_DATE, HUDDLE_METRIC, METRIC_NUMBER)
values (date, type, metric);

set @min_data = (select coalesce(dateadd(day,1,max(DATA_DATE)),@default_date) from Periscope_Data.dbo.HUDDLE_DATA_ENVOY where HUDDLE_METRIC IN ('NSFs'));

insert into Periscope_Data.dbo.HUDDLE_DATA_ENVOY
select nsfd_date , 'NSFs', count(*)
from Periscope_Data.dbo.wh_nsfd_pol_policy_processing_v

where nsfd_date  >= @min_data and nsfd_date < convert(date,getdate())

group by nsfd_date ;


merge Periscope_Data.dbo.HUDDLE_DATA_ENVOY as Target
using (select date, type, 0 as metric
from (select convert(date,dateadd(day,idx,@min_data)) as date
from Periscope_Data.dbo.DUMMY
where idx < datediff(day,@min_data,convert(date,getdate()))) a
join (select 'NSFs' as type) b on 1 = 1) as Source
on DATA_DATE = date and HUDDLE_METRIC = type
when not matched by Target then
insert (DATA_DATE, HUDDLE_METRIC, METRIC_NUMBER)
values (date, type, metric);




set @min_data = (select coalesce(dateadd(day,1,max(DATA_DATE)),@default_date) from Periscope_Data.dbo.HUDDLE_DATA_ENVOY
	where HUDDLE_METRIC in ('Possible Retained Policies','Retained Policies'));

set @reg_date = @min_data;
while @reg_date < convert(date,getdate())
begin
	insert into Periscope_Data.dbo.HUDDLE_DATA_ENVOY
	select @reg_date, type,
	case when type = 'Retained Policies' then 
		count(distinct(case when datediff(day,inceptDate,endDate) >= 185 then policy end))
	when type = 'Possible Retained Policies' then
		count(distinct(policy))
	end
	from (
	select left(policyNum,len(policyNum)-3) as policy,
	min(convert(date,effectiveDate)) as inceptDAte,
	convert(date,coalesce(min(cancelledDAte),max(expirationDate))) as endDate
	from Windhaven_Report.dbo.policy
	where left(policyNum,1) <> 'Q'
	and policyTerm = 6
	--adding Envoy Only
	and ratingProgram = 5
	group by left(policyNum,len(policyNum)-3)
	having min(convert(date,effectiveDate)) = dateadd(day,-203,@reg_date)) b
	join (select 'Retained Policies' as type union all select 'Possible Retained Policies' as type) a on 1 = 1
	group by type;
	set @reg_date = dateadd(day,1,@reg_date);
end;



GO

