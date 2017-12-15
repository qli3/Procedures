USE [Periscope_Data]
GO

/****** Object:  StoredProcedure [dbo].[AGENT_DASHBOARD]    Script Date: 12/15/2017 3:59:17 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Tim hu
-- Create date: 2017/10/26
-- Last updated 2017/11/8
-- Description:	TX Agent Dashboard data for periscope
-- =============================================
CREATE PROCEDURE [dbo].[AGENT_DASHBOARD]

AS
BEGIN

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
declare @date  as date
declare @YTDDay as date
set @date = eomonth(dateadd(month,-1,convert(date,getdate())))
set @YTDDay = DATEFROMPARTS(year(@date), 1,1)
--------------------------------------------------------------------------------------------------

--EARNED PREMIUM 
			IF OBJECT_ID('tempdb.dbo.#EP', 'U') IS NOT NULL
			DROP TABLE #EP;
			
			select PRODUCER.PRODUCERID , POLICY.POLICYID, concat(code,'-',subcode) AGENT_NUMBER,
				@date REPORT_DATE, 
				sum(coalesce(round(changeInTPD*
					case when transactionDate > @date or case when changeType = 1 then policy.effectiveDate else dateeffective end > @date then null
					else
						cast((1 + datediff(day,case when changeType = 1 then policy.effectiveDate else dateeffective end,
							case when @date >CAST(expirationDate AS DATE) then CAST(expirationDate AS DATE) else @date end
						)) as decimal)/cast(nullif((1+datediff(day,case when changeType = 1 then policy.effectiveDate else dateeffective end,CAST(expirationDate AS DATE))),0) as decimal) end,2),0))
				-
				sum(coalesce(round(changeInTPD*
					case when transactionDate > DATEADD(YEAR,-1, @date) or case when changeType = 1 then policy.effectiveDate else dateeffective end > DATEADD(YEAR,-1, @date)  then null
					else
						cast((1 + datediff(day,case when changeType = 1 then policy.effectiveDate else dateeffective end,
							case when DATEADD(YEAR,-1, @date)  >CAST(expirationDate AS DATE) then expirationDate else DATEADD(YEAR,-1, @date)  end
						)) as decimal)/cast(nullif((1+datediff(day,case when changeType = 1 then policy.effectiveDate else dateeffective end,expirationDate)),0) as decimal) end,2),0)) AS EP
			INTO #ep from Windhaven_Report.dbo.coveragePremium
			join Windhaven_Report.dbo.policy on policy.policyId = coveragePremium.policyId
			join Windhaven_Report.dbo.producer on policy.producerId = producer.producerId			
			group by PRODUCER.PRODUCERID , POLICY.POLICYID, concat(code,'-',subcode);
			
-- loss counts
			IF OBJECT_ID('tempdb.dbo.#FREQ', 'U') IS NOT NULL
			DROP TABLE #FREQ;		

			select PRODUCER.PRODUCERID, POLICY.POLICYID, concat(code,'-',subcode) AGENT_NUMBER,
				@date REPORT_DATE
				,SUM(CASE WHEN cov =  'COL'    THEN 1 ELSE 0 END ) AS     COL 
				,SUM(CASE WHEN cov =  'CMP'    THEN 1 ELSE 0 END ) AS 	  CMP 
				,SUM(CASE WHEN cov =  'BI'     THEN 1 ELSE 0 END ) AS 	  BI 
				,SUM(CASE WHEN cov =  'PD'     THEN 1 ELSE 0 END ) AS 	  PD 
				,SUM(CASE WHEN cov =  'PIP'    THEN 1 ELSE 0 END ) AS 	  PIP 
				,SUM(CASE WHEN cov =  'UMPD'   THEN 1 ELSE 0 END ) AS 	  UMPD
				,SUM(CASE WHEN cov =  'UMBI'   THEN 1 ELSE 0 END ) AS 	  UMBI
				,SUM(CASE WHEN cov =  'RENT'   THEN 1 ELSE 0 END ) AS 	  RENT
				,SUM(CASE WHEN cov =  'TOW'    THEN 1 ELSE 0 END ) AS 	  TOW 
				,SUM(CASE WHEN cov =  'UNPD'   THEN 1 ELSE 0 END ) AS 	  UNPD
				,SUM(CASE WHEN cov =  'UNBI'   THEN 1 ELSE 0 END ) AS 	  UNBI
				,SUM(CASE WHEN cov =  'CDW'    THEN 1 ELSE 0 END ) AS 	  CDW 
			INTO #FREQ from (
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
				case when dateadd(day,1,eomonth(dateadd(YEAR,-1,@date))) < '2017-01-01' then '2017-01-01'
					else dateadd(day,1,eomonth(dateadd(YEAR,-1,@date))) end
				and @date
			and cov in ('PIP','BI','CMP','COL','PD')
			group by PRODUCER.PRODUCERID , POLICY.POLICYID, concat(code,'-',subcode)

--NOtes/Calls data
	IF OBJECT_ID('tempdb.dbo.#NOTE', 'U') IS NOT NULL
	DROP TABLE #NOTE;

	select producerid, note.policyid, subject, count(*) as call_count, max(note.adddate) adddate
	into #note from windhaven_report.dbo.note
		left join windhaven_report.dbo.policy p on note.policyID = p.policyID
	where 
	(upper(subject ) like '%AGT%'
	or
	upper(subject ) like '%AGNT%'
	or
	upper(subject ) like '%AGENT%')
	and note.addDate between @YTDDay and @date
	group by producerid, note.policyid, subject
	order by count(*) desc
	
--Notetotal
	IF OBJECT_ID('tempdb.dbo.#NOTEtotal', 'U') IS NOT NULL
	DROP TABLE #NOTEtotal;

	select policyid, sum(call_count) as call_count
	into #notetotal from #note
	group by policyid

--Most common Call Reason
	IF OBJECT_ID('tempdb.dbo.#NOTEMAX1', 'U') IS NOT NULL
	DROP TABLE #NOTEMAX1;

	select producerID, subject common_call_reason, sum(call_count) as call_count
	into #NOTEMAX1 from #note n1
	group by producerID, subject 	

	IF OBJECT_ID('tempdb.dbo.#NOTEMAX2', 'U') IS NOT NULL
	DROP TABLE #NOTEMAX2;

	select producerID, common_call_reason, ROW_NUMBER () over( partition by producerid order by common_call_reason ) rownum
	into #notemax2 from #notemax1 n1
	where exists (select 1 from (select producerid, max(call_count) cc from #notemax1 group by producerID) n2 where n1.producerID = producerID and n1.call_count = n2.cc)

--Agency Permissions
	IF OBJECT_ID('tempdb.dbo.#appoint', 'U') IS NOT NULL
	DROP TABLE #appoint;

	select a.producerid
	,sum(case when b.ratingprogram = 1 and quotestatus = 1 and a.status = 1 then 1 else 0 end ) as APEX_STD_APPOINT 
	,sum(case when b.ratingprogram = 2 and quotestatus = 1 and a.status = 1 then 1 else 0 end ) as APEX_LTD_APPOINT 
	,sum(case when b.ratingprogram = 3 and quotestatus = 1 and a.status = 1 then 1 else 0 end ) as EDGE_STD_APPOINT 
	,sum(case when b.ratingprogram = 4 and quotestatus = 1 and a.status = 1 then 1 else 0 end ) as EDGE_LTD_APPOINT 
	,sum(case when b.ratingprogram = 5 and quotestatus = 1 and a.status = 1 then 1 else 0 end ) as ENVOY_APPOINT 		
	into #appoint 
	from [Windhaven_Report].[dbo].producer a
		left join [Windhaven_Report].[dbo].[ProducerPolicyType] b on a.producerid = b.producerid
	where 1=1 
	group by a.producerID

--AGENT DASHBOARD POLICY LEVEL DATA
	IF OBJECT_ID('tempdb.dbo.#DASHBOARD_PL', 'U') IS NOT NULL
		DROP TABLE #DASHBOARD_PL;
	
	select A.producerid, A.policynum
	, case when 
			CAST(a.effectiveDate AS DATE) <=   @date
		and case when status = 3 then CAST(cancelledDate AS DATE) else CAST(expirationDate AS DATE) end > @date then 1 else 0 end as current_MONTH_END_PIF
	, case when 
			CAST(a.effectiveDate AS DATE) <=   dateadd(MONTH	, -1, @date)
		and case when status = 3 then CAST(cancelledDate AS DATE) else CAST(expirationDate AS DATE) end > dateadd(MONTH	, -1, @date) then 1 else 0 end as Prior_MONTH_END_PIF
	, case when 
		CAST(a.effectiveDate AS DATE) <=   dateadd(year, -1, @date )
		and CAST(a.effectiveDate AS DATE) <   @date
		and case when status = 3 then CAST(cancelledDate AS DATE) else CAST(expirationDate AS DATE) end > dateadd(year, -1, @date )then 1 else 0 	
		end as PRIOR_YEAR_MONTH_END_PIF
	--TRAIL month NB
	, case when isRenewal  =  0 and CAST(bounddate AS DATE) between  dateadd(MONTH	, -1, @date) and @date then 1 else 0 end as NB_trail_1
	, case when isRenewal  =  0 and CAST(bounddate AS DATE) between  dateadd(MONTH	, -2, @date) and dateadd(MONTH	, -1, @date) then 1 else 0 end as NB_trail_2
	--NB TYD
	, case when isRenewal  =  0 and CAST(bounddate AS DATE) between @YTDDay and @date then 1 else 0 end as NB_YTD
	
	, case when isRenewal  =  0 and CAST(bounddate AS DATE) between @YTDDay and dateadd(MONTH	, -1, @date) then 1 else 0 end as prior_month_NB_YTD
	--NB Prior TYD
	, case when isRenewal  =  0 and CAST(bounddate AS DATE) between DATEADD(year,-1,@YTDDay ) and DATEADD(year,-1,@date ) then 1 else 0 end as NB_PYTD
	--EFT
	,  case when paymentPlanID in ( 19, 20, 25 ) and CAST(bounddate AS DATE) between  dateadd(MONTH	, -1, @date) and @date  then 1 else 0 end as eft_TRAIL_1
	,  case when paymentPlanID in ( 19, 20, 25 ) and CAST(bounddate AS DATE) between  dateadd(MONTH	, -2, @date) and dateadd(MONTH	, -1, @date) then 1 else 0 end as eft_TRAIL_2
	--EFT YTD
	, case when paymentPlanID in ( 19, 20, 25 ) and CAST(bounddate AS DATE) between  @YTDDay and @date  then 1 else 0 end as eft_YTD_1
	--6_1 and 7_6 metrics
	, CASE WHEN CAST(datefirstwritten AS DATE) BETWEEN dateadd(day, -154, dateadd(day, -30, @date)) AND dateadd(day, -154, @date)
		AND DATEDIFF(day, CAST(datefirstwritten AS DATE), case when status = '1' then CAST(expirationDate AS DATE) else CAST(cancelleddate AS DATE) end ) > 154 THEN 1 else 0 END as TRAIL_1_6_1
	, CASE WHEN CAST(datefirstwritten AS DATE) BETWEEN dateadd(day, -154, dateadd(day, -90, @date)) AND dateadd(day, -154, @date)
		AND DATEDIFF(day, CAST(datefirstwritten AS DATE), case when status = '1' then CAST(expirationDate AS DATE) else CAST(cancelleddate AS DATE) end ) > 154 THEN 1 else 0 END as TRAIL_3_6_1
	, CASE WHEN CAST(datefirstwritten AS DATE) BETWEEN datefromparts(year(dateadd(day, -1, @date)),1,1) AND dateadd(day, -154, @date)
		AND DATEDIFF(day, CAST(datefirstwritten AS DATE), case when status = '1' then CAST(expirationDate AS DATE) else CAST(cancelleddate AS DATE) end ) > 154 THEN 1 else 0 END as TRAIL_YTD_6_1
	, CASE WHEN CAST(datefirstwritten AS DATE) BETWEEN dateadd(day, -154, dateadd(day, -30, @date)) AND dateadd(day, -154, @date) THEN 1 else 0 END as possible_TRAIL_1_6_1
	, CASE WHEN CAST(datefirstwritten AS DATE) BETWEEN dateadd(day, -154, dateadd(day, -90, @date)) AND dateadd(day, -154, @date) THEN 1 else 0 END as possible_TRAIL_3_6_1
	, CASE WHEN CAST(datefirstwritten AS DATE) BETWEEN datefromparts(year(dateadd(day, -1, @date)),1,1) AND dateadd(day, -154, @date) THEN 1 else 0 END as possible_TRAIL_YTD_6_1
	, CASE WHEN CAST(datefirstwritten AS DATE) BETWEEN dateadd(day, -185, dateadd(day, -30, @date)) AND dateadd(day, -185, @date)
		AND DATEDIFF(day, CAST(datefirstwritten AS DATE), case when status = '1' then CAST(expirationDate AS DATE) else CAST(cancelleddate AS DATE) end ) > 185 THEN 1 else 0 END as TRAIL_1_7_6
	, CASE WHEN CAST(datefirstwritten AS DATE) BETWEEN dateadd(day, -185, dateadd(day, -90, @date)) AND dateadd(day, -185, @date)
		AND DATEDIFF(day, CAST(datefirstwritten AS DATE), case when status = '1' then CAST(expirationDate AS DATE) else CAST(cancelleddate AS DATE) end ) > 185 THEN 1 else 0 END as TRAIL_3_7_6   
	, CASE WHEN CAST(datefirstwritten AS DATE) BETWEEN datefromparts(year(dateadd(day, -1, @date)),1,1) AND dateadd(day, -185, @date)
		AND DATEDIFF(day, CAST(datefirstwritten AS DATE), case when status = '1' then CAST(expirationDate AS DATE) else CAST(cancelleddate AS DATE) end ) > 185 THEN 1 else 0 END as TRAIL_YTD_7_6   
	, CASE WHEN CAST(datefirstwritten AS DATE) BETWEEN dateadd(day, -185, dateadd(day, -30, @date)) AND dateadd(day, -185, @date) THEN 1 else 0 END as possible_TRAIL_1_7_6   
	, CASE WHEN CAST(datefirstwritten AS DATE) BETWEEN dateadd(day, -185, dateadd(day, -90, @date)) AND dateadd(day, -185, @date) THEN 1 else 0 END as possible_TRAIL_3_7_6   
	, CASE WHEN CAST(datefirstwritten AS DATE) BETWEEN datefromparts(year(dateadd(day, -1, @date)),1,1) AND dateadd(day, -185, @date) THEN 1 else 0 END as possible_TRAIL_YTD_7_6   
	--LR, 
	,CAST(ISNULL(E.EP	,0)  AS decimal(10,4)) AS EP
	,CAST(ISNULL(F.BI	,0) * (select  TOP 1 BI from Periscope_Data.dbo.SEVERITIES where STATE = 'TX' 
								order by case when MONTH_END = @date then 0 when @date < MONTH_END then 1 else 2 end asc,
								abs(datediff(day,@date,MONTH_END)) asc) AS decimal(10,4))+		 
		CAST(ISNULL(F.CMP	,0) * (select  TOP 1 CMP from Periscope_Data.dbo.SEVERITIES where STATE = 'TX' 
								order by case when MONTH_END = @date then 0 when @date < MONTH_END then 1 else 2 end asc,
								abs(datediff(day,@date,MONTH_END)) asc) AS decimal(10,4))+	
		CAST(ISNULL(F.COL	,0) * (select  TOP 1 COL from Periscope_Data.dbo.SEVERITIES where STATE = 'TX' 
								order by case when MONTH_END = @date then 0 when @date < MONTH_END then 1 else 2 end asc,
								abs(datediff(day,@date,MONTH_END)) asc) AS decimal(10,4))+	
		CAST(ISNULL(F.PD	,0) * (select  TOP 1 PD from Periscope_Data.dbo.SEVERITIES where STATE = 'TX' 
								order by case when MONTH_END = @date then 0 when @date < MONTH_END then 1 else 2 end asc,
								abs(datediff(day,@date,MONTH_END)) asc) AS decimal(10,4))+	
		CAST(ISNULL(F.PIP	,0) * (select  TOP 1 PIP from Periscope_Data.dbo.SEVERITIES where STATE = 'TX' 
								order by case when MONTH_END = @date then 0 when @date < MONTH_END then 1 else 2 end asc,
								abs(datediff(day,@date,MONTH_END)) asc) AS decimal(10,4))	 AS LOSS
		
	,isnull(COL ,0) + isnull(CMP ,0)+ isnull(BI ,0) + isnull(PD ,0) + isnull(PIP ,0)+
			isnull(UMPD,0)+ isnull(UMBI,0)+ isnull(RENT,0)+ isnull(TOW ,0)+
			isnull(UNPD,0)+ isnull(UNBI,0) + isnull(CDW ,0) as CLAIM_COUNT
	--WP
	, case when bounddate between dateadd(year, -1, @date ) and @date then CAST(termPremiumsDue AS decimal(10,4)) else 0 end AS WP_TRAIL_12
	--Cell TRAIL 1
	, case when phone2 is NOT null and bounddate between  dateadd(MONTH	, -1, @date) and @date  then 1 else 0 end as CELL_TRAIL_1
	, case when phone2 is NOT null and bounddate between  dateadd(MONTH	, -2, @date) and dateadd(MONTH	, -1, @date)  then 1 else 0 end as CELL_TRAIL_2
	--cell YTD
	, case when phone2 is NOT null and bounddate between @YTDDay and @date  then 1 else 0 end as cell_YTD
	--Email TRAIL 1 
	, case when email is not null and bounddate between  dateadd(MONTH	, -1, @date) and @date  then 1 else 0 end as email_TRAIL_1
	, case when email is not null and bounddate between  dateadd(MONTH	, -2, @date) and dateadd(MONTH	, -1, @date) then 1 else 0 end as email_TRAIL_2
	--email YTD
	, case when email is not null and bounddate between @YTDDay and @date then 1 else 0 end as email_YTD
	, n1.call_count
	, (select max(nx.adddate) from #note nx where a.policyid = nx.policyID) as last_call_date
	, case when APEX_LTD_APPOINT > 0 then 'Y' else 'N' end as APEX_LTD_APPOINT
	, case when APEX_STD_APPOINT > 0 then 'Y' else 'N' end as APEX_STD_APPOINT
	, case when EDGE_LTD_APPOINT > 0 then 'Y' else 'N' end as EDGE_LTD_APPOINT
	, case when EDGE_STD_APPOINT > 0 then 'Y' else 'N' end as EDGE_STD_APPOINT
	, case when ENVOY_APPOINT    > 0 then 'Y' else 'N' end as ENVOY_APPOINT   
	, a.ratingProgram
	INTO #DASHBOARD_PL 
		from windhaven_report.dbo.policy a
		left join windhaven_report.dbo.insured b on a.insuredid = b.insuredid
		LEFT JOIN #EP E ON A.POLICYID = E.POLICYID AND A.PRODUCERID = E.PRODUCERID
		LEFT JOIN #FREQ F ON A.POLICYID = F.POLICYID AND A.PRODUCERID = F.PRODUCERID
		left join #notetotal n1 on a.policyid = n1.policyid 
		left join #appoint ap on a.producerID = ap.producerID
	where 1=1
	--and A.producerid not in (5050, 738583, 738584)	--Windhaven codes
	and left(policynum, 1) <> 'Q'
	and bounddate is not null
	order by bounddate , a.policyid


--AGENT_DASHBOARD
	IF OBJECT_ID('Periscope_data.dbo.AGT_DASHBOARD1', 'U') IS NOT NULL
		DROP TABLE Periscope_data.dbo.AGT_DASHBOARD1 ;


		SELECT A.PRODUCERID as producer_id
			, max(@date ) as run_date
			, A.CODE +'-'+ A.subcode as agent_number
			, case when a.agentDBA = '' then producername else ISNULL(A.agentDBA,a.producername) end as agent_name
			, A.city
			, CASE   WHEN A.assignedSalesRepID = 256 THEN 'ERICA BOND'		 
					WHEN A.assignedSalesRepID = 129 THEN 'EVELYN MASTRAPA'	 
					WHEN A.assignedSalesRepID = 130 THEN 'GUS VASQUEZ'		 
					WHEN A.assignedSalesRepID = 253 THEN 'JULIE STOUT-DIAZ' 
					WHEN A.assignedSalesRepID = 128 THEN 'KELLEN BRITTAIN'	 
					WHEN A.assignedSalesRepID = 228 THEN 'KIMBER SCATLIN'	 
					WHEN A.assignedSalesRepID = 252 THEN 'MIREYA VALDES'	 
					WHEN A.assignedSalesRepID = 207 THEN 'SANDY GRAFF'		 
					WHEN A.assignedSalesRepID = 255 THEN 'VERONICA OLIVERA' 
					WHEN A.assignedSalesRepID = 254 THEN 'YEMI DIAZ'		 
					WHEN A.assignedSalesRepID = 244 THEN 'YUSIMI GRILLO '	 
					else '' end as agent_mkt_rep
			, SUM(ISNULL(B.current_MONTH_END_PIF,0)) AS current_eom_pif
			, SUM(ISNULL(B.Prior_MONTH_END_PIF,0)) AS prior_eom_pif

			, SUM(ISNULL(B.PRIOR_YEAR_MONTH_END_PIF,0)) AS prior_year_eom_pif
			, cast(SUM(ISNULL(B.current_MONTH_END_PIF,0))  as decimal(10,4))  pif_change_num
			, cast(SUM(ISNULL(B.prior_MONTH_END_PIF,0))  as decimal(10,4))  prior_month_pif_change_den
			, cast(SUM(ISNULL(B.PRIOR_YEAR_MONTH_END_PIF,0)) as decimal(10,4)) pif_change_den 

			, SUM(ISNULL(B.NB_TRAIL_1,0)) AS new_business_last_month
			, SUM(ISNULL(B.NB_YTD,0)) AS new_business_ytd
			, SUM(ISNULL(B.prior_month_NB_YTD,0)) AS prior_month_new_business_ytd
			, SUM(ISNULL(B.NB_PYTD,0)) AS new_business_pytd
			, cast(SUM(ISNULL(B.NB_YTD,0))  as decimal(10,4)) nb_change_num
			, cast(SUM(ISNULL(B.prior_month_NB_YTD,0))  as decimal(10,4)) prior_month_nb_change_den
			, cast(SUM(ISNULL(B.NB_PYTD,0)) as decimal(10,4)) nb_change_den
			, SUM(ISNULL(eft_TRAIL_1,0)) AS eft_last_month
			, SUM(ISNULL(B.EFT_YTD_1,0)) AS eft_ytd
			, CAST( SUM(ISNULL(B.TRAIL_1_6_1,0))   AS INT) retention_1_month_6_1_num , CAST(SUM(ISNULL(B.POSSIBLE_TRAIL_1_6_1,0))   AS DECIMAL(10,4)) AS retention_1_month_6_1_den
			, CAST( SUM(ISNULL(B.TRAIL_1_7_6,0))   AS INT) retention_1_month_7_6_num , CAST(SUM(ISNULL(B.POSSIBLE_TRAIL_1_7_6,0))   AS DECIMAL(10,4)) AS retention_1_month_7_6_den
			, CAST( SUM(ISNULL(B.TRAIL_YTD_6_1,0)) AS INT) retention_YTD_6_1_num, CAST(SUM(ISNULL(B.POSSIBLE_TRAIL_YTD_6_1,0)) AS DECIMAL(10,4)) AS retention_YTD_6_1_den
			, CAST( SUM(ISNULL(B.TRAIL_YTD_7_6,0)) AS INT) retention_YTD_7_6_num, CAST(SUM(ISNULL(B.POSSIBLE_TRAIL_YTD_7_6,0)) AS DECIMAL(10,4)) AS retention_YTD_7_6_den

			, SUM(ISNULL(B.LOSS,0)) lr_past_12_month_num, SUM(ISNULL(B.EP,0)) AS lr_past_12_month_den

			, SUM(ISNULL(B.WP_TRAIL_12,0)) AS wp_last_12_month

			, SUM(ISNULL(CELL_TRAIL_1,0)) AS cell_phone_past_month
			, SUM(ISNULL(CELL_TRAIL_2,0)) AS prior_month_cell_phone_past_month
			, SUM(ISNULL(CELL_YTD,0)) AS cell_phone_ytd
			, SUM(ISNULL(email_TRAIL_1,0)) AS email_phone_past_month
			, SUM(ISNULL(email_TRAIL_2,0)) AS prior_month_email_phone_past_month
			, SUM(ISNULL(EMAIL_YTD,0)) AS email_phone_ytd

			, SUM(ISNULL(call_count,0)) AS call_count
			, common_call_reason
			, max(isnull(last_call_date,'')) as last_call_date
			, apex_ltd_appoint
			, apex_std_appoint
			, edge_ltd_appoint
			, edge_std_appoint
			, envoy_appoint   
			, SUM(ISNULL(case when b.ratingProgram = 1 then B.current_MONTH_END_PIF else 0 end ,0)) AS apex_std_sold
			, SUM(ISNULL(case when b.ratingProgram = 2 then B.current_MONTH_END_PIF else 0 end ,0)) AS apex_ltd_sold
			, SUM(ISNULL(case when b.ratingProgram = 3 then B.current_MONTH_END_PIF else 0 end ,0)) AS edge_std_sold
			, SUM(ISNULL(case when b.ratingProgram = 4 then B.current_MONTH_END_PIF else 0 end ,0)) AS edge_ltd_sold
			, SUM(ISNULL(case when b.ratingProgram = 5 then B.current_MONTH_END_PIF else 0 end ,0)) AS envoy_sold
			, sum(isnull(claim_count,0)) claim_count
into Periscope_data.dbo.AGT_DASHBOARD1 
FROM PRODUCER A
	LEFT JOIN #DASHBOARD_PL B ON A.producerID = B.producerID
	left join #notemax2 n2 on a.producerID = n2.producerid  and rownum = 1
--WHERE A.producerid = 738136
where code <> 999960
GROUP BY A.PRODUCERID, A.CODE +'-'+ A.subcode, case when a.agentDBA = '' then producername else ISNULL(A.agentDBA,a.producername) end , A.city, A.assignedSalesRepID, common_call_reason
, APEX_LTD_APPOINT
, APEX_STD_APPOINT
, EDGE_LTD_APPOINT
, EDGE_STD_APPOINT
, ENVOY_APPOINT 



--AGENT_DASHBOARD
	IF OBJECT_ID('Periscope_data.dbo.AGT_DASHBOARD', 'U') IS NOT NULL
		DROP TABLE Periscope_data.dbo.AGT_DASHBOARD ;

	select * 
,case when pif_change_den= 0 then 0 else pif_change_num					 /pif_change_den							end as pif_change
,case when prior_month_pif_change_den= 0 then 0 else pif_change_num		/prior_month_pif_change_den					end as pif_change_month
,case when nb_change_den= 0 then 0 else nb_change_num					 /nb_change_den								end as nb_change
,case when prior_month_nb_change_den= 0 then 0 else nb_change_num		/prior_month_nb_change_den					end as nb_change_month
,case when retention_1_month_6_1_den= 0 then 0 else retention_1_month_6_1_num		 /retention_1_month_6_1_den		end as retention_1month_6_1
,case when retention_1_month_7_6_den= 0 then 0 else retention_1_month_7_6_num		 /retention_1_month_7_6_den		end as retention_1month_7_6
,case when retention_YTD_6_1_den= 0 then 0 else retention_YTD_6_1_num			 /retention_YTD_6_1_den				end as retention_ytd_6_1
,case when retention_YTD_7_6_den= 0 then  0 else retention_YTD_7_6_num			 /retention_YTD_7_6_den				end as retention_ytd_7_6
,case when lr_past_12_month_den= 0 then 0 else lr_past_12_month_num			 /lr_past_12_month_den					end as lr_past_12_months



	into  Periscope_data.dbo.AGT_DASHBOARD
	from  Periscope_data.dbo.AGT_DASHBOARD1  

END
GO

