---
layout: none    
---

const preCachedResources = [
  '/',
  '{{ site.default_lang }}/', 
  '{% asset main.css @path %}',
  '{% asset main.js @path %}'
];

const CACHE_NAME = '{{ site.name | slugify }}-v1';

self.addEventListener('install', event => {
  event.waitUntil(caches.open(CACHE_NAME)
  .then(cache => cache.addAll(preCachedResources))
  .catch(error => console.log('Service worker installation has failed', error)));
});

self.addEventListener('fetch', function(event) {
  event.respondWith(
    caches.open(CACHE_NAME)
    .then(cache => {
      return cache.match(event.request).then(response => {
        return response || fetch(event.request).then(response => {
          cache.put(event.request, response.clone());
          return response;
        });
      });
    })
  );
});
