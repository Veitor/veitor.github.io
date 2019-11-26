---
title: PHP性能调试工具xhprof的安装与使用
tags:
  - Linux
  - PHP
  - xhprof
url: 364.html
id: 364
categories:
  - PHP
  - 计算机系统
date: 2014-11-03 07:47:41
---

今天试用了一下facebook的php性能调试工具xhprof，在安装的时候是一波三折，虽说从百度了安装方法，但也折腾了半天，不知是说明没写全还是我个人操作失误，那么我在这把我的安装方法讲述一下。环境是：Linux+Nginx+PHP

#cd /tmp
#mkdir xhprof
#cd xhprof
#wget http://pecl.php.net/get/xhprof-0.9.4.tgz
//解压
#tar zxf xhprof-0.9.4.tgz
#cd xhprof-0.9.4/extension
//拷贝xhprof\_html和xhprof\_lib两个文件夹至可访问的web目录下，我的web根目录为/home/www
#cp -r xhprof\_html xhprof\_lib /home/www
//运行phpize
#/usr/local/webserver/php/bin/phpize
//运行configure为下一步编译做准备，详情了解Linux下的configure命令
#./configure --with-php-config=/usr/local/php/bin/php-config
#make
#make install

安装完后你会看到一个提示Installing shared extensions /usr/local/php/lib/php/extensions/no-debug-non-zts-20060626/xhprof.so，说明xhprof.so这个模块被生成了 接下来修改php.ini文件，添加：

//添加xhprof.so这个扩展，位置就是刚才生成给你的
extension=/usr/local/php/lib/php/extensions/no-debug-non-zts-20060626/xhprof.so
//指定生成测试报告分析日志的目录，并保证可写权限
xhprof.output_dir=/home/www/tmp

重启php-fpm重新加载php配置文件 #/etc/init.d/php-fpm restart 至此安装完毕，可以搞个phpinfo();页面看看，如果能看到下图则说明安装成功了[![QQ截图20141103143752](http://storage.veitor.net/uploads/2014/11/QQ截图20141103143752.jpg)](http://storage.veitor.net/uploads/2014/11/QQ截图20141103143752.jpg)  

xhprof的使用
---------

写一个php脚本如

xhprof_enable();
function test()
{
 return 'this is a test demo';
}
test();
$xhprofData = xhprof_disable();
include\_once '/home/www/houseinfo/xhprof\_lib/utils/xhprof_lib.php';
include\_once '/home/www/houseinfo/xhprof\_lib/utils/xhprof_runs.php';
$xhprofRuns = new XHProfRuns_Default();
$xhprofRuns->save\_run($xhprofData,'xhprof\_foo');
?>

通过URL访问该脚本后，会在之前设定的/home/www/tmp（php.ini中设定的）目录下生成分析日志，如“5457280fd8500.xhprof\_foo.xhprof” 其中5457280fd8500为日志生成的id，通过地址http://YOUR\_URL/xhprof_html/index.php?run=**5457315580b0e**&source=xhprof_foo即可查看性能分析（如下图） [![QQ截图20141103154222](http://storage.veitor.net/uploads/2014/11/QQ截图20141103154222.jpg)](http://storage.veitor.net/uploads/2014/11/QQ截图20141103154222.jpg) 你可以将上面php代码最后一行改为这样，以便直接点击链接到分析页查看，而无需自己再查看id并拼接成URL访问

<?php
$run\_id = $xhprofRuns->save\_run($xhprofData,'xhprof_foo');
echo '<a href="/xhprof\_html/index.php?run='.$run\_id.'&source=xhprof\_foo" target="\_blank">查看分析报告</a>';
?>

xhprof提供3种报告： 一、单一运行报告：通过http://YOUR\_URL/xhprof\_html/index.php?run=**5457315580b0e**&source=xhprof\_foo地址查看的单一运行时的报告 二、diff报告：地址如http://YOUR\_URL/xhprof_html/index.php?run1=**xxxxxx**&run2=**xxxxxxx**&source=xhprof\_foo，提供两次对比id即可。 三、汇总报告，指定一组run id来汇总得到您想要的报告视图。如果你有三个XHProf运行，都在"xhprof\_foo‘命名空间下,run id分别是1，2，3。要查看这些运行的汇总报告:http://YOUR\_URL/xhprof\_html/index.php?run**=1，2，3**&source=xhprof_foo XHProf输出说明 1. Inclusive Time ： 包括子函数所有执行时间。 2. Exclusive Time/Self Time ： 函数执行本身花费的时间，不包括子树执行时间。 3. Wall Time ： 花去了的时间或挂钟时间。 4. CPU Time ： 用户耗的时间+ 内核耗的时间 5. Inclusive CPU ： 包括子函数一起所占用的CPU 6. Exclusive CPU ： 函数自身所占用的CPU 可是这个界面看起来不是很直观也不爽，我们还可以装一个graphviz画图工具

#wget http://www.graphviz.org/pub/graphviz/stable/SOURCES/graphviz-2.28.0.tar.gz
#tar -zxvf graphviz-2.28.0.tar.gz
#cd graphviz-2.28.0
#./configure
#make
#make install

安装完成后，会生成/usr/local/bin/dot文件，确保路径在PATH环境变量里，以便XHProf能找到它，graphviz处于**/usr/local/lib/graphviz**。 #vi ~/.bash_profile [![QQ截图20141104133618](http://storage.veitor.net/uploads/2014/11/QQ截图20141104133618.jpg)](http://storage.veitor.net/uploads/2014/11/QQ截图20141104133618.jpg)#echo $PATH 输出一下看看应该有了这个路径 [![QQ截图20141104135151](http://storage.veitor.net/uploads/2014/11/QQ截图20141104135151.jpg)](http://storage.veitor.net/uploads/2014/11/QQ截图20141104135151.jpg) 之后进入分析页面点击\[View Full Callgraph\]就能看到类似下图了

[![callgraph](http://storage.veitor.net/uploads/2014/11/callgraph.png)](http://storage.veitor.net/uploads/2014/11/callgraph.png)