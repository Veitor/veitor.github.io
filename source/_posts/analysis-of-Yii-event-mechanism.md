---
title: Yii事件机制分析
tags:
  - PHP
  - Yii
  - 事件
url: 508.html
id: 508
categories:
  - PHP
  - 编程语言
date: 2015-02-26 13:34:26
---

在Yii中使用事件需要三个步骤：1、定义事件；2、定义事件回调函数；3、将回调函数添加到事件中4、触发事件。 Yii事件机制的实现是在其底层基类CComponent类里，这是所有组件的基类。

1、如何定义事件
--------

很简单，事件以on开头的命名方式定义，如以下定义了一个onEcho的事件：

public function onEcho($event)
{
     $this->raiseEvent('onEcho', $event);
}

这样就定义了一个事件，其中$event参数是一个CEvent或其子类的实例（但其实用到的并不多，下面再说）。

2、定义事件回调函数
----------

回调函数可以是一个全局函数或者一个类中的函数（说白了就是一个函数而已），其需要一个参数$event，如下：

public function huidiao($event)
{
     //TODO
}

$event参数其实是接收定义事件时传入的那个参数，也就是上面第一步定义的事件函数的参数，它最终会传到这个回调函数里来。然后回调函数根据业务逻辑使用这个参数，但一般情况下我们不怎么使用到这个参数，所以意义也不是很大，不过如果你需要参数的情况下可以通过这样方式定义，因为传入的参数并不一定限制是CEvent的实例或其子类，也可以是其他类型（待会下面继续解释）。

3、将回调函数添加到事件中
-------------

为啥还要将回调函数添加到事件中呢？因为当事件触发后总得要有程序逻辑（也就是一段php代码）去处理业务是吧。所以光光的定义一个事件而不往里面添加回调函数是没有意义的，而且即使定义了回调函数却添加到事件里也是没有意义的。就如同你只买了个电脑主机有啥意义呢？也或者你只买了一台显示器也同样没有意义，要将两者结合才是他们真正的用处。 那么如何将回调函数添加到事件中？

一种方法：$this->onEcho=array($this, 'huidiao');

另一种方法：$this->attachEventHandler('onEcho', array($this, 'huidiao'));

第一种方法利用了Yii组件中setter原理，看代码：

public function __set($name,$value)
{
	$setter='set'.$name;
	if(method_exists($this,$setter))
		return $this->$setter($value);
	elseif(strncasecmp($name,'on',2)===0 && method_exists($this,$name))
	{
		// duplicating getEventHandlers() here for performance
		$name=strtolower($name);
		if(!isset($this->_e\[$name\]))
			$this->_e\[$name\]=new CList;
		return $this->_e\[$name\]->add($value);
	}
	elseif(is\_array($this->\_m))
	{
		foreach($this->_m as $object)
		{
			if($object->getEnabled() && (property_exists($object,$name) || $object->canSetProperty($name)))
				return $object->$name=$value;
		}
	}
	if(method_exists($this,'get'.$name))
		throw new CException(Yii::t('yii','Property "{class}.{property}" is read only.',
			array('{class}'=>get_class($this), '{property}'=>$name)));
	else
		throw new CException(Yii::t('yii','Property "{class}.{property}" is not defined.',
			array('{class}'=>get_class($this), '{property}'=>$name)));
}

这是一个魔术方法\_\_set，6-13行是给事件添加回调函数的步骤。如果类里面存在以on开头的函数，那么将事件放到私有变量$\_e里，$\_e是个数组，其键名是事件名称，其值是一个CList实例（也可以理解为一个数组，因为CList实现了一个整数索引的集合类，可以用数组的形式往里面添加元素 ，可详见CList），再使用CList中add方法往数组形式的值里面添加回调函数，也等同于$\_e\['onecho'\]\[\]=array($this,'huidiao')。那么按我上面添加一个事件来说，添加一个回调函数huidiao后$_e的内容应该是array('onecho'=>array(array($this,'huidiao')) 第二种方法使用了类中的attachEventHandler函数，代码如下：

public function attachEventHandler($name,$handler)
{
	$this->getEventHandlers($name)->add($handler);
}
public function getEventHandlers($name)
{
	if($this->hasEvent($name))
	{
		$name=strtolower($name);
		if(!isset($this->_e\[$name\]))
			$this->_e\[$name\]=new CList;
		return $this->_e\[$name\];
	}
	else
		throw new CException(Yii::t('yii','Event "{class}.{event}" is not defined.',
			array('{class}'=>get_class($this), '{event}'=>$name)));
}
public function hasEvent($name)
{
	return !strncasecmp($name,'on',2) && method_exists($this,$name);
}

attachEventHandler函数首先用getEventHandler函数获取需要添加回调函数的事件，用hasEvent判断是否存在这个事件函数名，如果存在的话（也就是定义事件函数的话）就和第一种方法原理一样，获得$_e\['onecho'\]的值（CList实例），使用其方法add往数组形式的值里添加回调函数。 至此，回调函数都已经添加到事件中去了。

4、触发事件
------

这个比较简单，在你需要执行这个事件的地方调用第1步定义的事件，如$this->onEcho($event)，函数执行里面的一句话$this->raiseEvent('onEcho'.$event)，raiseEvent这个方法代码如下：

public function raiseEvent($name,$event)
{
	$name=strtolower($name);
	if(isset($this->_e\[$name\]))
	{
		foreach($this->_e\[$name\] as $handler)
		{
			if(is_string($handler))
				call\_user\_func($handler,$event);
			elseif(is_callable($handler,true))
			{
				if(is_array($handler))
				{
					// an array: 0 - object, 1 - method name
					list($object,$method)=$handler;
					if(is_string($object))	// static method call
						call\_user\_func($handler,$event);
					elseif(method_exists($object,$method))
						$object->$method($event);
					else
						throw new CException(Yii::t('yii','Event "{class}.{event}" is attached with an invalid handler "{handler}".',
							array('{class}'=>get_class($this), '{event}'=>$name, '{handler}'=>$handler\[1\])));
				}
				else // PHP 5.3: anonymous function
					call\_user\_func($handler,$event);
			}
			else
				throw new CException(Yii::t('yii','Event "{class}.{event}" is attached with an invalid handler "{handler}".',
					array('{class}'=>get_class($this), '{event}'=>$name, '{handler}'=>gettype($handler))));
			// stop further handling if param.handled is set true
			if(($event instanceof CEvent) && $event->handled)
				return;
		}
	}
	elseif(YII_DEBUG && !$this->hasEvent($name))
		throw new CException(Yii::t('yii','Event "{class}.{event}" is not defined.',
			array('{class}'=>get_class($this), '{event}'=>$name)));
}

这个方法会获得$\_e\['onecho'\]值，那么这个值是数组形式对吧，而且数组的每个元素都是一个回调函数，那么用foreach对其进行遍历（代码第6行），循环部分的代码最终都是调用了call\_user_func，把回调函数和$event传入进去，那么回调函数就被执行了，并且该回调函数得到的参数是触发事件时$this->onEcho($event)的这个$event参数。所以我在第2步中说道，这个$event参数并不一定要CEvent的实例或其子类，因为要看你回调函数需要什么参数。这么一看，通过foreach后，注册到这个事件onEcho中的所有回调函数都会被执行一遍。 那么就这样完成了整个事件了，还比较容易理解吧？有任何疑问可以留言，一起探讨