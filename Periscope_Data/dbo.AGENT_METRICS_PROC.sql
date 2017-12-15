USE [Periscope_Data]
GO

/****** Object:  StoredProcedure [dbo].[AGENT_METRICS_PROC]    Script Date: 12/15/2017 4:36:17 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[AGENT_METRICS_PROC]
as
	declare @report_date as date, @report_date_start date, @report_date_prior date;

/*
drop table Periscope_Data.dbo.AGENT_METRICS;
create table Periscope_Data.dbo.AGENT_METRICS
(AGENT_NUMBER varchar(20), REPORT_DATE date,
METRIC varchar(25), METRIC_NUMBER decimal(25,10),
AGENT_ACTIVE varchar(1),
primary key(AGENT_NUMBER, REPORT_DATE, METRIC));
*/
set @report_date = eomonth(dateadd(month,-1,convert(date,getdate())));

delete from Periscope_Data.dbo.AGENT_METRICS where REPORT_DATE = @report_date and METRIC <> 'QUOTES';

-- AGENT AGE

insert into Periscope_Data.dbo.AGENT_METRICS (AGENT_NUMBER, REPORT_DATE, METRIC, METRIC_NUMBER)
(select concat(code,'-',subcode), @report_date, 'AGENT AGE', datediff(day,convert(date,addDate),@report_date)
from Windhaven_Report.dbo.producer
where convert(date,addDate) <= @report_date);




/* Postgres Quotes
insert into Periscope_Data.dbo.AGENT_METRICS (AGENT_NUMBER, REPORT_DATE, METRIC, METRIC_NUMBER)
(select case when code is not null then concat(code,'-',subcode)
else left(concat(agentNumber,'-000-000'),14) end as agentNumber, 
reportDate, metricName, sum(metricNumber)
from (
values 

) s (agentNumber, reportDate, metricName, metricNumber)
left join Windhaven_Report.dbo.Producer on agentNumber = importProducerCode and importProducerCode <> ''
group by case when code is not null then concat(code,'-',subcode)
else left(concat(agentNumber,'-000-000'),14) end, 
reportDate, metricName);

select ('(' || chr(39) || agent_number || chr(39) || ',' || 
chr(39) || (date_trunc('MONTH',current_date - interval '1 month')+ interval '1 month - 1 day')::date || chr(39) || ',' ||
chr(39) || 'QUOTES' || chr(39) || ',' ||
quoteCount || '),')::text
from (
select agent_number, 
count(distinct(case when premium_installment > 10 then concat(insured_first_name,insured_last_name,left(insured_zip,5),agent_number,quote_date::date) end)) as quoteCount
from rtr_quote
where quote_date between date_trunc('MONTH',current_date - interval '1 month')::date
	and date_trunc('MONTH',current_date)::date
	and quote_type not in ('EQ','RQ')
group by 1) b;

*/

-- sales
insert into Periscope_Data.dbo.AGENT_METRICS (AGENT_NUMBER, REPORT_DATE, METRIC, METRIC_NUMBER)
select concat(code,'-',subcode),
@report_date,
'NEW BUSINESS',
count(distinct(policyNum))
from Windhaven_Report.dbo.Policy
join Windhaven_Report.dbo.Producer on producer.producerId = policy.producerid
where 
left(policyNum,1) <> 'Q' and
isRenewal = 0 and
convert(date,boundDate)
between dateadd(day,1,eomonth(dateadd(month,-1,@report_date))) and @report_date
group by concat(code,'-',subcode);

-- earned premium
set @report_date_prior = eomonth(dateadd(YEAR,-1,@report_date));
set @report_date_prior = case when @report_date_prior < '2016-12-31' then '2016-12-31' else @report_date_prior end;

insert into Periscope_Data.dbo.AGENT_METRICS (AGENT_NUMBER, REPORT_DATE, METRIC, METRIC_NUMBER)
select concat(code,'-',subcode),
@report_date,
'EARNED PREMIUM',
sum(coalesce(round(changeInTPD*
	case when transactionDate > @report_date or case when changeType = 1 then policy.effectiveDate else dateeffective end > @report_date then null
	else
		cast((1 + datediff(day,case when changeType = 1 then policy.effectiveDate else dateeffective end,
			case when @report_date >expirationDate then expirationDate else @report_date end
		)) as decimal)/cast(nullif((1+datediff(day,case when changeType = 1 then policy.effectiveDate else dateeffective end,expirationDate)),0) as decimal) end,2),0))
-
sum(coalesce(round(changeInTPD*
	case when transactionDate > @report_date_prior or case when changeType = 1 then policy.effectiveDate else dateeffective end > @report_date_prior then null
	else
		cast((1 + datediff(day,case when changeType = 1 then policy.effectiveDate else dateeffective end,
			case when @report_date_prior >expirationDate then expirationDate else @report_date_prior end
		)) as decimal)/cast(nullif((1+datediff(day,case when changeType = 1 then policy.effectiveDate else dateeffective end,expirationDate)),0) as decimal) end,2),0))
