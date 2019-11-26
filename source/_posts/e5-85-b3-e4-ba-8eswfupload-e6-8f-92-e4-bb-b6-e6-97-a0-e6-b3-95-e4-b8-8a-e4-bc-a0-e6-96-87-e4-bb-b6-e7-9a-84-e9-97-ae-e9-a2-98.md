---
title: 关于swfupload插件无法上传文件的问题
tags:
  - flash
  - PHP
  - session
url: 476.html
id: 476
categories:
  - JS
  - PHP
  - 编程语言
date: 2015-01-17 08:59:29
---

因为项目上所使用的flash上传图片插件名叫swfupload，但里面的js写法好像另一个上传插件sapload，所以我也搞不清到底是哪个，但最终了解到这两个插件都是有共同的一个问题，就是对需要进行身份才能上传文件的方式会失效。 我们都知道服务器端要对识别当前用户登录状态需要客户端cookie的支持，请求URL时会带着cookie，服务器端才能找到对应的session。而使用这个flash插件上传文件请求接口时，如果被请求的接口需要登陆才能传文件的话，那很可能就会失败。 **一种原因是说：因为该插件会忽略部分浏览器下的cookie，IE和chrome下是正常的，像火狐等浏览器上传文件时，服务器端会发现请求带过来的cookie是空的（建议尝试打印一下cookie）。** **另一种可能的说法：该插件是通过soket套接字进行通信，相当于建立了一次新对话，即使请求带着cookie过去了，但打印出来发现存储的sessionid并不是当前登录时的，因此用户身份又验证失败。（建议多打印cookie并查看）** **归根到底，无法上传文件的原因就是无法验证身份。** 解决方法有两种： 1、在初始化flash插件时，在js代码中设置一下传递参数（可参考其插件手册）。swfupload插件中增加一个post_params选项，格式如post\_params:{"PHPSESSID": <?php echo session\_id(); ?>} ，sapload插件中增加一个args选项，格式如args:"PHPSESSID=<?php echo session_id(); ?>" 。这两个意思都是在post文件时，带上参数PHPSESSID（注：后端是PHP脚本）。 咱用不了cookie中的值，那就用POST过来值，然后在PHP脚本中处理一下：

if(isset($_POST\['PHPSESSID'\])){
    session\_id($\_POST\['PHPSESSID'\]);
    session_start()
}

这样就可以使用当前登录正确的session id进行一系列操作了。 2、取消上传URL接口的登陆验证。（有点蛋疼，非必要情况下还是使用第一种方法吧）     附（这是给我自己看的，swfupload好像格式有所不同，如本文开头提到的，不知道是不是同一个插件）： **flash 接口文档：** upUrl ：后台文件的地址，必须要绝对路径 etmsg：每次文件上传成功后需不需要回调函数（0|1），默认回调函数为sapLoadMsg(x)函数。 ltmsg：最后一个文件上传成功后需不需要回调函数（0|1），默认回调函数为sapLoadMsg(x)函数。 types：上传文件的类型（如*.apk;*.jpg）用分号分隔各个类型 args：需要传递的参数（如apkName=123;apkName1=1234)用分号分隔各个类型 fileName：此参数可选，允许你自定义文件域名称，默认是Filedata。 maxNum：当最大上传数为1的时候自动切换到单文件上传模式，用户将不能在使用多选选取文件。