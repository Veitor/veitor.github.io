---
title: Mysql中使用Insert批量更新数据
tags:
  - mysql
url: 275.html
id: 275
categories:
  - PHP
  - 程序与生活
  - 经验分享
date: 2014-09-09 09:00:37
---

我们知道当插入多条数据的时候insert支持多条语句：

INSERT INTO t_member (id, name, email) VALUES
    (1, 'nick', 'nick@126.com'),
    (4, 'angel','angel@163.com'),
    (7, 'brank','ba198@126.com');

  但是对于更新记录，由于update语法不支持一次更新多条记录，只能一条一条执行：

UPDATE t_member SET name='nick', email='nick@126.com' WHERE id=1;
UPDATE t_member SET name='angel', email='angel@163.com' WHERE id=4;
UPDATE t_member SET name='brank', email='ba198@126.com' WHERE id=7;

这里问题就出现了，倘若这个update list非常大时(譬如说5000条)，这个执行率可想而知。 这就要介绍一下在MySql中INSERT语法具有一个条件DUPLICATE KEY UPDATE，这个语法和适合用在需要判断记录是否存在，不存在则插入存在则更新的记录。 具体的语法可以参见：[http://dev.mysql.com/doc/refman/5.0/en/insert.html](http://dev.mysql.com/doc/refman/5.0/en/insert.html) 基于上面这种情况，针对更新记录，仍然使用insert语句，不过限制主键重复时，更新字段。如下：

INSERT INTO t_member (id, name, email) VALUES
    (1, 'nick', 'nick@126.com'),
    (4, 'angel','angel@163.com'),
    (7, 'brank','ba198@126.com')
ON DUPLICATE KEY UPDATE name=VALUES(name), email=VALUES(email);

注意：ON DUPLICATE KEY UPDATE只是MySQL的特有语法，并不是SQL标准语法！ 原文地址：http://www.crackedzone.com/mysql-muti-sql-not-sugguest-update.html