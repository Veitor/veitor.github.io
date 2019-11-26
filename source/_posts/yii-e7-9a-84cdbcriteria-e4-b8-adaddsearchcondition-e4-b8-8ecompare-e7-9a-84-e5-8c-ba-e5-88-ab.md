---
title: Yii的CDbCriteria中addSearchCondition与compare的区别
tags:
  - Yii
url: 95.html
id: 95
categories:
  - PHP
date: 2014-05-22 03:36:27
---

在使用Yii过程中发现CDbCriteria类中addSearchCondition与compare的功能似乎都是用于增加搜索条件的，但仔细看其代码之后还是有区别的。 这里我就讲一下使用方法吧，不讲原理了，讲原理要分析其代码涉及很多。

addSearchCondition第一个参数为搜索的字段名
==============================

第二个参数为搜索关键词 第三个参数是设置是否过滤掉你关键词中的“%"百分号和”_“下划线这两个通配符，默认是true，即过滤这两个通配符，并在关键词前后自动加上"%"以进行匹配。第四个参数就是条件连接符，默认为AND，最后一个是Sql 关键字”LIKE"，还可以设置为“NOT LIKE"。基本上最后两个参数都不需要自己设置，都使用默认值就好了。 **addSearchCondition就大致理解为增加一个LIKE搜索条件即可。**

compare
=======

第一个参数一样为搜索的字段名 第二个参数也是关键词，但不同点也在于此，你可以在关键词开头加"<"、">"、"<="、">="、"<>"这四个比较符号，组成的sql语句就类似\[字段名\]\[比较符号\]\[搜索关键词\]，如我搜一个商品价格小于5的东西就这么写：compare('price','<5')，查询相当于这样"price < 5"，它会自动提取开头的比较符号，如果你没写比较符号，那默认的就是"="等于符号，写成这样compare('price','5')就相当于'price=5'这种效果。 第三个参数是开启模糊匹配，默认是false关闭的，开启后，会调用上面的addSearchCondition方法，也就又使用了LIKE。compare('price','5',true)即price LIKE %5%，compare('price','<>5',true)即price NOT LIKE %5%，如果使用其他比较符号如compare('price','<=5',true)、compare('price','>5',true)等，使不会增加addSearchCondition的。 第四个参数是条件连接符AND，当然可以设置为其他的。 第五个参数是设置addSearchCondition中第三个条件的，当然你前面的参数要确保能调用addSearchCondition这个方法。 **compare可以这么理解，相当于使用"<"、">"、"<="、">="、"<>"来比较值，启用模糊匹配就使用LIKE方式。**   差不多就是这些吧，如果还有不明白的可以提出，我再讲细一点。