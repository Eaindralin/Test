USE [HOYA_DEV]
GO
/****** Object:  StoredProcedure [dbo].[LeaveCalculation]    Script Date: 9/2/2020 1:48:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER     PROCEDURE [dbo].[LeaveCalculation]
	@FromDate date,@ToDate date,
	@SearchDate date
AS
BEGIN

declare @startDate datetime ;
declare @endDate datetime ;
set @startDate = CONVERT(date ,(select (case when FromYear = 0 then CONVERT(varchar(10),Year(GETDATE())) when FromYear = 1 then CONVERT(varchar(10),Year(GETDATE()) + 1) else CONVERT(varchar(10),Year(GETDATE()) - 1) end ) + '-' + CONVERT(varchar(10),FromMonth) + '-' + CONVERT(varchar(10),FromDay) From FiscalYear));
set @endDate = CONVERT(date ,(select (case when ToYear = 0 then CONVERT(varchar(10),Year(GETDATE())) when ToYear = 1 then CONVERT(varchar(10),Year(GETDATE()) + 1) else CONVERT(varchar(10),Year(GETDATE()) - 1) end ) + '-' + CONVERT(varchar(10),ToMonth) + '-' + CONVERT(varchar(10),ToDay) From FiscalYear));

if(GETDATE() NOT between @startDate and @endDate)
begin
 set @startDate = DATEADD(Year,-1,@startDate)
 set @endDate = DATEADD(Year,-1,@endDate)
end

-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SELECT RIGHTFUL.ID AS EmpID,RIGHTFUL.EmpName,RIGHTFUL.SubsidiaryID,RIGHTFUL.BranchID,Branch.Region As AccessPoint,Department.MainDeptId,RIGHTFUL.DeptID,Department.DeptName,Corporate.ID As CorporateID,
 RIGHTFUL.CASUAL,
 RIGHTFUL.EARN,
 --RIGHTFUL.ANNUAL,
 RIGHTFUL.MEDICAL,
 RIGHTFUL.MATERNAL,
 RIGHTFUL.WL,
-- RIGHTFUL.PARENTAL,
 
 ISNULL(USED.CL,0) USED_CL,
 ISNULL(USED.EL,0)USED_EL,
 --ISNULL(USED.AL,0) USED_AL,
 ISNULL(USED.MEL,0) USED_MEL,
 ISNULL(USED.ML,0) USED_ML,
 ISNULL(USED.WL,0) USED_WL,
 --ISNULL(USED.PL,0) USED_PL,
 
 (RIGHTFUL.CASUAL-ISNULL(USED.CL,0)) AS BAL_CL,
 (RIGHTFUL.EARN-ISNULL(USED.EL,0)) AS BAL_EL,
 --(RIGHTFUL.ANNUAL-ISNULL(USED.AL,0)) AS BAL_AL,
 (RIGHTFUL.MEDICAL-ISNULL(USED.MEL,0)) AS BAL_MEL,
 (RIGHTFUL.MATERNAL-ISNULL(USED.ML,0)) AS BAL_ML,
 (RIGHTFUL.WL-ISNULL(USED.WL,0)) AS BAL_WL,
 --(RIGHTFUL.PARENTAL-ISNULL(USED.PL,0)) AS BAL_PL,
 
 --(RIGHTFUL.CASUAL+RIGHTFUL.ANNUAL+RIGHTFUL.MEDICAL+RIGHTFUL.MATERNAL+RIGHTFUL.WL+RIGHTFUL.PARENTAL+RIGHTFUL.EARN) as Total_Leave,
 (RIGHTFUL.CASUAL+RIGHTFUL.MEDICAL+RIGHTFUL.MATERNAL+RIGHTFUL.WL+RIGHTFUL.PARENTAL+RIGHTFUL.EARN) as Total_Leave,
-- (ISNULL(USED.CL,0)+ISNULL(USED.AL,0)+ISNULL(USED.MEL,0)+ISNULL(USED.ML,0)+ISNULL(USED.WL,0)+ISNULL(USED.PL,0)+ISNULL(USED.EL,0)) AS USED_Total,
 (ISNULL(USED.CL,0)+ISNULL(USED.MEL,0)+ISNULL(USED.ML,0)+ISNULL(USED.WL,0)+ISNULL(USED.PL,0)+ISNULL(USED.EL,0)) AS USED_Total,
 --(RIGHTFUL.CASUAL+RIGHTFUL.ANNUAL+RIGHTFUL.MEDICAL+RIGHTFUL.MATERNAL+RIGHTFUL.WL+RIGHTFUL.PARENTAL+RIGHTFUL.EARN)-
  (RIGHTFUL.CASUAL+RIGHTFUL.MEDICAL+RIGHTFUL.MATERNAL+RIGHTFUL.WL+RIGHTFUL.PARENTAL+RIGHTFUL.EARN)-(ISNULL(USED.CL,0)+ISNULL(USED.MEL,0)+ISNULL(USED.ML,0)+ISNULL(USED.WL,0)+ISNULL(USED.PL,0)+ISNULL(USED.EL,0)) as Bal_Total,
 --(ISNULL(USED.CL,0)+ISNULL(USED.AL,0)+ISNULL(USED.MEL,0)+ISNULL(USED.ML,0)+ISNULL(USED.WL,0)+ISNULL(USED.PL,0)+ISNULL(USED.EL,0)) as Bal_Total,
 (CASE WHEN USED.EmpID IS NULL THEN 'No Leave' ELSE 'Leave Taken' end) as LStatus
 FROM
(
 SELECT (CASE WHEN isPermanent = 1 AND DATEDIFF(YEAR,EmployDate, @SearchDate) >= 1 THEN (SELECT LEAVEDAY FROM Leave WHERE ID=1) 
 ELSE (CASE WHEN isPermanent = 1 THEN (SELECT (LeaveDay * (12 - Month(EmployDate) + 1)) / 12 FROM Leave WHERE ID=1) ELSE 0 END) END) AS CASUAL ,

 (CASE WHEN isPermanent = 1 AND DATEDIFF(DAY, EmployDate, @startDate) > 365 AND (DATEADD(year, 1, EmployDate) between @startDate and @endDate) THEN (SELECT (LeaveDay * (12 - Month(EmployDate) + 1)) / 12 FROM Leave WHERE ID=2)
  WHEN isPermanent = 1 AND (DATEADD(year, 1, EmployDate)) <= @startDate THEN (SELECT LEAVEDAY FROM Leave WHERE ID=2) 
 ELSE (CASE WHEN isPermanent = 1 AND DATEDIFF(DAY,EmployDate, @SearchDate) = 365 THEN (SELECT (LeaveDay * (12 - Month(EmployDate) + 1)) / 12 FROM Leave WHERE ID=2) ELSE 0 END) END) AS EARN ,

 --(CASE WHEN isPermanent = 1 AND DATEDIFF(MONTH, EmployDate, @SearchDate) >= 6 THEN (SELECT LEAVEDAY FROM Leave WHERE ID=3) 
 --ELSE (CASE WHEN isPermanent = 1 THEN (SELECT (LeaveDay * (12 - Month(ApprovalDate) + 1)) / 12 FROM Leave WHERE ID=3) ELSE 0 END) END) AS MEDICAL,

 (CASE WHEN isPermanent = 1 AND DATEDIFF(MONTH, EmployDate, @SearchDate) >= 6 THEN (SELECT LEAVEDAY FROM Leave WHERE ID=3) 
  ELSE 0 END) AS MEDICAL,

 (CASE WHEN isPermanent = 1 AND DATEDIFF(YEAR, EmployDate, @SearchDate) >= 1 AND Gender = 0 THEN (SELECT LEAVEDAY FROM Leave WHERE ID=4) ELSE 0 END) AS MATERNAL,

 (CASE WHEN isPermanent = 1 THEN (SELECT LEAVEDAY FROM Leave WHERE ID=5) else 0 end) AS WL,

 (CASE WHEN isPermanent = 1 AND DATEDIFF(YEAR, EmployDate, @SearchDate) >= 1 AND Gender = 1 THEN (SELECT LEAVEDAY FROM Leave WHERE ID=6) ELSE 0 END) AS PARENTAL,
 --(CASE WHEN ISPERMANENT = 1 AND DATEDIFF(YEAR, EmployDate, GETDATE()) >= 1 THEN (SELECT LEAVEDAY FROM Leave WHERE ID=5) ELSE 0 END) AS WL,
 Employee.*
 FROM Employee --where IsActive = 1
  left join Employee_Resign er on Employee.ID = er.EmpID AND er.IsDeleted = 0  
 left join Employee_Dismission ed on Employee.ID = ed.EmployeeID  AND ed.IsDeleted = 0
 where (er.ResignDate is null or year(er.ResignDate) >= year(@SearchDate) or er.IsDeleted = 1) and
(ed.DismissionDate is null or year(ed.DismissionDate) >= year(@SearchDate)) and
Employee.IsDeleted=0
 ) RIGHTFUL LEFT JOIN
(
SELECT EmpID,ISNULL([Casual Leave],0) CL --,ISNULL([Annual Leave],0) AL
,ISNULL([Medical Leave],0) MEL,ISNULL([Maternal Leave],0) ML,ISNULL([Leave Without Pay],0) WL,ISNULL([Parental Leave],0)PL,ISNULL([Earn Leave],0)EL
FROM(
SELECT 
CASE WHEN LR.IsHalfDay=0 then
SUM( DATEDIFF(dd,(CASE WHEN @FromDate > UL.FromDate THEN @FromDate ELSE UL.FromDate   ENd),(CASE WHEN @ToDate < UL.ToDate THEN @ToDate ELSE UL.ToDate END) )+1) 
ELSE
SUM( DATEDIFF(dd,(CASE WHEN @FromDate > UL.FromDate THEN @FromDate ELSE UL.FromDate   ENd),(CASE WHEN @ToDate < UL.ToDate THEN @ToDate ELSE UL.ToDate END) )+0.5) end
AS LL,L.LeaveName,UL.EmpID
FROM Used_Leave UL 
INNER JOIN Leave L ON UL.LeaveID=L.ID
INNER JOIN Leave_Request LR ON LR.ID = UL.LeaveRequestID
WHERE CONVERT(DATE,UL.FromDate) <=@ToDate AND CONVERT(DATE,UL.ToDate) >= @FromDate
GROUP BY UL.EMPID,L.LeaveName,LR.IsHalfDay) AS LEAVETABLE
--PIVOT (SUM(LL) FOR LeaveName IN ([Casual Leave],[Annual Leave],[Medical Leave],[Maternal Leave],[Leave Without Pay],[Parental Leave],[Earn Leave])) AS PIVTABLE
PIVOT (SUM(LL) FOR LeaveName IN ([Casual Leave],[Medical Leave],[Maternal Leave],[Leave Without Pay],[Parental Leave],[Earn Leave])) AS PIVTABLE
) USED
ON RIGHTFUL.ID=USED.EmpID 
inner join Department on RIGHTFUL.DeptID = Department.ID
inner join Branch on RIGHTFUL.BranchID = Branch.ID
inner join Branch Sub on Branch.MainID = Sub.ID
inner join Corporate on Sub.Corporate_id = Corporate.ID
END