from Windhaven_Report.dbo.coveragePremium
join Windhaven_Report.dbo.policy on policy.policyId = coveragePremium.policyId
join Windhaven_Report.dbo.producer on policy.producerId = producer.producerId
group by concat(code,'-',subcode);

-- loss counts
insert into Periscope_Data.dbo.AGENT_METRICS (AGENT_NUMBER, REPORT_DATE, METRIC, METRIC_NUMBER)
select concat(code,'-',subcode),
@report_date,
concat(cov,' COUNT'),
count(*)
from (
select claimNum, cov, min(dateChanged) as openDate, min(policyId) as policyId
from (
select claim.claimNum,
case a.policyCoveragesId when 20 then 'COL' when 19 then 'CMP' when 11 then 'BI' when 12 then 'PD' when 22 then 'PIP'
	when 15 then 'UMPD' when 14 then 'UMBI' when 27 then 'RENT' when 24 then 'TOW' when 18 then 'UNPD'when 36 then 'UNBI' when 51 then 'CDW'
end as cov,
 a.dateOpened as dateChanged, ClaimIncident.policyId
from Windhaven_Report.dbo.ClaimLog a
join Windhaven_Report.dbo.claim on a.claimID = claim.claimID
join Windhaven_Report.dbo.claimincident on claim.claimincidentId = claimincident.claimincidentId
union all 
select ClaimNumber as claimNum,
replace(Coverage,'COM','CMP') as cov, TranDate as dateChanged, null as policyId
from Periscope_Data.B2_Data.Claims_Trans) b
where cov <> '*'
group by claimNum, cov) b
join Windhaven_Report.dbo.policy on policy.policyId = b.policyId
join Windhaven_Report.dbo.producer on producer.producerId = policy.producerId
where convert(date,openDate) between 
	case when dateadd(day,1,eomonth(dateadd(YEAR,-1,@report_date))) < '2017-01-01' then '2017-01-01'
		else dateadd(day,1,eomonth(dateadd(YEAR,-1,@report_date))) end
	and @report_date
and cov in ('PIP','BI','CMP','COL','PD')
group by concat(code,'-',subcode), cov

-- 7 month retention
insert into Periscope_Data.dbo.AGENT_METRICS (AGENT_NUMBER, REPORT_DATE, METRIC, METRIC_NUMBER)
select agentNumber,
@report_date,
type,
case when type = '7 MONTHS INFORCE' then
	count(distinct(case when datediff(day,inceptDate,endDate) >= 185 then policy end))
when type = '6 MONTHS INFORCE' then
	count(distinct(case when datediff(day,inceptDate,endDate) >= 154 then policy end))
end
from (select left(policyNum,len(policyNum)-3) as policy,
	(select top 1 concat(code,'-',subcode)
	from Windhaven_Report.dbo.producer
	join Windhaven_report.dbo.policy on policy.producerId = producer.producerid
	where left(policy.policyNum,len(policy.policyNum)-3) = left(a.policyNum,len(a.policyNum)-3)
	order by policy.policyId asc) as agentNumber,
	min(convert(date,effectiveDate)) as inceptDAte,
	convert(date,coalesce(min(cancelledDAte),max(expirationDate))) as endDate
	from Windhaven_Report.dbo.policy a
	where left(policyNum,1) <> 'Q'
	and policyTerm = 6
	group by left(policyNum,len(policyNum)-3)
	having min(convert(date,effectiveDate)) = dateadd(day,-200,@report_date)) b
	join (select '7 MONTHS INFORCE' as type union all select '6 MONTHS INFORCE' as type) a on 1 = 1
group by agentNumber, type


-- 6 month retention

-- set active flag
update met
set AGENT_ACTIVE = 'Y'
from Periscope_Data.dbo.AGENT_METRICS met
join WIndhaven_Report.dbo.Producer on concat(code,'-',subcode) = AGENT_NUMBER
and (cancelledDAte is null or convert(date,cancelledDate) > @report_date)
where REPORT_DATE = @report_date;

insert into Periscope_Data.dbo.AGENT_METRICS
select left(AGENT_NUMBER,6), @report_date, METRIC, sum(METRIC_NUMBER),
case when count(case when AGENT_ACTIVE = 'Y' then 1 end) > 0 then 'Y' else 'N' end
from Periscope_Data.dbo.AGENT_METRICS
where REPORT_DATE = @report_date
group by left(AGENT_NUMBER,6), METRIC
having count(distinct(AGENT_NUMBER)) > 1;


select * from Periscope_data.dbo.AGENT_METRICS;
GO

