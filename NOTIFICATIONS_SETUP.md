# Notifications/Reminders Setup Guide

## ✅ What Was Implemented

### Features
1. **Automatic Task Reminders** - 24 hours before task due date
2. **Overdue Task Alerts** - Immediate notification for overdue tasks
3. **Task Submission Confirmation** - Notification when task is successfully submitted
4. **Classroom Sync Notification** - Shows count of synced tasks
5. **Platform Support** - Android and iOS

### Files Added/Modified
- ✅ `lib/services/notification_service.dart` - Core notification service
- ✅ `pubspec.yaml` - Added `flutter_local_notifications` and `timezone` packages
- ✅ `lib/main.dart` - Initialize notification service
- ✅ `lib/screens/home_page.dart` - Schedule reminders + sync notification
- ✅ `lib/screens/task_detail_page.dart` - Submission and reminder cancellation
- ✅ `android/app/src/main/AndroidManifest.xml` - Added notification permissions
- ✅ `android/app/src/main/kotlin/.../MainActivity.kt` - Create notification channels

---

## 🤖 Android Setup (Already Done!)

### What's configured:
```
✅ Permissions: POST_NOTIFICATIONS, SCHEDULE_EXACT_ALARM
✅ Notification channel created in MainActivity
✅ Vibration and sound enabled
✅ High priority notifications for important reminders
```

### To Test (AVD/Physical Device):
```bash
flutter run
```

---

## 🍎 iOS Setup (Manual Steps Needed)

### Step 1: Enable Push Notifications in Xcode
1. Open iOS project: `ios/Runner.xcworkspace` (NOT .xcodeproj)
2. Select `Runner` in left panel
3. Select `Runner` target
4. Go to **Signing & Capabilities** tab
5. Click **+ Capability**
6. Add **Push Notifications**

### Step 2: Add Notification Categories (Optional but Recommended)
The iOS app will request notification permissions on first notification.

### Step 3: Build & Test
```bash
flutter run -d <ios-device-or-simulator>
```

First notification will show a permission request - User must grant permission.

---

## 🔔 How Notifications Work

### Task Reminder Flow
1. App loads tasks from Firestore
2. `NotificationService.scheduleAllReminders()` schedules notifications for all pending tasks
3. **24 hours before due date**: Local notification is triggered
4. User sees notification on lock screen/notification center

### Types of Notifications

| Type | When | Icon | Example |
|------|------|------|---------|
| Task Reminder | 24hrs before due | ⏰ | "⏰ Task 'Math HW' is due soon!" |
| Task Overdue | Past due date | ⚠️ | "⚠️ You have 2 overdue tasks!" |
| Submission Success | After submitting | ✅ | "✅ Task submitted successfully!" |
| Classroom Sync | After syncing | 🔄 | "🔄 Classroom sync completed - 5 tasks" |

---

## 🧪 Testing Notifications

### Cancel All Notifications
```dart
final notificationService = NotificationService();
await notificationService.cancelAllNotifications();
```

### Check Pending Notifications
```dart
final count = await notificationService.getPendingNotificationsCount();
print('Pending: $count notifications');
```

### Schedule Manual Reminder
```dart
final taskService = TaskService();
final tasks = await taskService.getTasks().first;
final notificationService = NotificationService();
await notificationService.scheduleTaskReminder(tasks.first);
```

---

## ⚙️ Configuration Details

### Android Notification Channel
```
Channel ID: task_channel
Name: Task Reminders
Priority: MAX (pops up on screen)
Sound: Default system sound
Vibration: Enabled
```

### Timezone Support
- Uses device timezone automatically
- Handles daylight saving time changes

### Notification Persistence
- Notifications persist even after app restart
- Automatically reschedules on app restart

---

## 🚀 Next Steps

### Optional Enhancements
- [ ] Add notification sound files (custom notification.aiff for iOS, notification.mp3 for Android)
- [ ] Add notification icons/images
- [ ] Implement notification actions (Mark as done from notification)
- [ ] Add notification grouping for multiple tasks
- [ ] Implement snooze functionality
- [ ] Add user preferences for notification timing (1hr, 6hr, 1day before)
- [ ] Add "Do not disturb" quiet hours

### Sound Setup (Optional)
1. **Android**: Place `notification.mp3` in `android/app/src/main/res/raw/`
2. **iOS**: Add `notification.aiff` to Xcode Runner project

---

## 📱 Common Issues & Fixes

### Issue: Notifications not showing on Android
**Solution**: Check notification permissions in app settings
```
Settings > Apps > StudyTask > Notifications > Toggle ON
```

### Issue: iOS notifications not working
**Solution**: 
1. Enable Push Notifications capability in Xcode
2. Restart simulator/device
3. Grant notification permission when prompted

### Issue: Reminders not scheduled for old tasks
**Solution**: Reminders are only scheduled for tasks with future due dates. For past tasks, show immediate notification.

### Issue: Timezone issues
**Solution**: `flutter_local_notifications` uses device timezone. Ensure device timezone is correct.

---

## 📞 Support

For issues, check:
- `lib/services/notification_service.dart` for debug prints
- Run with: `flutter run -v` for verbose logging
- Check Android logcat: `adb logcat | grep flutter`
- Check iOS logs: Xcode console

---

Created: April 6, 2026
Last Updated: April 6, 2026
