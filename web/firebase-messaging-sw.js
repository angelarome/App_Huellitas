importScripts('https://www.gstatic.com/firebasejs/9.23.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.23.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyBwOXrXvkR7KVJt7NrZPy5t9aSMG3vGbiM",
  authDomain: "huellitas-9c216.firebaseapp.com",
  projectId: "huellitas-9c216",
  storageBucket: "huellitas-9c216.firebasestorage.app",
  messagingSenderId: "317394582572",
  appId: "1:317394582572:web:6451f1d37a26cb441ea589",
  measurementId: "G-C36RH7Y8WE"
});

const messaging = firebase.messaging();
