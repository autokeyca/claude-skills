# Reports & Statistics

Advanced queries for analysis. Load only when user asks for stats/reports.

## Quick Stats

**Overall summary:**
```sql
USE PA;
SELECT
    (SELECT COUNT(*) FROM Tasks WHERE IsCompleted=0) AS OpenTasks,
    (SELECT COUNT(*) FROM Tasks WHERE IsCompleted=0 AND DueDate<GETDATE()) AS Overdue,
    (SELECT COUNT(*) FROM Tasks WHERE IsCompleted=0 AND UrgencyLevel=1) AS HighPriority,
    (SELECT COUNT(*) FROM Tasks WHERE IsCompleted=1 AND CompletedAt>=DATEADD(day,-7,GETDATE())) AS CompletedThisWeek,
    (SELECT COUNT(*) FROM Users WHERE Status='active') AS ActiveUsers,
    (SELECT COUNT(*) FROM Users WHERE Status='pending') AS PendingApprovals;
```

## Daily Summary

**Jerry's incomplete tasks:**
```sql
USE PA;
SELECT TaskID, TaskDescription, UrgencyLevel, DueDate, IsActive
FROM Tasks
WHERE CreatedBy=1 AND IsCompleted=0
ORDER BY IsActive DESC, UrgencyLevel, DueDate;
```

**Tasks Jerry assigned to others:**
```sql
USE PA;
SELECT t.TaskID, t.TaskDescription, u.DisplayName AS AssignedTo, t.DueDate, t.UrgencyLevel
FROM Tasks t
JOIN Users u ON t.AssignedTo = u.UserID
WHERE t.AssignedBy=1 AND t.IsCompleted=0
ORDER BY t.DueDate;
```

**Active task:**
```sql
USE PA;
SELECT t.TaskID, t.TaskDescription, t.DueDate
FROM Tasks t
WHERE t.IsActive=1 AND t.IsCompleted=0 AND (t.CreatedBy=1 OR t.AssignedTo=1);
```

## Team Analytics

**Tasks per team member:**
```sql
USE PA;
SELECT u.DisplayName, COUNT(*) AS Tasks,
    SUM(CASE WHEN t.UrgencyLevel=1 THEN 1 ELSE 0 END) AS High,
    SUM(CASE WHEN t.DueDate<GETDATE() THEN 1 ELSE 0 END) AS Overdue
FROM Tasks t
JOIN Users u ON t.AssignedTo = u.UserID
WHERE t.IsCompleted=0
GROUP BY u.DisplayName
ORDER BY Tasks DESC;
```

**Workload distribution by urgency:**
```sql
USE PA;
SELECT u.DisplayName,
    SUM(CASE WHEN t.UrgencyLevel=1 THEN 1 ELSE 0 END) AS High,
    SUM(CASE WHEN t.UrgencyLevel=2 THEN 1 ELSE 0 END) AS MedHigh,
    SUM(CASE WHEN t.UrgencyLevel=3 THEN 1 ELSE 0 END) AS MedLow,
    SUM(CASE WHEN t.UrgencyLevel=4 THEN 1 ELSE 0 END) AS Low,
    COUNT(*) AS Total
FROM Tasks t
JOIN Users u ON t.AssignedTo = u.UserID
WHERE t.IsCompleted=0
GROUP BY u.DisplayName
ORDER BY Total DESC;
```

**Unassigned tasks:**
```sql
USE PA;
SELECT TaskID, TaskDescription, UrgencyLevel, DueDate
FROM Tasks
WHERE IsCompleted=0 AND AssignedTo IS NULL
ORDER BY UrgencyLevel, DueDate;
```

## Overdue Analysis

**Overdue with days count:**
```sql
USE PA;
SELECT t.TaskID, t.TaskDescription,
    c.DisplayName AS CreatedBy, a.DisplayName AS AssignedTo,
    t.DueDate, DATEDIFF(day, t.DueDate, GETDATE()) AS DaysOverdue
FROM Tasks t
JOIN Users c ON t.CreatedBy = c.UserID
LEFT JOIN Users a ON t.AssignedTo = a.UserID
WHERE t.IsCompleted=0 AND t.DueDate < GETDATE()
ORDER BY DaysOverdue DESC;
```

**Overdue by assignee:**
```sql
USE PA;
SELECT COALESCE(u.DisplayName, 'Unassigned') AS Assignee,
    COUNT(*) AS OverdueTasks,
    MAX(DATEDIFF(day, t.DueDate, GETDATE())) AS MostOverdueDays
FROM Tasks t
LEFT JOIN Users u ON t.AssignedTo = u.UserID
WHERE t.IsCompleted=0 AND t.DueDate < GETDATE()
GROUP BY u.DisplayName
ORDER BY OverdueTasks DESC;
```

## Completion History

**Recently completed (7 days):**
```sql
USE PA;
SELECT t.TaskID, t.TaskDescription, t.CompletedAt,
    c.DisplayName AS CreatedBy, a.DisplayName AS CompletedBy
FROM Tasks t
JOIN Users c ON t.CreatedBy = c.UserID
LEFT JOIN Users a ON t.AssignedTo = a.UserID
WHERE t.IsCompleted=1 AND t.CompletedAt >= DATEADD(day, -7, GETDATE())
ORDER BY t.CompletedAt DESC;
```

**Completion rate by week:**
```sql
USE PA;
SELECT
    DATEPART(year, CompletedAt) AS Year,
    DATEPART(week, CompletedAt) AS Week,
    COUNT(*) AS Completed
FROM Tasks
WHERE IsCompleted=1 AND CompletedAt >= DATEADD(month, -3, GETDATE())
GROUP BY DATEPART(year, CompletedAt), DATEPART(week, CompletedAt)
ORDER BY Year DESC, Week DESC;
```

**Average time to complete (last 30 days):**
```sql
USE PA;
SELECT AVG(DATEDIFF(hour, CreatedAt, CompletedAt)) AS AvgHoursToComplete
FROM Tasks
WHERE IsCompleted=1 AND CompletedAt >= DATEADD(day, -30, GETDATE());
```

## Due Date Analysis

**Tasks due this week:**
```sql
USE PA;
SELECT t.TaskID, t.TaskDescription, t.UrgencyLevel, t.DueDate,
    COALESCE(a.DisplayName, 'Unassigned') AS AssignedTo
FROM Tasks t
LEFT JOIN Users a ON t.AssignedTo = a.UserID
WHERE t.IsCompleted=0
    AND t.DueDate >= CAST(GETDATE() AS DATE)
    AND t.DueDate < DATEADD(day, 7, CAST(GETDATE() AS DATE))
ORDER BY t.DueDate, t.UrgencyLevel;
```

**Tasks with no due date:**
```sql
USE PA;
SELECT TaskID, TaskDescription, UrgencyLevel, CreatedAt
FROM Tasks
WHERE IsCompleted=0 AND DueDate IS NULL
ORDER BY UrgencyLevel, CreatedAt;
```

## Permission Matrix Reference

| Role | Create | Assign | View | Complete |
|------|--------|--------|------|----------|
| owner | Yes | Anyone | All | Any |
| admin | Yes | Users | Own/assigned | Own |
| manager | Yes | Team | Own/team | Own/team |
| user | Yes | No | Own/assigned | Own |
