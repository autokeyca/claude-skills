# User Management & Onboarding

Extended reference for user lifecycle, permissions, and Telegram bot integration.

## User Status Flow

```
[New User] --/start--> [pending] --approve--> [active]
                           |
                           +--reject--> [deleted]

[Active User] --deactivate--> [inactive]
```

## Telegram Bot Onboarding

When a new user sends `/start` to the Elle Bot:

1. Bot collects: full name, email, role/position
2. Creates user with `Status='pending'`
3. Stores position in `Notes` field
4. Notifies admin (Jerry) with approve/reject options
5. On approval, user is notified and can access the system

### Onboarding Queries

**Check if user exists:**
```sql
USE PA;
SELECT UserID, DisplayName, Status, Role
FROM Users WHERE TelegramID = @telegramId;
```

**Create pending user (from onboarding):**
```sql
USE PA;
INSERT INTO Users (
    TelegramID, TelegramUsername, FirstName, LastName,
    DisplayName, Email, Role, Status, Notes, RequestedAt
)
VALUES (
    @telegramId, @username, @firstName, @lastName,
    @displayName, @email, 'user', 'pending', 'Position: ' + @position, GETDATE()
);
SELECT SCOPE_IDENTITY() AS UserID;
```

**Approve with notification lookup:**
```sql
USE PA;
-- Approve
UPDATE Users
SET Status='active', ApprovedAt=GETDATE(), ApprovedBy=1, UpdatedAt=GETDATE()
WHERE UserID=@id AND Status='pending';

-- Get TelegramID for notification
SELECT TelegramID FROM Users WHERE UserID=@id;
```

**Reject (delete pending):**
```sql
USE PA;
DELETE FROM Users WHERE UserID=@id AND Status='pending';
```

## Manual User Creation

For adding team members who may not use Telegram:

```sql
USE PA;
-- Use negative TelegramID as placeholder
DECLARE @placeholderId BIGINT;
SELECT @placeholderId = ISNULL(MIN(TelegramID), 0) - 1 FROM Users WHERE TelegramID < 0;

INSERT INTO Users (
    DisplayName, TelegramID, Email, Role, FirstName, LastName,
    Status, Notes, UpdatedAt
)
VALUES (
    @displayName, @placeholderId, @email, 'user', @firstName, @lastName,
    'active', 'Position: ' + @position, GETDATE()
);
SELECT SCOPE_IDENTITY() AS UserID;
```

## Permission Matrix

| Role | Create Tasks | Assign | View | Complete | Manage Users |
|------|--------------|--------|------|----------|--------------|
| owner (Jerry) | All | Anyone | All | Any | Full |
| admin | Own | Users | Own + assigned | Own | View only |
| manager | Own | Team | Own + team | Own + team | View team |
| user | Own | No | Own + assigned | Own | No |

## User Queries

**List by role:**
```sql
USE PA;
SELECT UserID, DisplayName, Email, Role, Notes
FROM Users
WHERE Status='active' AND Role=@role
ORDER BY DisplayName;
```

**Team members with task counts:**
```sql
USE PA;
SELECT u.UserID, u.DisplayName, u.Email, u.Notes,
       COUNT(t.TaskID) AS OpenTasks
FROM Users u
LEFT JOIN Tasks t ON u.UserID = t.AssignedTo AND t.IsCompleted = 0
WHERE u.Status = 'active'
GROUP BY u.UserID, u.DisplayName, u.Email, u.Notes
ORDER BY OpenTasks DESC;
```

**Recently active users:**
```sql
USE PA;
SELECT UserID, DisplayName, LastActiveAt
FROM Users
WHERE Status='active' AND LastActiveAt >= DATEADD(day, -7, GETDATE())
ORDER BY LastActiveAt DESC;
```

**Update last active:**
```sql
USE PA;
UPDATE Users SET LastActiveAt = GETDATE() WHERE TelegramID = @telegramId;
```

## Deactivation

**Deactivate user (keeps history):**
```sql
USE PA;
UPDATE Users SET Status='inactive', UpdatedAt=GETDATE() WHERE UserID=@id;
```

**Reassign tasks before deactivation:**
```sql
USE PA;
UPDATE Tasks
SET AssignedTo=@newUserId, AssignedBy=1, AssignedAt=GETDATE(), UpdatedAt=GETDATE()
WHERE AssignedTo=@oldUserId AND IsCompleted=0;
```

## Admin Check

**Is user admin (Jerry):**
```sql
-- Jerry's TelegramID: 858441656
-- Check in code: telegram_id == 858441656
```

Or environment variable: `TELEGRAM_ADMIN_ID=858441656`
