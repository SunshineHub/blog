<main class="page__container page__main">
    <div class="page__content">
        {% include './content.swig' %}
		
		
	{% if  page.comments%}
		   <section id="comments" sid="{{ page.title }}">
<!--高速版，加载速度快，使用前需测试页面的兼容性-->
		<div id="SOHUCS" ></div>
		<script>
		  (function(){
			var appid = 'cytQjiMgn',
			conf = 'dc36b4d3752f0ca2b04f292b3360ba26';
			var doc = document,
			s = doc.createElement('script'),
			h = doc.getElementsByTagName('head')[0] || doc.head || doc.documentElement;
			s.type = 'text/javascript';
			s.charset = 'utf-8';
			s.src =  'http://assets.changyan.sohu.com/upload/changyan.js?conf='+ conf +'&appid=' + appid;
			h.insertBefore(s,h.firstChild);
			window.SCS_NO_IFRAME = true;
		  })()
		</script>    
	</section>
	{% endif %}

        {% if page.comments && config.gitTalk %}
            <div id="comment-container"></div>
        {% endif %}
        {% if page.comments && config.disqus_shortname %}
            <div id="disqus_thread"></div>
        {% endif %}
    </div>

    {% include '../common/sidebar.swig' %}
</main>