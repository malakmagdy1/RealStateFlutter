# Subscription Display - Visual Guide

## 1. Mobile Profile Screen

### Location
**Profile Tab → Subscription Section (Top of Content)**

```
┌─────────────────────────────────────┐
│  Profile & Settings                 │
├─────────────────────────────────────┤
│                                     │
│        [User Avatar]                │
│        John Doe                     │
│     john@email.com                  │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  ╔═══════════════════════════════╗ │
│  ║ ⭐ Subscription Plan  [Active]║ │
│  ║                               ║ │
│  ║      Plus / بلس               ║ │
│  ║                               ║ │
│  ║  🔍 Unlimited searches        ║ │
│  ║                               ║ │
│  ║  [Manage Subscription]        ║ │
│  ╚═══════════════════════════════╝ │
│                                     │
├─────────────────────────────────────┤
│  👤 Personal Information            │
│  🔒 Security                        │
│  ⚙️  Preferences                    │
└─────────────────────────────────────┘
```

### For Free Plan with Limited Searches
```
┌─────────────────────────────────────┐
│  ╔═══════════════════════════════╗ │
│  ║ ⭐ Subscription Plan [Active] ║ │
│  ║                               ║ │
│  ║      Free / مجانية            ║ │
│  ║                               ║ │
│  ║  🔍 Searches: 3/5             ║ │
│  ║  [███████░░] 60%              ║ │
│  ║                               ║ │
│  ║  📅 Expires: 2025-12-03       ║ │
│  ║                               ║ │
│  ║  [Manage Subscription]        ║ │
│  ╚═══════════════════════════════╝ │
└─────────────────────────────────────┘
```

## 2. Web Profile Screen

### Location
**Profile → Right Column (Top)**

```
┌────────────────────────────────────────────────────────────────┐
│  [User Avatar] John Doe                                        │
│                john.doe@email.com                              │
│                ✅ Verified Account                             │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  ┌──────────────────────┐  ┌──────────────────────────────┐  │
│  │ 👤 Personal Info     │  │ 🏆 Subscription Plan [Active]│  │
│  │                      │  │                              │  │
│  │  • Edit Name         │  │  ┌────────────────────────┐ │  │
│  │  • Edit Phone        │  │  │      Plus              │ │  │
│  │  • Email Address     │  │  │      بلس               │ │  │
│  │                      │  │  ├────────────────────────┤ │  │
│  └──────────────────────┘  │  │ 🔍 Search Quota:       │ │  │
│                             │  │    Unlimited searches  │ │  │
│  ┌──────────────────────┐  │  │                        │ │  │
│  │ 🔒 Security          │  │  └────────────────────────┘ │  │
│  │                      │  │                              │  │
│  │  • Change Password   │  │  [Manage Subscription]       │  │
│  │  • 2FA               │  └──────────────────────────────┘  │
│  │                      │                                     │
│  └──────────────────────┘  ┌──────────────────────────────┐  │
│                             │ ⚙️  Preferences              │  │
│                             │                              │  │
│                             │  • Language                  │  │
│                             │  • Theme                     │  │
│                             │  • Notifications             │  │
│                             └──────────────────────────────┘  │
└────────────────────────────────────────────────────────────────┘
```

### For Limited Plan
```
┌──────────────────────────────────┐
│ 🏆 Subscription Plan [Active]    │
│                                  │
│  ┌────────────────────────────┐ │
│  │      Free Plan             │ │
│  │      مجانية                │ │
│  ├────────────────────────────┤ │
│  │ 🔍 Search Quota:           │ │
│  │    3 / 5 searches          │ │
│  │    [███████░░] 60%         │ │
│  │    2 searches remaining    │ │
│  │                            │ │
│  │ 📅 Expires On:             │ │
│  │    2025-12-03             │ │
│  └────────────────────────────┘ │
│                                  │
│  [Manage Subscription]           │
└──────────────────────────────────┘
```

## 3. Login Flow - Subscription Dialog

### After Successful Login (Both Mobile & Web)

```
┌─────────────────────────────────────┐
│  ℹ️  Choose Your Plan              │
├─────────────────────────────────────┤
│                                     │
│  You don't have an active          │
│  subscription yet. Choose a plan    │
│  to unlock unlimited searches and   │
│  premium features!                  │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  [Maybe Later]    [View Plans]     │
│                                     │
└─────────────────────────────────────┘
```

