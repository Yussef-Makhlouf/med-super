// Firebase Cloud Messaging service worker — required for the web build to
// receive a push while no tab is focused (background delivery). Must live
// at the site root (not under a subpath) per FCM's requirements.
//
// Config mirrors `lib/firebase_options.dart`'s `web` FirebaseOptions —
// keep the two in sync if the Firebase project ever changes.
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyBV_nkC-l4fl3UyXRYPk-qRtgaY5-1MTlU',
  appId: '1:221476713418:web:bb21f43fd270cdf6de5533',
  messagingSenderId: '221476713418',
  projectId: 'clinic-dd7cc',
  authDomain: 'clinic-dd7cc.firebaseapp.com',
  storageBucket: 'clinic-dd7cc.firebasestorage.app',
});

const messaging = firebase.messaging();

// Shows the OS/browser notification when a push arrives while no tab has
// focus. Foreground (tab focused) messages are handled instead by
// `FirebaseMessaging.onMessage` inside the Flutter app itself.
messaging.onBackgroundMessage((payload) => {
  const title = payload.notification?.title ?? payload.data?.title ?? 'ميدسوبر';
  const body = payload.notification?.body ?? payload.data?.body ?? '';
  self.registration.showNotification(title, {
    body,
    icon: '/icons/Icon-192.png',
    data: payload.data,
  });
});

// Deep-link on tap: focuses an existing tab if one is open, otherwise opens
// a new one. The Flutter app reads the target route from `data` via the
// same `notificationDeepLink` mapping used for in-app taps.
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      for (const client of clientList) {
        if ('focus' in client) return client.focus();
      }
      if (clients.openWindow) return clients.openWindow('/');
    }),
  );
});
