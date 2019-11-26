---
title: 关于python提示no module named win32api问题的解决
tags:
  - python
url: 452.html
id: 452
categories:
  - 程序与生活
  - 经验分享
date: 2014-12-22 08:34:42
---

本篇只介绍对于本机环境下问题的解决方案。我的系统是Win7 64位，并且安装的是64位的python2.7.6版本 当提示“no module named win32api”该信息时，需要安装pywin32模块，原本我是想通过pip安装的，但有问题。 于是上网找了对应的安装包，对应于我的python版本的，如果你也是用的2.7.6 64位的，可以下载我提供的这个附件：[pywin32-218.win-amd64-py2.7](http://www.veitor.net/article/452.html/pywin32-218-win-amd64-py2-7) 然后进行安装，如果打开程序安装报错的话，很有可能是找不到python的注册表信息，我的解决方法是重新安装python（当然也有写个脚本进行注册的方法），重装时选择只对本机用户，而不是所有用户。完成后就能成功安装pywin32了。