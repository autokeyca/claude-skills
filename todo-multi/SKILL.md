---
name: todo-multi
description: Manage multi-user tasks via SQL Server. Use for task CRUD, assignments, employee management, user onboarding.
---
# Task Management System (PA Database)

**Owner:** Jerry (UserID=1) | **Prefix all queries:** `USE PA;`

## Schema

### Tasks Table

| Column | Type | Description |
|--------|------|-------------|
| TaskID | int | Primary key (identity) |
| TaskDescription | nvarchar | Task text |
| UrgencyLevel | tinyint | 1=High, 2=Med-High, 3=Med-Low, 4=Low |
| DueDate | datetime | When task is due |
| IsCompleted | bit | 0=open, 1=done |
| CompletedAt | datetime | When completed |
| CreatedBy | int | FK→Users.UserID |
| AssignedTo | int | FK→Users.UserID (nullable) |
| AssignedBy | int | FK→Users.UserID (nullable) |
| AssignedAt | datetime | When assigned |
| IsActive | bit | Current focus task |
| Notes | nvarchar | Additional notes |
| Tags | nvarchar | Comma-separated tags |
| CreatedAt | datetime | Auto-set |
| UpdatedAt | datetime | Must update on writes |

### Users Table

| Column | Type | Description |
|--------|------|-------------|
| UserID | int | Primary key (identity) |
| TelegramID | bigint | Telegram user ID (NOT NULL) |
| TelegramUsername | nvarchar | @username |
| FirstName | nvarchar | First name |
| LastName | nvarchar | Last name |
| DisplayName | nvarchar | Display name |
| Email | nvarchar | Email address |
| Role | nvarchar | 'user', 'admin', 'manager' (default: 'user') |
| Status | nvarchar | 'pending', 'active', 'inactive' (default: 'pending') |
| RequestedAt | datetime | When access requested |
| ApprovedAt | datetime | When approved |
| ApprovedBy | int | FK→Users.UserID |
| LastActiveAt | datetime | Last activity |
| Notes | nvarchar | Position/notes (e.g., "Position: Office Manager") |
| NotificationPreferences | nvarchar | JSON preferences |
| CreatedAt | datetime | Auto-set |
| UpdatedAt | datetime | Must update on writes |

## Urgency Levels

| Level | Emoji | Name |
|-------|-------|------|
| 1 | 🔴 | High |
| 2 | 🟠 | Medium-High (default) |
| 3 | 🟡 | Medium-Low |
| 4 | 🟢 | Low |

---

## Task Operations

### Base Read Template

All task reads use this pattern—just swap `{WHERE}`:
```sql
USE PA;
SELECT t.TaskID, t.TaskDescription, t.UrgencyLevel, t.DueDate, t.IsActive,
       c.DisplayName AS CreatedBy, a.DisplayName AS AssignedTo
FROM Tasks t
JOIN Users c ON t.CreatedBy = c.UserID
LEFT JOIN Users a ON t.AssignedTo = a.UserID
WHERE {WHERE}
ORDER BY t.IsActive DESC, t.UrgencyLevel, t.DueDate
```

### Common WHERE Clauses

| Read | WHERE clause |
|------|--------------|
| All incomplete | `t.IsCompleted=0` |
| Active tasks only | `t.IsActive=1 AND t.IsCompleted=0` |
| Jerry's tasks | `t.IsCompleted=0 AND (t.CreatedBy=1 OR t.AssignedTo=1)` |
| Employee's tasks | `t.IsCompleted=0 AND t.AssignedTo=@EmpID` |
| Completed | `t.IsCompleted=1` *(order by CompletedAt DESC)* |
| Overdue | `t.IsCompleted=0 AND t.DueDate<GETDATE()` |
| Due today | `t.IsCompleted=0 AND CAST(t.DueDate AS DATE)=CAST(GETDATE() AS DATE)` |
| High priority | `t.IsCompleted=0 AND t.UrgencyLevel=1` |

### Create Task

**Personal task:**
```sql
USE PA;
INSERT INTO Tasks (TaskDescription, UrgencyLevel, DueDate, CreatedBy, UpdatedAt)
VALUES (@desc, 2, @due, 1, GETDATE());
SELECT SCOPE_IDENTITY() AS TaskID;
```

**Assigned task:**
```sql
USE PA;
INSERT INTO Tasks (TaskDescription, UrgencyLevel, DueDate, CreatedBy, AssignedTo, AssignedBy, AssignedAt, UpdatedAt)
VALUES (@desc, 2, @due, 1, @toUserID, 1, GETDATE(), GETDATE());
SELECT SCOPE_IDENTITY() AS TaskID;
```

### Complete Task(s)

**Single:**
```sql
USE PA;
UPDATE Tasks SET IsCompleted=1, CompletedAt=GETDATE(), UpdatedAt=GETDATE()
WHERE TaskID=@id AND (CreatedBy=1 OR AssignedTo=1);
```

**Multiple (batch):**
```sql
USE PA;
UPDATE Tasks SET IsCompleted=1, CompletedAt=GETDATE(), UpdatedAt=GETDATE()
WHERE TaskID IN (@id1, @id2, @id3) AND (CreatedBy=1 OR AssignedTo=1);
```

### Manage Active Tasks

**Multiple tasks can be active simultaneously.** Use toggle operations:

**Activate a task:**
```sql
USE PA;
UPDATE Tasks SET IsActive=1, UpdatedAt=GETDATE()
WHERE TaskID=@id AND (CreatedBy=1 OR AssignedTo=1) AND IsCompleted=0;
```

