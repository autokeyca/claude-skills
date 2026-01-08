# Todo-Multi: Multi-User Task Management

A comprehensive task management system with team collaboration, Telegram bot integration, and SQL Server backend.

## Features

### Task Management
- Create, update, complete, and delete tasks
- Urgency levels (High/Medium-High/Medium-Low/Low)
- Due date tracking with overdue detection
- Active task designation (focus mode)
- Batch operations (complete/delete multiple tasks at once)
- Task assignment to team members

### Team Management
- User onboarding with approval workflow
- Role-based access (owner/admin/manager/user)
- Email and position tracking
- Telegram integration for notifications

### Reports & Analytics
- Task summary by team member
- Overdue analysis
- Completion history
- Workload distribution

## Architecture

```
                    ┌──────────────────┐
                    │   Elle Bot       │
                    │   (Telegram)     │
                    └────────┬─────────┘
                             │
         ┌───────────────────┼───────────────────┐
         │                   │                   │
         ▼                   ▼                   ▼
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│  Task Commands  │ │  Team Commands  │ │  Claude Code    │
│  (zero tokens)  │ │  (zero tokens)  │ │  (full context) │
└────────┬────────┘ └────────┬────────┘ └────────┬────────┘
         │                   │                   │
         └───────────────────┼───────────────────┘
                             │
                             ▼
                    ┌──────────────────┐
                    │   SQL Server     │
                    │   (PA Database)  │
                    └──────────────────┘
```

## Setup

### Prerequisites

1. SQL Server with PA database
2. MSSQL MCP server configured
3. For Telegram bot: Elle Bot running

### Database Tables

```sql
-- Tasks: Core task data
CREATE TABLE Tasks (
    TaskID INT IDENTITY PRIMARY KEY,
    TaskDescription NVARCHAR(500),
    UrgencyLevel TINYINT DEFAULT 2,
    DueDate DATETIME,
    IsCompleted BIT DEFAULT 0,
    CompletedAt DATETIME,
    CreatedBy INT FOREIGN KEY REFERENCES Users(UserID),
    AssignedTo INT FOREIGN KEY REFERENCES Users(UserID),
    AssignedBy INT FOREIGN KEY REFERENCES Users(UserID),
    AssignedAt DATETIME,
    IsActive BIT DEFAULT 0,
    Notes NVARCHAR(MAX),
    Tags NVARCHAR(500),
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

-- Users: Team members
CREATE TABLE Users (
    UserID INT IDENTITY PRIMARY KEY,
    TelegramID BIGINT NOT NULL,
    TelegramUsername NVARCHAR(100),
    FirstName NVARCHAR(100),
    LastName NVARCHAR(100),
    DisplayName NVARCHAR(200),
    Email NVARCHAR(200),
    Role NVARCHAR(20) DEFAULT 'user',
    Status NVARCHAR(20) DEFAULT 'pending',
    RequestedAt DATETIME DEFAULT GETDATE(),
    ApprovedAt DATETIME,
    ApprovedBy INT,
    LastActiveAt DATETIME,
    Notes NVARCHAR(MAX),
    NotificationPreferences NVARCHAR(MAX),
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);
```

## File Structure

```
todo-multi/
├── SKILL.md                    # Primary reference (auto-loads)
├── README.md                   # This file
└── reference/
    ├── reports.md              # Stats & analytics queries
    └── user-management.md      # Onboarding & permissions
```

## Token Efficiency

| Scenario | Files Loaded | ~Tokens |
|----------|--------------|---------|
| Task CRUD | SKILL.md | ~500 |
| Team operations | SKILL.md | ~500 |
| Reports/Stats | + reports.md | ~700 |
| User management | + user-management.md | ~750 |

SKILL.md is self-sufficient for 90% of operations.

## Elle Bot Commands

### Task Commands (Zero-Token - Direct SQL)

| Command | Description |
|---------|-------------|
| `/tasks` | List all open tasks |
| `/task add <desc>` | Create new task |
| `/task done <id>` | Complete task(s) - comma-separated |
| `/task delete <id>` | Delete task(s) - comma-separated |
| `/task active <id>` | Set active/focus task |
| `/task today` | Tasks due today |
| `/task overdue` | Overdue tasks |
| `/task assign <id> <name>` | Assign to team member |
| `/task team [name]` | Team task summary |

### Team Commands (Zero-Token - Direct SQL)

| Command | Description |
|---------|-------------|
| `/team` | List team members |
| `/team add <name> [options]` | Add team member |
| `/team pending` | View pending approvals |
| `/team approve <id>` | Approve access request |
| `/team reject <id>` | Reject access request |

**Add Options:**
```
/team add Sarah Smith email:sarah@co.com role:manager first:Sarah last:Smith
```

### User Onboarding Flow

1. New user sends `/start`
2. Bot asks for: Full name, Email, Role/Position
3. Creates pending request, notifies admin
4. Admin approves/rejects via `/team approve|reject <id>`
5. User is notified of approval

## Quick Reference

### Urgency Levels

| Level | Emoji | Name |
|-------|-------|------|
| 1 | 🔴 | High |
| 2 | 🟠 | Medium-High (default) |
| 3 | 🟡 | Medium-Low |
| 4 | 🟢 | Low |

### User Roles

| Role | Description |
|------|-------------|
| owner | Full access (Jerry) |
| admin | Manage users, view all |
| manager | Manage team tasks |
| user | Own tasks only |

### User Status

| Status | Description |
|--------|-------------|
| pending | Awaiting approval |
| active | Full access |
| inactive | Disabled account |

## Owner

Jerry (UserID=1, TelegramID=858441656) has full administrative access.
