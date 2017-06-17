---
layout: page
title: Tags 

---

<div class="page-content wc-container">
	<div class="post">
		<ul>

		  {% assign tags_list = site.tags %}

		  {% if tags_list.first[0] == null %}
			{% for tag in tags_list %}
			  <li><a href="/tags#{{ tag }}-ref" >
				{{ tag }}
			  </a></li>
			{% endfor %}
		  {% else %}
			{% for tag in tags_list %}
			  <li><a href="/tags#{{ tag[0] }}-ref">
				{{ tag[0] }}
			  </a></li>
			{% endfor %}
		  {% endif %}

		  {% assign tags_list = nil %}
		</ul>


	{% for tag in site.tags %}
	  <h2 class='tag-header' style="padding-top: 50px;" id="{{ tag[0] }}-ref">{{ tag[0] }}</h2>
	  <ul>
		{% assign pages_list = tag[1] %}

		{% for node in pages_list %}
		  {% if node.title != null %}
			{% if group == null or group == node.group %}
			  {% if page.url == node.url %}
			  <li class="active"><a href="{{node.url}}" class="active">{{node.date | date: "%Y/%m/%d" }} - {{node.title}}</a></li>
			  {% else %}
			  <li><a href="{{node.url}}">{{ node.date | date: "%Y/%m/%d" }} - {{node.title}}</a></li>
			  {% endif %}
			{% endif %}
		  {% endif %}
		{% endfor %}

		{% assign pages_list = nil %}
		{% assign group = nil %}
	  </ul>
	{% endfor %}

	</div>
</div>
