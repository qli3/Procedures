USE [Periscope_Data]
GO

/****** Object:  StoredProcedure [dbo].[ENVOY_TRACKING]    Script Date: 12/15/2017 4:37:51 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Tim Hu>
-- Create date: <Create Date,,>
-- last changed 7/14/2017 3:50 central
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[ENVOY_TRACKING]

AS
	-- Add the parameters for the stored procedure here
	
		declare @EnvoyDate date, @today date;;
		
		set @EnvoyDate = convert(date,'2017-06-22');
		set @today = cast(getdate() as date);
	


BEGIN

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

/*
-- =============================================
update signed agent list , needs to be updated daily
-- =============================================

*/
			IF OBJECT_ID('tempdb.dbo.#Agents', 'U') IS NOT NULL
			DROP TABLE #Agents; 

			select code+'-'+subcode as agentCode 
			into #Agents
			from [Windhaven_Report].[dbo].producer a
			left join [Windhaven_Report].[dbo].[ProducerPolicyType] b on a.producerid = b.producerid
			where 1=1 
			and b.ratingprogram = 5
			and quotestatus <> 0
			and code <> 999960
			order by quoteStatus


			;;


/*
	#######################################################################################
	Bound Policies 
*/
			--drop bound table is needed
			IF OBJECT_ID('tempdb.dbo.#bound', 'U') IS NOT NULL
			DROP TABLE #bound; 		
	
		select  p.*, concat(u.code,'-',u.subcode) agentCode			
		into #bound from Windhaven_Report.dbo.policy p
			left join Windhaven_Report.dbo.producer u on p.producerid = u.producerid
			inner join #agents a  on concat(u.code,'-',u.subcode)  = a.agentcode
		where 
			p.bounddate >= @EnvoyDate and p.boundDate <  cast(getdate() as date)
			and isRenewal = 0
			and p.status in ( 1,2)
			;;

	/*
	#######################################################################################
	 rate request info 
	*/
				
			--drop table #t1
			IF OBJECT_ID('tempdb.dbo.#T1', 'U') IS NOT NULL
			DROP TABLE #T1; 		

			;;

			SELECT *,
					substring(jsondatastring,charindex('agentID', jsondatastring) + 10, 14)							
				AgentID,
					substring(jsondatastring,charindex('firstName', jsondatastring) + 11, charindex(',',jsondatastring,charindex('firstName',jsondatastring))-(charindex('firstName',jsondatastring)+11)) 
				FirstName,
					substring(jsondatastring,charindex('lastName', jsondatastring) + 10, charindex(',',jsondatastring,charindex('lastName',jsondatastring))-(charindex('lastName',jsondatastring)+10)) 
				LastName,
					substring(jsondatastring,charindex('GaragingAddress', jsondatastring) + 17, charindex('}',jsondatastring,charindex('GaragingAddress',jsondatastring))-(charindex('GaragingAddress',jsondatastring)+17)) 
				GaragingAddress,
					substring(clutchURL, charindex('SILVERVINE',clutchURL) + 11, len(clutchURL)-(charindex('SILVERVINE',clutchURL)+10)) 
				"Product/Route",
					substring(jsonDataString, charindex('creditScoreCode',jsonDataString)+18, 1) 
				CreditScoreCode,
					(case when quoteResponse LIKE '%total%' 
						then substring(quoteResponse, charindex('total',quoteResponse)+8,charindex('BI',quoteResponse)-(charindex('total', quoteResponse) + 11))
						else 'ERROR' end) 
				TotalPremium, 
					cast( adddate as date) 
				QuoteDate
			into #T1 FROM Windhaven_Report.maint.ClutchRateRequest 
			
			WHERE  1 = 1 
				AND substring(jsondatastring,charindex('agentID', jsondatastring) + 10, 14) IN ( select agentCode from #Agents)
				   AND adddate >= @EnvoyDate

			;;

			--Drop table 2 is created 
			IF OBJECT_ID('tempdb.dbo.#T2', 'U') IS NOT NULL
			DROP TABLE #T2; 		


			--split quote type and 
			select *,
					case when left("Product/Route", 4) = 'PLUS' then 'PLUS' 
						 when left("Product/Route", 8) = 'APEX-LTD' then 'APEX-LTD'
						 when left("Product/Route", 8) = 'APEX-STD' then 'APEX-STD'
						 when left("Product/Route", 8) = 'EDGE-LTD' then 'EDGE-LTD'
						 when left("Product/Route", 8) = 'EDGE-STD' then 'EDGE-STD'			 
						 else '' end as 
				product,
					case when right("Product/Route", 12) = 'minute_quote' then 'MQ' 
						 when right("Product/Route", 5) = 'quote' then 'FQ'
						 else 'E' end as 
				quoteType	
			into #T2 from #T1

		;;
	
	/*
	#########################################################################################
	clean producer data
	#########################################################################################
	*/
	

				--Drop table 2 is created 
			IF OBJECT_ID('tempdb.dbo.#producer', 'U') IS NOT NULL
			DROP TABLE #producer; 	


			select concat(code,'-',subcode) agentCode, producername , ROW_NUMBER () over (partition by code order by code, producername ) as num
			into #producer from Windhaven_Report.dbo.producer
			order by  concat(code,'-',subcode), producername
	
	
	
	/*
	#######################################################################################
	Create tables 
	*/

	;;;
	--Total Book

	
				--Drop table if created 
			IF OBJECT_ID('Periscope_Data.dbo.Envoy_Agent_ALL', 'U') IS NOT NULL
			DROP TABLE Periscope_Data.dbo.Envoy_Agent_ALL; 	



			select AGENTID, c.producername,
				   COUNT(DISTINCT (CASE WHEN QUOTETYPE = 'MQ'  and TotalPremium <> 'ERROR'
											and datename(dw, getDate()) <> 'Monday'
											and a.quotedate = dateadd(d, -1, cast(getdate() as date)) 
											THEN firstname+LASTNAME
										WHEN QUOTETYPE = 'MQ' and TotalPremium <> 'ERROR'
											and datename(dw,getDate()) = 'Monday'
											and (a.quotedate = dateadd(d, -3, cast(getdate() as date)) or a.quotedate = dateadd(d, -2, cast(getdate() as date)) or a.quotedate = dateadd(d, -1, cast(getdate() as date)))
											THEN firstname+LASTNAME  END)) AS QUOTES_PriorDay, 
				   COUNT(DISTINCT (CASE WHEN QUOTETYPE = 'MQ' and TotalPremium <> 'ERROR' THEN firstname+LASTNAME END)) AS QUOTES, 
				   COUNT(DISTINCT (CASE WHEN QUOTETYPE = 'FQ' 
											and datename(dw, getDate()) <> 'Monday'
											and a.quotedate = dateadd(d, -1, cast(getdate() as date))
											THEN firstname+LASTNAME
										WHEN QUOTETYPE = 'FQ'
											and datename(dw, getDate()) = 'Monday'
											and (a.quotedate = dateadd(d, -3, cast(getDate() as date)) or a.quoteDate = dateadd(d, -2, cast(getDate() as date)) or a.quoteDate = dateadd(d, -1, cast(getDate() as date)))
											THEN firstname+LASTNAME  END)) AS SUBMISSIONS_PriorDay,
				   COUNT(DISTINCT (CASE WHEN QUOTETYPE = 'FQ' THEN firstname+LASTNAME END)) AS SUBMISSIONS, 
				   COUNT(DISTINCT (case when datename(dw, getDate()) <> 'Monday'
											and cast(b.bounddate as date) = dateadd(d, -1, cast(getdate() as date)) then POLICYNUM
										when datename(dw, getDate()) = 'Monday'
											and (cast(b.boundDate as date) = dateadd(d, -3, cast(getdate() as date)) or cast(b.bounddate as date) = dateadd(d, -2, cast(getdate() as date)) or cast(b.bounddate as date) = dateadd(d, -1, cast(getdate() as date)))
											THEN policyNum end)) AS WRITTEN_PriorDay,
				   COUNT(DISTINCT POLICYNUM) AS WRITTEN
			into Periscope_Data.dbo.Envoy_Agent_ALL from #T2 A
				LEFT JOIN #bound B ON  A.AgentID = B.agentCode
				left join  #producer c on a.agentid = c.agentCode
			GROUP BY AGENTid, c.producername
			ORDER BY AgentID
			;;

	--Envoy Only
	
				--Drop table if created 
			IF OBJECT_ID('Periscope_Data.dbo.Envoy_Agent_Envoy', 'U') IS NOT NULL
			DROP TABLE Periscope_Data.dbo.Envoy_Agent_Envoy; 	


			select AGENTID, c.producername,
				   COUNT(DISTINCT (CASE WHEN QUOTETYPE = 'MQ' and TotalPremium <> 'ERROR'
											and datename(dw, getDate()) <> 'Monday' 
											and a.quotedate = dateadd(d, -1, cast(getdate() as date)) 
											THEN firstname+LASTNAME 
										WHEN QUOTETYPE = 'MQ' and TotalPremium <> 'ERROR'
											and datename(dw, getDate()) = 'Monday'
											and (a.quotedate =dateadd(d, -3, cast(getdate() as date)) or a.quotedate = dateadd(d, -2, cast(getdate() as date)) or a.quotedate = dateadd(d, -1, cast(getdate() as date)))											
											THEN firstname+LASTNAME  END)) AS QUOTES_PriorDay,  
				   COUNT(DISTINCT (CASE WHEN QUOTETYPE = 'MQ' and TotalPremium <> 'ERROR' THEN firstname+LASTNAME END)) AS QUOTES, 
				   COUNT(DISTINCT (CASE WHEN QUOTETYPE = 'FQ' 
											and datename(dw, getdate()) <> 'Monday'
											and a.quotedate = dateadd(d, -1, cast(getdate() as date))
											THEN firstname+LASTNAME 
										WHEN QUOTETYPE = 'FQ'
											and datename(dw, getDate()) = 'Monday'
											and (a.quotedate = dateadd(d, -3, cast(getDate() as date)) or a.quoteDate = dateadd(d, -2, cast(getDate() as date)) or a.quoteDate = dateadd(d, -1, cast(getDate() as date)))
											THEN firstname+LASTNAME  END)) AS SUBMISSIONS_PriorDay,
				   COUNT(DISTINCT (CASE WHEN QUOTETYPE = 'FQ' THEN firstname+LASTNAME END)) AS SUBMISSIONS, 
				   COUNT(DISTINCT (case when b.ratingprogram = 5 
											and cast(b.bounddate as date) = dateadd(d, -1, cast(getdate() as date)) 
											and datename(dw, getDate()) <> 'Monday' 
											then POLICYNUM 
										when b.ratingprogram = 5
											and datename(dw, getDate()) = 'Monday'
											and (cast(b.boundDate as date) = dateadd(d, -3, cast(getdate() as date)) or cast(b.bounddate as date) = dateadd(d, -2, cast(getdate() as date)) or cast(b.bounddate as date) = dateadd(d, -1, cast(getdate() as date)))
											then policyNum end)) AS WRITTEN_PriorDay,
				   COUNT(DISTINCT (case when b.ratingprogram = 5 then POLICYNUM end )) AS WRITTEN
			into Periscope_Data.dbo.Envoy_Agent_Envoy from #T2 A
				LEFT JOIN #bound B ON  A.AgentID = B.agentCode
				left join  #producer c on a.agentid = c.agentCode
				where product = 'PLUS'
			GROUP BY AGENTid , c.producername
			ORDER BY AgentID;

--APEX-LTD
	--Drop table if created 
			IF OBJECT_ID('Periscope_Data.dbo.Envoy_Agent_APEX_LTD', 'U') IS NOT NULL
			DROP TABLE Periscope_Data.dbo.Envoy_Agent_APEX_LTD; 	


			select AGENTID, c.producername,
				   COUNT(DISTINCT (CASE WHEN QUOTETYPE = 'MQ' and TotalPremium <> 'ERROR'
											and datename(dw, getDate()) <> 'Monday' 
											and a.quotedate = dateadd(d, -1, cast(getdate() as date)) 
											THEN firstname+LASTNAME 
										WHEN QUOTETYPE = 'MQ' and TotalPremium <> 'ERROR'
											and datename(dw, getDate()) = 'Monday'
											and (a.quotedate =dateadd(d, -3, cast(getdate() as date)) or a.quotedate = dateadd(d, -2, cast(getdate() as date)) or a.quotedate = dateadd(d, -1, cast(getdate() as date)))											
											THEN firstname+LASTNAME  END)) AS QUOTES_PriorDay,  
				   COUNT(DISTINCT (CASE WHEN QUOTETYPE = 'MQ' and TotalPremium <> 'ERROR' THEN firstname+LASTNAME END)) AS QUOTES, 
				   COUNT(DISTINCT (CASE WHEN QUOTETYPE = 'FQ' 
											and datename(dw, getdate()) <> 'Monday'
											and a.quotedate = dateadd(d, -1, cast(getdate() as date))
											THEN firstname+LASTNAME 
										WHEN QUOTETYPE = 'FQ'
											and datename(dw, getDate()) = 'Monday'
											and (a.quotedate = dateadd(d, -3, cast(getDate() as date)) or a.quoteDate = dateadd(d, -2, cast(getDate() as date)) or a.quoteDate = dateadd(d, -1, cast(getDate() as date)))
											THEN firstname+LASTNAME  END)) AS SUBMISSIONS_PriorDay,
				   COUNT(DISTINCT (CASE WHEN QUOTETYPE = 'FQ' THEN firstname+LASTNAME END)) AS SUBMISSIONS, 
				   COUNT(DISTINCT (case when b.ratingprogram = 2 
											and cast(b.bounddate as date) = dateadd(d, -1, cast(getdate() as date)) 
											and datename(dw, getDate()) <> 'Monday' 
											then POLICYNUM 
										when b.ratingprogram = 2
											and datename(dw, getDate()) = 'Monday'
											and (cast(b.boundDate as date) = dateadd(d, -3, cast(getdate() as date)) or cast(b.bounddate as date) = dateadd(d, -2, cast(getdate() as date)) or cast(b.bounddate as date) = dateadd(d, -1, cast(getdate() as date)))
											then policyNum end)) AS WRITTEN_PriorDay,
				   COUNT(DISTINCT (case when b.ratingprogram = 2 then POLICYNUM end )) AS WRITTEN
			into Periscope_Data.dbo.Envoy_Agent_APEX_LTD from #T2 A
				LEFT JOIN #bound B ON  A.AgentID = B.agentCode
				left join  #producer c on a.agentid = c.agentCode
				where product = 'APEX-LTD'
			GROUP BY AGENTid , c.producername
			ORDER BY AgentID;

--APEX-STD
	--Drop table if created 
			IF OBJECT_ID('Periscope_Data.dbo.Envoy_Agent_APEX_STD', 'U') IS NOT NULL
			DROP TABLE Periscope_Data.dbo.Envoy_Agent_APEX_STD; 	


			select AGENTID, c.producername,
				   COUNT(DISTINCT (CASE WHEN QUOTETYPE = 'MQ' and TotalPremium <> 'ERROR'
											and datename(dw, getDate()) <> 'Monday' 
											and a.quotedate = dateadd(d, -1, cast(getdate() as date)) 
											THEN firstname+LASTNAME 
										WHEN QUOTETYPE = 'MQ' and TotalPremium <> 'ERROR'
											and datename(dw, getDate()) = 'Monday'
											and (a.quotedate =dateadd(d, -3, cast(getdate() as date)) or a.quotedate = dateadd(d, -2, cast(getdate() as date)) or a.quotedate = dateadd(d, -1, cast(getdate() as date)))											
											THEN firstname+LASTNAME  END)) AS QUOTES_PriorDay,  
				   COUNT(DISTINCT (CASE WHEN QUOTETYPE = 'MQ' and TotalPremium <> 'ERROR' THEN firstname+LASTNAME END)) AS QUOTES, 
				   COUNT(DISTINCT (CASE WHEN QUOTETYPE = 'FQ' 
											and datename(dw, getdate()) <> 'Monday'
											and a.quotedate = dateadd(d, -1, cast(getdate() as date))
											THEN firstname+LASTNAME 
										WHEN QUOTETYPE = 'FQ'
											and datename(dw, getDate()) = 'Monday'
											and (a.quotedate = dateadd(d, -3, cast(getDate() as date)) or a.quoteDate = dateadd(d, -2, cast(getDate() as date)) or a.quoteDate = dateadd(d, -1, cast(getDate() as date)))
											THEN firstname+LASTNAME  END)) AS SUBMISSIONS_PriorDay,
				   COUNT(DISTINCT (CASE WHEN QUOTETYPE = 'FQ' THEN firstname+LASTNAME END)) AS SUBMISSIONS, 
				   COUNT(DISTINCT (case when b.ratingprogram = 1 
											and cast(b.bounddate as date) = dateadd(d, -1, cast(getdate() as date)) 
											and datename(dw, getDate()) <> 'Monday' 
											then POLICYNUM 
										when b.ratingprogram = 1
											and datename(dw, getDate()) = 'Monday'
											and (cast(b.boundDate as date) = dateadd(d, -3, cast(getdate() as date)) or cast(b.bounddate as date) = dateadd(d, -2, cast(getdate() as date)) or cast(b.bounddate as date) = dateadd(d, -1, cast(getdate() as date)))
											then policyNum end)) AS WRITTEN_PriorDay,
				   COUNT(DISTINCT (case when b.ratingprogram = 1 then POLICYNUM end )) AS WRITTEN
			into Periscope_Data.dbo.Envoy_Agent_APEX_STD from #T2 A
				LEFT JOIN #bound B ON  A.AgentID = B.agentCode
				left join  #producer c on a.agentid = c.agentCode
				where product = 'APEX-STD'
			GROUP BY AGENTid , c.producername
			ORDER BY AgentID;
--EDGE-LTD
	--Drop table if created 
			IF OBJECT_ID('Periscope_Data.dbo.Envoy_Agent_EDGE_LTD', 'U') IS NOT NULL
			DROP TABLE Periscope_Data.dbo.Envoy_Agent_EDGE_LTD; 	


			select AGENTID, c.producername,
				   COUNT(DISTINCT (CASE WHEN QUOTETYPE = 'MQ' and TotalPremium <> 'ERROR'
											and datename(dw, getDate()) <> 'Monday' 
											and a.quotedate = dateadd(d, -1, cast(getdate() as date)) 
											THEN firstname+LASTNAME 
										WHEN QUOTETYPE = 'MQ' and TotalPremium <> 'ERROR'
											and datename(dw, getDate()) = 'Monday'
											and (a.quotedate =dateadd(d, -3, cast(getdate() as date)) or a.quotedate = dateadd(d, -2, cast(getdate() as date)) or a.quotedate = dateadd(d, -1, cast(getdate() as date)))											
											THEN firstname+LASTNAME  END)) AS QUOTES_PriorDay,  
				   COUNT(DISTINCT (CASE WHEN QUOTETYPE = 'MQ' and TotalPremium <> 'ERROR' THEN firstname+LASTNAME END)) AS QUOTES, 
				   COUNT(DISTINCT (CASE WHEN QUOTETYPE = 'FQ' 
											and datename(dw, getdate()) <> 'Monday'
											and a.quotedate = dateadd(d, -1, cast(getdate() as date))
											THEN firstname+LASTNAME 
										WHEN QUOTETYPE = 'FQ'
											and datename(dw, getDate()) = 'Monday'
											and (a.quotedate = dateadd(d, -3, cast(getDate() as date)) or a.quoteDate = dateadd(d, -2, cast(getDate() as date)) or a.quoteDate = dateadd(d, -1, cast(getDate() as date)))
											THEN firstname+LASTNAME  END)) AS SUBMISSIONS_PriorDay,
				   COUNT(DISTINCT (CASE WHEN QUOTETYPE = 'FQ' THEN firstname+LASTNAME END)) AS SUBMISSIONS, 
				   COUNT(DISTINCT (case when b.ratingprogram = 4 
											and cast(b.bounddate as date) = dateadd(d, -1, cast(getdate() as date)) 
											and datename(dw, getDate()) <> 'Monday' 
											then POLICYNUM 
										when b.ratingprogram = 4
											and datename(dw, getDate()) = 'Monday'
											and (cast(b.boundDate as date) = dateadd(d, -3, cast(getdate() as date)) or cast(b.bounddate as date) = dateadd(d, -2, cast(getdate() as date)) or cast(b.bounddate as date) = dateadd(d, -1, cast(getdate() as date)))
											then policyNum end)) AS WRITTEN_PriorDay,
				   COUNT(DISTINCT (case when b.ratingprogram = 4 then POLICYNUM end )) AS WRITTEN
			into Periscope_Data.dbo.Envoy_Agent_EDGE_LTD from #T2 A
				LEFT JOIN #bound B ON  A.AgentID = B.agentCode
				left join  #producer c on a.agentid = c.agentCode
				where product = 'EDGE-LTD'
			GROUP BY AGENTid , c.producername
			ORDER BY AgentID;
--EDGE-STD
	--Drop table if created 
			IF OBJECT_ID('Periscope_Data.dbo.Envoy_Agent_EDGE_STD', 'U') IS NOT NULL
			DROP TABLE Periscope_Data.dbo.Envoy_Agent_EDGE_STD; 	


			select AGENTID, c.producername,
				   COUNT(DISTINCT (CASE WHEN QUOTETYPE = 'MQ' and TotalPremium <> 'ERROR'
											and datename(dw, getDate()) <> 'Monday' 
											and a.quotedate = dateadd(d, -1, cast(getdate() as date)) 
											THEN firstname+LASTNAME 
										WHEN QUOTETYPE = 'MQ' and TotalPremium <> 'ERROR'
											and datename(dw, getDate()) = 'Monday'
											and (a.quotedate =dateadd(d, -3, cast(getdate() as date)) or a.quotedate = dateadd(d, -2, cast(getdate() as date)) or a.quotedate = dateadd(d, -1, cast(getdate() as date)))											
											THEN firstname+LASTNAME  END)) AS QUOTES_PriorDay,  
				   COUNT(DISTINCT (CASE WHEN QUOTETYPE = 'MQ' and TotalPremium <> 'ERROR' THEN firstname+LASTNAME END)) AS QUOTES, 
				   COUNT(DISTINCT (CASE WHEN QUOTETYPE = 'FQ' 
											and datename(dw, getdate()) <> 'Monday'
											and a.quotedate = dateadd(d, -1, cast(getdate() as date))
											THEN firstname+LASTNAME 
										WHEN QUOTETYPE = 'FQ'
											and datename(dw, getDate()) = 'Monday'
											and (a.quotedate = dateadd(d, -3, cast(getDate() as date)) or a.quoteDate = dateadd(d, -2, cast(getDate() as date)) or a.quoteDate = dateadd(d, -1, cast(getDate() as date)))
											THEN firstname+LASTNAME  END)) AS SUBMISSIONS_PriorDay,
				   COUNT(DISTINCT (CASE WHEN QUOTETYPE = 'FQ' THEN firstname+LASTNAME END)) AS SUBMISSIONS, 
				   COUNT(DISTINCT (case when b.ratingprogram = 3 
											and cast(b.bounddate as date) = dateadd(d, -1, cast(getdate() as date)) 
											and datename(dw, getDate()) <> 'Monday' 
											then POLICYNUM 
										when b.ratingprogram = 3
											and datename(dw, getDate()) = 'Monday'
											and (cast(b.boundDate as date) = dateadd(d, -3, cast(getdate() as date)) or cast(b.bounddate as date) = dateadd(d, -2, cast(getdate() as date)) or cast(b.bounddate as date) = dateadd(d, -1, cast(getdate() as date)))
											then policyNum end)) AS WRITTEN_PriorDay,
				   COUNT(DISTINCT (case when b.ratingprogram = 3 then POLICYNUM end )) AS WRITTEN
			into Periscope_Data.dbo.Envoy_Agent_EDGE_STD from #T2 A
				LEFT JOIN #bound B ON  A.AgentID = B.agentCode
				left join  #producer c on a.agentid = c.agentCode
				where product = 'EDGE-STD'
			GROUP BY AGENTid , c.producername
			ORDER BY AgentID;

END
GO

