---
title: sublime下配置编译和运行C程序
tags:
  - C
  - sublime
url: 447.html
id: 447
categories:
  - 程序与生活
  - 经验分享
date: 2014-12-19 07:26:45
---

我使用的是sublime3，首先下载MinGW，别问我是啥，我也不怎么了解，网上说 MinGW 提供了一套简单方便的Windows下的基于GCC 程序开发环境，提供了GNU工具集。在这里我就理解它提供了gcc、g++、make等编译器吧。具体自行了解。 你可以上minGW官网http://www.mingw.org/或其他地方可以下载到，可视化安装界面，自行选择目录安装。比如我安装到了D:\\minGW 安装完毕后，将minGW安装目录下的bin目录添加到环境变量，如下图，我将D:\\minGW\\bin添加到环境变量

[![QQ图片20141219150247](http://storage.veitor.net/uploads/2014/12/QQ图片20141219150247.jpg)](http://storage.veitor.net/uploads/2014/12/QQ图片20141219150247.jpg)

接着配置sublime，工具栏选择工具（tools）-编译系统，然后新建一个编译系统

[![QQ图片20141219150736](http://storage.veitor.net/uploads/2014/12/QQ图片20141219150736.jpg)](http://storage.veitor.net/uploads/2014/12/QQ图片20141219150736.jpg)输入以下配置：

{
	"shell\_cmd": "gcc \\"${file}\\" -o \\"${file\_path}/${file\_base\_name}\\" -std=c11 -O2 -Wall -lm --static",
	"file_regex": "^(..\[^:\]*):(\[0-9\]+):?(\[0-9\]+)?:? (.*)$",
	"working\_dir": "${file\_path}",
	"selector": "source.c, source.c++",
	"variants":
	\[
		{
			"name": "Run",
			"shell\_cmd": "gcc -std=c11 -O2 -Wall -lm --static \\"${file}\\" -o \\"${file\_path}/${file\_base\_name}\\" && \\"${file\_path}/${file\_base_name}\\""
		}
	\]
}

保存在Sublime Text的Packages目录下即可。 然后敲一段C程序然后保存为.c文件，按ctrl+B会在这文件旁生成exe程序，按ctrl+shift+B会在sublime控制台中显示运行结果（如下图） [![QQ图片20141219152044](http://storage.veitor.net/uploads/2014/12/QQ图片20141219152044.jpg)](http://storage.veitor.net/uploads/2014/12/QQ图片20141219152044.jpg)   至此大功告成。