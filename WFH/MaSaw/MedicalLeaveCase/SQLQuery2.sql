USE [HOYA_DEV]
GO
/****** Object:  StoredProcedure [dbo].[LeaveCalculationMonthly]    Script Date: 9/2/2020 1:49:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,JinnySaw>
-- Create date: <Create Date,,2017Dec27 2:09 PM>
-- Description:	<Description,,>
-- =============================================
ALTER     PROCEDURE [dbo].[LeaveCalculationMonthly]
	 @FromDate date,@ToDate date,
	 @SearchDate date
AS
BEGIN
		declare @FirstDayofCurrentYear date = ''
	declare @LastDayofPreviousMonth date
	declare @PerviousEndDate date

	declare @fiscalStartDate date;

	declare @checkFiscalStartYear nvarchar(200) = (select FromYear from FiscalYear);
	declare @FiscalStartDay nvarchar(200) = (select FromDay from FiscalYear);
	declare @FiscalStartMonth nvarchar(200) = (select FromMonth from FiscalYear);
	declare @FiscalStartYear int;

	if(@checkFiscalStartYear = 0)
		set @FiscalStartYear = Year(@ToDate) - 1;
	else if(@checkFiscalStartYear = 1)
		set @FiscalStartYear = Year(@ToDate);
	else if(@checkFiscalStartYear = 2)
		set @FiscalStartYear = Year(@ToDate) + 1;

	set @fiscalStartDate = CAST(CAST(@FiscalStartYear AS varchar) + '-' + CAST(@FiscalStartMonth AS varchar) + '-' + CAST(@FiscalStartDay AS varchar) AS DATETIME)
	
	Set @FirstDayofCurrentYear = (SELECT Convert(date, DATEADD(DD,-DATEPART(DY,@FromDate)+1,@FromDate)));
	set @LastDayofPreviousMonth = (SELECT convert(date, DATEADD(s,-1,DATEADD(dd, DATEDIFF(d,0,@FromDate),0))));

    set @PerviousEndDate = (select convert(date,CONVERT(varchar(10), fromMonth) + '-' + convert (varchar(10),fromDay)+'-'+ convert (varchar(10),YEAR(@ToDate)-1) )
	from yeartype);

	--print(@fiscalStartDate);
	--print(@LastDayofPreviousMonth);

	SELECT RIGHTFUL.ID AS EmpID,RIGHTFUL.EmpName,RIGHTFUL.SubsidiaryID,RIGHTFUL.BranchID,Branch.Region As AccessPoint,Department.MainDeptId,RIGHTFUL.DeptID,Department.DeptName,Corporate.ID As CorporateID,
	 RIGHTFUL.CASUAL,
	 RIGHTFUL.EARN, 
	 RIGHTFUL.MEDICAL,
	 RIGHTFUL.MATERNAL,
	 RIGHTFUL.WL, 
	 
	 ISNULL(PREV.PREV_CL,0) PREV_CL,
	 ISNULL(PREV.PREV_EL,0) PREV_EL,
	 ISNULL(PREV.PREV_MEL,0) PREV_MEL,
	 ISNULL(PREV.PREV_ML,0) PREV_ML,
	 ISNULL(PREV.PREV_WL,0) PREV_WL,
	 
	 ISNULL(USED.CL,0) USED_CL,
	 ISNULL(USED.EL,0)USED_EL, 
	 ISNULL(USED.MEL,0) USED_MEL,
	 ISNULL(USED.ML,0) USED_ML,
	 ISNULL(USED.WL,0) USED_WL, 
	 
	 (RIGHTFUL.CASUAL- (ISNULL(USED.CL,0) + ISNULL(PREV.PREV_CL,0) )) AS BAL_CL,
	 (RIGHTFUL.EARN- (ISNULL(USED.EL,0) + ISNULL(PREV.PREV_EL,0))) AS BAL_EL, 
	 (RIGHTFUL.MEDICAL-(ISNULL(USED.MEL,0) + ISNULL(PREV.PREV_MEL,0))) AS BAL_MEL,
	 (RIGHTFUL.MATERNAL-(ISNULL(USED.ML,0) + ISNULL(PREV.PREV_ML,0))) AS BAL_ML,
	 (RIGHTFUL.WL-(ISNULL(USED.WL,0) + ISNULL(PREV.PREV_WL,0))) AS BAL_WL,
	  
	 (RIGHTFUL.CASUAL+RIGHTFUL.MEDICAL+RIGHTFUL.MATERNAL+RIGHTFUL.WL+ISNULL(RIGHTFUL.PARENTAL,0)+RIGHTFUL.EARN) as Total_Leave, 
	 (ISNULL(USED.CL,0)+ISNULL(USED.MEL,0)+ISNULL(USED.ML,0)+ISNULL(USED.WL,0)+ISNULL(USED.PL,0)+ISNULL(USED.EL,0)
	 +ISNULL(PREV.PREV_CL,0)  +
	 ISNULL(PREV.PREV_EL,0)  +
	 ISNULL(PREV.PREV_MEL,0)  +
	 ISNULL(PREV.PREV_ML,0)  +
	 ISNULL(PREV.PREV_WL,0)  
	 ) AS USED_Total, 
	  (RIGHTFUL.CASUAL+RIGHTFUL.MEDICAL+RIGHTFUL.MATERNAL+RIGHTFUL.WL+ISNULL(RIGHTFUL.PARENTAL,0)+RIGHTFUL.EARN)
	  - ((ISNULL(USED.CL,0)+ISNULL(USED.MEL,0)+ISNULL(USED.ML,0)+ISNULL(USED.WL,0)+ISNULL(USED.PL,0)+ISNULL(USED.EL,0)) +
	  +ISNULL(PREV.PREV_CL,0)  +
	 ISNULL(PREV.PREV_EL,0)  +
	 ISNULL(PREV.PREV_MEL,0)  +
	 ISNULL(PREV.PREV_ML,0)  +
	 ISNULL(PREV.PREV_WL,0)
	  )
	   as Bal_Total,
	 (CASE WHEN USED.EmpID IS NULL THEN 'No Leave' ELSE 'Leave Taken' end) as LStatus
	 FROM
	(
	SELECT (CASE WHEN isPermanent = 1 AND DATEDIFF(YEAR,EmployDate, @SearchDate) >= 1 THEN (SELECT LEAVEDAY FROM Leave WHERE ID=1) 
	ELSE (CASE WHEN isPermanent = 1 THEN (SELECT (LeaveDay * (12 - Month(EmployDate) + 1)) / 12 FROM Leave WHERE ID=1) ELSE 0 END) END) AS CASUAL ,

	(CASE WHEN isPermanent = 1 AND DATEDIFF(YEAR, EmployDate, @SearchDate) > 1 THEN (SELECT LEAVEDAY FROM Leave WHERE ID=2) 
	ELSE (CASE WHEN isPermanent = 1 AND DATEDIFF(YEAR,EmployDate, @SearchDate) = 1 THEN (SELECT (LeaveDay * (12 - Month(EmployDate) + 1)) / 12 FROM Leave WHERE ID=2) ELSE 0 END) END) AS EARN ,

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
	 where (er.ResignDate is null or er.ResignDate >= @SearchDate or er.IsDeleted = 1) and
	(ed.DismissionDate is null or ed.DismissionDate >= @SearchDate) and
	Employee.IsDeleted=0
	 ) RIGHTFUL LEFT JOIN
	(
	SELECT EmpID,ISNULL([Casual Leave],0) CL --,ISNULL([Annual Leave],0) AL
	,ISNULL([Medical Leave],0) MEL,ISNULL([Maternal Leave],0) ML,ISNULL([Leave Without Pay],0) WL,ISNULL([Parental Leave],0)PL,ISNULL([Earn Leave],0)EL
	FROM(
	SELECT 
	(CASE WHEN LR.IsHalfDay=0 then
	SUM( DATEDIFF(dd,(CASE WHEN @FromDate > UL.FromDate THEN @FromDate ELSE UL.FromDate   ENd),(CASE WHEN @ToDate < UL.ToDate THEN @ToDate ELSE UL.ToDate END) )+1) 
	ELSE
	SUM( DATEDIFF(dd,(CASE WHEN @FromDate > UL.FromDate THEN @FromDate ELSE UL.FromDate   ENd),(CASE WHEN @ToDate < UL.ToDate THEN @ToDate ELSE UL.ToDate END) )+0.5) end)
	AS LL,L.LeaveName,UL.EmpID
	FROM Used_Leave UL INNER JOIN Leave L
	ON UL.LeaveID=L.ID
	INNER JOIN Leave_Request LR ON LR.ID = UL.LeaveRequestID
	WHERE CONVERT(DATE,UL.FromDate) <=@ToDate AND CONVERT(DATE,UL.ToDate) >= @FromDate
	GROUP BY UL.EmpID,L.LeaveName,LR.isHalfDay) AS LEAVETABLE
	--PIVOT (SUM(LL) FOR LeaveName IN ([Casual Leave],[Annual Leave],[Medical Leave],[Maternal Leave],[Leave Without Pay],[Parental Leave],[Earn Leave])) AS PIVTABLE
	PIVOT (SUM(LL) FOR LeaveName IN ([Casual Leave],[Medical Leave],[Maternal Leave],[Leave Without Pay],[Parental Leave],[Earn Leave])) AS PIVTABLE
	) USED
	ON RIGHTFUL.ID=USED.EmpID 
	lEFT JOIN 
	(
	SELECT EmpID,ISNULL([Casual Leave],0) PREV_CL --,ISNULL([Annual Leave],0) AL
	,ISNULL([Medical Leave],0) PREV_MEL,ISNULL([Maternity Leave],0) PREV_ML,ISNULL([Leave Without Pay],0) PREV_WL,ISNULL([Parental Leave],0)PREV_PL,ISNULL([Earn Leave],0)PREV_EL
	FROM(
	SELECT 
	(CASE WHEN LR.IsHalfDay=0 then
	SUM( DATEDIFF(dd,(CASE WHEN @fiscalStartDate > UL.FromDate THEN @fiscalStartDate ELSE UL.FromDate   ENd),(CASE WHEN @LastDayofPreviousMonth < UL.ToDate THEN @LastDayofPreviousMonth ELSE UL.ToDate END) )+1) 
	ELSE
	SUM( DATEDIFF(dd,(CASE WHEN @fiscalStartDate > UL.FromDate THEN @fiscalStartDate ELSE UL.FromDate   ENd),(CASE WHEN @LastDayofPreviousMonth < UL.ToDate THEN @LastDayofPreviousMonth ELSE UL.ToDate END) )+0.5) end)
	AS LL,L.LeaveName,UL.EmpID
	FROM Used_Leave UL INNER JOIN Leave L
	ON UL.LeaveID=L.ID
	INNER JOIN Leave_Request LR ON LR.ID = UL.LeaveRequestID
	WHERE ((CONVERT(DATE,UL.FromDate) between @fiscalStartDate AND @LastDayofPreviousMonth) or (CONVERT(DATE,UL.ToDate) between @fiscalStartDate AND @LastDayofPreviousMonth))
	GROUP BY UL.EMPID,L.LeaveName,LR.isHalfDay) AS LEAVETABLE
	--PIVOT (SUM(LL) FOR LeaveName IN ([Casual Leave],[Annual Leave],[Medical Leave],[Maternal Leave],[Leave Without Pay],[Parental Leave],[Earn Leave])) AS PIVTABLE
	PIVOT (SUM(LL) FOR LeaveName IN ([Casual Leave],[Medical Leave],[Maternity Leave],[Leave Without Pay],[Parental Leave],[Earn Leave])) AS PIVTABLE
	) PREV
	ON PREV.EMPID= RIGHTFUL.ID
	inner join Department on RIGHTFUL.DeptID = Department.ID
	inner join Branch on RIGHTFUL.BranchID = Branch.ID
	inner join Branch Sub on Branch.MainID = Sub.ID
	inner join Corporate on Sub.Corporate_id = Corporate.ID
END
