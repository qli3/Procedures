USE [Periscope_Data]
GO

/****** Object:  StoredProcedure [dbo].[temp.ClutchRateRequest_EQ]    Script Date: 12/15/2017 4:41:09 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[temp.ClutchRateRequest_EQ]
	
AS
	declare @startDate date, @endDate date;;

	SET @startDate = cast(DATEADD(d, -14, getDate()) as date);
	SET @endDate = cast(getDate() as date);


	IF OBJECT_ID('#T', 'U') IS NOT NULL
	DROP TABLE #T;;

	SELECT case when charindex('\"error\":\"', quoteResponse) <> 0 
														THEN substring(quoteResponse, charindex('\"error\":\"', quoteResponse)+len('\"error\":\"') , charindex('\"', quoteResponse, charindex('\"error\":\"', quoteResponse)+len('\"error\":\"'))-(charindex('\"error\":\"', quoteResponse)+len('\"error\":\"')))
											   WHEN charindex('\"errors\":\"', quoteResponse) <> 0
														THEN substring(quoteResponse, charindex('\"errors\":\"', quoteResponse)+len('\"errors\":\"'), charindex('\"', quoteResponse, charindex('\"errors\":\"', quoteResponse)+len('\"errors\":\"'))-(charindex('\"errors\":\"', quoteResponse)+len('\"errors\":\"'))) 
											   WHEN charindex('\"error\":{\"message\":\"', quoteResponse) <> 0 
														THEN substring(quoteResponse, charindex('\"error\":{\"message\":\"', quoteResponse)+len('\"error\":{\"message\":\"'), charindex('\"', quoteResponse, charindex('\"error\":{\"message\":\"', quoteResponse)+len('\"error\":{\"message\":\"'))-(charindex('\"error\":{\"message\":\"', quoteResponse)+len('\"error\":{\"message\":\"'))) 
											   WHEN charindex('},\"message\":\"', quoteResponse) <> 0 THEN substring(quoteResponse, charindex('},\"message\":\"', quoteResponse)+len('},\"message\":\"'), charindex('\"', quoteResponse, charindex('},\"message\":\"', quoteResponse)+len('},\"message\":\"'))-(charindex('},\"message\":\"', quoteResponse)+len('},\"message\":\"'))) 
											   WHEN substring(quoteResponse, charindex('"Statuscode":"', quoteResponse)+len('"Statuscode":"'), charindex('",', quoteResponse, charindex('"Statuscode":"', quoteResponse)+len('"Statuscode":"'))- (charindex('"Statuscode":"', quoteResponse)+len('"Statuscode":"'))) <> '200 OK'
														THEN substring(quoteResponse, charindex('"Statuscode":"', quoteResponse)+len('"Statuscode":"'), charindex('",', quoteResponse, charindex('"Statuscode":"', quoteResponse)+len('"Statuscode":"'))- (charindex('"Statuscode":"', quoteResponse)+len('"Statuscode":"')))
											   ELSE NULL END errormessage, p.policyNum, c.* 
	INTO #T
	FROM Windhaven_Report.maint.ClutchRateRequest c 
	--LEFT JOIN  Windhaven_Report.dbo.vehicle v on substring(jsondatastring,charindex('vehicleID', jsondatastring) + 12, 6) = cast(v.vehicleID as varchar) 
	--LEFT JOIN  Windhaven_Report.dbo.policy p on p.policyID = v.policyID
	LEFT JOIN Windhaven_Report.dbo.policy p on p.policyID = c.policyID
	WHERE 1 = 1
	AND right(clutchURL, 8) = '/endorse'
	AND LEFT(substring(clutchURL, charindex('SILVERVINE/', clutchURL) + len('SILVERVINE/'), charindex('/', clutchURL, charindex('SILVERVINE/', clutchURL) + len('SILVERVINE/')) - charindex('SILVERVINE/', clutchURL) - len('SILVERVINE/')), 4) in ('APEX', 'EDGE', 'PLUS')
	AND c.addDate >= @startDate
	AND c.addDate <= @endDate


BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF OBJECT_ID('Periscope_Data.dbo.Temp_ClutchRateRequest_EQ', 'U') IS NOT NULL
		DROP TABLE Periscope_Data.dbo.Temp_ClutchRateRequest_EQ;
	

	SELECT						c.addDate,
								LEFT(substring(clutchURL, charindex('SILVERVINE/', clutchURL) + len('SILVERVINE/'), charindex('/', clutchURL, charindex('SILVERVINE/', clutchURL) + len('SILVERVINE/')) - charindex('SILVERVINE/', clutchURL) - len('SILVERVINE/')), 4) as product,
								c.policyNum,
								c.errormessage,
								case when errormessage is null then substring(quoteResponse, charindex('\"term\":\"', quoteresponse) + len('\"term\":\"'), 1) else null end as term,
								case when errormessage is null then case when substring(quoteResponse, charindex('\"algorithm\":\"', quoteResponse)+len('\"algorithm\":\"'), 4) = 'PLUS' and substring(quoteResponse, charindex('\"pifpolicy\":',quoteResponse)+len('\"pifpolicy\":'),4) = 'true'
									then 'Y' 
									else case when substring(quoteResponse, charindex('\"eftPolicy\":',quoteResponse)+len('\"eftPolicy\":'),4) = 'true'
									then 'Y'
									else 'N' end end else null end as eftPolicy,
								case when errormessage is null then case when quoteResponse like '%transferDiscount%'
									then substring(quoteResponse, charindex('\"transferDiscount\":\"',quoteResponse)+len('\"transferDiscount\":\"'),charindex('\"', quoteResponse, charindex('\"transferDiscount\":\"', quoteResponse)+len('\"transferDiscount\":\"'))-(charindex('\"transferDiscount\":\"', quoteResponse)+len('\"transferDiscount\":\"')))
									else '0' end else null end as transfer,
								case when errormessage is null then substring(quoteResponse, charindex('\"selectedProgramName\":\"', quoteResponse)+len('\"selectedProgramName\":\"'), 3) else null end as program,
								case when errormessage is null then substring(quoteResponse, charindex('\"renewal\":\"',quoteResponse)+len('\"renewal\":\"'),charindex('\",', quoteResponse, charindex('\"renewal\":\"', quoteResponse)+len('\"renewal\":\"'))-(charindex('\"renewal\":\"', quoteResponse)+len('\"renewal\":\"'))) else null end as renewal,
								case when errormessage is null then case when substring(quoteResponse, charindex('\"electronicDelivery\":',quoteResponse)+len('\"electronicDelivery\":'),4) = 'true'
									then 'Y'
									else 'N' end else null end as electronicDelivery,
								case when errormessage is null then case when substring(quoteResponse, charindex('\"pifpolicy\":',quoteResponse)+len('\"pifpolicy\":'),4) = 'true'
									then 'Y'
									else 'N' end else null end as pifpolicy,
								case when errormessage is null then case when substring(quoteResponse, charindex('\"fullDisclosurediscount\":',quoteResponse)+len('\"fullDisclosurediscount\":'),4) = 'true'
									then 'Y'
									else 'N' end else null end as fullDisclosure,
								case when errormessage is null then concat(substring(quoteResponse, 1+charindex('/',quoteResponse, charindex('\"bilimit\":\"', quoteResponse)),charindex('\"', quoteResponse, charindex('\"bilimit\":\"', quoteResponse)+len('\"bilimit\":\"'))-(charindex('/',quoteResponse, charindex('\"bilimit\":\"', quoteResponse))+1)),'000') else null end as bilimit,
								case when errormessage is null then substring(quoteResponse, charindex('\"pdlimit\":\"',quoteResponse)+len('\"pdlimit\":\"'),charindex('\"', quoteResponse, charindex('\"pdlimit\":\"', quoteResponse)+len('\"pdlimit\":\"'))-(charindex('\"pdlimit\":\"', quoteResponse)+len('\"pdlimit\":\"'))) else null end as pdlimit,
								case when errormessage is null then substring(quoteResponse, charindex('\"medlimit\":\"',quoteResponse)+len('\"medlimit\":\"'),charindex('\"', quoteResponse, charindex('\"medlimit\":\"', quoteResponse)+len('\"medlimit\":\"'))-(charindex('\"medlimit\":\"', quoteResponse)+len('\"medlimit\":\"'))) else null end as medlimit,
								case when errormessage is null then substring(quoteResponse, charindex('\"piplimit\":\"',quoteResponse)+len('\"piplimit\":\"'),charindex('\"', quoteResponse, charindex('\"piplimit\":\"', quoteResponse)+len('\"piplimit\":\"'))-(charindex('\"piplimit\":\"', quoteResponse)+len('\"piplimit\":\"'))) else null end as piplimit,
								case when errormessage is null then substring(quoteResponse, charindex('\"umpdlimit\":\"',quoteResponse)+len('\"umpdlimit\":\"'),charindex('\"', quoteResponse, charindex('\"umpdlimit\":\"', quoteResponse)+len('\"umpdlimit\":\"'))-(charindex('\"umpdlimit\":\"', quoteResponse)+len('\"umpdlimit\":\"'))) else null end as umpdlimit,
								case when errormessage is null then concat(substring(quoteResponse, 1+charindex('/',quoteResponse, charindex('\"umbilimit\":\"', quoteResponse)),charindex('\"', quoteResponse, charindex('\"umbilimit\":\"', quoteResponse)+len('\"umbilimit\":\"'))-(charindex('/',quoteResponse, charindex('\"umbilimit\":\"', quoteResponse))+1)),'000') else null end as umbilimit,
								case when errormessage is null then case when substring(quoteResponse, charindex('\"homeownerdiscount\":', quoteResponse)+len('\"homeownerdiscount\":'), 4) = 'TRUE' then 'Y' else 'N' end else null end as homeowner,
								case when errormessage is null then case when substring(quoteResponse, charindex('\"inagencydiscount\":', quoteResponse)+len('\"inagencydiscount\":'), 4) = 'TRUE' OR substring(quoteResponse, charindex('\"algorithm\":\"', quoteResponse)+len('\"algorithm\":\"'),4) = 'APEX'
																		then substring(quoteResponse, charindex('\"priorInsuredMonths\":\"',quoteResponse)+len('\"priorInsuredMonths\":\"'),charindex('\"', quoteResponse, charindex('\"priorInsuredMonths\":\"', quoteResponse)+len('\"priorInsuredMonths\":\"'))-(charindex('\"priorInsuredMonths\":\"', quoteResponse)+len('\"priorInsuredMonths\":\"'))) 
																		else substring(quoteResponse, charindex('\"priorInsuranceDiscount\":\"',quoteResponse)+len('\"priorInsuranceDiscount\":\"'),charindex('\"', quoteResponse, charindex('\"priorInsuranceDiscount\":\"', quoteResponse)+len('\"priorInsuranceDiscount\":\"'))-(charindex('\"priorInsuranceDiscount\":\"', quoteResponse)+len('\"priorInsuranceDiscount\":\"'))) 
																		end else null end as prior,
								case when errormessage is null then case when substring(quoteResponse, charindex('\"inagencydiscount\":', quoteResponse)+len('\"inagencydiscount\":'), 4) = 'TRUE' then 'Y' else 'N' end else null end as inAgency,
								case when errormessage is null then case when substring(quoteResponse, charindex('\"advancedQuoteDiscount\":', quoteResponse)+len('\"advancedQuoteDiscount\":'), 4) = 'TRUE' then 'Y' else 'N' end else null end as advancedQuote,
								case when errormessage is null then substring(quoteResponse, charindex('\"creditscore\":\"',quoteResponse)+len('\"creditscore\":\"'),charindex('\"', quoteResponse, charindex('\"creditscore\":\"', quoteResponse)+len('\"creditscore\":\"'))-(charindex('\"creditscore\":\"', quoteResponse)+len('\"creditscore\":\"'))) else null end as credit,
														  
								case when errormessage is null then 1 else null end as vehicleNum1,
								case when errormessage is null then substring(quoteResponse, charindex('\"modelyear\":\"', quoteResponse)+len('\"modelyear\":\"'), 4) else null end as modelYear1,
								case when errormessage is null then substring(quoteResponse, charindex('\"garagingCounty\":\"',quoteResponse)+len('\"garagingCounty\":\"'),charindex('\"', quoteResponse, charindex('\"garagingCounty\":\"', quoteResponse)+len('\"garagingCounty\":\"'))-(charindex('\"garagingCounty\":\"', quoteResponse)+len('\"garagingCounty\":\"'))) else null end as garagingCounty1,
								case when errormessage is null then substring(quoteResponse, charindex('\"garagingZip\":\"', quoteResponse)+len('\"garagingZip\":\"'), 5) else null end as garagingZip1,
								case when errormessage is null then 'N' else null end as altGaragingZip,
								case when errormessage is null then case when substring(quoteResponse, charindex('\"otcDeductible\":\"',quoteResponse)+len('\"otcDeductible\":\"'),charindex('\"', quoteResponse, charindex('\"otcDeductible\":\"', quoteResponse)+len('\"otcDeductible\":\"'))-(charindex('\"otcDeductible\":\"', quoteResponse)+len('\"otcDeductible\":\"'))) = 'NOCOV'
									then '0'
									else substring(quoteResponse, charindex('\"otcDeductible\":\"',quoteResponse)+len('\"otcDeductible\":\"'),charindex('\"', quoteResponse, charindex('\"otcDeductible\":\"', quoteResponse)+len('\"otcDeductible\":\"'))-(charindex('\"otcDeductible\":\"', quoteResponse)+len('\"otcDeductible\":\"')))
									end else null end as otcDeductible1,
								case when errormessage is null then case when substring(quoteResponse, charindex('\"collDeductible\":\"',quoteResponse)+len('\"collDeductible\":\"'),charindex('\"', quoteResponse, charindex('\"collDeductible\":\"', quoteResponse)+len('\"collDeductible\":\"'))-(charindex('\"collDeductible\":\"', quoteResponse)+len('\"collDeductible\":\"'))) = 'NOCOV'
									then '0'
									else substring(quoteResponse, charindex('\"collDeductible\":\"',quoteResponse)+len('\"collDeductible\":\"'),charindex('\"', quoteResponse, charindex('\"collDeductible\":\"', quoteResponse)+len('\"collDeductible\":\"'))-(charindex('\"collDeductible\":\"', quoteResponse)+len('\"collDeductible\":\"')))
									end else null end as collDeductible1,
								case when errormessage is null then case when substring(quoteResponse, charindex('\"rrlimit\":\"',quoteResponse)+len('\"rrlimit\":\"'),charindex('\"', quoteResponse, charindex('\"rrlimit\":\"', quoteResponse)+len('\"rrlimit\":\"'))-(charindex('\"rrlimit\":\"', quoteResponse)+len('\"rrlimit\":\"'))) = 'NOCOV'
									then '0' else substring(quoteResponse, 1 + charindex('/', quoteResponse, charindex('\"rrlimit\":\"', quoteResponse)),charindex('\"', quoteResponse, charindex('\"rrlimit\":\"', quoteResponse)+len('\"rrlimit\":\"'))-(charindex('/', quoteResponse, charindex('\"rrlimit\":\"', quoteResponse))+1)) end
									else null end as rrlimit1,
								case when errormessage is null then substring(quoteResponse, charindex('\"towlimit\":\"',quoteResponse)+len('\"towlimit\":\"'),charindex('\"', quoteResponse, charindex('\"towlimit\":\"', quoteResponse)+len('\"towlimit\":\"'))-(charindex('\"towlimit\":\"', quoteResponse)+len('\"towlimit\":\"'))) else null end as towlimit1,
								case when errormessage is null then case when substring(quoteResponse, charindex('\"mileageSurcharge\":',quoteResponse)+len('\"mileageSurcharge\":'),4) = 'true'
									then 'Y'
									else 'N' end else null end as mileageSurcharge1,
								case when errormessage is null then case when substring(quoteResponse, charindex('\"vehicleInspection\":',quoteResponse)+len('\"vehicleInspection\":'),4) = 'true'
									then 'Y'
									else 'N' end else null end as vehicleInspection1,
								case when errormessage is null then substring(quoteResponse, charindex('\"otcsymbol\":\"',quoteResponse)+len('\"otcsymbol\":\"'),charindex('\"', quoteResponse, charindex('\"otcsymbol\":\"', quoteResponse)+len('\"otcsymbol\":\"'))-(charindex('\"otcsymbol\":\"', quoteResponse)+len('\"otcsymbol\":\"'))) else null end as otcSymbol1,
								case when errormessage is null then substring(quoteResponse, charindex('\"collsymbol\":\"',quoteResponse)+len('\"collsymbol\":\"'),charindex('\"', quoteResponse, charindex('\"collsymbol\":\"', quoteResponse)+len('\"collsymbol\":\"'))-(charindex('\"collsymbol\":\"', quoteResponse)+len('\"collsymbol\":\"'))) else null end  as colSymbol1,
								case when errormessage is null then substring(quoteResponse, charindex('\"bisymbol\":\"',quoteResponse)+len('\"bisymbol\":\"'),charindex('\"', quoteResponse, charindex('\"bisymbol\":\"', quoteResponse)+len('\"bisymbol\":\"'))-(charindex('\"bisymbol\":\"', quoteResponse)+len('\"bisymbol\":\"'))) else null end  as bisymbol1,
								case when errormessage is null then substring(quoteResponse, charindex('\"pdsymbol\":\"',quoteResponse)+len('\"pdsymbol\":\"'),charindex('\"', quoteResponse, charindex('\"pdsymbol\":\"', quoteResponse)+len('\"pdsymbol\":\"'))-(charindex('\"pdsymbol\":\"', quoteResponse)+len('\"pdsymbol\":\"')))  else null end as pdsymbol1,
								case when errormessage is null then substring(quoteResponse, charindex('\"medSymbol\":\"',quoteResponse)+len('\"medSymbol\":\"'),charindex('\"', quoteResponse, charindex('\"medSymbol\":\"', quoteResponse)+len('\"medSymbol\":\"'))-(charindex('\"medSymbol\":\"', quoteResponse)+len('\"medSymbol\":\"'))) else null end  as medSymbol1,
								case when errormessage is null then substring(quoteResponse, charindex('\"pipsymbol\":\"',quoteResponse)+len('\"pipsymbol\":\"'),charindex('\"', quoteResponse, charindex('\"pipsymbol\":\"', quoteResponse)+len('\"pipsymbol\":\"'))-(charindex('\"pipsymbol\":\"', quoteResponse)+len('\"pipsymbol\":\"')))  else null end as pipsymbol1,
								case when errormessage is null then substring(quoteResponse, charindex('\"umbisymbol\":\"',quoteResponse)+len('\"umbisymbol\":\"'),charindex('\"', quoteResponse, charindex('\"umbisymbol\":\"', quoteResponse)+len('\"umbisymbol\":\"'))-(charindex('\"umbisymbol\":\"', quoteResponse)+len('\"umbisymbol\":\"')))  else null end as umbisymbol1,
								case when errormessage is null then substring(quoteResponse, charindex('\"umpdsymbol\":\"',quoteResponse)+len('\"umpdsymbol\":\"'),charindex('\"', quoteResponse, charindex('\"umpdsymbol\":\"', quoteResponse)+len('\"umpdsymbol\":\"'))-(charindex('\"umpdsymbol\":\"', quoteResponse)+len('\"umpdsymbol\":\"')))  else null end as umpdsymbol1,
								case when errormessage is null then substring(quoteResponse, charindex('\"equipAmount\":\"',quoteResponse)+len('\"equipAmount\":\"'),charindex('\"', quoteResponse, charindex('\"equipAmount\":\"', quoteResponse)+len('\"equipAmount\":\"'))-(charindex('\"equipAmount\":\"', quoteResponse)+len('\"equipAmount\":\"')))  else null end as se1,
								case when errormessage is null then case when veh2.pos > 0 then 2 else NULL end  else null end as vehicleNum2,
								case when errormessage is null then case when veh2.pos > 0 
									then substring(quoteResponse, charindex('\"modelyear\":\"', quoteResponse, veh2.pos)+len('\"modelyear\":\"'), 4)
									else NULL end  else null end as modelyear2,
								case when errormessage is null then case when veh2.pos > 0
									then substring(quoteResponse, charindex('\"garagingCounty\":\"',quoteResponse, veh2.pos)+len('\"garagingCounty\":\"'),charindex('\"', quoteResponse, charindex('\"garagingCounty\":\"', quoteResponse, veh2.pos)+len('\"garagingCounty\":\"'))-(charindex('\"garagingCounty\":\"', quoteResponse, veh2.pos)+len('\"garagingCounty\":\"'))) 
									else NULL end else null end as garagingCounty2,
								case when errormessage is null then case when veh2.pos > 0
									then substring(quoteResponse, charindex('\"garagingZip\":\"', quoteResponse, veh2.pos)+len('\"garagingZip\":\"'), 5)
									else NULL end else null end as garagingZip2,
								case when errormessage is null then case when veh2.pos > 0 then 'N' else NULL end else null end as altGaragingZip2,
								case when errormessage is null then case when veh2.pos > 0
									then
										case when substring(quoteResponse, charindex('\"otcDeductible\":\"',quoteResponse, veh2.pos)+len('\"otcDeductible\":\"'),charindex('\"', quoteResponse, charindex('\"otcDeductible\":\"', quoteResponse, veh2.pos)+len('\"otcDeductible\":\"'))-(charindex('\"otcDeductible\":\"', quoteResponse, veh2.pos)+len('\"otcDeductible\":\"'))) = 'NOCOV'
											 then '0'
											 else substring(quoteResponse, charindex('\"otcDeductible\":\"',quoteResponse, veh2.pos)+len('\"otcDeductible\":\"'),charindex('\"', quoteResponse, charindex('\"otcDeductible\":\"', quoteResponse, veh2.pos)+len('\"otcDeductible\":\"'))-(charindex('\"otcDeductible\":\"', quoteResponse, veh2.pos)+len('\"otcDeductible\":\"'))) end
									else NULL end else null end as otcDeductible2,
								case when errormessage is null then case when veh2.pos > 0
									then
										case when substring(quoteResponse, charindex('\"collDeductible\":\"',quoteResponse, veh2.pos)+len('\"collDeductible\":\"'),charindex('\"', quoteResponse, charindex('\"collDeductible\":\"', quoteResponse, veh2.pos)+len('\"collDeductible\":\"'))-(charindex('\"collDeductible\":\"', quoteResponse, veh2.pos)+len('\"collDeductible\":\"'))) = 'NOCOV'
											 then '0'
											 else substring(quoteResponse, charindex('\"collDeductible\":\"',quoteResponse, veh2.pos)+len('\"collDeductible\":\"'),charindex('\"', quoteResponse, charindex('\"collDeductible\":\"', quoteResponse, veh2.pos)+len('\"collDeductible\":\"'))-(charindex('\"collDeductible\":\"', quoteResponse, veh2.pos)+len('\"collDeductible\":\"'))) end
									else NULL end else null end as collDeductible2,
								case when errormessage is null then case when veh2.pos > 0
									then substring(quoteResponse, 1 + charindex('/',quoteResponse, charindex('\"rrlimit\":\"',quoteResponse, veh2.pos)),charindex('\"', quoteResponse, charindex('\"rrlimit\":\"', quoteResponse, veh2.pos)+len('\"rrlimit\":\"'))-charindex('/',quoteResponse, charindex('\"rrlimit\":\"',quoteResponse, veh2.pos))-1) end 
									else NULL end as rrlimit2,
								case when errormessage is null then case when veh2.pos > 0
									then substring(quoteResponse, charindex('\"towlimit\":\"',quoteResponse, veh2.pos)+len('\"towlimit\":\"'),charindex('\"', quoteResponse, charindex('\"towlimit\":\"', quoteResponse, veh2.pos)+len('\"towlimit\":\"'))-(charindex('\"towlimit\":\"', quoteResponse, veh2.pos)+len('\"towlimit\":\"'))) 
									else NULL end else null end as towlimit2,
								case when errormessage is null then case when veh2.pos > 0
									then case when substring(quoteResponse, charindex('\"mileageSurcharge\":',quoteResponse, veh2.pos)+len('\"mileageSurcharge\":'),4) = 'true'
											  then 'Y'
											  else 'N' end
								    else NULL end else null end as mileageSurcharge2,
								case when errormessage is null then case when veh2.pos > 0
									then case when substring(quoteResponse, charindex('\"vehicleInspection\":',quoteResponse, veh2.pos)+len('\"vehicleInspection\":'),4) = 'true'
											  then 'Y'
											  else 'N' end 
								    else NULL end else null end as vehicleInspection2,
								case when errormessage is null then case when veh2.pos > 0
									then substring(quoteResponse, charindex('\"otcsymbol\":\"',quoteResponse, veh2.pos)+len('\"otcsymbol\":\"'),charindex('\"', quoteResponse, charindex('\"otcsymbol\":\"', quoteResponse, veh2.pos)+len('\"otcsymbol\":\"'))-(charindex('\"otcsymbol\":\"', quoteResponse, veh2.pos)+len('\"otcsymbol\":\"'))) 
									else NULL end else null end as otcSymbol2,
								case when errormessage is null then case when veh2.pos > 0
									then substring(quoteResponse, charindex('\"collsymbol\":\"',quoteResponse, veh2.pos)+len('\"collsymbol\":\"'),charindex('\"', quoteResponse, charindex('\"collsymbol\":\"', quoteResponse, veh2.pos)+len('\"collsymbol\":\"'))-(charindex('\"collsymbol\":\"', quoteResponse, veh2.pos)+len('\"collsymbol\":\"'))) 
									else NULL end else null end as colSymbol2,
								case when errormessage is null then case when veh2.pos > 0
									then substring(quoteResponse, charindex('\"bisymbol\":\"',quoteResponse, veh2.pos)+len('\"bisymbol\":\"'),charindex('\"', quoteResponse, charindex('\"bisymbol\":\"', quoteResponse, veh2.pos)+len('\"bisymbol\":\"'))-(charindex('\"bisymbol\":\"', quoteResponse, veh2.pos)+len('\"bisymbol\":\"'))) 
									else NULL end else null end as bisymbol2,
								case when errormessage is null then case when veh2.pos > 0
									then substring(quoteResponse, charindex('\"pdsymbol\":\"',quoteResponse, veh2.pos)+len('\"pdsymbol\":\"'),charindex('\"', quoteResponse, charindex('\"pdsymbol\":\"', quoteResponse, veh2.pos)+len('\"pdsymbol\":\"'))-(charindex('\"pdsymbol\":\"', quoteResponse, veh2.pos)+len('\"pdsymbol\":\"')))
									else NULL end else null end as pdsymbol2,
								case when errormessage is null then case when veh2.pos > 0
									then substring(quoteResponse, charindex('\"medSymbol\":\"',quoteResponse, veh2.pos)+len('\"medSymbol\":\"'),charindex('\"', quoteResponse, charindex('\"medSymbol\":\"', quoteResponse, veh2.pos)+len('\"medSymbol\":\"'))-(charindex('\"medSymbol\":\"', quoteResponse, veh2.pos)+len('\"medSymbol\":\"'))) 
									else NULL end else null end as medSymbol2,
								case when errormessage is null then case when veh2.pos > 0
									then substring(quoteResponse, charindex('\"pipsymbol\":\"',quoteResponse, veh2.pos)+len('\"pipsymbol\":\"'),charindex('\"', quoteResponse, charindex('\"pipsymbol\":\"', quoteResponse, veh2.pos)+len('\"pipsymbol\":\"'))-(charindex('\"pipsymbol\":\"', quoteResponse, veh2.pos)+len('\"pipsymbol\":\"')))
									else NULL end else null end as pipsymbol2,
								case when errormessage is null then case when veh2.pos > 0
									then substring(quoteResponse, charindex('\"umbisymbol\":\"',quoteResponse, veh2.pos)+len('\"umbisymbol\":\"'),charindex('\"', quoteResponse, charindex('\"umbisymbol\":\"', quoteResponse, veh2.pos)+len('\"umbisymbol\":\"'))-(charindex('\"umbisymbol\":\"', quoteResponse, veh2.pos)+len('\"umbisymbol\":\"')))
									else NULL end else null end as umbisymbol2,
								case when errormessage is null then case when veh2.pos > 0
									then substring(quoteResponse, charindex('\"umpdsymbol\":\"',quoteResponse, veh2.pos)+len('\"umpdsymbol\":\"'),charindex('\"', quoteResponse, charindex('\"umpdsymbol\":\"', quoteResponse, veh2.pos)+len('\"umpdsymbol\":\"'))-(charindex('\"umpdsymbol\":\"', quoteResponse, veh2.pos)+len('\"umpdsymbol\":\"'))) 
									else NULL end else null end as umpdsymbol2,
								case when errormessage is null then case when veh2.pos > 0
									then substring(quoteResponse, charindex('\"equipAmount\":\"',quoteResponse, veh2.pos)+len('\"equipAmount\":\"'),charindex('\"', quoteResponse, charindex('\"equipAmount\":\"', quoteResponse, veh2.pos)+len('\"equipAmount\":\"'))-(charindex('\"equipAmount\":\"', quoteResponse, veh2.pos)+len('\"equipAmount\":\"')))
									else NULL end else null end as se2,
																case when errormessage is null then case when veh3.pos > 0 then 3 else NULL end  else null end as vehicleNum3,
								case when errormessage is null then case when veh3.pos > 0 
									then substring(quoteResponse, charindex('\"modelyear\":\"', quoteResponse, veh3.pos)+len('\"modelyear\":\"'), 4)
									else NULL end  else null end as modelyear3,
								case when errormessage is null then case when veh3.pos > 0
									then substring(quoteResponse, charindex('\"garagingCounty\":\"',quoteResponse, veh3.pos)+len('\"garagingCounty\":\"'),charindex('\"', quoteResponse, charindex('\"garagingCounty\":\"', quoteResponse, veh3.pos)+len('\"garagingCounty\":\"'))-(charindex('\"garagingCounty\":\"', quoteResponse, veh3.pos)+len('\"garagingCounty\":\"'))) 
									else NULL end else null end as garagingCounty3,
								case when errormessage is null then case when veh3.pos > 0
									then substring(quoteResponse, charindex('\"garagingZip\":\"', quoteResponse, veh3.pos)+len('\"garagingZip\":\"'), 5)
									else NULL end else null end as garagingZip3,
								case when errormessage is null then case when veh3.pos > 0 then 'N' else NULL end else null end as altGaragingZip3,
								case when errormessage is null then case when veh3.pos > 0
									then
										case when substring(quoteResponse, charindex('\"otcDeductible\":\"',quoteResponse, veh3.pos)+len('\"otcDeductible\":\"'),charindex('\"', quoteResponse, charindex('\"otcDeductible\":\"', quoteResponse, veh3.pos)+len('\"otcDeductible\":\"'))-(charindex('\"otcDeductible\":\"', quoteResponse, veh3.pos)+len('\"otcDeductible\":\"'))) = 'NOCOV'
											 then '0'
											 else substring(quoteResponse, charindex('\"otcDeductible\":\"',quoteResponse, veh3.pos)+len('\"otcDeductible\":\"'),charindex('\"', quoteResponse, charindex('\"otcDeductible\":\"', quoteResponse, veh3.pos)+len('\"otcDeductible\":\"'))-(charindex('\"otcDeductible\":\"', quoteResponse, veh3.pos)+len('\"otcDeductible\":\"'))) end
									else NULL end else null end as otcDeductible3,
								case when errormessage is null then case when veh3.pos > 0
									then
										case when substring(quoteResponse, charindex('\"collDeductible\":\"',quoteResponse, veh3.pos)+len('\"collDeductible\":\"'),charindex('\"', quoteResponse, charindex('\"collDeductible\":\"', quoteResponse, veh3.pos)+len('\"collDeductible\":\"'))-(charindex('\"collDeductible\":\"', quoteResponse, veh3.pos)+len('\"collDeductible\":\"'))) = 'NOCOV'
											 then '0'
											 else substring(quoteResponse, charindex('\"collDeductible\":\"',quoteResponse, veh3.pos)+len('\"collDeductible\":\"'),charindex('\"', quoteResponse, charindex('\"collDeductible\":\"', quoteResponse, veh3.pos)+len('\"collDeductible\":\"'))-(charindex('\"collDeductible\":\"', quoteResponse, veh3.pos)+len('\"collDeductible\":\"'))) end
									else NULL end else null end as collDeductible3,
								case when errormessage is null then case when veh3.pos > 0
									then
										case when substring(quoteResponse, charindex('\"rrlimit\":\"',quoteResponse, veh3.pos)+len('\"rrlimit\":\"'),charindex('\"', quoteResponse, charindex('\"rrlimit\":\"', quoteResponse, veh3.pos)+len('\"rrlimit\":\"'))-(charindex('\"rrlimit\":\"', quoteResponse, veh3.pos)+len('\"rrlimit\":\"'))) = 'NOCOV'
										then '0'
										else substring(quoteResponse, 1 + charindex('/',quoteResponse, charindex('\"rrlimit\":\"',quoteResponse, veh3.pos)),charindex('\"', quoteResponse, charindex('\"rrlimit\":\"', quoteResponse, veh3.pos)+len('\"rrlimit\":\"'))-charindex('/',quoteResponse, charindex('\"rrlimit\":\"',quoteResponse, veh3.pos))-1) end 
									else NULL end else null end as rrlimit3,
								case when errormessage is null then case when veh3.pos > 0
									then substring(quoteResponse, charindex('\"towlimit\":\"',quoteResponse, veh3.pos)+len('\"towlimit\":\"'),charindex('\"', quoteResponse, charindex('\"towlimit\":\"', quoteResponse, veh3.pos)+len('\"towlimit\":\"'))-(charindex('\"towlimit\":\"', quoteResponse, veh3.pos)+len('\"towlimit\":\"'))) 
									else NULL end else null end as towlimit3,
								case when errormessage is null then case when veh3.pos > 0
									then case when substring(quoteResponse, charindex('\"mileageSurcharge\":',quoteResponse, veh3.pos)+len('\"mileageSurcharge\":'),4) = 'true'
											  then 'Y'
											  else 'N' end
								    else NULL end else null end as mileageSurcharge3,
								case when errormessage is null then case when veh3.pos > 0
									then case when substring(quoteResponse, charindex('\"vehicleInspection\":',quoteResponse, veh3.pos)+len('\"vehicleInspection\":'),4) = 'true'
											  then 'Y'
											  else 'N' end 
								    else NULL end else null end as vehicleInspection3,
								case when errormessage is null then case when veh3.pos > 0
									then substring(quoteResponse, charindex('\"otcsymbol\":\"',quoteResponse, veh3.pos)+len('\"otcsymbol\":\"'),charindex('\"', quoteResponse, charindex('\"otcsymbol\":\"', quoteResponse, veh3.pos)+len('\"otcsymbol\":\"'))-(charindex('\"otcsymbol\":\"', quoteResponse, veh3.pos)+len('\"otcsymbol\":\"'))) 
									else NULL end else null end as otcSymbol3,
								case when errormessage is null then case when veh3.pos > 0
									then substring(quoteResponse, charindex('\"collsymbol\":\"',quoteResponse, veh3.pos)+len('\"collsymbol\":\"'),charindex('\"', quoteResponse, charindex('\"collsymbol\":\"', quoteResponse, veh3.pos)+len('\"collsymbol\":\"'))-(charindex('\"collsymbol\":\"', quoteResponse, veh3.pos)+len('\"collsymbol\":\"'))) 
									else NULL end else null end as colSymbol3,
								case when errormessage is null then case when veh3.pos > 0
									then substring(quoteResponse, charindex('\"bisymbol\":\"',quoteResponse, veh3.pos)+len('\"bisymbol\":\"'),charindex('\"', quoteResponse, charindex('\"bisymbol\":\"', quoteResponse, veh3.pos)+len('\"bisymbol\":\"'))-(charindex('\"bisymbol\":\"', quoteResponse, veh3.pos)+len('\"bisymbol\":\"'))) 
									else NULL end else null end as bisymbol3,
								case when errormessage is null then case when veh3.pos > 0
									then substring(quoteResponse, charindex('\"pdsymbol\":\"',quoteResponse, veh3.pos)+len('\"pdsymbol\":\"'),charindex('\"', quoteResponse, charindex('\"pdsymbol\":\"', quoteResponse, veh3.pos)+len('\"pdsymbol\":\"'))-(charindex('\"pdsymbol\":\"', quoteResponse, veh3.pos)+len('\"pdsymbol\":\"')))
									else NULL end else null end as pdsymbol3,
								case when errormessage is null then case when veh3.pos > 0
									then substring(quoteResponse, charindex('\"medSymbol\":\"',quoteResponse, veh3.pos)+len('\"medSymbol\":\"'),charindex('\"', quoteResponse, charindex('\"medSymbol\":\"', quoteResponse, veh3.pos)+len('\"medSymbol\":\"'))-(charindex('\"medSymbol\":\"', quoteResponse, veh3.pos)+len('\"medSymbol\":\"'))) 
									else NULL end else null end as medSymbol3,
								case when errormessage is null then case when veh3.pos > 0
									then substring(quoteResponse, charindex('\"pipsymbol\":\"',quoteResponse, veh3.pos)+len('\"pipsymbol\":\"'),charindex('\"', quoteResponse, charindex('\"pipsymbol\":\"', quoteResponse, veh3.pos)+len('\"pipsymbol\":\"'))-(charindex('\"pipsymbol\":\"', quoteResponse, veh3.pos)+len('\"pipsymbol\":\"')))
									else NULL end else null end as pipsymbol3,
								case when errormessage is null then case when veh3.pos > 0
									then substring(quoteResponse, charindex('\"umbisymbol\":\"',quoteResponse, veh3.pos)+len('\"umbisymbol\":\"'),charindex('\"', quoteResponse, charindex('\"umbisymbol\":\"', quoteResponse, veh3.pos)+len('\"umbisymbol\":\"'))-(charindex('\"umbisymbol\":\"', quoteResponse, veh3.pos)+len('\"umbisymbol\":\"')))
									else NULL end else null end as umbisymbol3,
								case when errormessage is null then case when veh3.pos > 0
									then substring(quoteResponse, charindex('\"umpdsymbol\":\"',quoteResponse, veh3.pos)+len('\"umpdsymbol\":\"'),charindex('\"', quoteResponse, charindex('\"umpdsymbol\":\"', quoteResponse, veh3.pos)+len('\"umpdsymbol\":\"'))-(charindex('\"umpdsymbol\":\"', quoteResponse, veh3.pos)+len('\"umpdsymbol\":\"'))) 
									else NULL end else null end as umpdsymbol3,
								case when errormessage is null then case when veh3.pos > 0
									then substring(quoteResponse, charindex('\"equipAmount\":\"',quoteResponse, veh3.pos)+len('\"equipAmount\":\"'),charindex('\"', quoteResponse, charindex('\"equipAmount\":\"', quoteResponse, veh3.pos)+len('\"equipAmount\":\"'))-(charindex('\"equipAmount\":\"', quoteResponse, veh3.pos)+len('\"equipAmount\":\"')))
									else NULL end else null end as se3,
																case when errormessage is null then case when veh4.pos > 0 then 4 else NULL end  else null end as vehicleNum4,
								case when errormessage is null then case when veh4.pos > 0 
									then substring(quoteResponse, charindex('\"modelyear\":\"', quoteResponse, veh4.pos)+len('\"modelyear\":\"'), 4)
									else NULL end  else null end as modelyear4,
								case when errormessage is null then case when veh4.pos > 0
									then substring(quoteResponse, charindex('\"garagingCounty\":\"',quoteResponse, veh4.pos)+len('\"garagingCounty\":\"'),charindex('\"', quoteResponse, charindex('\"garagingCounty\":\"', quoteResponse, veh4.pos)+len('\"garagingCounty\":\"'))-(charindex('\"garagingCounty\":\"', quoteResponse, veh4.pos)+len('\"garagingCounty\":\"'))) 
									else NULL end else null end as garagingCounty4,
								case when errormessage is null then case when veh4.pos > 0
									then substring(quoteResponse, charindex('\"garagingZip\":\"', quoteResponse, veh4.pos)+len('\"garagingZip\":\"'), 5)
									else NULL end else null end as garagingZip4,
								case when errormessage is null then case when veh4.pos > 0 then 'N' else NULL end else null end as altGaragingZip4,
								case when errormessage is null then case when veh4.pos > 0
									then
										case when substring(quoteResponse, charindex('\"otcDeductible\":\"',quoteResponse, veh4.pos)+len('\"otcDeductible\":\"'),charindex('\"', quoteResponse, charindex('\"otcDeductible\":\"', quoteResponse, veh4.pos)+len('\"otcDeductible\":\"'))-(charindex('\"otcDeductible\":\"', quoteResponse, veh4.pos)+len('\"otcDeductible\":\"'))) = 'NOCOV'
											 then '0'
											 else substring(quoteResponse, charindex('\"otcDeductible\":\"',quoteResponse, veh4.pos)+len('\"otcDeductible\":\"'),charindex('\"', quoteResponse, charindex('\"otcDeductible\":\"', quoteResponse, veh4.pos)+len('\"otcDeductible\":\"'))-(charindex('\"otcDeductible\":\"', quoteResponse, veh4.pos)+len('\"otcDeductible\":\"'))) end
									else NULL end else null end as otcDeductible4,
								case when errormessage is null then case when veh4.pos > 0
									then
										case when substring(quoteResponse, charindex('\"collDeductible\":\"',quoteResponse, veh4.pos)+len('\"collDeductible\":\"'),charindex('\"', quoteResponse, charindex('\"collDeductible\":\"', quoteResponse, veh4.pos)+len('\"collDeductible\":\"'))-(charindex('\"collDeductible\":\"', quoteResponse, veh4.pos)+len('\"collDeductible\":\"'))) = 'NOCOV'
											 then '0'
											 else substring(quoteResponse, charindex('\"collDeductible\":\"',quoteResponse, veh4.pos)+len('\"collDeductible\":\"'),charindex('\"', quoteResponse, charindex('\"collDeductible\":\"', quoteResponse, veh4.pos)+len('\"collDeductible\":\"'))-(charindex('\"collDeductible\":\"', quoteResponse, veh4.pos)+len('\"collDeductible\":\"'))) end
									else NULL end else null end as collDeductible4,
								case when errormessage is null then case when veh4.pos > 0
									then
										case when substring(quoteResponse, charindex('\"rrlimit\":\"',quoteResponse, veh4.pos)+len('\"rrlimit\":\"'),charindex('\"', quoteResponse, charindex('\"rrlimit\":\"', quoteResponse, veh4.pos)+len('\"rrlimit\":\"'))-(charindex('\"rrlimit\":\"', quoteResponse, veh4.pos)+len('\"rrlimit\":\"'))) = 'NOCOV'
										then '0'
										else substring(quoteResponse, 1 + charindex('/',quoteResponse, charindex('\"rrlimit\":\"',quoteResponse, veh4.pos)),charindex('\"', quoteResponse, charindex('\"rrlimit\":\"', quoteResponse, veh4.pos)+len('\"rrlimit\":\"'))-charindex('/',quoteResponse, charindex('\"rrlimit\":\"',quoteResponse, veh4.pos))-1) end 
									else NULL end else null end as rrlimit4,
								case when errormessage is null then case when veh4.pos > 0
									then substring(quoteResponse, charindex('\"towlimit\":\"',quoteResponse, veh4.pos)+len('\"towlimit\":\"'),charindex('\"', quoteResponse, charindex('\"towlimit\":\"', quoteResponse, veh4.pos)+len('\"towlimit\":\"'))-(charindex('\"towlimit\":\"', quoteResponse, veh4.pos)+len('\"towlimit\":\"'))) 
									else NULL end else null end as towlimit4,
								case when errormessage is null then case when veh4.pos > 0
									then case when substring(quoteResponse, charindex('\"mileageSurcharge\":',quoteResponse, veh4.pos)+len('\"mileageSurcharge\":'),4) = 'true'
											  then 'Y'
											  else 'N' end
								    else NULL end else null end as mileageSurcharge4,
								case when errormessage is null then case when veh4.pos > 0
									then case when substring(quoteResponse, charindex('\"vehicleInspection\":',quoteResponse, veh4.pos)+len('\"vehicleInspection\":'),4) = 'true'
											  then 'Y'
											  else 'N' end 
								    else NULL end else null end as vehicleInspection4,
								case when errormessage is null then case when veh4.pos > 0
									then substring(quoteResponse, charindex('\"otcsymbol\":\"',quoteResponse, veh4.pos)+len('\"otcsymbol\":\"'),charindex('\"', quoteResponse, charindex('\"otcsymbol\":\"', quoteResponse, veh4.pos)+len('\"otcsymbol\":\"'))-(charindex('\"otcsymbol\":\"', quoteResponse, veh4.pos)+len('\"otcsymbol\":\"'))) 
									else NULL end else null end as otcSymbol4,
								case when errormessage is null then case when veh4.pos > 0
									then substring(quoteResponse, charindex('\"collsymbol\":\"',quoteResponse, veh4.pos)+len('\"collsymbol\":\"'),charindex('\"', quoteResponse, charindex('\"collsymbol\":\"', quoteResponse, veh4.pos)+len('\"collsymbol\":\"'))-(charindex('\"collsymbol\":\"', quoteResponse, veh4.pos)+len('\"collsymbol\":\"'))) 
									else NULL end else null end as colSymbol4,
								case when errormessage is null then case when veh4.pos > 0
									then substring(quoteResponse, charindex('\"bisymbol\":\"',quoteResponse, veh4.pos)+len('\"bisymbol\":\"'),charindex('\"', quoteResponse, charindex('\"bisymbol\":\"', quoteResponse, veh4.pos)+len('\"bisymbol\":\"'))-(charindex('\"bisymbol\":\"', quoteResponse, veh4.pos)+len('\"bisymbol\":\"'))) 
									else NULL end else null end as bisymbol4,
								case when errormessage is null then case when veh4.pos > 0
									then substring(quoteResponse, charindex('\"pdsymbol\":\"',quoteResponse, veh4.pos)+len('\"pdsymbol\":\"'),charindex('\"', quoteResponse, charindex('\"pdsymbol\":\"', quoteResponse, veh4.pos)+len('\"pdsymbol\":\"'))-(charindex('\"pdsymbol\":\"', quoteResponse, veh4.pos)+len('\"pdsymbol\":\"')))
									else NULL end else null end as pdsymbol4,
								case when errormessage is null then case when veh4.pos > 0
									then substring(quoteResponse, charindex('\"medSymbol\":\"',quoteResponse, veh4.pos)+len('\"medSymbol\":\"'),charindex('\"', quoteResponse, charindex('\"medSymbol\":\"', quoteResponse, veh4.pos)+len('\"medSymbol\":\"'))-(charindex('\"medSymbol\":\"', quoteResponse, veh4.pos)+len('\"medSymbol\":\"'))) 
									else NULL end else null end as medSymbol4,
								case when errormessage is null then case when veh4.pos > 0
									then substring(quoteResponse, charindex('\"pipsymbol\":\"',quoteResponse, veh4.pos)+len('\"pipsymbol\":\"'),charindex('\"', quoteResponse, charindex('\"pipsymbol\":\"', quoteResponse, veh4.pos)+len('\"pipsymbol\":\"'))-(charindex('\"pipsymbol\":\"', quoteResponse, veh4.pos)+len('\"pipsymbol\":\"')))
									else NULL end else null end as pipsymbol4,
								case when errormessage is null then case when veh4.pos > 0
									then substring(quoteResponse, charindex('\"umbisymbol\":\"',quoteResponse, veh4.pos)+len('\"umbisymbol\":\"'),charindex('\"', quoteResponse, charindex('\"umbisymbol\":\"', quoteResponse, veh4.pos)+len('\"umbisymbol\":\"'))-(charindex('\"umbisymbol\":\"', quoteResponse, veh4.pos)+len('\"umbisymbol\":\"')))
									else NULL end else null end as umbisymbol4,
								case when errormessage is null then case when veh4.pos > 0
									then substring(quoteResponse, charindex('\"umpdsymbol\":\"',quoteResponse, veh4.pos)+len('\"umpdsymbol\":\"'),charindex('\"', quoteResponse, charindex('\"umpdsymbol\":\"', quoteResponse, veh4.pos)+len('\"umpdsymbol\":\"'))-(charindex('\"umpdsymbol\":\"', quoteResponse, veh4.pos)+len('\"umpdsymbol\":\"'))) 
									else NULL end else null end as umpdsymbol4,
								case when errormessage is null then case when veh4.pos > 0
									then substring(quoteResponse, charindex('\"equipAmount\":\"',quoteResponse, veh4.pos)+len('\"equipAmount\":\"'),charindex('\"', quoteResponse, charindex('\"equipAmount\":\"', quoteResponse, veh4.pos)+len('\"equipAmount\":\"'))-(charindex('\"equipAmount\":\"', quoteResponse, veh4.pos)+len('\"equipAmount\":\"')))
									else NULL end else null end as se4,
																case when errormessage is null then case when veh5.pos > 0 then 5 else NULL end  else null end as vehicleNum5,
								case when errormessage is null then case when veh5.pos > 0 
									then substring(quoteResponse, charindex('\"modelyear\":\"', quoteResponse, veh5.pos)+len('\"modelyear\":\"'), 4)
									else NULL end  else null end as modelyear5,
								case when errormessage is null then case when veh5.pos > 0
									then substring(quoteResponse, charindex('\"garagingCounty\":\"',quoteResponse, veh5.pos)+len('\"garagingCounty\":\"'),charindex('\"', quoteResponse, charindex('\"garagingCounty\":\"', quoteResponse, veh5.pos)+len('\"garagingCounty\":\"'))-(charindex('\"garagingCounty\":\"', quoteResponse, veh5.pos)+len('\"garagingCounty\":\"'))) 
									else NULL end else null end as garagingCounty5,
								case when errormessage is null then case when veh5.pos > 0
									then substring(quoteResponse, charindex('\"garagingZip\":\"', quoteResponse, veh5.pos)+len('\"garagingZip\":\"'), 5)
									else NULL end else null end as garagingZip5,
								case when errormessage is null then case when veh5.pos > 0 then 'N' else NULL end else null end as altGaragingZip5,
								case when errormessage is null then case when veh5.pos > 0
									then
										case when substring(quoteResponse, charindex('\"otcDeductible\":\"',quoteResponse, veh5.pos)+len('\"otcDeductible\":\"'),charindex('\"', quoteResponse, charindex('\"otcDeductible\":\"', quoteResponse, veh5.pos)+len('\"otcDeductible\":\"'))-(charindex('\"otcDeductible\":\"', quoteResponse, veh5.pos)+len('\"otcDeductible\":\"'))) = 'NOCOV'
											 then '0'
											 else substring(quoteResponse, charindex('\"otcDeductible\":\"',quoteResponse, veh5.pos)+len('\"otcDeductible\":\"'),charindex('\"', quoteResponse, charindex('\"otcDeductible\":\"', quoteResponse, veh5.pos)+len('\"otcDeductible\":\"'))-(charindex('\"otcDeductible\":\"', quoteResponse, veh5.pos)+len('\"otcDeductible\":\"'))) end
									else NULL end else null end as otcDeductible5,
								case when errormessage is null then case when veh5.pos > 0
									then
										case when substring(quoteResponse, charindex('\"collDeductible\":\"',quoteResponse, veh5.pos)+len('\"collDeductible\":\"'),charindex('\"', quoteResponse, charindex('\"collDeductible\":\"', quoteResponse, veh5.pos)+len('\"collDeductible\":\"'))-(charindex('\"collDeductible\":\"', quoteResponse, veh5.pos)+len('\"collDeductible\":\"'))) = 'NOCOV'
											 then '0'
											 else substring(quoteResponse, charindex('\"collDeductible\":\"',quoteResponse, veh5.pos)+len('\"collDeductible\":\"'),charindex('\"', quoteResponse, charindex('\"collDeductible\":\"', quoteResponse, veh5.pos)+len('\"collDeductible\":\"'))-(charindex('\"collDeductible\":\"', quoteResponse, veh5.pos)+len('\"collDeductible\":\"'))) end
									else NULL end else null end as collDeductible5,
								case when errormessage is null then case when veh5.pos > 0
									then
										case when substring(quoteResponse, charindex('\"rrlimit\":\"',quoteResponse, veh5.pos)+len('\"rrlimit\":\"'),charindex('\"', quoteResponse, charindex('\"rrlimit\":\"', quoteResponse, veh5.pos)+len('\"rrlimit\":\"'))-(charindex('\"rrlimit\":\"', quoteResponse, veh5.pos)+len('\"rrlimit\":\"'))) = 'NOCOV'
										then '0'
										else substring(quoteResponse, 1 + charindex('/',quoteResponse, charindex('\"rrlimit\":\"',quoteResponse, veh5.pos)),charindex('\"', quoteResponse, charindex('\"rrlimit\":\"', quoteResponse, veh5.pos)+len('\"rrlimit\":\"'))-charindex('/',quoteResponse, charindex('\"rrlimit\":\"',quoteResponse, veh5.pos))-1) end 
									else NULL end else null end as rrlimit5,
								case when errormessage is null then case when veh5.pos > 0
									then substring(quoteResponse, charindex('\"towlimit\":\"',quoteResponse, veh5.pos)+len('\"towlimit\":\"'),charindex('\"', quoteResponse, charindex('\"towlimit\":\"', quoteResponse, veh5.pos)+len('\"towlimit\":\"'))-(charindex('\"towlimit\":\"', quoteResponse, veh5.pos)+len('\"towlimit\":\"'))) 
									else NULL end else null end as towlimit5,
								case when errormessage is null then case when veh5.pos > 0
									then case when substring(quoteResponse, charindex('\"mileageSurcharge\":',quoteResponse, veh5.pos)+len('\"mileageSurcharge\":'),4) = 'true'
											  then 'Y'
											  else 'N' end
								    else NULL end else null end as mileageSurcharge5,
								case when errormessage is null then case when veh5.pos > 0
									then case when substring(quoteResponse, charindex('\"vehicleInspection\":',quoteResponse, veh5.pos)+len('\"vehicleInspection\":'),4) = 'true'
											  then 'Y'
											  else 'N' end 
								    else NULL end else null end as vehicleInspection5,
								case when errormessage is null then case when veh5.pos > 0
									then substring(quoteResponse, charindex('\"otcsymbol\":\"',quoteResponse, veh5.pos)+len('\"otcsymbol\":\"'),charindex('\"', quoteResponse, charindex('\"otcsymbol\":\"', quoteResponse, veh5.pos)+len('\"otcsymbol\":\"'))-(charindex('\"otcsymbol\":\"', quoteResponse, veh5.pos)+len('\"otcsymbol\":\"'))) 
									else NULL end else null end as otcSymbol5,
								case when errormessage is null then case when veh5.pos > 0
									then substring(quoteResponse, charindex('\"collsymbol\":\"',quoteResponse, veh5.pos)+len('\"collsymbol\":\"'),charindex('\"', quoteResponse, charindex('\"collsymbol\":\"', quoteResponse, veh5.pos)+len('\"collsymbol\":\"'))-(charindex('\"collsymbol\":\"', quoteResponse, veh5.pos)+len('\"collsymbol\":\"'))) 
									else NULL end else null end as colSymbol5,
								case when errormessage is null then case when veh5.pos > 0
									then substring(quoteResponse, charindex('\"bisymbol\":\"',quoteResponse, veh5.pos)+len('\"bisymbol\":\"'),charindex('\"', quoteResponse, charindex('\"bisymbol\":\"', quoteResponse, veh5.pos)+len('\"bisymbol\":\"'))-(charindex('\"bisymbol\":\"', quoteResponse, veh5.pos)+len('\"bisymbol\":\"'))) 
									else NULL end else null end as bisymbol5,
								case when errormessage is null then case when veh5.pos > 0
									then substring(quoteResponse, charindex('\"pdsymbol\":\"',quoteResponse, veh5.pos)+len('\"pdsymbol\":\"'),charindex('\"', quoteResponse, charindex('\"pdsymbol\":\"', quoteResponse, veh5.pos)+len('\"pdsymbol\":\"'))-(charindex('\"pdsymbol\":\"', quoteResponse, veh5.pos)+len('\"pdsymbol\":\"')))
									else NULL end else null end as pdsymbol5,
								case when errormessage is null then case when veh5.pos > 0
									then substring(quoteResponse, charindex('\"medSymbol\":\"',quoteResponse, veh5.pos)+len('\"medSymbol\":\"'),charindex('\"', quoteResponse, charindex('\"medSymbol\":\"', quoteResponse, veh5.pos)+len('\"medSymbol\":\"'))-(charindex('\"medSymbol\":\"', quoteResponse, veh5.pos)+len('\"medSymbol\":\"'))) 
									else NULL end else null end as medSymbol5,
								case when errormessage is null then case when veh5.pos > 0
									then substring(quoteResponse, charindex('\"pipsymbol\":\"',quoteResponse, veh5.pos)+len('\"pipsymbol\":\"'),charindex('\"', quoteResponse, charindex('\"pipsymbol\":\"', quoteResponse, veh5.pos)+len('\"pipsymbol\":\"'))-(charindex('\"pipsymbol\":\"', quoteResponse, veh5.pos)+len('\"pipsymbol\":\"')))
									else NULL end else null end as pipsymbol5,
								case when errormessage is null then case when veh5.pos > 0
									then substring(quoteResponse, charindex('\"umbisymbol\":\"',quoteResponse, veh5.pos)+len('\"umbisymbol\":\"'),charindex('\"', quoteResponse, charindex('\"umbisymbol\":\"', quoteResponse, veh5.pos)+len('\"umbisymbol\":\"'))-(charindex('\"umbisymbol\":\"', quoteResponse, veh5.pos)+len('\"umbisymbol\":\"')))
									else NULL end else null end as umbisymbol5,
								case when errormessage is null then case when veh5.pos > 0
									then substring(quoteResponse, charindex('\"umpdsymbol\":\"',quoteResponse, veh5.pos)+len('\"umpdsymbol\":\"'),charindex('\"', quoteResponse, charindex('\"umpdsymbol\":\"', quoteResponse, veh5.pos)+len('\"umpdsymbol\":\"'))-(charindex('\"umpdsymbol\":\"', quoteResponse, veh5.pos)+len('\"umpdsymbol\":\"'))) 
									else NULL end else null end as umpdsymbol5,
								case when errormessage is null then case when veh5.pos > 0
									then substring(quoteResponse, charindex('\"equipAmount\":\"',quoteResponse, veh5.pos)+len('\"equipAmount\":\"'),charindex('\"', quoteResponse, charindex('\"equipAmount\":\"', quoteResponse, veh5.pos)+len('\"equipAmount\":\"'))-(charindex('\"equipAmount\":\"', quoteResponse, veh5.pos)+len('\"equipAmount\":\"')))
									else NULL end else null end as se5,
																case when errormessage is null then case when veh6.pos > 0 then 6 else NULL end  else null end as vehicleNum6,
								case when errormessage is null then case when veh6.pos > 0 
									then substring(quoteResponse, charindex('\"modelyear\":\"', quoteResponse, veh6.pos)+len('\"modelyear\":\"'), 4)
									else NULL end  else null end as modelyear6,
								case when errormessage is null then case when veh6.pos > 0
									then substring(quoteResponse, charindex('\"garagingCounty\":\"',quoteResponse, veh6.pos)+len('\"garagingCounty\":\"'),charindex('\"', quoteResponse, charindex('\"garagingCounty\":\"', quoteResponse, veh6.pos)+len('\"garagingCounty\":\"'))-(charindex('\"garagingCounty\":\"', quoteResponse, veh6.pos)+len('\"garagingCounty\":\"'))) 
									else NULL end else null end as garagingCounty6,
								case when errormessage is null then case when veh6.pos > 0
									then substring(quoteResponse, charindex('\"garagingZip\":\"', quoteResponse, veh6.pos)+len('\"garagingZip\":\"'), 5)
									else NULL end else null end as garagingZip6,
								case when errormessage is null then case when veh6.pos > 0 then 'N' else NULL end else null end as altGaragingZip6,
								case when errormessage is null then case when veh6.pos > 0
									then
										case when substring(quoteResponse, charindex('\"otcDeductible\":\"',quoteResponse, veh6.pos)+len('\"otcDeductible\":\"'),charindex('\"', quoteResponse, charindex('\"otcDeductible\":\"', quoteResponse, veh6.pos)+len('\"otcDeductible\":\"'))-(charindex('\"otcDeductible\":\"', quoteResponse, veh6.pos)+len('\"otcDeductible\":\"'))) = 'NOCOV'
											 then '0'
											 else substring(quoteResponse, charindex('\"otcDeductible\":\"',quoteResponse, veh6.pos)+len('\"otcDeductible\":\"'),charindex('\"', quoteResponse, charindex('\"otcDeductible\":\"', quoteResponse, veh6.pos)+len('\"otcDeductible\":\"'))-(charindex('\"otcDeductible\":\"', quoteResponse, veh6.pos)+len('\"otcDeductible\":\"'))) end
									else NULL end else null end as otcDeductible6,
								case when errormessage is null then case when veh6.pos > 0
									then
										case when substring(quoteResponse, charindex('\"collDeductible\":\"',quoteResponse, veh6.pos)+len('\"collDeductible\":\"'),charindex('\"', quoteResponse, charindex('\"collDeductible\":\"', quoteResponse, veh6.pos)+len('\"collDeductible\":\"'))-(charindex('\"collDeductible\":\"', quoteResponse, veh6.pos)+len('\"collDeductible\":\"'))) = 'NOCOV'
											 then '0'
											 else substring(quoteResponse, charindex('\"collDeductible\":\"',quoteResponse, veh6.pos)+len('\"collDeductible\":\"'),charindex('\"', quoteResponse, charindex('\"collDeductible\":\"', quoteResponse, veh6.pos)+len('\"collDeductible\":\"'))-(charindex('\"collDeductible\":\"', quoteResponse, veh6.pos)+len('\"collDeductible\":\"'))) end
									else NULL end else null end as collDeductible6,
								case when errormessage is null then case when veh6.pos > 0
									then
										case when substring(quoteResponse, charindex('\"rrlimit\":\"',quoteResponse, veh6.pos)+len('\"rrlimit\":\"'),charindex('\"', quoteResponse, charindex('\"rrlimit\":\"', quoteResponse, veh6.pos)+len('\"rrlimit\":\"'))-(charindex('\"rrlimit\":\"', quoteResponse, veh6.pos)+len('\"rrlimit\":\"'))) = 'NOCOV'
										then '0'
										else substring(quoteResponse, 1 + charindex('/',quoteResponse, charindex('\"rrlimit\":\"',quoteResponse, veh6.pos)),charindex('\"', quoteResponse, charindex('\"rrlimit\":\"', quoteResponse, veh6.pos)+len('\"rrlimit\":\"'))-charindex('/',quoteResponse, charindex('\"rrlimit\":\"',quoteResponse, veh6.pos))-1) end 
									else NULL end else null end as rrlimit6,
								case when errormessage is null then case when veh6.pos > 0
									then substring(quoteResponse, charindex('\"towlimit\":\"',quoteResponse, veh6.pos)+len('\"towlimit\":\"'),charindex('\"', quoteResponse, charindex('\"towlimit\":\"', quoteResponse, veh6.pos)+len('\"towlimit\":\"'))-(charindex('\"towlimit\":\"', quoteResponse, veh6.pos)+len('\"towlimit\":\"'))) 
									else NULL end else null end as towlimit6,
								case when errormessage is null then case when veh6.pos > 0
									then case when substring(quoteResponse, charindex('\"mileageSurcharge\":',quoteResponse, veh6.pos)+len('\"mileageSurcharge\":'),4) = 'true'
											  then 'Y'
											  else 'N' end
								    else NULL end else null end as mileageSurcharge6,
								case when errormessage is null then case when veh6.pos > 0
									then case when substring(quoteResponse, charindex('\"vehicleInspection\":',quoteResponse, veh6.pos)+len('\"vehicleInspection\":'),4) = 'true'
											  then 'Y'
											  else 'N' end 
								    else NULL end else null end as vehicleInspection6,
								case when errormessage is null then case when veh6.pos > 0
									then substring(quoteResponse, charindex('\"otcsymbol\":\"',quoteResponse, veh6.pos)+len('\"otcsymbol\":\"'),charindex('\"', quoteResponse, charindex('\"otcsymbol\":\"', quoteResponse, veh6.pos)+len('\"otcsymbol\":\"'))-(charindex('\"otcsymbol\":\"', quoteResponse, veh6.pos)+len('\"otcsymbol\":\"'))) 
									else NULL end else null end as otcSymbol6,
								case when errormessage is null then case when veh6.pos > 0
									then substring(quoteResponse, charindex('\"collsymbol\":\"',quoteResponse, veh6.pos)+len('\"collsymbol\":\"'),charindex('\"', quoteResponse, charindex('\"collsymbol\":\"', quoteResponse, veh6.pos)+len('\"collsymbol\":\"'))-(charindex('\"collsymbol\":\"', quoteResponse, veh6.pos)+len('\"collsymbol\":\"'))) 
									else NULL end else null end as colSymbol6,
								case when errormessage is null then case when veh6.pos > 0
									then substring(quoteResponse, charindex('\"bisymbol\":\"',quoteResponse, veh6.pos)+len('\"bisymbol\":\"'),charindex('\"', quoteResponse, charindex('\"bisymbol\":\"', quoteResponse, veh6.pos)+len('\"bisymbol\":\"'))-(charindex('\"bisymbol\":\"', quoteResponse, veh6.pos)+len('\"bisymbol\":\"'))) 
									else NULL end else null end as bisymbol6,
								case when errormessage is null then case when veh6.pos > 0
									then substring(quoteResponse, charindex('\"pdsymbol\":\"',quoteResponse, veh6.pos)+len('\"pdsymbol\":\"'),charindex('\"', quoteResponse, charindex('\"pdsymbol\":\"', quoteResponse, veh6.pos)+len('\"pdsymbol\":\"'))-(charindex('\"pdsymbol\":\"', quoteResponse, veh6.pos)+len('\"pdsymbol\":\"')))
									else NULL end else null end as pdsymbol6,
								case when errormessage is null then case when veh6.pos > 0
									then substring(quoteResponse, charindex('\"medSymbol\":\"',quoteResponse, veh6.pos)+len('\"medSymbol\":\"'),charindex('\"', quoteResponse, charindex('\"medSymbol\":\"', quoteResponse, veh6.pos)+len('\"medSymbol\":\"'))-(charindex('\"medSymbol\":\"', quoteResponse, veh6.pos)+len('\"medSymbol\":\"'))) 
									else NULL end else null end as medSymbol6,
								case when errormessage is null then case when veh6.pos > 0
									then substring(quoteResponse, charindex('\"pipsymbol\":\"',quoteResponse, veh6.pos)+len('\"pipsymbol\":\"'),charindex('\"', quoteResponse, charindex('\"pipsymbol\":\"', quoteResponse, veh6.pos)+len('\"pipsymbol\":\"'))-(charindex('\"pipsymbol\":\"', quoteResponse, veh6.pos)+len('\"pipsymbol\":\"')))
									else NULL end else null end as pipsymbol6,
								case when errormessage is null then case when veh6.pos > 0
									then substring(quoteResponse, charindex('\"umbisymbol\":\"',quoteResponse, veh6.pos)+len('\"umbisymbol\":\"'),charindex('\"', quoteResponse, charindex('\"umbisymbol\":\"', quoteResponse, veh6.pos)+len('\"umbisymbol\":\"'))-(charindex('\"umbisymbol\":\"', quoteResponse, veh6.pos)+len('\"umbisymbol\":\"')))
									else NULL end else null end as umbisymbol6,
								case when errormessage is null then case when veh6.pos > 0
									then substring(quoteResponse, charindex('\"umpdsymbol\":\"',quoteResponse, veh6.pos)+len('\"umpdsymbol\":\"'),charindex('\"', quoteResponse, charindex('\"umpdsymbol\":\"', quoteResponse, veh6.pos)+len('\"umpdsymbol\":\"'))-(charindex('\"umpdsymbol\":\"', quoteResponse, veh6.pos)+len('\"umpdsymbol\":\"'))) 
									else NULL end else null end as umpdsymbol6,
								case when errormessage is null then case when veh6.pos > 0
									then substring(quoteResponse, charindex('\"equipAmount\":\"',quoteResponse, veh6.pos)+len('\"equipAmount\":\"'),charindex('\"', quoteResponse, charindex('\"equipAmount\":\"', quoteResponse, veh6.pos)+len('\"equipAmount\":\"'))-(charindex('\"equipAmount\":\"', quoteResponse, veh6.pos)+len('\"equipAmount\":\"')))
									else NULL end else null end as se6,
								case when errormessage is null then 1 else null end as driverNum1,
								case when errormessage is null then substring(quoteResponse, charindex('\"gender\":\"', quoteResponse)+len('\"gender\":\"'), 1) else null end as gender1,
								case when errormessage is null then substring(quoteResponse, charindex('\"marital\":\"', quoteResponse)+len('\"marital\":\"'), 1) else null end as marital1,
								case when errormessage is null then case when charindex('\"points\":\"', quoteResponse) <> 0 then	substring(quoteResponse, charindex('\"points\":\"',quoteResponse)+len('\"points\":\"'),charindex('\"', quoteResponse, charindex('\"points\":\"', quoteResponse)+len('\"points\":\"'))-(charindex('\"points\":\"', quoteResponse)+len('\"points\":\"'))) else 0 end else null end as points1,
								case when errormessage is null then substring(quoteResponse, charindex('\"age\":\"',quoteResponse)+len('\"age\":\"'),charindex('\"', quoteResponse, charindex('\"age\":\"', quoteResponse)+len('\"age\":\"'))-(charindex('\"age\":\"', quoteResponse)+len('\"age\":\"'))) else null end as age1,
								case when errormessage is null then case when charindex('\"goodStudentDiscount\":\"', quoteResponse) <> 0
									then 
									case when substring(quoteResponse, charindex('\"goodStudentDiscount\":\"',quoteResponse)+len('\"goodStudentDiscount\":\"'),charindex('\"', quoteResponse, charindex('\"goodStudentDiscount\":\"', quoteResponse)+len('\"goodStudentDiscount\":\"'))-(charindex('\"goodStudentDiscount\":\"', quoteResponse)+len('\"goodStudentDiscount\":\"'))) in ('3', 'Y') then 'GS1'
										 when substring(quoteResponse, charindex('\"goodStudentDiscount\":\"',quoteResponse)+len('\"goodStudentDiscount\":\"'),charindex('\"', quoteResponse, charindex('\"goodStudentDiscount\":\"', quoteResponse)+len('\"goodStudentDiscount\":\"'))-(charindex('\"goodStudentDiscount\":\"', quoteResponse)+len('\"goodStudentDiscount\":\"'))) in ('0', 'N') then 'GS0'
										 when substring(quoteResponse, charindex('\"goodStudentDiscount\":\"',quoteResponse)+len('\"goodStudentDiscount\":\"'),charindex('\"', quoteResponse, charindex('\"goodStudentDiscount\":\"', quoteResponse)+len('\"goodStudentDiscount\":\"'))-(charindex('\"goodStudentDiscount\":\"', quoteResponse)+len('\"goodStudentDiscount\":\"'))) = '3.5' then 'GS2'
										 else 'GS0' end
									else 'GS0' end else null end as goodstudent1,
								case when errormessage is null then case when substring(quoteResponse, charindex('\"driverstatus\":\"', quoteResponse)+len('\"driverstatus\":\"'), 1) = 'E' then 'Y' else 'N' end else null end as excluded1,
								case when errormessage is null then case when substring(quoteResponse, charindex('\"preferredDriverDiscount\":', quoteResponse)+len('\"preferredDriverDiscount\":'), 4) = 'TRUE' then 'Y' else 'N' end else null end as preferredDriver1,
								case when errormessage is null then case when drv2.pos > 0 then 2 else null end else null end as driverNum2,
								case when errormessage is null then case when drv2.pos > 0 then substring(quoteResponse, charindex('\"gender\":\"', quoteResponse, drv2.pos)+len('\"gender\":\"'), 1) else null end else null end as gender2,
								case when errormessage is null then case when drv2.pos > 0 then substring(quoteResponse, charindex('\"marital\":\"', quoteResponse, drv2.pos)+len('\"marital\":\"'), 1) else null end else null end as marital2,
								case when errormessage is null then case when drv2.pos > 0 then case when charindex('\"points\":\"', quoteResponse, drv2.pos) <> 0 then	substring(quoteResponse, charindex('\"points\":\"',quoteResponse, drv2.pos)+len('\"points\":\"'),charindex('\"', quoteResponse, charindex('\"points\":\"', quoteResponse, drv2.pos)+len('\"points\":\"'))-(charindex('\"points\":\"', quoteResponse, drv2.pos)+len('\"points\":\"'))) else 0 end else null end else null end as points2,
								case when errormessage is null then case when drv2.pos > 0 then substring(quoteResponse, charindex('\"age\":\"',quoteResponse, drv2.pos)+len('\"age\":\"'),charindex('\"', quoteResponse, charindex('\"age\":\"', quoteResponse,drv2.pos)+len('\"age\":\"'))-(charindex('\"age\":\"', quoteResponse, drv2.pos)+len('\"age\":\"'))) else null end else null end as age2,
								case when errormessage is null then case when drv2.pos > 0 then case when charindex('\"goodStudentDiscount\":\"', quoteResponse, drv2.pos) <> 0
									then 
									case when substring(quoteResponse, charindex('\"goodStudentDiscount\":\"',quoteResponse, drv2.pos)+len('\"goodStudentDiscount\":\"'),charindex('\"', quoteResponse, charindex('\"goodStudentDiscount\":\"', quoteResponse, drv2.pos)+len('\"goodStudentDiscount\":\"'))-(charindex('\"goodStudentDiscount\":\"', quoteResponse, drv2.pos)+len('\"goodStudentDiscount\":\"'))) in ('3', 'Y') then 'GS1'
										 when substring(quoteResponse, charindex('\"goodStudentDiscount\":\"',quoteResponse, drv2.pos)+len('\"goodStudentDiscount\":\"'),charindex('\"', quoteResponse, charindex('\"goodStudentDiscount\":\"', quoteResponse, drv2.pos)+len('\"goodStudentDiscount\":\"'))-(charindex('\"goodStudentDiscount\":\"', quoteResponse, drv2.pos)+len('\"goodStudentDiscount\":\"'))) in ('0', 'N') then 'GS0'
										 when substring(quoteResponse, charindex('\"goodStudentDiscount\":\"',quoteResponse, drv2.pos)+len('\"goodStudentDiscount\":\"'),charindex('\"', quoteResponse, charindex('\"goodStudentDiscount\":\"', quoteResponse, drv2.pos)+len('\"goodStudentDiscount\":\"'))-(charindex('\"goodStudentDiscount\":\"', quoteResponse, drv2.pos)+len('\"goodStudentDiscount\":\"'))) = '3.5' then 'GS2'
										 else 'GS0' end
									else 'GS0' end else null end else null end as goodstudent2,
								case when errormessage is null then case when drv2.pos > 0 then case when substring(quoteResponse, charindex('\"driverstatus\":\"', quoteResponse, drv2.pos)+len('\"driverstatus\":\"'), 1) = 'E' then 'Y' else 'N' end else null end else null end as excluded2,
								case when errormessage is null then case when drv2.pos > 0 then case when substring(quoteResponse, charindex('\"preferredDriverDiscount\":', quoteResponse, drv2.pos)+len('\"preferredDriverDiscount\":'), 4) = 'TRUE' then 'Y' else 'N' end else null end else null end as preferredDriver2,
																case when errormessage is null then case when drv3.pos > 0 then 3 else null end else null end as driverNum3,
								case when errormessage is null then case when drv3.pos > 0 then substring(quoteResponse, charindex('\"gender\":\"', quoteResponse, drv3.pos)+len('\"gender\":\"'), 1) else null end else null end as gender3,
								case when errormessage is null then case when drv3.pos > 0 then substring(quoteResponse, charindex('\"marital\":\"', quoteResponse, drv3.pos)+len('\"marital\":\"'), 1) else null end else null end as marital3,
								case when errormessage is null then case when drv3.pos > 0 then case when charindex('\"points\":\"', quoteResponse, drv3.pos) <> 0 then	substring(quoteResponse, charindex('\"points\":\"',quoteResponse, drv3.pos)+len('\"points\":\"'),charindex('\"', quoteResponse, charindex('\"points\":\"', quoteResponse, drv3.pos)+len('\"points\":\"'))-(charindex('\"points\":\"', quoteResponse, drv3.pos)+len('\"points\":\"'))) else 0 end else null end else null end as points3,
								case when errormessage is null then case when drv3.pos > 0 then substring(quoteResponse, charindex('\"age\":\"',quoteResponse, drv3.pos)+len('\"age\":\"'),charindex('\"', quoteResponse, charindex('\"age\":\"', quoteResponse, drv3.pos)+len('\"age\":\"'))-(charindex('\"age\":\"', quoteResponse, drv3.pos)+len('\"age\":\"'))) else null end else null end as age3,
								case when errormessage is null then case when drv3.pos > 0 then case when charindex('\"goodStudentDiscount\":\"', quoteResponse, drv3.pos) <> 0
									then 
									case when substring(quoteResponse, charindex('\"goodStudentDiscount\":\"',quoteResponse, drv3.pos)+len('\"goodStudentDiscount\":\"'),charindex('\"', quoteResponse, charindex('\"goodStudentDiscount\":\"', quoteResponse, drv3.pos)+len('\"goodStudentDiscount\":\"'))-(charindex('\"goodStudentDiscount\":\"', quoteResponse, drv3.pos)+len('\"goodStudentDiscount\":\"'))) in ('3', 'Y') then 'GS1'
										 when substring(quoteResponse, charindex('\"goodStudentDiscount\":\"',quoteResponse, drv3.pos)+len('\"goodStudentDiscount\":\"'),charindex('\"', quoteResponse, charindex('\"goodStudentDiscount\":\"', quoteResponse, drv3.pos)+len('\"goodStudentDiscount\":\"'))-(charindex('\"goodStudentDiscount\":\"', quoteResponse, drv3.pos)+len('\"goodStudentDiscount\":\"'))) in ('0', 'N') then 'GS0'
										 when substring(quoteResponse, charindex('\"goodStudentDiscount\":\"',quoteResponse, drv3.pos)+len('\"goodStudentDiscount\":\"'),charindex('\"', quoteResponse, charindex('\"goodStudentDiscount\":\"', quoteResponse, drv3.pos)+len('\"goodStudentDiscount\":\"'))-(charindex('\"goodStudentDiscount\":\"', quoteResponse, drv3.pos)+len('\"goodStudentDiscount\":\"'))) = '3.5' then 'GS2'
										 else 'GS0' end
									else 'GS0' end else null end else null end as goodstudent3,
								case when errormessage is null then case when drv3.pos > 0 then case when substring(quoteResponse, charindex('\"driverstatus\":\"', quoteResponse, drv3.pos)+len('\"driverstatus\":\"'), 1) = 'E' then 'Y' else 'N' end else null end else null end as excluded3,
								case when errormessage is null then case when drv3.pos > 0 then case when substring(quoteResponse, charindex('\"preferredDriverDiscount\":', quoteResponse, drv3.pos)+len('\"preferredDriverDiscount\":'), 4) = 'TRUE' then 'Y' else 'N' end else null end else null end as preferredDriver3,
																case when errormessage is null then case when drv4.pos > 0 then 4 else null end else null end as driverNum4,
								case when errormessage is null then case when drv4.pos > 0 then substring(quoteResponse, charindex('\"gender\":\"', quoteResponse, drv4.pos)+len('\"gender\":\"'), 1) else null end else null end as gender4,
								case when errormessage is null then case when drv4.pos > 0 then substring(quoteResponse, charindex('\"marital\":\"', quoteResponse, drv4.pos)+len('\"marital\":\"'), 1) else null end else null end as marital4,
								case when errormessage is null then case when drv4.pos > 0 then case when charindex('\"points\":\"', quoteResponse, drv4.pos) <> 0 then	substring(quoteResponse, charindex('\"points\":\"',quoteResponse, drv4.pos)+len('\"points\":\"'),charindex('\"', quoteResponse, charindex('\"points\":\"', quoteResponse, drv4.pos)+len('\"points\":\"'))-(charindex('\"points\":\"', quoteResponse, drv4.pos)+len('\"points\":\"'))) else 0 end else null end else null end as points4,
								case when errormessage is null then case when drv4.pos > 0 then substring(quoteResponse, charindex('\"age\":\"',quoteResponse, drv4.pos)+len('\"age\":\"'),charindex('\"', quoteResponse, charindex('\"age\":\"', quoteResponse, drv4.pos)+len('\"age\":\"'))-(charindex('\"age\":\"', quoteResponse, drv4.pos)+len('\"age\":\"'))) else null end else null end as age4,
								case when errormessage is null then case when drv4.pos > 0 then case when charindex('\"goodStudentDiscount\":\"', quoteResponse, drv4.pos) <> 0
									then 
									case when substring(quoteResponse, charindex('\"goodStudentDiscount\":\"',quoteResponse, drv4.pos)+len('\"goodStudentDiscount\":\"'),charindex('\"', quoteResponse, charindex('\"goodStudentDiscount\":\"', quoteResponse, drv4.pos)+len('\"goodStudentDiscount\":\"'))-(charindex('\"goodStudentDiscount\":\"', quoteResponse, drv4.pos)+len('\"goodStudentDiscount\":\"'))) in ('3', 'Y') then 'GS1'
										 when substring(quoteResponse, charindex('\"goodStudentDiscount\":\"',quoteResponse, drv4.pos)+len('\"goodStudentDiscount\":\"'),charindex('\"', quoteResponse, charindex('\"goodStudentDiscount\":\"', quoteResponse, drv4.pos)+len('\"goodStudentDiscount\":\"'))-(charindex('\"goodStudentDiscount\":\"', quoteResponse, drv4.pos)+len('\"goodStudentDiscount\":\"'))) in ('0', 'N') then 'GS0'
										 when substring(quoteResponse, charindex('\"goodStudentDiscount\":\"',quoteResponse, drv4.pos)+len('\"goodStudentDiscount\":\"'),charindex('\"', quoteResponse, charindex('\"goodStudentDiscount\":\"', quoteResponse, drv4.pos)+len('\"goodStudentDiscount\":\"'))-(charindex('\"goodStudentDiscount\":\"', quoteResponse, drv4.pos)+len('\"goodStudentDiscount\":\"'))) = '3.5' then 'GS2'
										 else 'GS0' end
									else 'GS0' end else null end else null end as goodstudent4,
								case when errormessage is null then case when drv4.pos > 0 then case when substring(quoteResponse, charindex('\"driverstatus\":\"', quoteResponse, drv4.pos)+len('\"driverstatus\":\"'), 1) = 'E' then 'Y' else 'N' end else null end else null end as excluded4,
								case when errormessage is null then case when drv4.pos > 0 then case when substring(quoteResponse, charindex('\"preferredDriverDiscount\":', quoteResponse, drv4.pos)+len('\"preferredDriverDiscount\":'), 4) = 'TRUE' then 'Y' else 'N' end else null end else null end as preferredDriver4,
																case when errormessage is null then case when drv5.pos > 0 then 5 else null end else null end as driverNum5,
								case when errormessage is null then case when drv5.pos > 0 then substring(quoteResponse, charindex('\"gender\":\"', quoteResponse, drv5.pos)+len('\"gender\":\"'), 1) else null end else null end as gender5,
								case when errormessage is null then case when drv5.pos > 0 then substring(quoteResponse, charindex('\"marital\":\"', quoteResponse, drv5.pos)+len('\"marital\":\"'), 1) else null end else null end as marital5,
								case when errormessage is null then case when drv5.pos > 0 then case when charindex('\"points\":\"', quoteResponse, drv5.pos) <> 0 then	substring(quoteResponse, charindex('\"points\":\"',quoteResponse, drv5.pos)+len('\"points\":\"'),charindex('\"', quoteResponse, charindex('\"points\":\"', quoteResponse, drv5.pos)+len('\"points\":\"'))-(charindex('\"points\":\"', quoteResponse, drv5.pos)+len('\"points\":\"'))) else 0 end else null end else null end as points5,
								case when errormessage is null then case when drv5.pos > 0 then substring(quoteResponse, charindex('\"age\":\"',quoteResponse, drv5.pos)+len('\"age\":\"'),charindex('\"', quoteResponse, charindex('\"age\":\"', quoteResponse, drv5.pos)+len('\"age\":\"'))-(charindex('\"age\":\"', quoteResponse, drv5.pos)+len('\"age\":\"'))) else null end else null end as age5,
								case when errormessage is null then case when drv5.pos > 0 then case when charindex('\"goodStudentDiscount\":\"', quoteResponse, drv5.pos) <> 0
									then 
									case when substring(quoteResponse, charindex('\"goodStudentDiscount\":\"',quoteResponse, drv5.pos)+len('\"goodStudentDiscount\":\"'),charindex('\"', quoteResponse, charindex('\"goodStudentDiscount\":\"', quoteResponse, drv5.pos)+len('\"goodStudentDiscount\":\"'))-(charindex('\"goodStudentDiscount\":\"', quoteResponse, drv5.pos)+len('\"goodStudentDiscount\":\"')))  in ('3', 'Y') then 'GS1'
										 when substring(quoteResponse, charindex('\"goodStudentDiscount\":\"',quoteResponse, drv5.pos)+len('\"goodStudentDiscount\":\"'),charindex('\"', quoteResponse, charindex('\"goodStudentDiscount\":\"', quoteResponse, drv5.pos)+len('\"goodStudentDiscount\":\"'))-(charindex('\"goodStudentDiscount\":\"', quoteResponse, drv5.pos)+len('\"goodStudentDiscount\":\"')))  in ('0', 'N') then 'GS0'
										 when substring(quoteResponse, charindex('\"goodStudentDiscount\":\"',quoteResponse, drv5.pos)+len('\"goodStudentDiscount\":\"'),charindex('\"', quoteResponse, charindex('\"goodStudentDiscount\":\"', quoteResponse, drv5.pos)+len('\"goodStudentDiscount\":\"'))-(charindex('\"goodStudentDiscount\":\"', quoteResponse, drv5.pos)+len('\"goodStudentDiscount\":\"')))  = '3.5' then 'GS2'
										 else 'GS0' end
									else 'GS0' end else null end else null end as goodstudent5,
								case when errormessage is null then case when drv5.pos > 0 then case when substring(quoteResponse, charindex('\"driverstatus\":\"', quoteResponse, drv5.pos)+len('\"driverstatus\":\"'), 1) = 'E' then 'Y' else 'N' end else null end else null end as excluded5,
								case when errormessage is null then case when drv5.pos > 0 then case when substring(quoteResponse, charindex('\"preferredDriverDiscount\":', quoteResponse, drv5.pos)+len('\"preferredDriverDiscount\":'), 4) = 'TRUE' then 'Y' else 'N' end else null end else null end as preferredDriver5,
																case when errormessage is null then case when drv6.pos > 0 then 6 else null end else null end as driverNum6,
								case when errormessage is null then case when drv6.pos > 0 then substring(quoteResponse, charindex('\"gender\":\"', quoteResponse, drv6.pos)+len('\"gender\":\"'), 1) else null end else null end as gender6,
								case when errormessage is null then case when drv6.pos > 0 then substring(quoteResponse, charindex('\"marital\":\"', quoteResponse, drv6.pos)+len('\"marital\":\"'), 1) else null end else null end as marital6,
								case when errormessage is null then case when drv6.pos > 0 then case when charindex('\"points\":\"', quoteResponse, drv6.pos) <> 0 then	substring(quoteResponse, charindex('\"points\":\"',quoteResponse, drv6.pos)+len('\"points\":\"'),charindex('\"', quoteResponse, charindex('\"points\":\"', quoteResponse, drv6.pos)+len('\"points\":\"'))-(charindex('\"points\":\"', quoteResponse, drv6.pos)+len('\"points\":\"'))) else 0 end else null end else null end as points6,
								case when errormessage is null then case when drv6.pos > 0 then substring(quoteResponse, charindex('\"age\":\"',quoteResponse, drv6.pos)+len('\"age\":\"'),charindex('\"', quoteResponse, charindex('\"age\":\"', quoteResponse, drv6.pos)+len('\"age\":\"'))-(charindex('\"age\":\"', quoteResponse, drv6.pos)+len('\"age\":\"'))) else null end else null end as age6,
								case when errormessage is null then case when drv6.pos > 0 then case when charindex('\"goodStudentDiscount\":\"', quoteResponse, drv6.pos) <> 0
									then 
									case when substring(quoteResponse, charindex('\"goodStudentDiscount\":\"',quoteResponse, drv6.pos)+len('\"goodStudentDiscount\":\"'),charindex('\"', quoteResponse, charindex('\"goodStudentDiscount\":\"', quoteResponse, drv6.pos)+len('\"goodStudentDiscount\":\"'))-(charindex('\"goodStudentDiscount\":\"', quoteResponse, drv6.pos)+len('\"goodStudentDiscount\":\"'))) in ('3', 'Y') then 'GS1'
										 when substring(quoteResponse, charindex('\"goodStudentDiscount\":\"',quoteResponse, drv6.pos)+len('\"goodStudentDiscount\":\"'),charindex('\"', quoteResponse, charindex('\"goodStudentDiscount\":\"', quoteResponse, drv6.pos)+len('\"goodStudentDiscount\":\"'))-(charindex('\"goodStudentDiscount\":\"', quoteResponse, drv6.pos)+len('\"goodStudentDiscount\":\"'))) in ('0', 'N') then 'GS0'
										 when substring(quoteResponse, charindex('\"goodStudentDiscount\":\"',quoteResponse, drv6.pos)+len('\"goodStudentDiscount\":\"'),charindex('\"', quoteResponse, charindex('\"goodStudentDiscount\":\"', quoteResponse, drv6.pos)+len('\"goodStudentDiscount\":\"'))-(charindex('\"goodStudentDiscount\":\"', quoteResponse, drv6.pos)+len('\"goodStudentDiscount\":\"'))) = '3.5' then 'GS2'
										 else'GS0' end
									else 'GS0' end else null end else null end as goodstudent6,
								case when errormessage is null then case when drv6.pos > 0 then case when substring(quoteResponse, charindex('\"driverstatus\":\"', quoteResponse, drv6.pos)+len('\"driverstatus\":\"'), 1) = 'E' then 'Y' else 'N' end else null end else null end as excluded6,
								case when errormessage is null then case when drv6.pos > 0 then case when substring(quoteResponse, charindex('\"preferredDriverDiscount\":', quoteResponse, drv6.pos)+len('\"preferredDriverDiscount\":'), 4) = 'TRUE' then 'Y' else 'N' end else null end else null end as preferredDriver6,

								--premiums
								case when errormessage is null then substring(quoteResponse, charindex('\"total\":',quoteResponse)+len('\"total\":'),charindex(',\"', quoteResponse, charindex('\"total\":', quoteResponse)+len('\"total\":'))-(charindex('\"total\":', quoteResponse)+len('\"total\":'))) else null end as prem1,
								case when errormessage is null then case when prem2.pos > 0
									then substring(quoteResponse, charindex('\"total\":',quoteResponse, prem2.pos)+len('\"total\":'),charindex(',\"', quoteResponse, charindex('\"total\":', quoteResponse, prem2.pos)+len('\"total\":'))-(charindex('\"total\":', quoteResponse, prem2.pos)+len('\"total\":')))
									else null end else null end as prem2,
								case when errormessage is null then case when prem3.pos > 0
									then substring(quoteResponse, charindex('\"total\":',quoteResponse, prem3.pos)+len('\"total\":'),charindex(',\"', quoteResponse, charindex('\"total\":', quoteResponse, prem3.pos)+len('\"total\":'))-(charindex('\"total\":', quoteResponse, prem3.pos)+len('\"total\":')))
									else null end else null end as prem3,
								case when errormessage is null then case when prem4.pos > 0
									then substring(quoteResponse, charindex('\"total\":',quoteResponse, prem4.pos)+len('\"total\":'),charindex(',\"', quoteResponse, charindex('\"total\":', quoteResponse, prem4.pos)+len('\"total\":'))-(charindex('\"total\":', quoteResponse, prem4.pos)+len('\"total\":')))
									else null end else null end as prem4,
								case when errormessage is null then case when prem5.pos > 0
									then substring(quoteResponse, charindex('\"total\":',quoteResponse, prem5.pos)+len('\"total\":'),charindex(',\"', quoteResponse, charindex('\"total\":', quoteResponse, prem5.pos)+len('\"total\":'))-(charindex('\"total\":', quoteResponse, prem5.pos)+len('\"total\":')))
									else null end else null end as prem5,
								case when errormessage is null then case when prem6.pos > 0
									then substring(quoteResponse, charindex('\"total\":',quoteResponse, prem6.pos)+len('\"total\":'),charindex(',\"', quoteResponse, charindex('\"total\":', quoteResponse, prem6.pos)+len('\"total\":'))-(charindex('\"total\":', quoteResponse, prem6.pos)+len('\"total\":')))
									else null end else null end as prem6,
								case when errormessage is null then case when substring(quoteResponse, charindex('\"unacceptableVehicleOrDriverSurcharge\":', quoteResponse)+len('\"unacceptableVehicleOrDriverSurcharge\":'),4) = 'TRUE' then 'Y' else 'N' end else null end as unacceptable,
								case when errormessage is null then case when charindex('\"warningMessages\":[\"', quoteResponse) <> 0 then substring(quoteResponse, charindex('\"warningMessages\":[\"', quoteResponse)+len('\"warningMessages\":[\"'), charindex('\"', quoteResponse, charindex('\"warningMessages\":[\"', quoteResponse)+len('\"warningMessages\":[\"'))-(charindex('\"warningMessages\":[\"', quoteResponse)+len('\"warningMessages\":[\"'))) else null end else null end  as warningmessage,
								case when errormessage is null then substring(quoteResponse, charindex('\"rateChartVersion\":\"', quoteResponse)+len('\"rateChartVersion\":\"'), charindex('\"', quoteResponse, charindex('\"rateChartVersion\":\"', quoteResponse)+len('\"rateChartVersion\":\"'))-(charindex('\"rateChartVersion\":\"', quoteResponse)+len('\"rateChartVersion\":\"')))  else null end as rateChart

INTO Periscope_Data.dbo.Temp_ClutchRateRequest_EQ
								FROM #T c
								cross apply (select (charindex('\"otcSymbol\":\"',quoteResponse) + len('\"otcSymbol\":\"'))) as veh1(pos)
								cross apply (select (charindex('\"otcSymbol\":\"',quoteResponse,veh1.pos + 1))) as veh2(pos)	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	                                                                                                                                                                                                                                                           
								cross apply (select case when veh2.pos > 0 then (charindex('\"otcSymbol\":\"',quoteResponse,veh2.pos + 1)) end) as veh3(pos)	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	                                                                                                                                                                                                                                                           
								cross apply (select case when veh3.pos > 0 then (charindex('\"otcSymbol\":\"',quoteResponse,veh3.pos + 1)) end) as veh4(pos)	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	                                                                                                                                                                                                                                                           
								cross apply (select case when veh4.pos > 0 then (charindex('\"otcSymbol\":\"',quoteResponse,veh4.pos + 1)) end) as veh5(pos)	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	                                                                                                                                                                                                                                                           
								cross apply (select case when veh5.pos > 0 then (charindex('\"otcSymbol\":\"',quoteResponse,veh5.pos + 1)) end) as veh6(pos)	 	 	
								cross apply (select (charindex('\"age\":\"',quoteResponse))) as drv1(pos)
								cross apply (select (charindex('\"age\":\"',quoteResponse, drv1.pos + 1))) as drv2(pos)
								cross apply (select case when drv2.pos >0 then (charindex('\"age\":\"',quoteResponse, drv2.pos + 1)) end) as drv3(pos)
								cross apply (select case when drv3.pos >0 then (charindex('\"age\":\"',quoteResponse, drv3.pos + 1)) end) as drv4(pos)
								cross apply (select case when drv4.pos >0 then (charindex('\"age\":\"',quoteResponse, drv4.pos + 1)) end) as drv5(pos)
								cross apply (select case when drv5.pos >0 then (charindex('\"age\":\"',quoteResponse, drv5.pos + 1)) end) as drv6(pos)
								cross apply (select (charindex('\"total\"', quoteResponse))) as prem1(pos)
								cross apply (select (charindex('\"total\"', quoteResponse, prem1.pos + 1))) as prem2(pos)
								cross apply (select case when prem2.pos > 0 then (charindex('\"total\"', quoteResponse, prem2.pos + 1)) end) as prem3(pos)
								cross apply (select case when prem3.pos > 0 then (charindex('\"total\"', quoteResponse, prem3.pos + 1)) end) as prem4(pos)
								cross apply (select case when prem4.pos > 0 then (charindex('\"total\"', quoteResponse, prem4.pos + 1)) end) as prem5(pos)
								cross apply (select case when prem5.pos > 0 then (charindex('\"total\"', quoteResponse, prem5.pos + 1)) end) as prem6(pos)

END
GO

