importScripts("https://www.gstatic.com/firebasejs/9.10.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.10.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyDEOZ4rBqoKqJDjoYycza2fpML6gIdUEf4",
  authDomain: "aqar.bdcbiz.com",
  projectId: "realstate-4564d",
  storageBucket: "realstate-4564d.firebasestorage.app",
  messagingSenderId: "832433207149",
  appId: "1:832433207149:web:2aea4e6bfcc664d8e0cc64",
  measurementId: "G-SFX5H50KQM"
});

const messaging = firebase.messaging();

// Store recently shown notification IDs to prevent duplicates
const shownNotificationIds = new Set();

messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);

  // ⚠️ CHECK IF NOTIFICATIONS ARE DISABLED - MUST BE FIRST!
  try {
    // The SharedPreferences key used by notification_preferences.dart is stored with prefix
    // We need to check localStorage for the Flutter SharedPreferences key
    const notificationsEnabled = localStorage.getItem('flutter.notifications_enabled');

    console.log('[firebase-messaging-sw.js] Notifications enabled preference:', notificationsEnabled);

    // If explicitly set to false (string 'false'), block the notification completely
    if (notificationsEnabled === 'false') {
      console.log('🔕 Notifications are DISABLED by user. Blocking notification completely.');
      console.log('🔕 NOT saving to storage, NOT showing popup.');
      return Promise.resolve(); // Exit immediately - don't save, don't show
    }

    // If null or 'true', allow notifications (default is enabled)
    console.log('✅ Notifications are enabled. Processing notification.');
  } catch (e) {
    console.error('⚠️ Error checking notification preference:', e);
    // If there's an error, default to allowing notifications
  }

  // Generate unique notification ID
  const notificationId = payload.messageId || payload.data?.notification_id || Date.now().toString();

  // Check if we already showed this notification (prevent duplicates)
  if (shownNotificationIds.has(notificationId)) {
    console.log('⚠️ Duplicate notification detected, skipping:', notificationId);
    return Promise.resolve(); // Skip duplicate
  }

  // Add to shown set
  shownNotificationIds.add(notificationId);

  // Clean up old IDs (keep only last 100)
  if (shownNotificationIds.size > 100) {
    const idsArray = Array.from(shownNotificationIds);
    shownNotificationIds.clear();
    idsArray.slice(-50).forEach(id => shownNotificationIds.add(id));
  }

  // Save notification to localStorage so Flutter app can pick it up
  try {
    const notification = {
      id: notificationId,
      title: payload.notification?.title || payload.data?.title || 'Notification',
      message: payload.notification?.body || payload.data?.body || '',
      type: payload.data?.type || 'general',
      timestamp: new Date().toISOString(),
      isRead: false,
      imageUrl: payload.data?.image_url || null,
      data: payload.data || {}
    };

    // Get existing notifications from localStorage
    const existingNotifications = JSON.parse(localStorage.getItem('pending_web_notifications') || '[]');

    // Check if notification already exists (double-check for duplicates)
    const alreadyExists = existingNotifications.some(n => n.id === notificationId);
    if (alreadyExists) {
      console.log('⚠️ Notification already in storage, skipping:', notificationId);
      return Promise.resolve();
    }

    // Add new notification
    existingNotifications.unshift(notification);

    // Keep only last 100 notifications to prevent storage overflow
    const limitedNotifications = existingNotifications.slice(0, 100);

    // Save back to localStorage
    localStorage.setItem('pending_web_notifications', JSON.stringify(limitedNotifications));

    console.log('✅ Background notification saved to localStorage');
  } catch (e) {
    console.error('❌ Error saving notification to localStorage:', e);
  }

  const notificationTitle = payload.notification?.title || 'Notification';
  const notificationOptions = {
    body: payload.notification?.body || '',
    icon: '/firebase-logo.png',
    data: payload.data,
    tag: notificationId, // Use tag to prevent duplicate visual notifications
    requireInteraction: false,
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});
