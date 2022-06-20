---
title: 了解PHP中crypt加密函数
tags:
  - crypt
  - PHP
  - 加密
url: 86.html
id: 86
categories:
  - PHP
date: 2014-05-10 08:33:05
---

曾经在分析Yii框架的博客demo中看到使用了这个crypt函数，于是就大致的了解了一下。

crypt() 返回一个基于标准 UNIX DES 算法或系统上其他可用的替代算法的散列字符串，这是手册中写到的，可能有些同学不是很理解这句话，我的理解就是，crypt回返回不同类型的散列字符串，即使用了不同算法返回的。而具体使用哪个算法，还要看所以来的操作系统。 PHP中有几个常量，分别是CRYPT_STD_DES 、CRYPT_EXT_DES、CRYPT_MD5、CRYPT_BLOWFISH、CRYPT_SHA256、CRYPT_SHA512。 这些常量不是1就是0，也意味着其所对应的算法是否可用。

<!-- more -->

我们可以看一下下面代码的输出结果：

if (CRYPT_STD_DES == 1) {
    echo 'Standard DES: ' . crypt('rasmuslerdorf', 'rl') . "<br>";
}
if (CRYPT_EXT_DES == 1) {
    echo 'Extended DES: ' . crypt('rasmuslerdorf', '_J9..rasm') . "<br>";
}
if (CRYPT_MD5 == 1) {
    echo 'MD5:          ' . crypt('rasmuslerdorf', '$1$rasmusle$') . "<br>";
}
if (CRYPT_BLOWFISH == 1) {
    echo 'Blowfish:     ' . crypt('rasmuslerdorf', '$2a$07$usesomesillystringforsalt$') . "<br>";
}
if (CRYPT_SHA256 == 1) {
    echo 'SHA-256:      ' . crypt('rasmuslerdorf', '$5$rounds=5000$usesomesillystringforsalt$') . "<br>";
}
if (CRYPT_SHA512 == 1) {
    echo 'SHA-512:      ' . crypt('rasmuslerdorf', '$6$rounds=5000$usesomesillystringforsalt$') . "<br>";
}

输出结果：

Standard DES: rl.3StKT.4T8M
Extended DES: _J9..rasmBYk8r9AiWNc
MD5: $1$rasmusle$rISCgZzpwk3UhDidwXvin0
Blowfish: $2a$07$usesomesillystringfore2uDLvp1Ii2e./U9C8sBjqp8I90dH6hi
SHA-256: $5$rounds=5000$usesomesillystri$KqJWpanXZHKq2BOB43TSaYhEWsQ1Lr5QNyPCDH/Tp.6
SHA-512: $6$rounds=5000$usesomesillystri$D4IrlXatmP7rx3P3InaxBeoomnAihCKRVQP22JZ6EY47Wc6BkroIuUUBOov1i.S5KPgErtP/EN5mcO.ChWQW21

第一个结果是基于标准 DES 算法的散列，使用 "./0-9A-Za-z" 字符中的两个字符作为盐值，本例中使用了"rl"，你可以试一下添加更多字符如"rlsdfs"，输出结果还是不变的。手册中说，如果不提供salt，默认使用该算法，但我试过之后发现是使用的下面md5。 第二个结果是扩展的基于 DES 算法的散列。其盐值为 9 个字符的字符串，由 1 个下划线后面跟着 4 字节循环次数和 4 字节盐值组成。它们被编码成可打印字符，每个字符 6 位，有效位最少的优先。0 到 63 被编码为 "./0-9A-Za-z"。 第三个结果就是使用了md5后的散列，使用一个以 $1$ 开始的 12 字符的字符串盐值。 第四个Blowfish 算法使用如下盐值：“$2a$”，一个两位 cost 参数，“$” 以及 64 位由 “./0-9A-Za-z” 中的字符组合而成的字符串。在盐值中使用此范围之外的字符将导致 crypt() 返回一个空字符串。两位 cost 参数是循环次数以 2 为底的对数，它的范围是 04-31，超出这个范围将导致 crypt() 失败。 第五个结果是 SHA-256 算法，使用一个以 $5$ 开头的 16 字符字符串盐值进行散列。如果盐值字符串以 “rounds=<N>$” 开头，N 的数字值将被用来指定散列循环的执行次数，这点很像 Blowfish 算法的 cost 参数。默认的循环次数是 5000，最小是 1000，最大是 999,999,999。超出这个范围的 N 将会被转换为最接近的值。 第六个是 SHA-512 算法，使用一个以 $6$ 开头的 16 字符字符串盐值进行散列。如果盐值字符串以 “rounds=<N>$” 开头，N 的数字值将被用来指定散列循环的执行次数，这点很像 Blowfish 算法的 cost 参数。默认的循环次数是 5000，最小是 1000，最大是 999,999,999。超出这个范围的 N 将会被转换为最接近的值。

* * *

大致的了解了一下crypt几种散列类型，但最终如何应用？ 使用crypt加密就是为了即使加密列表落入他人手中，也无法获得其明文，因为该加密是不可逆的。 单纯的使用crypt($input_pwd)会生成不同的随机值。（本人在win系统和centos上获得的都是基于md5的散列值，即$1$开头的随机值） 使用crypt加密方式有很多，你或许可以使用：

<?php
$pwd = 'veitor';		//注册密码明文
crypt($pwd);
?php

将注册密码明文用crypt随机生成的散列值存入数据库。 验证登陆时：

<?php
$input_pwd = 'veitor';		      //表单输入密码明文
crypt($input_pwd, $pwd) == $pwd       //$pwd为上一步数据库中的加密暗文
?>

你需要使用库中的加密暗文作为salt，这样做是指定crypt使用的散列类型。比如我上一步注册生成的暗文是基于MD5的，则暗文以$1$开头多位字符串，那么在这一步中，使用该暗文作为salt，crypt判断$1$就知道使用的散列类型是md5了。（另外，改成crypt($input_pwd, sub_str($pwd,0,12)) == $pwd也是正确的，因为基于md5散列时，salt只使用到前12个字符） 当然你还可以使用crypt和md5两个函数的结合，使得密码更安全，如md5(crypt($pwd))这种方式，生成后的依旧是32位字符，初看就以为是md5加密而已，即使再庞大的数据系统也难以进行暴力破解。 以上只是本人的一点小理解，或许存在偏差，如果你有更好的想法，不妨留个言一起探讨。