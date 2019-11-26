---
title: 'PHP 5.3.6及以前版本的PDO的bindParam,bindValue潜在的安全隐患'
tags:
  - mysql
  - 转载
url: 396.html
id: 396
categories:
  - Mysql
date: 2014-11-20 02:03:42
---

PHP 5.3.6及以前版本的PDO的bindParam,bindValue潜在的安全隐患 使用PDO的参数化查询时，可以使用bindParam,bindValue为占位符绑定相应的参数或变量， 我们往往使用如下格式： $statement->bindParam(1, $string); $statement->bindParam(2, $int, PDO::PARAM\_INT); 我在以前的文章中分析介绍过PDO的ATTR\_EMULATE\_PREPARES属性对PDO底层协议与MySQL Server通讯机制影响： 1. 默认情况下，PDO会使用DSN中指定的字符集对输入参数进行本地转义（PHP手册中称为native prepared statements），然后拼接成完整的SQL语句，发送给MySQL Server。这有些像我们平时程序中拼接变量到SQL再执行查询的形式。 这种情况下，PDO驱动能否正确转义输入参数，是拦截SQL注入的关键。然而PHP 5.3.6及老版本，并不支持在DSN中定义charset属性（会忽略之），这时如果使用PDO的本地转义，仍然可能导致SQL注入，解决办法后面会提到。 2. MySQL Server 5.1开始支持prepare预编译SQL机制，即SQL查询语句与参数分离提交，但这个特性需要客户端协议支持支持，目前所有版本的PHP均支持。 如果PDO客户端使用mysql Server的prepare功能，大致的交互过程是： A. PDO将SQL模板发送给mysql server， SQL模板即包含参数占位符（问号或命名参数）的SQL语句 B. PDO不对输入参数作任何转义处理，将参数的位置，值，类型等等信息发送给MySQL Server C. PDO客户端调用execute statement D. MySQL Server 对B步骤提交的参数进行内部转义，并执行查询,返回结果给客户端。 看到没有，如果使用了mysql server prepare功能，则字符串的转义是由MySQL Server完成的。mysql会根据字符集（set names <charset>）对输入参数转换，确保没有注入产生。   PDO默认情况下使用了本地模拟prepare（并未使用MySQL server的prepare）,如果要禁止PDO本地模拟行为而使用MySQL Server的prepare机制，则需要设置PDO的参数： $pdo->setAttribute(PDO::ATTR\_EMULATE\_PREPARES,false); 如果你使用了PHP 5.3.6及以前版本，强烈推荐使用上述语句加强安全性。 如果你使用PHP 5.3.6+, 则请在DSN中指定 charset，是否设置上述参数，都是安全的。   好了，现在步入正题，假设有以下代码逻辑：   $pdo = new PDO("mysql:host=localhost;dbname=test;charset=utf8",'root',''); $pdo->setAttribute(PDO::ATTR\_ERRMODE,PDO::ERRMODE\_EXCEPTION); $pdo->setAttribute(PDO::ATTR\_DEFAULT\_FETCH\_MODE,PDO::FETCH\_ASSOC); $pdo->exec('set names utf8'); $id = '0 or 1 =1 order by id desc'; $sql = "select * from article where id = ?"; $statement = $pdo->prepare($sql); $statement->bindParam(1, $id, PDO::PARAM\_INT); $statement->execute(); 假设$id是外部变量（由其它函数传递，或用户提交），我们也没有使用intval对这两个参数进行强制类型转换（我们认为使用PDO绑定参数时已经指定参数类型为INT, 即PDO::PARAM\_INT），期待PDO能使用我们指定的类型对其进行转义，但是事实上呢？却有太多不确定因素： 1. 以上代码实测在PHP 5.2.1造成了SQL注入 2. 以上代码在PHP 5.3.9下，没有造成任何SQL注入 那么，如果使用了存在bug的PHP版本，那么如何从根本上解决这个问题？ 1. 设置PDO不使用本地模拟prepare, 即 $pdo->setAttribute(PDO::ATTR\_EMULATE_PREPARES,false);   这样，即使不使用intval对输入进行转换，也可以确保是安全的。如果由于程序员遗忘没有使用intval转换，那么还是存在安全隐患的。   使用这种方式，更彻底，更安全。 原文地址：http://zhangxugg-163-com.iteye.com/blog/1855088