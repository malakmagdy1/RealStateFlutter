# Subscription System - Testing Guide

## Quick Test Steps

### Prerequisites
1. Make sure the backend API is running at `https://aqar.bdcbiz.com/api`
2. Have a test account ready with login credentials
3. Have your auth token ready (you can get it from the web profile developer section)

## Test 1: Login and Subscription Dialog

### Mobile App
1. Open the app
2. Login with credentials
3. ✅ Verify subscription dialog appears
4. ✅ Verify plan details are shown correctly
5. ✅ Close dialog or navigate to plans
6. ✅ Verify navigation to home works

### Web App
1. Open the web app
2. Login with credentials
3. ✅ Verify subscription dialog appears
4. ✅ Verify plan details match API response
5. ✅ Close dialog or navigate to plans
6. ✅ Verify navigation to home works

## Test 2: Profile Screen Display

### Mobile Profile
1. Navigate to Profile tab
2. ✅ Verify subscription card appears at the top
3. ✅ Verify plan name shows correctly (both languages if applicable)
4. ✅ Verify active/inactive badge appears
5. ✅ Verify search quota displays correctly
6. For limited plans:
   - ✅ Verify progress bar shows
   - ✅ Verify remaining searches count
   - ✅ Verify expiration date displays
7. For unlimited plans:
   - ✅ Verify "Unlimited searches" text shows
   - ✅ No progress bar
8. ✅ Click "Manage Subscription" button
9. ✅ Verify navigation to plans screen

### Web Profile
1. Navigate to Profile section
2. ✅ Verify subscription section appears in right column
3. ✅ Verify premium card styling
4. ✅ Verify all details display correctly
5. ✅ Verify status badge with shadow effect
6. For limited plans:
   - ✅ Verify search quota with progress
   - ✅ Verify remaining searches text
   - ✅ Verify expiration information
7. For unlimited plans:
   - ✅ Verify "Unlimited searches" text
8. ✅ Click "Manage Subscription" button
9. ✅ Verify button hover effect
10. ✅ Verify navigation works

## Test 3: API Integration

### Using Postman or API Client

#### Test Current Subscription
```http
GET https://aqar.bdcbiz.com/api/subscription/current
Authorization: Bearer {your_token}
```

**Expected Response:**
```json
{
  "success": true,
  "data": {
    "id": 25,
    "status": "active",
    "started_at": "2025-11-03T09:33:58.000000Z",
    "expires_at": "2025-12-03T09:33:58.000000Z",
    "searches_used": 25,
    "remaining_searches": 0,
    "is_active": true,
    "is_expired": false,
    "can_search": false,
    "plan": {
      "id": 4,
      "name": "مجانية",
      "name_en": "Free",
      "slug": "free",
      "search_limit": 5,
      "validity_days": 30
    }
  }
}
```

✅ Verify all fields are present
✅ Verify dates are in ISO format
✅ Verify plan details are included

#### Test Subscription Status
```http
GET https://aqar.bdcbiz.com/api/subscription/status
Authorization: Bearer {your_token}
```

**Expected Response:**
```json
{
  "success": true,
  "data": {
    "has_active_subscription": true,
    "can_search": true,
    "searches_used": 0,
    "remaining_searches": -1,
    "search_limit": -1,
    "expires_at": null,
    "plan_name": "بلس",
    "plan_name_en": "Plus"
  }
}
```

✅ Verify status fields are correct
✅ Verify -1 means unlimited
✅ Verify bilingual plan names

#### Test Subscribe to Plan
```http
POST https://aqar.bdcbiz.com/api/subscription/subscribe
Authorization: Bearer {your_token}
Content-Type: application/json

{
  "subscription_plan_id": 2,
  "billing_cycle": "monthly",
  "auto_renew": true
}
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Successfully subscribed to plan",
  "data": {
    "id": 26,
    "status": "active",
    "started_at": "2025-11-03T17:01:17.000000Z",
    "expires_at": null,
    "searches_used": 0,
    "remaining_searches": -1,
    "plan": {
      "id": 2,
      "name": "بلس",
      "name_en": "Plus",
      "search_limit": -1,
      "validity_days": -1
    }
  }
}
```

✅ Verify subscription created successfully
✅ Verify new subscription ID returned
✅ Verify plan details included

#### Test Cancel Subscription
```http
POST https://aqar.bdcbiz.com/api/subscription/cancel
Authorization: Bearer {your_token}
Content-Type: application/json

{
  "reason": "Testing cancellation"
}
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Subscription cancelled successfully"
}
```

✅ Verify cancellation successful
✅ Verify status changes to cancelled

## Test 4: Different Subscription States

### Test Unlimited Plan
1. Subscribe to unlimited plan (Plus/Premium/Pro)
2. ✅ Profile shows "Unlimited searches"
3. ✅ No progress bar displayed
4. ✅ No expiration date shown
5. ✅ Active badge shows green

### Test Limited Plan with Searches Left
1. Subscribe to free/basic plan
2. Use some searches (but not all)
3. ✅ Profile shows "X/Y searches"
4. ✅ Progress bar shows correct percentage
5. ✅ Remaining searches count correct
6. ✅ Expiration date displays
7. ✅ Active badge shows green

### Test Limited Plan - No Searches Left
1. Use all available searches
2. ✅ Profile shows "X/X searches" (0 remaining)
3. ✅ Progress bar full (red color)
4. ✅ "No searches remaining" text shows
5. ✅ Status shows warning or inactive

### Test Expired Plan
1. Wait for plan to expire or set expired date
2. ✅ Status shows "Inactive"
3. ✅ Expired message displays
4. ✅ Badge shows orange/inactive color

