// ==UserScript==
// @name         YoutubeToInvidious
// @version      1.0.0
// @description  Rewrite the youtube URL to an Invidious instance
// @author       dezeroku
// @match        *://www.youtube.com/*
// ==/UserScript==
{% if qutebrowser_invidious_domain | length %}
var new_url = "https://{{ qutebrowser_invidious_domain }}" + window.location.pathname + window.location.search;
location.replace(new_url);
{% else %}
console.log("invidious_redirect: disabled, no qutebrowser_invidious_domain provided in ansible");
{% endif %}
