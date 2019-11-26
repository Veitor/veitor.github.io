---
title: PHP命名大小写敏感规则
tags:
  - PHP
url: 501.html
id: 501
categories:
  - PHP
date: 2015-02-25 14:44:24
---

一直觉得PHP中各种大小写规则理不清，就连工作多年的老手们也不一定能对PHP大小写敏感问题足够了解。在PHP中，大小写敏感问题的处理比较乱，大家一定要注意。即使某些地方大小写不敏感，但在编程过程中能始终坚持“大小写敏感”是最好不过的。下面整理了一些大小写问题注意点：

> **大小写敏感**

**1\. 变量名区分大小写** 所有变量均区分大小写，包括普通变量以 及$\_GET,$\_POST,$\_REQUEST,$\_COOKIE,$\_SESSION,$GLOBALS,$\_SERVER,$\_FILES,$\_ENV 等；

<?php
$abc = 'abc';
echo $abc;    //输出'abc'
echo $aBc;    //无输出
echo $ABC;    //无输出
?>

**2、常量名区分大小写** 使用define定义的常量是区分大小写的。

<?php
define('BLOGGER','Veitor');
echo BLOGGER;    //输出'Veitor'
echo BLOgger;    //报NOTICE提示，并输出'BLOgger'
echo blogger;    //报NOTICE提示，并输出'blogger'
?>

**3、数组索引（键名）区分大小写**

<?php
$arr = array('one'=>'first');
echo $arr\['one'\];    //输出'first'
echo $arr\['One'\];    //无输出并报错
echo $Arr\['one'\];    //上面讲过，变量名区分大小写，所以无输出并报错
?>

 

> **大小写不敏感**

**1\. 函数名、方法名、类名不区分大小写** 虽然这些不区分大小写，但坚持“大小写敏感”原则，建议还是使用与定义时相同大小写的名字

<?php
class Test
{
    static public function Ceshi()
    {
        echo '123';
    }
    public funcion Dxx()
    {
        echo '321';
    }
}
$obj = new Test;
$obj->Dxx();    //成功实例化Test类，并调用Dxx方法输出'321'
$obj->dxx();    //成功实例化Test类，并调用Dxx方法输出'321'
$obj = new test;
$obj->Dxx();    //成功实例化Test类，并调用Dxx方法输出'321'
$obj->dxx();    //成功实例化Test类，并调用Dxx方法输出'321'
Test::Ceshi();    //输出'123'
test::Ceshi();    //输出'123'
Test::ceshi();    //输出'123'
test::ceshi();    //输出'123'
?>

**2、魔术常量不区分大小写** 一些魔术常量包括：\_\_LINE\_\_、\_\_FILE\_\_、\_\_DIR\_\_、\_\_FUNCTION\_\_、\_\_CLASS\_\_、\_\_METHOD\_\_、 \_\_NAMESPACE\_\_等都不区分大小写。

<?php
echo \_\_LINE\_\_;    //输出2
echo \_\_line\_\_;    //输出3
?>

** 3、 NULL、TRUE、FALSE不区分大小写** 这个知道的人应该比较多就不举例了。 **4、强制类型转换不区分大小写** 如这些 (int)，(integer) – 转换成整型 (bool)，(boolean) – 转换成布尔型 (float)，(double)，(real) – 转换成浮点型 (string) – 转换成字符串 (array) – 转换成数组 (object) – 转换成对象 一般我们都小写，这个问题不大。   **总的来说，容易搞不明白的就是变量、常量、类名、方法名和函数名，把这些记住对自己会有帮助的。**