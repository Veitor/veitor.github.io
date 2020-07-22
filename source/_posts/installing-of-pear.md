---
title: pear安装
tags:
  - pear
  - PHP
url: 470.html
id: 470
categories:
  - 经验分享
date: 2015-01-07 08:45:13
---

说到安装pear，我是因为给一个变量起一个名字，联想到了如何起名才规范，于是又联想到了PHPDocument，要安装PHPDocument可以通过pear安装和手动下载安装，于是乎我就折腾起了这个pear的安装。 根据：http://pear.php.net/manual/en/installation.getting.php中的内容翻译得来 点此http://pear.php.net/go-pear.phar下载文件到本地并命名为go-pear.phar进行保存。在cmd中输入php go-pear.phar 开始安装。

Are you installing a system-wide PEAR or a local copy?
(system|local) \[system\] :

** 选择系统级别安装还是安装本地，默认是system，直接按回车继续。**

Below is a suggested file layout for your new PEAR installation.  To
change individual locations, type the number in front of the
directory.  Type 'all' to change all of them or simply press Enter to
accept these locations.
 1\. Installation base ($prefix)                   : D:\\php5
 2\. Temporary directory for processing            : D:\\php5\\tmp
 3\. Temporary directory for downloads             : D:\\php5\\tmp
 4\. Binaries directory                            : D:\\php5
 5\. PHP code directory ($php_dir)                 : D:\\php5\\pear
 6\. Documentation directory                       : D:\\php5\\docs
 7\. Data directory                                : D:\\php5\\data
 8\. User-modifiable configuration files directory : D:\\php5\\cfg
 9\. Public Web Files directory                    : D:\\php5\\www
10\. Tests directory                               : D:\\php5\\tests
11\. Name of configuration file                    : C:\\Windows\\pear.ini
12\. Path to CLI php.exe                           : D:\\php5
1-12, 'all' or Enter to continue:

**以上是默认的pear的临时、数据、配置、测试、执行目录的设置，第11项默认的话会显示错误，我所以还是改到了D:\\php5目录下（输入需要改的数字项，会提示让你输入新的目录地址，不改的话啥也不用输入直接回车）。然后回车。** **然后一系列安装，其中有以下这个警告：**

WARNING!  The include_path defined in the currently used php.ini does not
contain the PEAR PHP directory you just specified:
<D:\\php5\\pear>
If the specified directory is also not in the include_path used by
your scripts, you will have problems getting any PEAR packages working.
Would you like to alter php.ini<D:\\php5\\php.ini>?\[Y/n\]

**需要将pear配置目录D:\\php5\\pear加入php.ini的include_path指令中。输入Y后自动修改php.ini中的路径。**

php.ini <D:\\php5\\php.ini> include_path updated.
Current include path           : .;C:\\php\\pear
Configured directory           : D:\\php5\\pear
Currently used php.ini (guess) : D:\\php5\\php.ini
Press Enter to continue:

** 到这里也没啥了，按回车基本安装成功了。会在D:\\php5下面生成一个PEAR_ENV.reg的文件，双击运行进行注册表注册即可。** 通过命令pear install package安装程序包，如果出现failed to mkdir的错误，只要以管理员身份重新运行cmd即可。