**Deactivate a task:**
```sql
USE PA;
UPDATE Tasks SET IsActive=0, UpdatedAt=GETDATE()
WHERE TaskID=@id AND (CreatedBy=1 OR AssignedTo=1);
```

**Toggle task active status:**
```sql
USE PA;
-- Check current status first
SELECT IsActive FROM Tasks WHERE TaskID=@id;
-- Then toggle
UPDATE Tasks SET IsActive=CASE WHEN IsActive=1 THEN 0 ELSE 1 END, UpdatedAt=GETDATE()
WHERE TaskID=@id AND (CreatedBy=1 OR AssignedTo=1);
```

**Get all active tasks grouped by assignee:**
```sql
USE PA;
SELECT t.TaskID, t.TaskDescription, t.UrgencyLevel, t.DueDate,
       c.DisplayName AS CreatedBy,
       COALESCE(a.DisplayName, 'Unassigned') AS AssignedTo
FROM Tasks t
JOIN Users c ON t.CreatedBy = c.UserID
LEFT JOIN Users a ON t.AssignedTo = a.UserID
WHERE t.IsActive=1 AND t.IsCompleted=0
ORDER BY a.DisplayName, t.UrgencyLevel, t.DueDate;
```

### Assign Task

```sql
USE PA;
UPDATE Tasks
SET AssignedTo=@toUserID, AssignedBy=1, AssignedAt=GETDATE(), UpdatedAt=GETDATE()
WHERE TaskID=@id AND CreatedBy=1;
```

### Update Task

```sql
USE PA;
UPDATE Tasks
SET TaskDescription=@desc, UrgencyLevel=@urg, DueDate=@due, Notes=@notes, UpdatedAt=GETDATE()
WHERE TaskID=@id;
```

### Delete Task(s)

**Single:**
```sql
USE PA;
DELETE FROM Tasks WHERE TaskID=@id AND CreatedBy=1;
```

**Multiple (batch):**
```sql
USE PA;
DELETE FROM Tasks WHERE TaskID IN (@id1, @id2, @id3) AND CreatedBy=1;
```

---

## User Operations

### List Users

**All active users:**
```sql
USE PA;
SELECT UserID, DisplayName, Email, Role, Notes
FROM Users WHERE Status='active'
ORDER BY DisplayName;
```

**Pending approval:**
```sql
USE PA;
SELECT UserID, DisplayName, TelegramUsername, Email, Notes, RequestedAt
FROM Users WHERE Status='pending'
ORDER BY RequestedAt;
```

### Find User

**By name (partial match):**
```sql
USE PA;
SELECT UserID, DisplayName, Email, Role
FROM Users WHERE LOWER(DisplayName) LIKE LOWER('%@name%') AND Status='active';
```

**By TelegramID:**
```sql
USE PA;
SELECT UserID, DisplayName, TelegramID, Status, Role, Email
FROM Users WHERE TelegramID=@telegramId;
```

### Add User

**Quick add (for manual team member creation):**
```sql
USE PA;
INSERT INTO Users (DisplayName, TelegramID, Email, Role, FirstName, LastName, Status, UpdatedAt)
VALUES (@name, @telegramId, @email, 'user', @firstName, @lastName, 'active', GETDATE());
SELECT SCOPE_IDENTITY() AS UserID;
```

Note: Use negative TelegramID for users who don't use Telegram directly.

### Onboarding (Pending User)

**Create pending request:**
```sql
USE PA;
INSERT INTO Users (TelegramID, TelegramUsername, FirstName, LastName, DisplayName, Role, Status, RequestedAt)
VALUES (@telegramId, @username, @firstName, @lastName, @displayName, 'user', 'pending', GETDATE());
SELECT SCOPE_IDENTITY() AS UserID;
```

**Approve user:**
```sql
USE PA;
UPDATE Users
SET Status='active', ApprovedAt=GETDATE(), ApprovedBy=1, UpdatedAt=GETDATE()
WHERE UserID=@id AND Status='pending';
```

**Reject user (delete):**
```sql
USE PA;
DELETE FROM Users WHERE UserID=@id AND Status='pending';
```

---

## Team Summary

**Tasks per team member:**
```sql
USE PA;
SELECT COALESCE(u.DisplayName, 'Unassigned') AS Assignee, COUNT(*) AS TaskCount
FROM Tasks t
LEFT JOIN Users u ON t.AssignedTo = u.UserID
WHERE t.IsCompleted=0 AND t.CreatedBy=1
GROUP BY u.DisplayName
ORDER BY TaskCount DESC;
```

**Get specific user's tasks:**
```sql
USE PA;
SELECT t.TaskID, t.TaskDescription, t.UrgencyLevel, t.DueDate
FROM Tasks t
WHERE t.IsCompleted=0 AND t.AssignedTo=@userID
ORDER BY t.UrgencyLevel, t.DueDate;
```

---

## Rules

1. **Always `USE PA;`** prefix on all queries
2. **JOIN for DisplayName** — never expose raw UserIDs to users
3. **Always set `UpdatedAt=GETDATE()`** on all writes
4. **Multiple active tasks** allowed per user (use toggle operations)
5. **Owner (Jerry) sees all** — others see only own/assigned
6. **Check Status='active'** when looking up users for assignment
7. **Batch operations** — use `IN (@id1, @id2, ...)` for multiple IDs

## Extended Reference

- `reference/reports.md` — Stats, workload, completion analytics
- `reference/user-management.md` — Full onboarding flow, permissions
