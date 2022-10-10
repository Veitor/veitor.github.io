---
title: '什么是Uber-JAR？'
tags:
  - Java
categories:
  - Java
date: 2022-09-07 09:31:08
---

https://blog.payara.fish/what-is-a-java-uber-jar

`uber-JAR`也叫`fat JAR`或`JAR with dependencies`，一个JAR文件不仅包含了项目模块本身的Java代码，也包含了它的依赖，同时也可能包含了所需要运行的web应用。

### 什么是Uber-JAR？

如前面所讲，`Uber-JAR`在JAR文件中包含了所有的依赖包，它不仅仅包括你写的Java代码类，也包括了在运行时所需的所有依赖。这将使得运行一个Java程序变得简单，你只需要一个包含了所有代码的JAR文件然后输入简单的命令：

```shell
java -jar myapplication.jar
```

当你在Manifest文件中定义了一个带有main方法的类名时，通过这种方式来运行应用程序就足够了。`Uber-JAR`因此还被称为`可执行的JAR`。

### 它可以运行一个Web应用吗？

在Web应用中，你除了main方法之外还有更多的方法需要被启动运行。一个web应用拥有一个特定的artifact、WAR文件夹，还有你放置在`WEB_INF/classes`文件夹下的应用代码和放置在`WEB-INF/lib`目录下的依赖。

这里也存在一个`可执行的WAR`的概念