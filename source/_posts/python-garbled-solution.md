---
title: Python乱码问题解决方法
tags:
  - python
  - 编码
url: 459.html
id: 459
categories:
  - Python
date: 2015-01-06 01:46:19
---

最近要写个python脚本，遇到各种乱码问题，后来一查原来python乱码问题还真是层出不穷，让人头疼啊。 我主要是用的sublime进行脚本编写，使用cmd或python自带的GUI运行脚本调试查看。 比如下列的脚本代码在运行时会产生乱码

<!-- more -->

#coding:utf-8
print "的是"

[![QQ截图20150106092343](http://storage.veitor.net/uploads/2015/01/QQ截图20150106092343.jpg)](http://storage.veitor.net/uploads/2015/01/QQ截图20150106092343.jpg)因为编写代码时保存的编码为UTF-8，而在Windows中运行读取脚本时以系统的编码GBK去执行，因此GBK与UTF-8冲突导致编码错误。

解决方法有三种：

> 1、我们往往在代码顶部加入#coding:utf-8 这样指明解码时的字符集，而指明utf-8还是会出现所说的乱码，还是因为运行时采用的GBK与我们指定的UTF-8冲突。所以要指明编码的话就只好指明为和系统编码一样的字符集，如这样指明#coding:gbk ，不写coding的话默认为与系统一样的编码
> 
> [![QQ截图20150106094006](http://storage.veitor.net/uploads/2015/01/QQ截图20150106094006.jpg)](http://storage.veitor.net/uploads/2015/01/QQ截图20150106094006.jpg)
> 
> 2、在打印的字符前加上u，如print u"是" ，这样就指明了使用头部coding指定的字符集解码，当然前提是要在头部添加coding，并且coding所指的的字符集与操作系统用的字符集一样（刚才第一条说明了）
> 
> [![QQ截图20150106094135](http://storage.veitor.net/uploads/2015/01/QQ截图20150106094135.jpg)](http://storage.veitor.net/uploads/2015/01/QQ截图20150106094135.jpg)
> 
> 3、输出时指定使用的字符集，如print '是'.decode('utf-8')
> 
> [![QQ截图20150106094339](http://storage.veitor.net/uploads/2015/01/QQ截图20150106094339.jpg)](http://storage.veitor.net/uploads/2015/01/QQ截图20150106094339.jpg)

当然保存脚本时的编码要与coding一样。 另外据说还有种方法是加入这三行代码：

import sys
reload(sys)
sys.setdefaultencoding('utf-8')

这种方法我没试过，看起来好像是从系统编码进行下手的，将系统编码临时改掉，这样的话你们懂的。