## Test 5: Error Handling

### No Internet Connection
1. Disable internet
2. Navigate to profile
3. ✅ Loading indicator appears
4. ✅ Error state displays after timeout
5. ✅ Appropriate error message shown

### Invalid Token
1. Use expired or invalid token
2. ✅ API returns 401 Unauthorized
3. ✅ User redirected to login
4. ✅ Token cleared from storage

### API Errors
1. Simulate API error
2. ✅ Error state displays
3. ✅ User-friendly error message
4. ✅ Option to retry

## Test 6: Refresh Behavior

### Profile Screen Refresh
1. Open profile
2. ✅ Subscription loads on first view
3. Navigate away and back
4. ✅ Subscription reloads
5. Pull to refresh (mobile)
6. ✅ Subscription data refreshes

### After Subscription Change
1. Change subscription (subscribe/upgrade/cancel)
2. Return to profile
3. ✅ New subscription details display
4. ✅ No stale data shown

## Test 7: Localization

### English Language
1. Set app language to English
2. ✅ All labels in English
3. ✅ Plan name shows English version
4. ✅ Button text in English

### Arabic Language
1. Set app language to Arabic
2. ✅ All labels in Arabic
3. ✅ Plan name shows Arabic version
4. ✅ Button text in Arabic
5. ✅ RTL layout works correctly

## Test 8: Navigation

### From Profile to Plans
1. Click "Manage Subscription" in profile
2. ✅ Navigate to subscription plans screen
3. ✅ All plans display
4. ✅ Can navigate back to profile

### From Login Dialog to Plans
1. Login to app
2. Click "View Plans" in dialog
3. ✅ Navigate to plans screen
4. ✅ Can select a plan
5. ✅ Navigate to home after selection

## Test 9: Performance

### Loading Speed
1. Time subscription load on profile
2. ✅ Loads within 2 seconds (normal network)
3. ✅ Shows loading indicator immediately
4. ✅ Smooth transition to content

### UI Responsiveness
1. Scroll profile with subscription card
2. ✅ No lag or jank
3. ✅ Animations smooth
4. ✅ Touch targets responsive

## Test 10: Edge Cases

### No Subscription
1. User with no subscription
2. ✅ Appropriate message or default plan shows
3. ✅ Call to action to subscribe

### Multiple Active Subscriptions
1. If backend allows multiple active subscriptions
2. ✅ Shows most recent or highest tier
3. ✅ Handles gracefully

### Plan Change During Session
1. Change plan while app is open
2. ✅ Refresh profile shows new plan
3. ✅ No app restart needed

## Checklist Summary

### Mobile App
- [ ] Login shows subscription dialog
- [ ] Profile displays subscription card
- [ ] Plan details correct
- [ ] Search quota accurate
- [ ] Progress bar works
- [ ] Manage button navigates
- [ ] Error handling works
- [ ] Loading states display
- [ ] Localization works

### Web App
- [ ] Login shows subscription dialog
- [ ] Profile displays subscription section
- [ ] Premium styling displays
- [ ] All details accurate
- [ ] Gradients and shadows work
- [ ] Hover effects functional
- [ ] Navigation works
- [ ] Responsive on all sizes
- [ ] Error handling works
- [ ] Loading states display

### API Integration
- [ ] GET /subscription/current works
- [ ] GET /subscription/status works
- [ ] POST /subscription/subscribe works
- [ ] POST /subscription/cancel works
- [ ] Auth token included automatically
- [ ] Error responses handled
- [ ] Response parsing correct

## Expected Results

✅ **All tests passing** means:
- Users can see their subscription plan
- Plan details are accurate and up-to-date
- UI looks professional and modern
- Navigation works smoothly
- API integration is solid
- Error handling is graceful
- Performance is acceptable
- System is production-ready

## Reporting Issues

If any test fails, note:
1. **What failed**: Specific test that failed
2. **Expected behavior**: What should happen
3. **Actual behavior**: What actually happened
4. **Steps to reproduce**: How to recreate the issue
5. **Screenshots**: Visual evidence if applicable
6. **Logs**: Console/API logs showing the error
7. **Environment**: Mobile/Web, OS version, browser

## Quick Command Reference

### Get Token from Profile (Web Only)
1. Login to web app
2. Go to Profile
3. Scroll to "Developer Tools" section
4. Click "Copy Token"
5. Use in Postman/API client

### Test All Endpoints Quickly
Use the provided Postman collection or run these curl commands:

```bash
# Set your token
TOKEN="your_token_here"

# Get current subscription
curl -H "Authorization: Bearer $TOKEN" \
  https://aqar.bdcbiz.com/api/subscription/current

# Get subscription status
curl -H "Authorization: Bearer $TOKEN" \
  https://aqar.bdcbiz.com/api/subscription/status

# Subscribe to plan
curl -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"subscription_plan_id":2,"billing_cycle":"monthly","auto_renew":true}' \
  https://aqar.bdcbiz.com/api/subscription/subscribe

# Cancel subscription
curl -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"reason":"Testing"}' \
  https://aqar.bdcbiz.com/api/subscription/cancel
```

## Success Criteria

The subscription system is working correctly if:

✅ Users can view their subscription in profile
✅ All API endpoints respond correctly
✅ UI displays all subscription details accurately
✅ Search quota tracking works
✅ Progress bars show correct percentages
✅ Navigation flows work smoothly
✅ Error handling is graceful
✅ Loading states appear appropriately
✅ Both mobile and web apps work
✅ Localization (EN/AR) works correctly

Happy Testing! 🎉
