/*
################################################
# TEAM CASELOAD: DAYS SINCE LATEST APPOINTMENT #
################################################

Takes two variables @team_name & @attended_flag
Set these at the top. See below for details of what 
they do. 

Overall scripts gives you all of a team's open cases 
with the most recent appointment and how long ago that
appointment was in days. 

*/

--- Declare what team(s) you want to include
--- Note that team name in script is in the form 
--- '%@team_name%'. 
DECLARE @team_name NVARCHAR(100) = 'DN';

--- Include: 
--- attended appointments only = 1
--- any appointment (inc DNA, cancel etc) = 0
DECLARE @attended_flag BIT = 0;

WITH RankedAppointments AS (
    SELECT 
        r.pasid,
        r.ReferralNumber,
        r.TeamReferredToDescription,
        a.AppointmentDate,
		a.OutcomeGrouped,
        ROW_NUMBER() OVER (
            PARTITION BY r.pasid, r.ReferralNumber
            ORDER BY a.AppointmentDate DESC
        ) AS 'row_number',
		GETDATE() AS 'report_date' ,
		DATEDIFF(DAY,a.AppointmentDate,GETDATE()) AS days_between
    FROM BI_Reporting.dbo.tbl_Referral AS r
    LEFT JOIN BI_Reporting.dbo.tbl_Appointment AS a
        ON r.PASID = a.PASID
        AND r.ReferralNumber = a.ReferralNumber
    WHERE 
		a.AppointmentDate <= GETDATE()
		AND r.TeamReferredToDescription LIKE '%' + @team_name + '%'
		AND r.ReferralDischargedDate IS NULL
		AND (
            @attended_flag = 0 -- include all if flag is 0
			OR (@attended_flag = 1 AND a.OutcomeGrouped = '1.Attended')
        )
)
SELECT 
    pasid,
    ReferralNumber,
    TeamReferredToDescription,
    AppointmentDate,
	OutcomeGrouped,
	report_date,
	days_between
FROM RankedAppointments
WHERE row_number = 1;

