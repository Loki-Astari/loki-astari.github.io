---
layout: post
title: "Switching to OctoPress"
date: 2013-11-30 15:37:34 -0800
comments: true
categories: [WordPress, OctoPress, Blogging]
---

##Switching to OctoPress and Github

I have not blogged much, until recently, so I am not an HTML/CSS/Javascript expert. Thus layout, or layout during writing a blog article, is not of supreme importance for me. I expect the framework to handle that all for me. But that was my issue with WordPress. As a normal blogger I am sure it is not an issue but the tools for blogging about code are rudimentary and not will integrated in WordPress and basically forced me to write in HTML (see [Set up WordPress](http://lokiastari.com/blog/2013/11/12/want-to-set-up-wordpress-to-write-about-programming/)). I do write a lot on other sites that specialize in coding and these sites have developed a style called <MarkDown>. The two most common versions are `[StackOverFlow markdown](http://stackoverflow.com/editing-help)` and `[GitHub markdown](http://daringfireball.net/projects/markdown/syntax)`.

###MarkDown

Markdown is a very simplistic form of 'Markup' that is designed to specifically to be simple and deal with the common issues of writing word based articles. Coder sites usually extend this with basic support for placing code (or reformatted text) directly into the article. It is not designed for non technical people (they should be using a 'Visual' interface not markup) but for the technical writer who does not want the full blown power of HTML but wants slightly more control than visual interfaces provide.

###Attack Vector

WordPress is also infamous for being the target of attackers. There are constantly new attacks being developed against WordPress (the joy of being top dog). This can be mitigated by putting your WordPress site on [wordpress.com](wordpress.com). This not only provides you with free hosting but they do keep on top of security vulnerabilities and make sure all hosted sites are not overexposed. But if you want use your own domain name (i.e. [LokiAstari.com](LokiAstari.com)) or any other "featured" services then you either need to fork up the cash (not an insignificant sum) or run your WordPress site.

So I have been running my own WordPress sites. But running your own site opens you to the vulnerabilities of WordPress attacks. To be honest not a big deal until I actually tweeted about my articles (now very much so). So the combination has made me look for alternatives.

###OctoPress

[OctoPress](octopress.org) was suggested by a colleague [Dan Lecocq](https://github.com/danlecocq). It is basically an off-line blogging system that takes your articles and creates a set of static pages. You can then use one of several systems to publish these static pages. As the pages are generated once (each time you create a new article) the requirements for the hosting system are minimal and consequently because there is no dynamic content there are no attack vectors that can be used against the site. Note: This does not mean the site has to be simple and boring as the pages can still have dynamic content loaded from other sites (like twitter/github/facebook etc.) It is just that the dynamic content will be fetched by the browser and from other sites.

The other major advantage is that it natively supports MarkDown. In fact you plug in your favorite MarkDown engine (I have currently stuck with the default 'GitHub markdown'). So you can write youre article in MarkDown and it will translate to the appropriate HTML.

Like WordPress comes with user created themes. Though not as well established as WordPress with themes you can easily extend it to build your own. There are already a couple of themes based on [Bootstrap](https://github.com/twbs/bootstrap) the most commonly forked HTML5/CSS/Javascript web-site project on [GitHub](github.com).

###GitHub

OctoPress also integrates with [GitHub Pages](http://pages.github.com/) a feature of the site designed to allow you create documentation for your software.





