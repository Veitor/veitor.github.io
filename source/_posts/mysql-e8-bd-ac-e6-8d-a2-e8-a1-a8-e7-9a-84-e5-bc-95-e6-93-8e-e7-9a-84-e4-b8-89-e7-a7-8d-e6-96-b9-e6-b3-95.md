---
title: Mysql转换表的引擎的三种方法
url: 439.html
id: 439
categories:
  - Mysql
date: 2014-12-14 07:37:11
tags:
---

> ALTER TABLE

将表从一个引擎修改为另一个引擎最简单的办法就是使用ALTER TABLE语句。下面将mytable的引擎修改为InnoDB：

mysql> ALTER TABLE \`mytable\` ENGINE = InnoDB；

上述语法可以适用任何存储引擎。担忧一个问题：需要执行很长时间。Mysql会按行将数据从原表复制到一张新的表中，在赋值期间可能会小号系统所有的I\\O能力，同时原表上会加上读锁。所以，在繁忙的表上执行此操作要特别小心。一个替代方案是采用下面的导出与导入的方法，手工进行表的复制。

> 导出与导入

为了更好的控制转换过程，可以使用mysqldump工具将数据导出到文件，然后修改文件中CREATE TABLE语句的存储引擎选项，注意同时修改表名，因为同一个数据库中不能存在相同的表名，即使它们使用的是不同的存储引擎。同时要注意mysqldump默认会子的那个在CREATE TABLE语句前加上DROP TABLE语句，不注意这一点可能会导致数据丢失。

> 创建与查询（CREATE和SELECT）

第三种转换的技术综合了第一种方法的高效和第二种方法的安全。不需要导出整个表的数据，而是先创建一个新的存储引擎的表，然后利用INSERT...SELECT语法来导数据：

mysql> CREATE TABLE \`innodb\_table\` LIKE \`myisam\_table\`;
mysql> ALTER TABLE \`innodb_table\` ENGINE = InnoDB;
mysql> INSERT INTO \`innodb\_table\` SELECT * FROM \`myisam\_table\`;

数据量不大的话，这样做工作的很好。如果数量很大，则可以考虑做分批处理，针对每一段数据执行事务提交操作，以避免大事务产生过多的undo。假设有主键字段id，重复运行以下语句（最小值x和最大值y进行相应的替换）将数据导入到新表：

mysql> START TRANSACTION;
mysql> INSERT INTO \`innodb\_table\` SELECT * FROM \`myisam\_tale\` BETWEEN x AND y;
mysql> COMMIT;

这样操作完成以后，新表示原表的一个全量复制，原表还在，如果需要可以删除原表，如果有表要，可以在执行的过程中对原表加锁，以确保新表和原表的数据一致。   Percona Tolkit提供了一个pt-online-schema-change的工具（基于Facebook的在线schema变更技术），可以比较简单、方便的执行上述过程，避免手工操作可能导致的失误和繁琐。