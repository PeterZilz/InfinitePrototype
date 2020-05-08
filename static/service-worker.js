"use strict";

// Note: The service worker will terminate, when idle for too long.
// That means, that all (global) state is lost.

const CACHE_NAME = "infinite-prototype-v1";
const urlsToCache = [
    "./js/elm.js",
    "./style/index.css",
    "./favicon.svg",
    "./favicon32.png",
    "./favicon96.png",
    "./favicon144.png",
    "./index.html",
    "./",
    "./manifest.json",
];

// triggered after registration or after update
self.addEventListener("install", (event) => {
    event.waitUntil(
        caches.open(CACHE_NAME)
            .then(cache => {
                return cache.addAll(urlsToCache);
            })
    );
});

self.addEventListener("fetch", event => {
    event.respondWith(
        caches.match(event.request)
            .then(response => {
                if(response) {
                    // found something in the cache
                    return response;
                }
                // didn't find, have to fetch
                return fetch(event.request);
            })
    );
});

// When a service worker update is installed,
// then the old one is still running until the next page load.
// Until then the new one is in "waiting".
// On the next page load, "activate" is triggered 
// and the new starts to run.
// self.addEventListener("activate", event => {
//     // delete all non whitelisted caches
//     const cacheWhiteList = [".."];
//     event.waitUntil(
//         caches.keys().then(cacheNames => {
//             return Promise.all(
//                 cacheNames.map(cacheName => {
//                     if(cacheWhiteList.indexOf(cacheName) === -1)
//                     {
//                         return caches.delete(cacheName);
//                     }
//                 })
//             )
//         })
//     );
// });
