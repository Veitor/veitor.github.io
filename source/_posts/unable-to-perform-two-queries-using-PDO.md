---
title: 关于使用PDO无法执行两次查询的问题
tags:
  - mysql
  - PDO
url: 445.html
id: 445
categories:
  - PHP
date: 2014-12-16 13:38:41
---

今天在使用PDO查询数据时遇到这么一个问题，使用实例化的PDO类无法执行两次查询，即第一次查询是正常的，第二次查询是无效的。 举个栗子：

```
$pdo = new PDO('mysql:host=127.0.0.1;dbname=test;', 'root', '');
$stmt1 = $pdo->query('select count(*） from table');
$stmt2 = $pdo->query('select * from table limit 0,5');
```

<!-- more -->

实例化PDO类，调用类中方法query查询一条语句`select count(*) from table`，返回的$stmt1变量是一个PDOStatement对象，而此时没有使用$stmt1这个实例做任何操作（或者只是使用了$stmt1->fetchColumn()获得了数据数量）。

接着再调用PDO实例中的方法query（使用prepare后再execute也一样）再一次查询数据，这是返回给$stmt2变量的值就不是一个PDOStatement对象了，而是false。使用`$stmt2->errorInfo()`打印出结果可以看到这么个错误`Cannot execute queries while other unbuffered queries are active.Consider using PDOStatement::fetchAll().Alternatively, if your code is only ever going to run against mysql, you may enable query buffering by setting the PDO::MYSQL_ATTR_USE_BUFFERED_QUERY attribute`

大致意思是说，当一个未缓存查询正在活动时不能再执行查询操作。

解决方式有： 

1. 可以考虑使用前一个查询返回的PDOStatement对象（本例子中是`$stmt1`）中fetchAll方法把数据处理完毕 
2. 亦或者是将前一个查询PDOStatement对象设为null：`$stmt1=null`
3. 再或者是连接数据库后使用PDO实例中方法`$pdo->setAttribute(PDO::MYSQL\_ATTR\_USE\_BUFFERED\_QUERY, true);`设置mysql启用缓冲查询。 这时第二次查询时$stmt2就不会为false了。