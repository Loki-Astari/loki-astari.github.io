---
layout: page
title: "Series"
comments: true
sharing: true
footer: true
---

<section>
{% for tag in site.tags %}
<h1>Series: {{ tag[0] }}</h1>
{% capture prefix %}{{ tag[0] }} - {% endcapture %}
<ul id="recent_posts">
{% for post in tag[1] reversed %}
<li class="post">
<a href="{{ root_url }}{{ post.url }}">{{ post.title | remove: prefix | titlecase }}</a>
</li>
{% endfor %}
</ul>
{% endfor %}
</section>

