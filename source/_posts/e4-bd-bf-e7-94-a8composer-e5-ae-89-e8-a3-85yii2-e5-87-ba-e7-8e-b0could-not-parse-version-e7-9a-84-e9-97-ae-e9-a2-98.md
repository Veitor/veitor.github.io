---
title: 使用composer安装yii2出现"could not parse version.."的问题
url: 528.html
id: 528
categories:
  - 程序与生活
  - 经验分享
date: 2015-08-14 00:53:42
tags:
---

如果安装时出现这个错误

\[UnexpectedValueException\]
Could not parse version constraint <=2.*: Invalid version string "2.*"

很有可能是composer Asset插件版本的问题 官网说明使用“composer global require "fxp/composer-asset-plugin:~1.0.0"” 可是会出错，所以如果出错了，使用这个命令"composer global require "fxp / composer-asset-plugin: 1.0.1"重新安装一遍后，再安装yii2应该会正常了