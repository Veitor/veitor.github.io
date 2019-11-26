---
title: 团队开发中的代码编写规范
tags:
  - 规范
url: 113.html
id: 113
categories:
  - 程序与生活
date: 2014-06-03 14:20:00
---

代码规范问题虽然不影响程序的运行，但是却很可以使代码在管理上变得很容易。

#### 注释

注释是对于那些容易忘记作用的代码添加简短的介绍性内容。请使用 C 样式的注释“/* */”和标准 C++ 注释“//”。类、方法、函数请使用 phpdoc 格式的注释，在函数及方法的注释中至少要有 @param 和 @return 标签，如：

 /\*\*
\* 这里是函数说明
\*
\* @param int $a 参数1
\* @param int $b 参数2
\* @return xxx 参数1与参数2乘积
*/
public function function\_demo\_1($a, $b)
{
	return intval($a) * intval($b);
}

对于 bug 修正时务必写上 bug 修改人、修改时间和修正 bug 的原因。

// add xxx by liuming@leju.sina.com.cn on 2009-09-01, test
// remove xxx by guoning@leju.sina.com.cn on 2009-09-02, test
// last modified by liuxin@leju.sina.com.cn on 2009-09-05, typo
// last modified by dengwei@leju.sina.com.cn on 2009-09-09, typo
// fixed memory leak
unset($something);

程序开发中难免留下一些临时代码和调试代码，此类代码必须添加注释，以免日后遗忘。所有临时性、调试性、试验性的代码，必须添加统一的注释标记“//@debug:”并后跟完整的注释信息，这样可以方便在程序发布和最终调试前批量检查程序中是否还存在有疑问的代码。例如：

$num = 1;
$flag = true; // @debug: 测试文件加载
if (!$flag)
{
	// debug statements
}

 

#### 书写规则

缩进与换行：每个缩进的单位约定是一个TAB(4个空白字符宽度)，需每个参与项目的开发人员在编辑器中进行强制设定，以防在编写代码时遗忘而造成格式上的不规范。并且所有换行采用 UNIX 格式，既只有 \\n 换行。 本缩进规范适用于 HTML、PHP、JS、AS 中的函数、类、逻辑结构、循环等。 大括号 {}、if 和 switch：首括号与关键词同行，尾括号与关键字同列； if 结构中，if 和 elseif 与前后两个圆括号同行，左右各一个空格，所有大括号都单独另起一行。另外，即便if后只有一行语句，仍然需要加入大括号，以保证结构清晰； switch 结构中，通常当一个 case 块处理后，将跳过之后的 case 块处理，因此大多数情况下需要添加 break。break 的位置视程序逻辑，与 case 同在一行，或新起一行均可，但同一 switch 体中，break 的位置格式应当保持一致。 以下是符合上述规范的例子：

if ($condition)
{
	switch ($var)
	{
    	case 1:
       		echo 'var is 1';
      		break;
      	case 2:
          	echo 'var is 2';
          	break;
        	default:
    	echo 'var is neither 1 or 2';
        	break;
	}
}
else
{
	switch ($str)
 	{
   		case 'abc':
     		$result = 'abc';
    		break;
     	default:
           	$result = ‘unknown’;
        	break;
	}
}

例外的，数据库 SQL 语句中，除字符串外所有数据都不得加单引号，但是在进行 SQL 查询之前都必须经过 intval 等相关函数处理；所有字符串都必须加单引号，以避免可能的注入漏洞和SQL错误。正确的写法为：

