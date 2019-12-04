---
title: 记一次Safari中无法跨域设置cookie的坑
tags:
  - iphone
  - safari
url: 551.html
id: 551
categories:
  - 经验分享
date: 2018-04-03 06:46:14
---

问题重现步骤：  
有两个不同域名的页面a.com/a.php和b.com/a.php两个域名，其中b.com/a.php会在其`b.com`下设置cookie，a.com/a.php页面中通过`iframe`或`script src`等方式嵌入b.com/a.php页面。保持b.com下的cookie为空，正常chrome等浏览器访问a.com/a.php时，嵌入的b.com/a.php可以正常对`b.com`域名下设置cookie，而safari中设置不了。

<!-- more -->

一开始以为是自己在b.com页面中设置cookie方式有问题，对cookie的name、value、expire、path、secure、httponly等都检查了好多次都没找出原因。并且当时会出现偶尔可以设置偶尔不可以设置的现象，后来逐一条件排查下来是要在b.com域名下cookie清空的条件下会产生这问题，如果b.com下有任意的一个或多个cookie项，那么safari就能正常写进去。

我主要是在iphone上进行的测试，后经查也有人反馈在pc上的safari也有这问题，那最后基本可以定位这问题的原因了。  
试过通过在b.com下设置各种cors header头，加各种P3P header均没有效果。  
这估计还是因为safari的cookie策略导致的。。最后。。只能根据问题现象，使用很屎的中转办法了，提前在b.com下设置任意一个cookie来确保该域名下至少有cookie，后续才能设置成功。

查找过的相关文章：  
[https://blog.csdn.net/zhx19920405/article/details/51417250](https://blog.csdn.net/zhx19920405/article/details/51417250)  
[https://stackoverflow.com/questions/32713992/safari-does-not-allowed-cross-domain-cookies-in-iframe](https://stackoverflow.com/questions/32713992/safari-does-not-allowed-cross-domain-cookies-in-iframe)