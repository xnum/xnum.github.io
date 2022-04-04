---
layout: post
title:  "jekyll 增加 category 頁面"
date:   2017-04-17 20:21:06 +0800
categories: jekyll
comments: true
---

稍微搜尋了一下，網路上很多解法，但是有些已經過時了，或是過於複雜

我要的效果很簡單，一個頁面可以列出有哪些分類，和他下面的文章

{% raw %}
```
+---
+layout: default
+---
+
++<h2>Categories</h2>
+{% for category in site.categories %}
+<h4>{{ category[0] }}</h4>
+<ul>
+    {% for post in category[1] %}
+    +    <li><a href="{{ post.url }}">{{ post.title }}</a></li>
+    +    {% endfor %}
+    +</ul>
+    +{% endfor %}
+    +
+
```

主要是新增一個空白的頁面去顯示我要的內容

實際上有一個layout來秀結果

大概撞了幾個牆

1. liquid template在印文字要用`{{`，邏輯控制則是`{%`，有點小差異
2. `site.categories`是一個hash table，用for loop解開後要用[0]存取key，用[1]存取value
{% endraw %}

p.s. Jekyll 版本為 3.4.3