### For Active Subscription

```
┌─────────────────────────────────────┐
│  ✅ Active Subscription             │
├─────────────────────────────────────┤
│                                     │
│  Plan: Plus                         │
│                                     │
│  ┌───────────────────────────────┐ │
│  │ 🔍 Unlimited searches         │ │
│  └───────────────────────────────┘ │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  [Continue]        [Upgrade Plan]  │
│                                     │
└─────────────────────────────────────┘
```

## 4. Design Elements

### Color Scheme

**Mobile:**
- **Active Badge**: Green background, white text
- **Inactive Badge**: Orange background, white text
- **Card Background**: Gradient from main color (10% opacity) to (5% opacity)
- **Border**: Main color (30% opacity)
- **Progress Bar**: Main color when searches available, red when depleted
- **Button**: Main color with white text

**Web:**
- **Active Badge**: Green with shadow effect
- **Inactive Badge**: Orange with shadow effect
- **Card Background**: White with premium gradient border
- **Section Background**: Main color gradient (5% to 2% opacity)
- **Progress Bar**: Main color gradient
- **Button**: Main color gradient with shadow

### Icons Used

- ⭐ / 🏆 - Subscription Plan header
- 🔍 - Search quota
- 📅 - Expiration date
- ⬆️ - Manage/Upgrade button
- ✅ - Active status
- ⚠️ - Inactive status

### Typography

**Mobile:**
- Plan Name: 24px, Bold
- Search Info: 14px, Regular
- Badge: 12px, SemiBold
- Button: 16px, SemiBold

**Web:**
- Plan Name: 28px, Bold
- Section Title: 20px, Bold
- Search Info: 18px, SemiBold
- Details: 16px, Regular
- Button: 16px, SemiBold

## 5. States to Display

### State 1: Active Unlimited Plan
```
Plan: Plus / Premium / Pro
Searches: Unlimited
Status: Active ✅
Actions: Manage Subscription
```

### State 2: Active Limited Plan (Searches Available)
```
Plan: Free / Basic
Searches: 3/5 (2 remaining)
Progress: [███████░░] 60%
Status: Active ✅
Expires: 2025-12-03
Actions: Manage Subscription
```

### State 3: Active Limited Plan (No Searches Left)
```
Plan: Free / Basic
Searches: 5/5 (0 remaining)
Progress: [██████████] 100% (Red)
Status: Active ⚠️ (No searches)
Expires: 2025-12-03
Actions: Upgrade Now!
```

### State 4: Expired Plan
```
Plan: Free / Basic
Status: Inactive ⚠️
Message: Subscription expired
Actions: Renew Subscription
```

### State 5: Loading
```
[Loading spinner]
Checking subscription...
```

### State 6: Error
```
Unable to load subscription info
[Retry button]
```

## 6. User Journey

### New User (First Login)
```
Login → Dialog appears → "Choose Your Plan"
Options:
  - Maybe Later (go to app with free tier)
  - View Plans (see all subscription options)
```

### Existing User with Active Plan
```
Login → Dialog appears → "Active Subscription" + Plan details
Options:
  - Continue (go to app)
  - Upgrade Plan (if not on highest tier)
```

### User Checking Profile
```
Navigate to Profile → Subscription card loads
  - See current plan
  - See usage stats
  - Click "Manage Subscription" → Subscription Plans Screen
```

## 7. Responsive Behavior

### Mobile (< 600px)
- Single column layout
- Full-width subscription card
- Stacked elements
- Touch-friendly button sizes (min 48px height)

### Tablet (600px - 900px)
- Single column layout
- Wider subscription card
- More padding and spacing

### Desktop (> 900px)
- Two-column layout
- Subscription in right column
- Wider cards with more details
- Hover effects on buttons

## Summary

The subscription display is:
✅ **Prominent** - Users can't miss it in their profile
✅ **Informative** - Shows all key details at a glance
✅ **Actionable** - Easy to manage/upgrade subscription
✅ **Beautiful** - Modern design with gradients and shadows
✅ **Responsive** - Works on all screen sizes
✅ **Bilingual** - Supports English and Arabic
✅ **User-friendly** - Clear status indicators and progress bars
