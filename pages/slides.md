---
layout: page
title: Slides
description: 
keywords: 
comments: true
menu: 簡報
permalink: /slides/
---

<ul>
{% for slide in site.data.slides %}
  <li><a href="{{ slide.url }}" target="_blank">{{ slide.date }} - {{ slide.topic }} @ {{ slide.group }}</a></li>
{% endfor %}
</ul>
