{% extends '_layout.swig' %}
{% import '_macro/sidebar.swig' as sidebar_template with context %}

{% block title %}{{ page.title }} | {{ title }}{% endblock %}

{% block content %}

  <div class="posts-expand">
    {{ partial('_macro/post.swig', {post: page}) }}
  </div>

{% endblock %}

{% block sidebar %}
  {{ sidebar_template.render(true) }}
{% endblock %}

{### 下面script代码块使用了giscus作为评论组件，不用时去除下面script ###}
{% block comment %}
<script src="https://giscus.app/client.js"
        data-repo="Veitor/veitor.github.io"
        data-repo-id="MDEwOlJlcG9zaXRvcnkyMjQxOTk3OTU="
        data-category="Article Discussions"
        data-category-id="DIC_kwDODV0Ec84CpCCm"
        data-mapping="title"
        data-strict="1"
        data-reactions-enabled="1"
        data-emit-metadata="0"
        data-input-position="top"
        data-theme="preferred_color_scheme"
        data-lang="zh-CN"
        data-loading="lazy"
        crossorigin="anonymous"
        async>
</script>
{% endblock %}