---
title: 网站如何适配Retina屏幕
tags:
  - retina
  - 前端
  - 适配
url: 265.html
id: 265
categories:
  - JS
date: 2014-08-28 00:37:21
---

**前言**
======

随着2012年苹果发布第一款Retina Macbook Pro（以下简称RMBP），Retina屏幕开始进入笔记本行业。两年过去了，RMBP的市场占有率越来越高，且获得了一大批设计师朋友的青睐，网站对于Retina屏幕的适配越来越重要。 如果大家对于Retina适配的重要性不是特别清楚，请看我的两个截图： [![QQ20140827-1@2x](http://storage.veitor.net/uploads/2014/08/QQ20140827-1@2x.jpg)](http://storage.veitor.net/uploads/2014/08/QQ20140827-1@2x.jpg) 上图是Google的首页LOGO，我们对比下图SOSO的LOGO： [![QQ20140827-2@2x](http://storage.veitor.net/uploads/2014/08/QQ20140827-2@2x.jpg)](http://storage.veitor.net/uploads/2014/08/QQ20140827-2@2x.jpg) 如果大家还是看不出来，请自行访问这两个网站或者下载附件的截图对比。 那么说完了重要性，适配Retina的原理又是什么呢？我们知道，当一个图像在标准设备下全屏显示时，一位图像素对应的就是一设备像素，导致一个完全保 真的显示，因为一个位置像素不能进一步分裂。而当在Retina屏幕下时，他要放大四倍来保持相同的物理像素的大小，这样就会丢失很多细节，造成失真的情 形。换句话说，每一位图像素被乘以四填补相同的物理表面在视网膜屏幕下显示。（摘自《走向视网膜（Retina）的Web时代》） 那么，解决方法相信大家也都听过，就是通过手动制图或以编程的方式制作两种不同的图形，一张是普通屏幕的图片，另外一种是Retina屏幕的图形，而且Retina屏幕下的图片是普通屏幕的两倍像素。 原理虽然简单，在现实中要实现就不仅仅如此，需综合考虑加载速度，浏览器适配等多方面因素，本文就是教大家如何对Retina的屏幕进行适配。

正文
==

### **1.直接加载2倍大小的图片。**

假如要显示的图片大小为200px\*300px，你准备的实际图片大小应该为400px\*600px，并且使用以下代码控制即可：

<img src="pic.png" height="200px" width="300px" />

这种方法就解决了Retina显示不清楚的问题，但是在普通屏幕下，这种图片要经过浏览器的压缩，在IE6和IE7上有十分差得显示效果，同时，两倍大小的图片势必会导致页面加载时间加长，用户体验下降，此时，我们可以通过Retina.js（[http://retinajs.com/](http://retinajs.com/)）文件解决：

    <img class="pic" src="pic.png" height="200px" width="300px"/>
    <script type="text/javascript">
    $(document).ready(function () {
    if (window.devicePixelRatio > 1) {
    var images = $("img.pic");
    images.each(function(i) {
    var x1 = $(this).attr('src');
    var x2 = x1.replace(/(.*)(.w+)/, "$1@2x$2");
    $(this).attr('src', x2);
    });
    }
    });
    </script>

 

### 2.Image-set控制

假如要显示的图片大小为200px\*300px，你准备的图片应有两张：一张大小为200px\*300px，命名为pic.png；另一张大小为 400px*600px，命名为pic@2x.png（@2x是Retina图标的标准命名方式），然后使用以下css代码控制：

    #logo {
    background: url(pic.png) 0 0 no-repeat;
    background-image: -webkit-image-set(url(pic.png) 1x, url(pic@2x.png) 2x);
    background-image: -moz-image-set(url(pic.png) 1x,url(images/pic@2x.png) 2x);
    background-image: -ms-image-set(url(pic.png) 1x,url(images/pic@2x.png) 2x);
    background-image: -o-image-set(url(url(pic.png) 1x,url(images/pic@2x.png) 2x);
    }

或者使用HTML代码控制亦可：

<img src="pic.png" srcset="pic@2x.png 2x" />

 

### 3.使用@media控制

实际是判断屏幕的像素比来取舍是否显示高分辨率图像，代码如下：

    @media only screen and (-webkit-min-device-pixel-ratio: 1.5),
           only screen and (min--moz-device-pixel-ratio: 1.5), /* 注意这里的写法比较特殊 */
           only screen and (-o-min-device-pixel-ratio: 3/2),
           only screen and (min-device-pixel-ratio: 1.5) {
    #logo {
    background-image: url(pic@2x.png);
    background-size: 100px auto;
    }
    }

使用这个的确定就是IE6、7、8不支持@media，所以无效。但是如果你只是支持苹果的RMBP的话，不存在兼容问题，因为MacOS X上压根没有IE！哈哈哈！ **OK，本文到这里就结束了，介绍了上面的三个办法大家可以各有取舍的使用吧~** 附件：[附件](http://storage.veitor.net/uploads/2014/08/76757.1946.zip) 原文地址：http://www.ui.cn/project.php?id=24556