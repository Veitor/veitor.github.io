---
title: 单表继承（Single Table Inheritance）
url: 573.html
id: 573
categories:
  - PHP
date: 2018-08-03 01:01:35
tags:
---

_将类的继承层次表示为单张数据表，这张表内含有每个类的所有字段_

![classInheritanceTableSketch.gif](http://storage.veitor.net/2018/08/2552666952.gif "classInheritanceTableSketch.gif")

关系数据库不支持继承，当对象映射到数据库时，我们必须考虑如何在关系数据表中良好的展示我们的对象继承结构。当对象映射到关系数据库时，在多张表中处理继承结构过程中，我们尝试着去尽量减少迅速增加的join查询。（参考[类表查询](http://www.veitor.net/article/571.html)）。`单表继承`将所有类的继承结构的所有字段映射到了一张表中。