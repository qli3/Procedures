USE [Periscope_Data]
GO

/****** Object:  StoredProcedure [dbo].[ENVOY_TRACKING_TEST]    Script Date: 12/15/2017 4:37:59 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[ENVOY_TRACKING_TEST]

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

			CREATE TABLE #Agents (
  
			  agentCode VARCHAR(30) NOT NULL
			);

			INSERT INTO #Agents 
				(agentCode) 
			VALUES 
('100003-000-000')
,('100003-001-000')
,('100003-002-000')
,('100007-001-000')
,('100024-000-000')
,('100025-000-000')
,('100028-000-000')
,('100029-000-000')
,('100030-000-000')
,('100031-000-000')
,('100032-000-000')
,('100033-000-000')
,('100040-000-000')
,('100051-000-000')
,('100057-000-000')
,('100059-000-000')
,('100061-000-000')
,('100076-000-000')
,('100089-000-000')
,('100092-000-000')
,('100098-000-000')
,('100102-000-000')
,('100116-000-000')
,('100120-000-000')
,('100149-000-000')
,('100177-000-000')
,('100180-000-000')
,('100180-001-000')
,('100180-002-000')
,('100180-003-000')
,('100180-004-000')
,('100180-005-000')
,('100180-006-000')
,('100180-007-000')
,('100180-008-000')
,('100192-000-000')
,('100211-000-000')
,('100212-000-000')
,('100212-001-000')
,('100224-000-000')
,('100238-000-000')
,('100245-000-000')
,('100246-000-000')
,('100248-000-000')
,('100251-000-000')
,('100272-000-000')
,('100273-000-000')
,('100274-000-000')
,('100282-000-000')
,('100288-000-000')
,('100288-001-000')
,('100288-002-000')
,('100299-000-000')
,('100299-001-000')
,('100321-000-000')
,('100323-000-000')
,('100327-000-000')
,('100329-000-000')
,('100345-000-000')
,('100347-000-000')
,('100362-000-000')
,('100364-000-000')
,('100384-000-000')
,('100406-000-000')
,('100416-000-000')
,('100435-000-000')
,('100445-000-000')
,('100445-001-000')
,('100445-002-000')
,('100445-003-000')
,('100445-004-000')
,('100453-000-000')
,('100454-000-000')
,('100460-000-000')
,('100463-000-000')
,('100486-000-000')
,('100498-000-000')
,('100499-000-000')
,('100502-000-000')
,('100504-000-000')
,('100507-000-000')
,('100510-000-000')
,('100520-000-000')
,('100594-000-000')
,('100631-000-000')
,('100631-001-000')
,('100639-000-000')
,('100649-003-000')
,('100649-015-000')
,('100653-000-000')
,('100654-000-000')
,('100657-000-000')
,('100659-000-000')
,('100666-000-000')
,('100698-000-000')
,('100701-000-000')
,('100704-000-000')
,('100721-000-000')
,('100725-000-000')
,('100733-000-000')
,('100734-000-000')
,('100747-000-000')
,('100750-000-000')
,('100762-000-000')
,('100763-000-000')
,('100766-000-000')
,('100768-000-000')
,('100773-000-000')
,('100774-000-000')
,('100775-000-000')
,('100780-000-000')
,('100782-000-000')
,('100783-000-000')
,('100784-000-000')
,('100784-001-000')
,('100784-002-000')
,('100784-004-000')
,('100784-007-000')
,('100784-010-000')
,('100788-000-000')
,('100806-000-000')
,('100817-000-000')
,('100818-000-000')
,('100818-001-000')
,('100822-000-000')
,('100823-000-000')
,('100823-001-000')
,('100823-002-000')
,('100823-003-000')
,('100823-004-000')
,('100823-005-000')
,('100823-007-000')
,('100823-008-000')
,('100823-009-000')
,('100823-010-000')
,('100823-011-000')
,('100823-012-000')
,('100823-013-000')
,('100823-014-000')
,('100823-015-000')
,('100823-016-000')
,('100824-000-000')
,('100830-000-000')
,('100830-001-000')
,('100839-000-000')
,('100839-001-000')
,('100843-000-000')
,('100855-000-000')
,('100856-000-000')
,('100862-000-000')
,('100867-000-000')
,('100870-000-000')
,('100870-001-000')
,('100870-002-000')
,('100871-000-000')
,('100871-001-000')
,('100874-000-000')
,('100874-001-000')
,('100874-002-000')
,('100874-003-000')
,('100874-004-000')
,('100874-005-000')
,('100874-006-000')
,('100874-007-000')
,('100874-008-000')
,('100874-009-000')
,('100875-000-000')
,('100882-000-000')
,('100891-000-000')
,('100893-000-000')
,('100894-000-000')
,('100899-000-000')
,('100902-000-000')
,('100905-000-000')
,('100905-001-000')
,('100905-002-000')
,('100906-000-000')
,('100913-000-000')
,('100914-000-000')
,('100921-000-000')
,('100929-000-000')
,('100929-001-000')
,('100932-000-000')
,('100934-000-000')
,('100942-000-000')
,('100947-000-000')
,('100948-000-000')
,('100961-000-000')
,('100967-000-000')
,('100974-000-000')
,('100977-000-000')
,('100984-000-000')
,('100997-000-000')
,('100999-000-000')
,('101001-000-000')
,('101002-000-000')
,('101008-000-000')
,('101011-000-000')
,('101017-000-000')
,('101020-000-000')
,('101023-000-000')
,('101026-000-000')
,('101032-000-000')
,('101034-000-000')
,('101037-000-000')
,('101039-000-000')
,('101041-000-000')
,('101044-000-000')
,('101044-001-000')
,('101044-002-000')
,('101044-003-000')
,('101044-004-000')
,('101044-005-000')
,('101046-000-000')
,('101077-000-000')
,('101078-000-000')
,('101081-000-000')
,('101083-000-000')
,('101086-000-000')
,('101086-000-001')
,('101086-000-002')
,('101086-000-003')
,('101089-000-000')
,('101095-000-000')
,('101114-000-000')
,('101118-000-000')
,('101119-000-000')
,('101119-001-000')
,('101121-000-000')
,('101121-001-000')
,('101121-002-000')
,('101129-000-000')
,('101133-000-000')
,('101135-000-000')
,('101149-000-000')
,('101150-000-000')
,('101159-000-000')
,('101160-000-000')
,('101164-000-000')
,('101166-000-000')
,('101167-000-000')
,('101168-000-000')
,('101174-000-000')
,('865700-000-000')







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
	Envoy Only 
	*/

	;;;
	--Total Book

	
				--Drop table if created 
			IF OBJECT_ID('Periscope_Data.dbo.Envoy_Agent_ALL_TEST', 'U') IS NOT NULL
			DROP TABLE Periscope_Data.dbo.Envoy_Agent_ALL_TEST; 	



			select AGENTID, c.producername,
				   COUNT(DISTINCT (CASE WHEN QUOTETYPE = 'MQ' 
											and datename(dw, getDate()) <> 'Monday'
											and a.quotedate = dateadd(d, -1, cast(getdate() as date)) 
											THEN firstname+LASTNAME
										WHEN QUOTETYPE = 'MQ'
											and datename(dw,getDate()) = 'Monday'
											and (a.quotedate = dateadd(d, -3, cast(getdate() as date)) or a.quotedate = dateadd(d, -2, cast(getdate() as date)) or a.quotedate = dateadd(d, -1, cast(getdate() as date)))
											THEN firstname+LASTNAME  END)) AS QUOTES_PriorDay, 
				   COUNT(DISTINCT (CASE WHEN QUOTETYPE = 'MQ' THEN firstname+LASTNAME END)) AS QUOTES, 
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
			into Periscope_Data.dbo.Envoy_Agent_ALL_TEST from #T2 A
				LEFT JOIN #bound B ON  A.AgentID = B.agentCode
				left join  #producer c on a.agentid = c.agentCode
			GROUP BY AGENTid, c.producername
			ORDER BY AgentID
			;;

	--Envoy Only
	
				--Drop table if created 
			IF OBJECT_ID('Periscope_Data.dbo.Envoy_Agent_Envoy_TEST', 'U') IS NOT NULL
			DROP TABLE Periscope_Data.dbo.Envoy_Agent_Envoy_TEST; 	


			select AGENTID, c.producername,
				   COUNT(DISTINCT (CASE WHEN QUOTETYPE = 'MQ'
											and datename(dw, getDate()) <> 'Monday' 
											and a.quotedate = dateadd(d, -1, cast(getdate() as date)) 
											THEN firstname+LASTNAME 
										WHEN QUOTETYPE = 'MQ'
											and datename(dw, getDate()) = 'Monday'
											and (a.quotedate =dateadd(d, -3, cast(getdate() as date)) or a.quotedate = dateadd(d, -2, cast(getdate() as date)) or a.quotedate = dateadd(d, -1, cast(getdate() as date)))											
											THEN firstname+LASTNAME  END)) AS QUOTES_PriorDay,  
				   COUNT(DISTINCT (CASE WHEN QUOTETYPE = 'MQ' THEN firstname+LASTNAME END)) AS QUOTES, 
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
			into Periscope_Data.dbo.Envoy_Agent_Envoy_TEST from #T2 A
				LEFT JOIN #bound B ON  A.AgentID = B.agentCode
				left join  #producer c on a.agentid = c.agentCode
				where product = 'PLUS'
			GROUP BY AGENTid , c.producername
			ORDER BY AgentID;


END
GO

