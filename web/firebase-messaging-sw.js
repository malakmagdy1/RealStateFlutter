importScripts("https://www.gstatic.com/firebasejs/9.10.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.10.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyDw0MpADUzW4cV5sMLRWDqKT7L0Js_TVLE",
  authDomain: "real-1be1b.firebaseapp.com",
  projectId: "real-1be1b",
  storageBucket: "real-1be1b.firebasestorage.app",
  messagingSenderId: "1004033355654",
  appId: "1:1004033355654:web:3cf04e93a618ae2f55f70f",
  measurementId: "G-E1Y3S4FKPK"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);

  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/firebase-logo.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