$catid = intval($catid); // 当 $catid 只能为 int 时
$username = addslashes($username);
$username = "SELECT * FROM phpcms_member WHERE username = '{$username}' AND catid = {$catid}";

  所有数据在插入数据库之前，均需要进行addslashes()处理，以免特殊字符未经转义在插入数据库的时候出现错误。如果使用基础类 baselib\_request\_arg 通过 GET、POST、FILE 取得的变量默认情况下已经使用了 addslashes() 进行了转义，不必重复进行。如果数据处理必要(例如用于直接显示)，可以使用 stripslashes() 恢复，但数据在插入数据库之前必须再次进行转义。 缓存文件中，一般对缓存数据的值采用 addcslashes($string, '\\'\\\') 进行转义。

#### 命名原则

命名是程序规划的核心，只要你给事物想到正确的名字，就会给你以及后来的人带来比代码更强的力量。总的来说，只有了解系统的程序员才能为系统取出最合适的名字。如果所有的命名都与其自然相适合，则关系清晰，含义可以推导得出，一般人的推想也能在意料之中。 就一般约定而言，类、函数和变量的名字应该总是能够描述让代码阅读者能够容易的知道这些代码的作用。形式越简单、越有规则，就越容易让人感知和理解。应该避免使用模棱两可，晦涩不标准的命名。 **变量、对象、函数名** 变量、对象、函数名一律为小写格式，单词之间一般使用下划线 “_” 进行分割； 以标准计算机英文为蓝本，杜绝一切拼音、或拼音英文混杂的命名方式； 变量命名只能使用项目中有据可查的英文缩写方式，例如可以使用$data而不可使用$data1、$data2这样容易产生混淆的形式，应当使用 $article\_data、$user\_data 这样一目了然容易理解的形式； 可以合理的对过长的命名进行缩写，例如 $bio($biography)，$tpp($threadsPerPage)，$uid($userid) 前提是英文中有这样既有的缩写形式，或字母符合英文缩写规范； 必须清楚所使用英文单词的词性，在权限相关的范围内，大多使用$enable***、$is*** 的形式，前者后面接动词，后者后面接形容词。 **常量** 常量应该总是全部使用大写字母命名，少数特别必要的情况下，可使用划线来分隔单词； PHP 的内建值 TRUE、FALSE 和 NULL 必须全部采用大写字母书写。

#### 变量的初始化与逻辑检查

任何变量在进行累加、直接显示或存储前必需进行初使化，例如：  

$number = 0; //数值型初始化
$string = ''; //字符串初始化
$array = array(); //数组初始化

  判断一个无法确定（不知道是否已被赋值）的变量时，可用 empty() 或 isset()，而不要直接使用 if($switch) 的形式，除非你确切的知道此变量一定已经被初始化并赋值。 判断一个变量是否为数组，请使用is_array()，这种判断尤其适用于对数组进行遍历的操作，例如foreach()，因为如果不事先判断，foreach()会对非数组类型的变量报错； 判断一个数组元素是否存在，可使用isset($array\[‘key’\])，也可使用empty()，两者异同见上。

#### 兼容性

代码设计应当兼顾 PHP 高低版本的特性。当前应仍然以 PHP 5.2 作为最低通过平台(部分历史遗留项目例外)，尽量不使用高版本 PHP 5.3 新增的函数、常数或者常量。如果使用只在高版本才具备的函数，必须对其进行二次封装，自动判断当前 PHP 版本，并自行编写低版本下的兼容代码； 对于个别函数，参数要求或者代码要求应当以较为严格的PHP版本为准； 除非必要，不要使用 PHP 扩展模块中的函数。使用时应当加入必要的判断，当服务器环境不支持此函数的时候，进行必要的处理。文档和程序中的功能说明中，也应加上兼容性说明。

#### 包含调用

包含调用程序文件时，请全部使用 require\_once，以避免可能的重复包含问题； 包含调用缓存文件，由于缓存文件无法保证 100% 正确打开，请使用 include\_once。在必要时，可以使用 @include\_once 的方式，以忽略错误提示；我们仍建议大家把缓存数据放到 LC (Local cache:xcache、eaccelerator、APC) 或 RC (remote cache:memcached、couchdb ...)。 包含和调用代码中，须以 APP\_ROOT . '/'开头，应避免直接写程序文件名 (例如：require_once 'x.php') 的做法； 所有被包含和调用的程序文件，包括但不限于程序、缓存或模板，通常其不能被直接URL请求。通过在 ./config.php 中定义一个标记性常量 APPNAME ，来判断程序是否被合法调用。因此，在除了./config.php 以外的任何一个被包含和调用的程序文件中，需要包含以下内容，以使得访问者无法直接通过URL 请求该文件： defined('APPNAME') or exit('Access Denied'); **错误报告级别** 在开发和调试阶段，请使用 error\_reporting(E\_ALL) 作为默认的错误报告级别，此级别最为严格，能够报告程序中所有的错误、警告和提示信息，以帮助大家检查和核对代码，避免大多数安全性问题和逻辑错误、拼写错误。error\_reporting() 可以公共头文件进行设置，或某个指定的文件进行设置，但是请不要在各个文件中都加一个 error\_reporting 。 代码部署时，请删除所有 error\_reporting 和 ini\_set('display_errors', xxx) 设置，php 采用服务器默认配置，此配置由服务器维护人员统一配置。

#### 数据库设计

**字段** 表和字段命名：表和字段的命名以前面《命名原则》的约定为基本准则。所有数据表名称，只要其名称是可数名词，则必须以复数方式命名，例如：members(用户表)；存储多项内容的字段，或代表数量的字段，也应当以复数方式命名，例如：hits(查看次数)、items(内容数量)。 当几个表间的字段有关连时，要注意表与表之间关联字段命名的统一，如 article\_hash\_01 表中的 articleid 与 article\_data\_hash_01 表中的 articleid。 代表id自增量的字段，通常用以下几种形式：

*   一般情况下，使用全称的形式，例如 userid、articleid；
*   没有功能性作用，只为管理和维护方便而设的id，可以使用全称的形式，也可只将其命名为id。

**字段结构** 允许 NULL 值的字段，数据库在进行比较操作时，会先判断其是否为 NULL，非 NULL 时才进行值的必对。因此基于效率的考虑，建议所有字段均不能为空，即全部 NOT NULL； 预计不会存储非负数的字段，例如各项 id、发帖数等，必须设置为 UNSIGNED 类型。 UNSIGNED 类型比非 UNSIGNED 类型所能存储的正整数范围大一倍，因此能获得更大的数值存储空间； 存储开关、选项数据的字段，通常使用 tinyint(1) 非 UNSIGNED 类型，少数情况也可能使用enum() 结果集的方式。tinyint 作为开关字段时，通常 1 为打开；0 为关闭；-1 为特殊数据，例如 N/A(不可用)；高于 1 的为特殊结果或开关二进制数组合； MEMORY/HEAP 类型的表中，要尤其注意规划节约使用存储空间，这将节约更多内存。例如cdb_sessions 表中，就将 IP 地址的存储拆分为4个 tinyint(3) UNSIGNED 类型的字段，而没有采用 char(15) 的方式； 任何类型的数据表，字段空间应当本着足够用，不浪费的原则。

#### SQL语句

所有 SQL 语句中，除了表名、字段名称以外，全部语句和函数均需大写，应当杜绝小写方式或大小写混杂的写法。例如 select * from members; 是不符合规范的写法。 很长的 SQL 语句应当有适当的断行，依据 JOIN、FROM、ORDER BY等关键字进行界定。 通常情况下，在对多表进行操作时，要根据不同表名称，对每个表指定一个 1 ~ 2 个字母的缩写，以利于语句简洁和可读性。 如下的语句范例，是符合规范的：

$result = $db->query("SELECT m.*, i.*
FROM " . TABLE\_MEMBER . " AS m, " . TABLE\_MEMBERINFO . " AS i
WHERE m.userid = i.userid AND m.userid = '$_userid');

  原文地址：http://www.nowamagic.net/librarys/veda/detail/513