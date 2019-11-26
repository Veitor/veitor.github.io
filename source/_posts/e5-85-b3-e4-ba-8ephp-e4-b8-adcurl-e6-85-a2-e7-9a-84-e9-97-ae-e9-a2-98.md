---
title: 关于php中curl慢的问题
tags:
  - DNS
  - PHP
url: 479.html
id: 479
categories:
  - 程序与生活
  - 经验分享
date: 2015-01-22 06:57:54
---

今天在自己的服务器上运行程序时需要远程请求一个接口，发现此时程序响应特别慢，平均时间都要十几秒。 最后断定问题出现在了curl地方，使用服务器命令（我的是centos）curl一个域名也很慢，但curl一个IP却能得到及时响应。（因此其实本文标题说是PHP中的问题是不严谨的） 这说明问题可能就出现在了DNS设置上，后来改了一下DNS后发现正常了，在此写文记一下。 配置DNS： 输入命令vi /etc/resolv.conf 设置一下DNS，我这里使用的阿里DNS

nameserver 223.5.5.5
nameserver 223.6.6.6

最后再重启下php和nginx

/etc/init.d/php-fpm restart
/etc/init.d/php-fpm restart