---
title: 用mysql_unbuffered_query函数取大数据
tags:
  - mysql
  - PHP
url: 166.html
id: 166
categories:
  - PHP
date: 2014-08-13 12:52:04
---

昨天在做项目的时候，因为涉及到数据表结构的改动，需要进行大量数据的导入，那么如何高效的进行是我比较关注的。本文暂且从使用PHP脚本层面上来说，因为使用其他语言或其他方式也可以进行数据的重导。 在讨论这个问题的时候，前辈给我的意见就是单独做一个脚本，如果能拿python做更好，当然，python我还不是很会，所以拿php也能完成。既然这样，就采用最原生的方式来进行数据的重导。 整个过程中要先从一张表中取出全部数据，再进行数据的处理后导入到新的数据表中。而就我测试的那个数据库中的那张表里，数据量就已经上万了，如果直接全部取出必定会有性能上的问题。 他人给我的建议是，使用mysql\_connect后用mysql\_query执行sql（取大数据的情况如sele ct * from tbl）语句，理由是mysql\_query不是返回的数据结果，因为后面用到mysql\_fetch\_assoc之类的函数，进行游标的移动来取得数据。并在sql执行前后分别使用了memory\_get\_usage来查看内存使用量。当然，执行后内存使用量比执行前大了，虽然使用了不多的内存，但对于只是测试数据库里的数据而言还行，当数据处理量很大的时候，php程序脚本可能会崩溃。为了确保重导真正线上数据库的数据万无一失，我还是查了一些相关资料。 最后了解到PHP中有个mysql\_unbuffered\_query这个函数，与mysql\_query有点类似，手册上写了该函数不缓存的查询结果，它所带来的好处就是**一不用缓存结果，二就是不必等待全部查询后进行操作，而是直接获取一条数据就可以操作**。而mysql\_query是查询出所有符合条件的结果并缓存后才能进行操作，这就让我怀疑之前建议的那个方法。 于是我同样用mysql\_unbuffered_query查询同样一条sql语句，也同样对执行前后查看了内存使用量，结果前后内存使用量没有变，这就说明了内存并没有被拿来做查询数据缓存的相关事情。当然也可以使用以下方法来测试：

   $link = mysql_con nect('localhost','root','root');
   mysql\_select\_ db('phpcms');
   $sql = "SEL ECT * FROM \`phpcms_content\`";
   //$result = mysql\_unbuffered\_query($sql,$link);
   $result = mysql_query($sql,$link);
   while ($row = mysql\_fe tch\_array($result, MYSQL_NUM)) {
      printf ("ID: %s Name: %s", $row\[0\], $row\[1\]);
   }
   mysql\_data\_seek($result,0);
   echo "<br/>";
   while ($row = mysql\_fetch\_array($result, MYSQL_NUM)) {
      printf ("ID: %s Name: %s", $row\[0\], $row\[1\]);
   }
    mysql\_free\_result($result);

你会发现使用mysql\_query会输出两次，而mysql\_unbuffered\_query只输出一次，说明使用mysql\_query查询结果必定被缓存了，而使用mysql\_unbuffered\_query则边进行查询边给出结果。 最后再说明，使用mysql\_unbuffered\_query的话，不能使用mysql\_num\_rows()和mysql\_data\_seek()这也正因为它的特性方式决定了这样。还有比较重要的一点，如果你只是单单获取大数据量使用这个函数可以，**但是，如果你在取得大数据的时候，使用while($row = mysql\_fetch\_assoc($result))方式进行执行新的sql语句的话，会出错。手册上也写明了，在执行一条心的sql之前，要提取所有未缓存的sql查询所产生的行。**所以只使用mysql\_unbuffered\_query取数据可以，但期间还要执行其他sql就不行了。 以上只是我对这个函数的初步认识，如果理解有误，也希望能指正交流。