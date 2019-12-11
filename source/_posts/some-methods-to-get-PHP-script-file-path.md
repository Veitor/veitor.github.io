---
title: 获取PHP脚本文件路径的几个方法
url: 39.html
id: 39
categories:
  - PHP
date: 2014-04-21 05:23:12
tags:
---

别的不扯，直接正题。 在PHP中获得所执行脚本文件路径有以下几个方法：

1.  魔术常量\_\_FILE\_\_：这个魔术常量使用率非常高，经常在定义目录的绝对路径时用dirname(\_\_FILE\_\_)这种形式。另一种绝对路径定义见这篇博文[《魔术常量\_\_DIR\_\_和\_\_FILE\_\_的用法区别》](http://www.veitor.net/article/37.html "魔术常量__DIR__和__FILE__的用法区别")，但是使用场合与下面两种有区别，使用该常量最终返回的都是包含的文件（这句话的意思就看下面的示例代码吧）。
2.  使用两个全局变量字符串连接$\_SERVER\['DOCUMENT\_ROOT'\] . $SERVER\['PHP_SELF'\]：两个变量拼接而成，前一个变量是获取根目录完整路径，后一个变量是获取从网站根目录到该执行文件的绝对路径。拼接后即是所需要的脚本文件完整路径。
3.  依然是全局变量$\_SERVER\['SCRIPT\_FILENAME'\]：这个变量效果和第2种类似

示例代码： index.php文件，存放在e:/project/文件夹下，其中include了同级目录中的test1.php和子目录test中的test2.php

<?php
include './test1.php';
include './test/test2.php';
echo "<br>";
echo \_\_FILE\_\_;
echo "<br>";
echo $\_SERVER\['DOCUMENT\_ROOT'\].$\_SERVER\['PHP\_SELF'\];
echo "<br>";
echo $\_SERVER\['SCRIPT\_FILENAME'\];
echo "<br>";
?>

./test.1php和./test/test2.php文件代码相同。

<?php
echo "<br>";
echo \_\_FILE\_\_;
echo "<br>";
echo $\_SERVER\['DOCUMENT\_ROOT'\].$\_SERVER\['PHP\_SELF'\];
echo "<br>";
echo $\_SERVER\['SCRIPT\_FILENAME'\];
echo "<br>";
?>

接下来看一下结果：

E:\\project\\test1.php
E:/project/index.php
E:/project/index.php
E:\\project\\test\\test2.php
E:/project/index.php
E:/project/index.php
E:\\project\\index.php
E:/project/index.php
E:/projectt/index.php

你会发现结果第5行有个不同处，该行就是输出的\_\_FILE\_\_，并且代码是在子目录test中test2.php文件里的。也就是说明\_\_FILE\_\_写在哪个文件里，输出结果就是显示哪个文件。而其他两个全局变量$_SERVER输出的结果都是最终包含的文件，在这个示例中也就是index.php文件（如果不明白这句话意思，看前面红色的文字，意思就是和它相反的）。 如果对本文有疑问，欢迎留言，一起探讨。