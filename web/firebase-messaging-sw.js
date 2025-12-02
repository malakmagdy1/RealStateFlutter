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
// Store content hashes to prevent language duplicates (EN + AR same notification)
const shownContentHashes = new Set();

// Use IndexedDB for storing notifications (service workers can't use localStorage)
const DB_NAME = 'notifications_db';
const STORE_NAME = 'pending_notifications';
const DB_VERSION = 1;

function openDB() {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open(DB_NAME, DB_VERSION);

    request.onerror = () => reject(request.error);
    request.onsuccess = () => resolve(request.result);

    request.onupgradeneeded = (event) => {
      const db = event.target.result;
      if (!db.objectStoreNames.contains(STORE_NAME)) {
        db.createObjectStore(STORE_NAME, { keyPath: 'id' });
      }
    };
  });
}

async function saveNotificationToDB(notification) {
  try {
    const db = await openDB();
    const tx = db.transaction(STORE_NAME, 'readwrite');
    const store = tx.objectStore(STORE_NAME);
    store.put(notification);
    await tx.complete;
    console.log('✅ Notification saved to IndexedDB:', notification.id);
  } catch (e) {
    console.error('❌ Error saving to IndexedDB:', e);
  }
}

async function getAllNotificationsFromDB() {
  try {
    const db = await openDB();
    const tx = db.transaction(STORE_NAME, 'readonly');
    const store = tx.objectStore(STORE_NAME);
    return new Promise((resolve, reject) => {
      const request = store.getAll();
      request.onsuccess = () => resolve(request.result || []);
      request.onerror = () => reject(request.error);
    });
  } catch (e) {
    console.error('❌ Error reading from IndexedDB:', e);
    return [];
  }
}

async function clearNotificationsFromDB() {
  try {
    const db = await openDB();
    const tx = db.transaction(STORE_NAME, 'readwrite');
    const store = tx.objectStore(STORE_NAME);
    store.clear();
    console.log('✅ Cleared all notifications from IndexedDB');
  } catch (e) {
    console.error('❌ Error clearing IndexedDB:', e);
  }
}

// Send notification to all clients (Flutter app windows)
async function notifyClients(notification) {
  const clients = await self.clients.matchAll({ type: 'window', includeUncontrolled: true });
  console.log('[SW] Found', clients.length, 'clients to notify');

  clients.forEach(client => {
    client.postMessage({
      type: 'NEW_NOTIFICATION',
      notification: notification
    });
    console.log('[SW] Posted notification to client:', client.id);
  });
}

messaging.onBackgroundMessage(async function(payload) {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);

  // Generate unique notification ID
  const notificationId = payload.messageId || payload.data?.notification_id || Date.now().toString();

  // Check if we already showed this notification (prevent duplicates by ID)
  if (shownNotificationIds.has(notificationId)) {
    console.log('⚠️ Duplicate notification detected (same ID), skipping:', notificationId);
    return Promise.resolve(); // Skip duplicate
  }

  // Also check for content duplicates (same notification in different language)
  // This prevents showing both EN and AR versions of the same notification
  const data = payload.data || {};
  const contentHash = `${data.type || ''}_${data.unit_id || data.compound_id || data.company_id || ''}_${Math.floor(Date.now() / 60000)}`; // Group by minute

  if (shownContentHashes.has(contentHash) && contentHash && contentHash !== '__') {
    console.log('⚠️ Duplicate notification detected (same content, different language), skipping');
    console.log('   Content hash:', contentHash);
    return Promise.resolve(); // Skip duplicate
  }

  // Add to shown sets
  shownNotificationIds.add(notificationId);
  if (contentHash && contentHash !== '__') {
    shownContentHashes.add(contentHash);
  }

  // Clean up old IDs (keep only last 100)
  if (shownNotificationIds.size > 100) {
    const idsArray = Array.from(shownNotificationIds);
    shownNotificationIds.clear();
    idsArray.slice(-50).forEach(id => shownNotificationIds.add(id));
  }
  if (shownContentHashes.size > 100) {
    const hashesArray = Array.from(shownContentHashes);
    shownContentHashes.clear();
    hashesArray.slice(-50).forEach(hash => shownContentHashes.add(hash));
  }

  // Create notification object
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

  // Save to IndexedDB
  await saveNotificationToDB(notification);

  // Notify all clients (Flutter app windows)
  await notifyClients(notification);

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

// Handle notification click
self.addEventListener('notificationclick', function(event) {
  console.log('[SW] Notification clicked:', event.notification.tag);
  event.notification.close();

  // Open or focus the app
  event.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function(clientList) {
      // If app is already open, focus it
      for (let i = 0; i < clientList.length; i++) {
        const client = clientList[i];
        if (client.url && 'focus' in client) {
          return client.focus();
        }
      }
      // Otherwise, open a new window
      if (self.clients.openWindow) {
        return self.clients.openWindow('/');
      }
    })
  );
});

// Handle messages from the main app
self.addEventListener('message', async function(event) {
  console.log('[SW] Received message:', event.data);

  if (event.data && event.data.type === 'GET_NOTIFICATIONS') {
    const notifications = await getAllNotificationsFromDB();
    event.ports[0].postMessage({ notifications: notifications });
  }

  if (event.data && event.data.type === 'CLEAR_NOTIFICATIONS') {
    await clearNotificationsFromDB();
    event.ports[0].postMessage({ success: true });
  }
});
