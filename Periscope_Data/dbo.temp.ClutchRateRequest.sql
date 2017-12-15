USE [Periscope_Data]
GO

/****** Object:  StoredProcedure [dbo].[temp.ClutchRateRequest]    Script Date: 12/15/2017 4:40:56 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Zoey Chen>
-- Create date: <08/30/2017>
-- Description:	<Create a 2-week temporary table for clutch rate requests.>
-- =============================================
CREATE PROCEDURE [dbo].[temp.ClutchRateRequest]

AS
	-- Add the parameters for the stored procedure here
	declare @startDate date, @endDate date;;

	set @startDate = cast(DATEADD(d, -14, getDate()) as date);
	set @endDate = cast(getDate() as date);

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Drop table if created 
		IF OBJECT_ID('Periscope_Data.dbo.Temp_ClutchRateRequest', 'U') IS NOT NULL
		DROP TABLE Periscope_Data.dbo.Temp_ClutchRateRequest;	

		SELECT case when charindex('\"error\":\"', quoteResponse) <> 0 
														THEN substring(quoteResponse, charindex('\"error\":\"', quoteResponse)+len('\"error\":\"') , charindex('\"', quoteResponse, charindex('\"error\":\"', quoteResponse)+len('\"error\":\"'))-(charindex('\"error\":\"', quoteResponse)+len('\"error\":\"')))
											   WHEN charindex('\"errors\":\"', quoteResponse) <> 0
														THEN substring(quoteResponse, charindex('\"errors\":\"', quoteResponse)+len('\"errors\":\"'), charindex('\"', quoteResponse, charindex('\"errors\":\"', quoteResponse)+len('\"errors\":\"'))-(charindex('\"errors\":\"', quoteResponse)+len('\"errors\":\"'))) 
											   WHEN charindex('\"error\":{\"message\":\"', quoteResponse) <> 0 
														THEN substring(quoteResponse, charindex('\"error\":{\"message\":\"', quoteResponse)+len('\"error\":{\"message\":\"'), charindex('\"', quoteResponse, charindex('\"error\":{\"message\":\"', quoteResponse)+len('\"error\":{\"message\":\"'))-(charindex('\"error\":{\"message\":\"', quoteResponse)+len('\"error\":{\"message\":\"'))) 
											   WHEN charindex('},\"message\":\"', quoteResponse) <> 0 THEN substring(quoteResponse, charindex('},\"message\":\"', quoteResponse)+len('},\"message\":\"'), charindex('\"', quoteResponse, charindex('},\"message\":\"', quoteResponse)+len('},\"message\":\"'))-(charindex('},\"message\":\"', quoteResponse)+len('},\"message\":\"'))) 
											   ELSE NULL END errormessage,
			   policyNum, 
			   substring(clutchURL, charindex('SILVERVINE/', clutchURL) + len('SILVERVINE/'), charindex('/', clutchURL, charindex('SILVERVINE/', clutchURL) + len('SILVERVINE/')) - charindex('SILVERVINE/', clutchURL) - len('SILVERVINE/')) as Program,
			   case 
					when right(clutchURL, 12) = 'minute_quote' then 'MQ'
					when right(clutchURL, 5) = 'quote' then 'FQ'
					when right(clutchURL, 7) = 'endorse' then 'EQ'
					when right(clutchURL, 5) = 'renew' then 'RQ'
				end as Route,
			   jsonDataString, quoteResponse, c.addDate
		INTO Periscope_Data.dbo.Temp_ClutchRateRequest
			FROM Windhaven_Report.maint.ClutchRateRequest c
			LEFT JOIN  Windhaven_Report.dbo.vehicle v on substring(jsondatastring,charindex('vehicleID', jsondatastring) + 12, 6) = cast(v.vehicleID as varchar)
			LEFT JOIN  Windhaven_Report.dbo.policy p on p.policyID = v.policyID
			WHERE 1 = 1
			AND right(clutchURL, 12) <> 'minute_quote'
			AND c.addDate >= @startDate
			AND c.addDate <= @endDate 
END
GO

