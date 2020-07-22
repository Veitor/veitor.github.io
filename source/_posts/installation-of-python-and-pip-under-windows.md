---
title: Windows下安装python和pip
tags:
  - pip
  - python
url: 389.html
id: 389
categories:
  - python
date: 2014-11-18 08:11:43
---

此前安装过python，但因为安装pip过程中遇到了问题，所以把python也一起卸载了。现在重新安装一下这两个。 这里选择了python2.7.8版本进行安装，因为我需要使用sqlmap这个工具，而这个工具对python版本有要求，最新版本的python会出错，所以我选择了2.7.8的版本。 首先上官网https://www.python.org/downloads 下载

[![QQ截图20141118141425](http://storage.veitor.net/uploads/2014/11/QQ截图20141118141425.jpg)](http://storage.veitor.net/uploads/2014/11/QQ截图20141118141425.jpg)

下载的是msi文件，直接打开像安装普通软件一样安装就行。**但有一点一定要注意，如果你要使用pip，则安装python时选择的安装路径目录中不要有空格，如果安装到了Program Files这样的目录下，那么接下来安装的pip将无法正常运行，会报错。**所以这里我直接选择了D盘下，安装前记得选择将python.exe添加到系统环境变量。 [![QQ图片20141118142038](http://storage.veitor.net/uploads/2014/11/QQ图片20141118142038.jpg)](http://storage.veitor.net/uploads/2014/11/QQ图片20141118142038.jpg)   安装完之后在CMD中输入python命令会看到欢迎界面。 接下来安装pip，上https://pip.pypa.io/en/latest/installing.html下载 get-pip.py脚本 在CMD下找到该文件目录并运行下列命令（需要管理员权限）： python get-pip.py [![QQ截图20141118142644](http://storage.veitor.net/uploads/2014/11/QQ截图20141118142644.jpg)](http://storage.veitor.net/uploads/2014/11/QQ截图20141118142644.jpg) 安装好之后，会发现python安装目录下会多出一个Scripts目录（若之前没有）。 这时我们直接在命令行输入pip，会显示‘pip’不是内部命令，也不是可运行的程序。因为我们还没有添加环境变量。 只要在PATH变量中添加：D:\\Python27\\Scripts;（路径自己更换）就好了，输入pip list 查看安装情况 [![QQ截图20141118143306](http://storage.veitor.net/uploads/2014/11/QQ截图20141118143306.jpg)](http://storage.veitor.net/uploads/2014/11/QQ截图20141118143306.jpg)   如果出现下列错误，那么原因可能就是上面我所说的python安装路径目录名中有空格了  

Fatal error in launcher: Unable to create process using '"D:\\Program Files\\Python27\\python.exe" "D:\\Program Files\\Python27\\Scripts\\pip.exe" '

  （完）