---
title: URL相似度计算的思考
tags:
  - URL
url: 138.html
id: 138
categories:
  - 经验分享
date: 2014-07-17 00:59:35
---

在做一些web相关的工作的时候，我们往往可能需要做一些对url的处理，其中包括对相似的url的识别和处理。这就需要计算两个url的相似度。 那么怎么进行url相似度的计算的？我首先想到的是把一个url看作是一个字符串，这样就简化成两个字符串相似度的计算。字符串相似度计算有很多已经比较成熟的算法，比如“[编辑距离算法](http://en.wikipedia.org/wiki/Levenshtein_Distance)”，该算法描述了两个字符串之间转换需要的最小的编辑次数；还有一些其他的比如“[最长公共字串](http://www.cnblogs.com/dartagnan/archive/2011/10/06/2199764.html)”等方法。但这些方法对于url相似度的计算来说是不是够了呢？比如给以下三个url： url1: www.spongeliu.com/xxx/123.html url2: www.spongeliu.com/xxx/456.html url3: www.spongeliu.com/xxx/abc.html 这三个url的编辑距离是一致的，但是直观上我们却认为url1和url2更加相似一些。 再比如我们要判断两个站点是否同一套建站模版建立的，抽出两个url如下这样： url1: www.163.com/go/artical/43432.html url2: www.sina.com.cn/go/artical/453109.html 这两个url按照情景应该是相似的，这就超出了字符串相似度判断的能力范围。 

重新回到问题，要判断的是两个url的相似度，但是字符串的判断方法又不能很好应用。那么url和字符串的区别在哪里？这取决于如何定义相似的url。可以注意到，url比字符串含有更多的信息可以参考，因为url本身是包含**结构和特征**的，比如站点、目录。定义相似url的时候，是否要考虑站点？是否要考虑目录的一致？是否要考虑目录的深度？这取决于具体的需求。 考虑到url本身的结构，对其相似度的计算就可以抽象为对其关键特征相似度的计算。比如可以把站点抽象为一维特征，目录深度抽象为一维特征，一级目录、二级目录、尾部页面的名字也都可以抽象为一维特征。比如下面两个url: url1:  http://www.spongeliu.com/go/happy/1234.html url2:  http://www.spongeliu.com/snoopy/tree/abcd.html 先不定义他们是否相似，先来抽象一下他们的特征： 

1、站点特征：如果两个url站点一样，则特征取值1，否则取值0； 

2、目录深度特征：特征取值分别是两个url的目录深度是否一致； 

3、一级目录特征：在这维特征的取值上，可以采用多种方法，比如如果一级目录名字相同则特征取1，否则取0；或者根据目录名字的编辑距离算出一个特征值； 或者根据目录名字的pattern，如是否数字、是否字母、是否字母数字穿插等。这取决于具体需求，这里示例仅仅根据目录名是否相同取1和0； 

4、尾页面特征：这维特征的取值同一级目录，可以判断后缀是否相同、是否数字页、是否机器生成的随机字符串或者根据编辑长度来取值，具体也依赖于需求。这里示例仅仅判断最后一级目录的特征是否一致（比如是否都由数字组成、是否都有字母组成等）。 这样，对于这两个url就获得了4个维度的特征，分别是：1 1 0 0 。 有了这两个特征组合，就可以根据具体需求判断是否相似了。我们定义一下每个特征的重要程度，给出一个公式： similarity = feather1 * x1 + feather2\*x2 + feather3\*x3 + feather4*x4; 其 中x表示对应特征的重要程度，比如我认为站点和目录都不重要，最后尾页面的特征才是最重要的，那么x1,x2,x3都可以取值为0，x4取值为 1，这样根据similarity就能得出是否相似了。或者认为站点的重要性占10%，目录深度占50%，尾页面的特征占40%，那么系数分别取值为 0.1\\0.5\\0\\0.4即可。 其实这样找出需要的特征，可以把这个问题简化成一个机器学习的问题，只需要人为判断出一批url是否相似，用svm训练一下就可以达到机器判断的目的。 除了上面这种两个url相似度的判断，也可以将每一条url都抽象成一组特征，然后计算出一个url的得分，设置一个分数差的阈值，就可以达到从一大堆url中找出相似的url的目的。   下面的代码是perl编写的抽象两个url特征的脚本，这只是一个测试的脚本，难免有bug和丑陋的地方，仅供参考：

```perl
#!/usr/bin/perl
use strict;
use warnings;
my $url1 = $ARGV\[0\];
my $url2 = $ARGV\[1\];
my @array1 = split( /\\//, $url1 );
my @array2 = split( /\\//, $url2 );
#特征1：目录数
my $path1 = @array1;
my $path2 = @array2;
#print $path1, $path2;
#特征2：是否目录结尾
my $lastispath1 = 0;
my $lastispath2 = 0;
if( $url1 =~ /\\/$/ )
{
	$lastispath1 = 1;
}
if( $url1 =~ /\\/$/ )
{
	$lastispath2 = 1;
}
```
#特征3：最后一级是否有后缀(htm,html,shtml等)
```shell
my $len;
my $hassuffix1 = 0;
my $hassuffix2 = 0;
my $suffixstr;
my $laststr1 = $array1\[$path1 - 1\];
my $laststr2 = $array2\[$path2 - 1\];
my $issuffixsame = 0;
if( $lastispath1 == 0 )
{
	my @suffix1 = split( /\\./, $array1\[$path1 - 1\]);
	if( @suffix1 &gt;= 2 )
	{
		$len = rindex( $suffix1\[@suffix1 - 1\]."\\$", "\\$");
		if( $len &lt;= 5 )
		{
			$hassuffix1 = 1;
			$suffixstr = $suffix1\[@suffix1 - 1\];
			my $tmplen = rindex( $array1\[@array1 - 1\]."\\$", "\\$");
			$laststr1 = substr( $array1\[@array1 - 1\], 0, $tmplen-$len-1 );
		}
	}
}
if( $lastispath2 == 0 )
{
	my @suffix2 = split( /\\./, $array2\[$path2 - 1\]);
	if( @suffix2 &gt;= 2 )
	{
		$len = rindex( $suffix2\[@suffix2 - 1\]."\\$", "\\$");
		if( $len &lt;= 5 )
		{
			$hassuffix2 = 1;
			if($suffixstr eq $suffix2\[@suffix2 - 1\])
			{
				$issuffixsame = 1;
			}
			my $tmplen = rindex( $array2\[@array2 - 1\]."\\$", "\\$");
			$laststr2 = substr( $array2\[@array2 - 1\], 0, $tmplen-$len-1 );
		}
	}
}
```
#特征3：最后一级几个分隔符(通过特征匹配计算laststr1和laststr2相似度，如果仅计算字符串相似度，可以用编辑长度)
```
my @area1 = split(/-/, $laststr1);
my @area2 = split(/-/, $laststr2);
my $i;
my $j;
my $totalarea1=0;
my $totalarea2=0;
my @patternarray1={0};
my @patternarray2={0};
my @splitarray1={0};
my @splitarray2={0};
#my $numarea1 = @area2;
#print $laststr1," ",$laststr2,"\\n",$numarea1,"\\n";
for ( $i = 1; $i&lt;=@area1; $i++ )
{
	my @tmp1 = split( /_/, $area1\[$i-1\]);
	for( $j = 0; $j&lt;@tmp1; $j++)
	{
		if( $tmp1\[$j\] =~ /^\\d+$/ )
		{
			$patternarray1\[$totalarea1\] = 1; #数字pattern
		}
		elsif( $tmp1\[$j\] =~ /^\[a-zA-Z\]+$/)
		{
			$patternarray1\[$totalarea1\] = 2; #纯字母pattern
		}
		elsif( $tmp1\[$j\] =~ /^\[a-zA-Z\]+\[0-9\]+$/)
		{
			$patternarray1\[$totalarea1\] = 3; #先字母后数字pattern
		}
		elsif( $tmp1\[$j\] =~ /^\[0-9\]+\[a-zA-Z\]+$/)
		{
			$patternarray1\[$totalarea1\] = 4; #先数字后字母pattern
		}
		else
		{
			$patternarray1\[$totalarea1\] = 5; #其他pattern
		}
		if( $j == 0 )
		{
			$splitarray1\[$totalarea1\]=1;
		}
		else
		{
			$splitarray1\[$totalarea1\]=2;
		}
		$totalarea1 ++;
	}
}
for ( $i = 1; $i&lt;=@area2; $i++ )
{
	my @tmp2 = split( /_/, $area2\[$i-1\]);
	for( $j = 0; $j&lt;@tmp2; $j++)
	{
		if( $tmp2\[$j\] =~ /^\\d+$/ )
		{
			$patternarray2\[$totalarea2\] = 1; #数字pattern
		}
		elsif( $tmp2\[$j\] =~ /^\[a-zA-Z\]+$/)
		{
			$patternarray2\[$totalarea2\] = 2; #纯字母pattern
		}
		elsif( $tmp2\[$j\] =~ /^\[a-zA-Z\]+\[0-9\]+$/)
		{
			$patternarray2\[$totalarea2\] = 3; #先字母后数字pattern
		}
		elsif( $tmp2\[$j\] =~ /^\[0-9\]+\[a-zA-Z\]+$/)
		{
			$patternarray2\[$totalarea2\] = 4; #先数字后字母pattern
		}
		else
		{
			$patternarray2\[$totalarea2\] = 5; #其他pattern
		}
		if( $j == 0 )
		{
			$splitarray2\[$totalarea2\]=1;
		}
		else
		{
			$splitarray2\[$totalarea2\]=2;
		}
		$totalarea2 ++;
	}
}
print $path1," ",$lastispath1," ",$hassuffix1," ",$issuffixsame," ",$totalarea1;
for( $i = 0; $i&lt;$totalarea1; $i++)
{
	print " ",$splitarray1\[$i\]," ",$patternarray1\[$i\];
}
print "\\n";
print $path2," ",$lastispath2," ",$hassuffix1," ",$issuffixsame," ",$totalarea2;
for( $i = 0; $i&lt;$totalarea2; $i++)
{
	print " ",$splitarray2\[$i\]," ",$patternarray2\[$i\];
}
print "\\n";
#print @array1;
```