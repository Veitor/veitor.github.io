---
title: 'PHP日志处理指南'
tags:
  - php
categories:
  - PHP
date: 2020-06-30 15:52:27
---

PHP日志不仅仅记录错误，你也可以使用日志来追踪API或函数调用的性能，或统计你应用程序中重要事件的发生次数（例如登录、注册、下载等）。无论你是微服务还是单体架构，对PHP应用程序日志的全面记录将会让你能够追踪应用中关键点，并优化其性能。

PHP和开源的日志库让你可以选择在哪里发送日志和存储日志。如你在这篇文章中看到，将PHP日志存储在一个中央仓库是最简单的，并且为以后处理和分析日志提供了很大的便捷。当你使用专用的工具对日志文件进行tail并转发到中央仓库时，你的应用程序代码不需要承担缓冲日志和处理网络错误的代价。

在这篇文章，你将学习到：

- 配置PHP System logger来实现自动记录错误日志
- 使用PHP原生方法来记录自定义错误
- 使用Monolog日志库来扩展你的日志收集能力
- 捕获PHP异常和任意的事件

<!-- more -->

# PHP如何创建日志

当你的代码产生了一个错误时，PHP [System logger](http://php.net/manual/en/book.errorfunc.php) 会自动创建日志。你也可以在你的应用程序中，根据你的需求调用PHP日志方法来创建日志，记录你的自定义错误或任意的事件。接下来，我们将看到每种机制下的日志是如何被创建和被路由的。

### PHP System logger

你可以在PHP配置文件`php.ini`中使用`error_reporting`指令来配置PHP Sysyem logger，这将指定PHP自动记录日志的类型。其使用预定义的一组常量和位运算符来表示日志中哪些类型的事件将被包含或排除：

```ini
error_reporting = E_ALL
```

PHP的`display_errors`配置指令可以让你将日志消息展示在浏览器中。在生产环境，出于安全原因，你应该总是设置`display_errors`为`off`。但是，在开发环境，你可以把warnings和errors直接展示在浏览器中以便开发人员能够直接了解信息。

![在浏览器中展示日志信息](https://imgix.datadoghq.com/img/blog/php-logging-guide/php-display-errors.png?auto=format&w=1140)

PHP System logger根据你在`php.ini`中`error_log`指令配置的值，来以不同的方式对日志进行路由：

- 如果`error_log`指定了一个文件，PHP将日志写入该文件。
- 如果`error_log`设置为`syslog`，PHP发送日志到OS logger，在Linux上通常是`syslog`或者更新的`rsyslog`（实现了syslog协议），在Windows上是`Event Log`。
- 如果`error_log`未设置，PHP使用[Server API(SAPI)](http://php.net/manual/en/function.php-sapi-name.php)创建日志。SAPI的使用由你的平台决定。例如LAMP中使用`apache`作为SAPI，并且日志将写到[Apache的error log](http://httpd.apache.org/docs/current/logs.html#errorlog)。

为了让你日后可以有最全的日志数据进行收集、处理和分析，添加这些配置到你的`php.ini`中（在PHP的`.ini`文件中，一个分号表示一个注释语句）：

```ini
; Log all errors
error_reporting = E_ALL
; Don't display any errors in the browser
display_errors = Off
; Write all logs to this file:
error_log = my_file.log
```

现在你的日志将会按照`error_log`指令的配置往`my_file.log`文件中写入。

### PHP的日志函数

你可以在应用程序中显示调用PHP的`error_log()`或`syslog()`函数记录任何的事件。这些方法将创建包含你所提供的内容信息的日志。`syslog()`方法会使用你`rsyslog.conf`配置文件中的配置来写入日志信息。`error_log`方法会把日志路由到`error_log`指令所配置的文件中。下面的示例发送了一个信息到PHP system logger：

```php
<?php
error_log("An error has occurred.");
```

PHP system logger自动为每条日志创建一个时间戳，像这样：

```
[15-Apr-2019 20:25:11 UTC] An error has occurred.
```

如果`php.ini`中没有配置`error_log`，日志将会由SAPI生成，其格式由SAPI决定。例如，在LAMP中，使用的是[Apache的默认日志配置](http://httpd.apache.org/docs/current/logs.html)，则上面示例将会生成日志到Apache的错误错误日志中（如/var/log/apache2/error.log）：

```
[Mon Apr 15 20:25:11.950260 2019] [php7:notice] [pid 26154] [client 123.123.123.123:57728] An error has occurred.
```

PHP的`error_log()`和`syslog()`方法提供了更多选项配置让你往哪发送日志。例如，当你决定调用`error_log()`，你可以提供一个与`.ini`文件中`error_log`指定不同的文件路径，则日志将会记录到该路径中。关于`error_log()`和`syslog()`更多高级路由能力请参考[PHP文档](https://www.php.net/manual/en/ref.errorfunc.php)。在这篇文章中，我们将关注记录日志到文件中，因为这将给你提供转发和处理日志的能力。

### 集中存储你的日志

到目前我们已经了解了PHP的system logger和原生日志方法。当你想要自定义你的日志如何格式化和路由时，这些方法无法更多的灵活性，但是我们可以将它们写入到一个本地文件中再进行下一步操作。你可以使用外部服务来处理你的日志，考虑一下这个策略：写入日志到一个本地文件，并把它们转发到外部服务进行聚合、分析和监控。这样你可以在单个平台聚合所有机器上的日志，切可以更有效的对事件进行故障排查。

当你使用一个日志管理和分析平台时，我们推荐你使用`JSON`格式的日志。这会使得其容器被处理、搜索、过滤和监控。为了使得创建JSON日志并路由它们到文件更加容易，我们推荐你使用Monolog库来格式化你的日志为JSON，并自动添加元信息到你的日志中。

### 使用Monolog日志库

Monolog是一个使用最广泛的PHP日志记录库，你可以通过Composer安装：

```
composer require monolog/monolog
```

关于更多Monolog库的使用方法，推荐直接查看Monolog官方文档：https://github.com/Seldaek/monolog

### 捕获异常并记录日志

这一节就不过多阐述了，你完全可以参考目前比较流行的几个PHP框架，去了解这些框架中如何捕获异常并记录日志的。

