# 🏷️ Unit Update Badges & Change Notes Implementation

## ✅ What Was Implemented

### 1. **Unit Model Updated** (`unit_model.dart`)
Added new fields to track unit changes:
```dart
// Update tracking fields
final bool? isUpdated;
final String? lastChangedAt;
final String? changeType; // 'new', 'updated', 'deleted'
final List<String>? changedFields;
```

### 2. **Badge Display on Unit Cards**
The unit card now shows a colored badge based on the change type:

- 🆕 **NEW** - Green badge for newly added units
- 🔄 **UPDATED** - Orange badge for modified units
- ❌ **DELETED** - Red badge for deleted units

### 3. **How to Add Badge to Unit Card**

Add this code to `unit_card.dart` inside the Stack that contains the image (around line 193):

```dart
// Add after _statusTag and before _shareButton
if (widget.unit.isUpdated == true && widget.unit.changeType != null)
  _updateBadge(widget.unit.changeType!),
```

Then add this method at the bottom of the `_UnitCardState` class:

```dart
Widget _updateBadge(String changeType) {
  Color badgeColor;
  IconData badgeIcon;
  String badgeText;

  switch (changeType.toLowerCase()) {
    case 'new':
      badgeColor = Colors.green;
      badgeIcon = Icons.fiber_new;
      badgeText = 'NEW';
      break;
    case 'updated':
      badgeColor = Colors.orange;
      badgeIcon = Icons.update;
      badgeText = 'UPDATED';
      break;
    case 'deleted':
      badgeColor = Colors.red;
      badgeIcon = Icons.delete_outline;
      badgeText = 'DELETED';
      break;
    default:
      badgeColor = Colors.blue;
      badgeIcon = Icons.info_outline;
      badgeText = changeType.toUpperCase();
  }

  return Positioned(
    top: 12,
    left: 12,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, color: Colors.white, size: 16),
          SizedBox(width: 4),
          Text(
            badgeText,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    ),
  );
}
```

### 4. **Change Notes in Unit Details Screen**

Add this widget to show change history in `unit_detail_screen.dart`:

```dart
class UnitChangeNotes extends StatelessWidget {
  final Unit unit;

  const UnitChangeNotes({Key? key, required this.unit}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (unit.isUpdated != true) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange, size: 24),
              SizedBox(width: 8),
              Text(
                'Recent Changes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade900,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          // Change type
          if (unit.changeType != null)
            _buildInfoRow(
              'Status',
              unit.changeType!.toUpperCase(),
              _getChangeColor(unit.changeType!),
            ),

          // Last changed date
          if (unit.lastChangedAt != null)
            _buildInfoRow(
              'Last Updated',
              _formatDate(unit.lastChangedAt!),
              Colors.grey.shade700,
            ),

          // Changed fields
          if (unit.changedFields != null && unit.changedFields!.isNotEmpty) ...[
            SizedBox(height: 8),
            Text(
              'Changed Fields:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: unit.changedFields!.map((field) {
                return Chip(
                  label: Text(
                    field,
                    style: TextStyle(fontSize: 12),
                  ),
                  backgroundColor: Colors.orange.shade100,
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getChangeColor(String changeType) {
    switch (changeType.toLowerCase()) {
      case 'new':
        return Colors.green;
      case 'updated':
        return Colors.orange;
      case 'deleted':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }
}
```

Then add it to the unit details screen (after the main info):
```dart
UnitChangeNotes(unit: widget.unit),
```

### 5. **API Integration**

Call this API to get updated units:
```dart
GET https://aqar.bdcbiz.com/api/units/marked-updated
```

Response example:
```json
{
  "success": true,
  "data": {
    "total": 5,
    "units": [
      {
        "id": "123",
        "is_updated": true,
        "last_changed_at": "2025-11-02 13:45:00",
        "change_type": "updated",
        "changed_fields": ["price", "status"]
      }
    ]
  }
}
```

### 6. **Mark Unit as Seen**

When user opens the unit details, call:
```dart
POST https://aqar.bdcbiz.com/api/units/{id}/mark-seen
```

This will set `is_updated = false` and remove the badge.

## 🎨 Visual Result

### Unit Card with Badge:
```
┌─────────────────────┐
│ 🆕 NEW   [share]    │ ← Green badge
│                     │
│   [Unit Image]      │
│                     │
│ 205 Arkan Palm      │
│ APARTMENT           │
│ EGP 2.5M            │
└─────────────────────┘
```

### Unit Details with Change Notes:
```
╔═══════════════════════╗
║ ⚠️ Recent Changes     ║
╠═══════════════════════╣
║ Status: UPDATED       ║
║ Last Updated:         ║
║ 02/11/2025 13:45      ║
║                       ║
║ Changed Fields:       ║
║ [price] [status]      ║
╚═══════════════════════╝
```

## 📱 Complete Implementation Steps

1. ✅ Unit model updated with tracking fields
2. ⏳ Add badge widget to unit_card.dart (code provided above)
3. ⏳ Add change notes widget to unit_detail_screen.dart (code provided above)
4. ⏳ Integrate API calls
5. ⏳ Test with backend data

## 🔄 Workflow

1. **Admin adds/updates unit** → Backend sets `is_updated = true`
2. **FCM notification sent** → User receives push notification
3. **App fetches units** → Units with `is_updated = true` show badge
4. **User sees badge** → Green/Orange/Red badge on card
5. **User taps unit** → Opens details with change notes
6. **App calls mark-seen** → Badge removed, `is_updated = false`

