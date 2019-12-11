---
title: 谷歌服务被“封” 网站加载变慢
tags:
  - google
url: 117.html
id: 117
categories:
  - 程序与生活
date: 2014-06-24 09:00:32
---

[![1402017825583](http://storage.veitor.net/uploads/2014/06/1402017825583.jpg)](http://storage.veitor.net/uploads/2014/06/1402017825583.jpg) 从5月27号左右开始，谷歌(Google)在华的几乎所有的服务都处于无法使用的状态，谷歌官网域名Google.com、谷歌香港 Google.com.hk所有服务都打不开。ping出来的IP均显示为“美国”，也就是说谷歌香港的服务器，已经由香港转移至美国，所以链接实际会很 长，甚至断断续续出现请求超时的情况。 当时我的博客所在的SAE也有点小故障，所以那几天我的博客一直访问很慢，我以为是SAE的问题，结果后来终于发现博客的几个页面加载了google的字体资源，所以导致网站加载特别缓慢，现在终于解决了。 360网站卫士的解决方案： 修改方法如下： 打开wordpress代码中的文件wp-includes/script-loader.php文件，搜索：fonts.googleapis.com找到这行代码： $open\_sans\_font_url = “//fonts.googleapis.com/css?family1=Open+Sans:300italic,400italic,600italic,300,400,600&subset=$subsets”; 把fonts.googleapis.com替换为fonts.useso.com 修改完保存，再次刷新，大家就可以发现，自己的网站速度已经比以前快了很多，几乎瞬间就可以拿到Google字体了。原因就是本来需要从美国服务器才能拿到的google字体，现在已经遍布360全国的机房了。 醒妹网的解决方案： 既然是关于Google字体，那解除字体问题就可以了。如果网页中设定的字体无法加载，那么网页会按照浏览器默认的字体显示。但浏览器并不知道Google字体服务被屏蔽了，还那么二的一直加载，直到加载失败。但这个过程会耗费十几秒的时间。 **　　WordPress网站解决Google字体的办法：** 第一种方法：安装Disable Google Font插件，但经过测试之后，没有明显效果。 第二种方法：注释或删除掉style.css和function.php有关加载Google字体的代码fonts.googleapis.com即可。 当然以上两种方法可以同时使用。 如果在更改style.css或function.php文件之后，wordpress网站报错，无法打开，或者新建文章时上传图片失败。一定是将wordpress文件的编码保存为非ANSI编码，用记事本打开，保存时选择编码ANSI替换掉原来的文件即可。