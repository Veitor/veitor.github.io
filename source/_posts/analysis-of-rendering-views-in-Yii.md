---
title: Yii：render渲染视图分析
tags:
  - Yii
  - 模板
url: 74.html
id: 74
categories:
  - PHP
date: 2014-04-28 03:12:42
---

一起了解一下render方法的工作原理，先看render代码：

```php
public function render($view,$data=null,$return=false)
	{
		if($this->beforeRender($view))
		{
			$output=$this->renderPartial($view,$data,true);
			if(($layoutFile=$this->getLayoutFile($this->layout))!==false)
				$output=$this->renderFile($layoutFile,array('content'=>$output),true);
			$this->afterRender($view,$output);
			$output=$this->processOutput($output);
			if($return)
				return $output;
			else
				echo $output;
		}
	}
```

<!-- more -->

首先是beforeRender：

```php
protected function beforeRender($view)
{
	return true;
}
```

这个封装方法是用在render方法开头，参数是模板文件名称（不带后缀），是用来在渲染视图之前做的一些预处理，我们可以在控制器里重写这个方法来处理，但结果返回的值必须等于true，以便输出视图。 接着执行renderPartial方法：

```php
public function renderPartial($view,$data=null,$return=false,$processOutput=false)
	{
		if(($viewFile=$this->getViewFile($view))!==false)
		{
			$output=$this->renderFile($viewFile,$data,true);
			if($processOutput)
				$output=$this->processOutput($output);
			if($return)
				return $output;
			else
				echo $output;
		}
		else
			throw new CException(Yii::t('yii','{controller} cannot find the requested view "{view}".',
				array('{controller}'=>get_class($this), '{view}'=>$view)));
	}
```

这个方法是$view为模板文件名（不带后缀，后缀通过配置指定），$data是一个关联数组，它将被extract函数提取成供模板中使用的PHP变量。这个方法与render区别在于，该方法渲染视图时，不会渲染布局也不会加载Yii内置的js\css，而render会一起渲染布局文件和脚本。 其中的getViewFile方法是根据模板名寻找木板文件的方法，如果在main配置文件中指定了主题，那么确定的一个模板将被找到。否则的话将按以下规则寻找：
- 模块内的视图：直接指定模板文件路径，以单个斜线“\”开始的路径。 
- 应用内的视图：直接指定模板文件路径，以双斜线“\\”开始的路径。
- 别名路径：以点分割的路径。别名路径alias以后会讲，其实在初始化应用的时候定义了一些路径别名。 
  
这里只需了解getViewFile是寻找模板地址和extract变量即可，接着讲renderPartial，找到模板后继续执行。接着要执行到判断第四个参数processOutput，该函数主要是用于是否加载Yii内置js\css，即上面刚才说的render和renderPartial区别之一，在render中该参数为true即加载，在renderPartial中反之。 然后接着执行到getLayoutFile，刚才是获取了不带布局视图，相当于只执行了renderPartial方法，这里再获取布局文件。getLayoutFile是查找布局模板文件，查找方法和上面的查找模板文件类似。通过在控制器中设置layout变量，加载应用内的布局文件的话设置路径只要以双斜线“\\”开头即可，加载模块内的布局路径以单个斜线“\”开头，另外还有别名路径同样可以设置。 

找到布局文件之后，依然使用renderFile方法渲染布局文件，将之前渲染的试图文件插入到布局文件中。 接着执行afterRender方法，也不需要太多解释了，当然是执行渲染之后的一些工作，可以自己定义。 再执行processOutput，因为render是默认加载js\css的，所以这里不需要判断了。 最后再根据render第三个参数判断是否要直接输出，如果为false的话，就是直接看到的页面了，为true只将html代码返回。 render的方法基本就是这样了，主要还是在renderPartial里处理过程比较多。

如果有疑问，可以在下面留言给我，一起探讨。