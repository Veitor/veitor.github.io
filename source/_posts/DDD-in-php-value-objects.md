---
title: '[译]值对象 - 《Domain-Driven Design in PHP》第2章'
tags:
  - ddd
  - 领域驱动设计
categories:
  - PHP
date: 2020-05-23 20:35:51
---

> 本篇博文由本博客(`http://www.veitor.net`)经原文翻译，转载请注明出处。

通过使用`self`关键字，我们不会将"值对象"作为领域驱动设计的基本构建块，而是在代码中将它们作为你通用语言的概念。一个值对象在你的领域中不仅仅是一个东西，它能够度量、量化或者描述一些信息。值对象可以看作是小的简单对象（如金钱或者日期范围），它们不像实体（Entity）通过身份标识来进行区分，而是根据其所持有的内容来做区分。

例如，一个产品价格可以用值对象来表示。此时，该值对象不代表一个东西，而是能够让我们衡量这个产品价值多少钱的一个值。这些对象的内存占用非常容易确定（根据其组成的部分计算），并且开销很少。因此，即使想用一个值对象来代表同一个值，人们还是更喜欢新创建一个值对象实例也不去重复引用之前的值对象。然后根据两个实例的字段内容来检查这两个实例是否相等。


定义
---

Ward Cunningham对值对象的定义：

某个事物的量或者描述。值对象的例子有数字、日期、金钱、字符串。通常他们是被使用最多的小对象。它们的身份是基于它们的状态而不是它们的对象标识。你可以拥有相同概念值对象的多个副本。每张5元的钞票都有其自己的标识（该钞票上印的标记号码），但是在使用上每张5元钞票与其他的5元钞票都具有相同的价值。

Martin Fowler对值对象的定义：

像金钱或者日期范围这样的小对象。它们是遵循值而不是引用。你通常能够区分它们是因为判断它们是否相等并不基于身份标识，而是基于它们所持有的字段内容是否相等。尽管所有字段是相等的，你可能也不必真去比较所有字段（比如一个子集具有唯一性的情况下，如货币代码对于货币对象来说足够来测试是否相等）。值对象不应该被改变。如果要修改值对象，则应该使用新的对象来替换掉该对象。值对象本身的改变会引发aliasing problems（别名问题）。

值对象的例子有数字、文本字符、日期、时间、一个人的全名、货币、颜色、手机号、邮政编码等等。

Value Object与Entity对比
---

为了更好的理解值对象与实体之间的区别，思考一下下面的例子：

- 值对象：当人们付钱交换钞票时，他们通常不会去区分每张钞票，而是只关注这钞票的面值。这种情况下，钞票是值对象。但是，对于银行来说他们可能会关注每张钞票，此时，每张钞票是实体。

- 实体：大多数飞机航班都区分飞机上的每张座位，此时每张座位就是实体。然而有一些航司不区分每张座位，所有座位都一样可以坐，此时座位是值对象。

Currency(货币)和Money（钱）的示例
---

货币和钱是解释值对象最常用的例子了。

在现实世界中，货币单位的描述方式与距离单位描述方式一样。每个货币都用三个字母的大写ISO来表示：

```php
class Currency
{
	private $isoCode;

	public function __construct($anIsoCode)
	{
		$this->setIsoCode($anIsoCode);
	}
	private function setIsoCode($anIsoCode)
	{
		if (!preg_match('/^[A-Z]{3}$/', $anIsoCode)) {
			throw new InvalidArgumentException();
		}
		$this->isoCode = $anIsoCode;
	}
	public function isoCode()
	{
		return $this->isoCode;
	}
}
```

值对象的主要目标之一同时也是面向对象设计的目标：封装。通过这种形式，你将有一个地方来进行验证、逻辑比较。

> 在前一个示例中，我们可以使用AAA的ISO代码构建一个货币对象。这是一个无效的ISO代码。因此在值对象中可以完善写清对货币ISO代码是否有效的验证逻辑。

另外，您可能还注意到，我们正在使用自封装赋值ISO代码，该代码集中在值对象中进行修改：

```php
class Money
{
	private $amount;

	private $currency;

	public function __construct($anAmount, Currency $aCurrency)
	{
		$this->setAmount($anAmount);
		$this->setCurrency($aCurrency);
	}
	
	private function setAmount($anAmount)
	{
		$this->amount = (int) $anAmount;
	}

	private function setCurrency(Currency $aCurrency)
	{
		$this->currency = $aCurrency;
	}

	public function amount()
	{
		return $this->amount;
	}

	public function currency()
	{
		return $this->currency;
	}
}
```

既然您已经知道了值对象的正式定义，那么让我们更深入地研究它们提供的一些强大功能。

特征
---

在代码中构建通用语言概念模型时，你应该总是优先用值对象而不是实体。值对象容易被创建、测试、使用和维护。

记住下面这些，你可以确定问题中的概念是否能够被建模成值对象：

- 它能在领域中度量、量化或者描述一个事物。
- 它能够保持不变。
- 它能够将相关属性作为一个整体来对概念建模。
- 它能够通过值的相等性来与其他对象进行比较。
- 当度量或描述改变时，它是完全可以被替换的。
- 它为合作者提供了无副作用的行为。

## 度量、量化、描述

像上面讨论的那样，一个值对象不应该作为你领域中的一个事物。而是作为一个值，它在你领域中可以度量、量化或者描述一个事物。

在我们的示例中，Currency货币对象描述了Money钱是什么类型。Money钱对象对给定的货币进行了度量或量化。


### 不可变

这是最重要的方面之一。值对象在其生命周期内不应该被改变。由于这种不变性，值对象易于被推理和测试，并且没有不良的副作用。因此，值对象应该通过它们的构造函数创建。构建一个值对象时，你通常传入必要的基本类型或者其他值对象到这个值对象的构造函数。

值对象总是处于有效的状态（valid state）。这就是为什么我们会在单个原子步骤中创建它们的原因。带有多个settter和getter方法的空构造函数将创建职责移到了客户端，导致贫血模型，这是反面模式。

还有一点应当指出，就是不要在你的值对象中引用实体（Entity）。实体是可变的，持有实体的值对象可能会导致意想不到的副作用问题。

在具有`方法重载(method overlanding)`的语言中（如JAVA），你可以创建多个相同名字的构造函数。每个构造函数都提供了不同的参数选项来构建相同类型的对象。而在PHP中，我们可以通过`工厂方法(factory methods)`提供类似的功能，这些工厂方法被称为`语义化构造函数(semantic constructors)`。`fromMoney`方法的主要目的是提供比纯构造函数更多的上线文含义，甚至可以将`__construct`构造函数设为private私有，并使用语义化构造函数（即工厂方法）来实例化每个对象。

在`Money`对象中，我们可以像这样增加一些有用的工厂方法：

```php
class Money
{
	// ...
	public static function fromMoney(Money $aMoney)
	{
		return new self(
			$aMoney->amount(),
			$aMoney->currency()
		);
	}
	
	public static function ofCurrency(Currency $aCurrency)
	{
		return new self(0, $aCurrency);
	}
}
```

通过使用`self`关键字，我们不会将代码与类名耦合。因此更改类名或者命名空间不会影响这些工厂方法。这个小的实现细节有助于以后重构代码。

> **使用static还是self关键字？**
> 当值对象继承另一个值对象时，使用static可能会产生意想不到的问题。（译者注：static和self关键字的使用场景建议另外去了解）


由于这种不变性，我们必须考虑在有状态的上下文中如何处理常见的变化行为。如果我们需要状态进行改变，则必须返回改变后的新的值对象。如果我们需要增加Money值对象的mount数量，则需要返回修改后的新的Money的实例对象。还好，这还是比较容易实现的：

```php
class Money
{
	// ...
	public function increaseAmountBy($anAmount)
	{
		return new self(
			$this->amount() + $anAmount,
			$this->currency()
		);
	}
}
```

由`increaseAmountBy`方法返回的Money对象与接受的参数的Money对象不同，可以通过下面来看出：

```php
$aMoney = new Money(100, new Currency('USD'));
$otherMoney = $aMoney->increaseAmountBy(100);

var_dump($aMoney === otherMoney); // bool(false)

$aMoney = $aMoney->increaseAmountBy(100);
var_dump($aMoney === $otherMoney); // bool(false)
```

#### 整体概念

为什么不像下面这个示例一样来实现，来避免使用新的值对象呢？

```php
class Product
{
	private id;
	private name;
	/**
	* @var int
	*/
	private $amount;
	/**
	* @var string
	*/
	private $currency;
	// ...
}
```

这种方式存在明显的缺陷。比如，你想要验证ISO的有效性。而用Product产品对象来验证货币的ISO代码是没意义的（这违反了单一职责原则）。如果你想在其他地方重用这个ISO验证逻辑，则更加能说明还是需要去遵守DRY原则的。

基于这些因素，我们所举的例子对于抽象成值对象是一个理想的选择。使用抽象不仅让你有机会将相关属性组合在一起，而且也能让你可以创建更高层的概念和更具体的通用语言。

#### 值的相等性

如这章开头所谈到，如果两个值对象所含的数量、描述等内容相同，则这俩值对象相等。

想象一下两个Money对象表示1美元。我们能认为他们相等吗？在真实世界，两张1美元面额的钞票相等吗？当然相同，我们将注意力转移到代码的实现上，代码是使用两个值对象实例来表示的，但是这两个实例都表示着相同的值，这使得两个实例相等。

对于PHP，通常会使用`==`运算符来比较两个值对象，查阅PHP的相关文档中对`==`这个操作符后会发现一个有趣的情况：

```
使用比较运算符==时，将以简单的方式来比较对象变量。即如果两个对象实例具有相同的属性和值，并且是同一个类的实例，则它们相等。
```

PHP中这样的情况与我们给值对象的定义一样（即值对象中包含内容相等则值对象相等），但是由于精准类匹配谓词的存在，你应该在处理子类型时要小心谨慎。

更加严格的`===`运算符对我们没有帮助：当使用运算符`===`时，只有变量对象引用了相同类的实例时才是相同的。下面的例子有助于我们认识到这些细微差别：

```php
$a = new Currency('USD');
$b = new Currency('USD');

var_dump($a == $b); // bool(true)
var_dump($a === $b); // bool(false)

$c = new Currency('EUR');

var_dump($a == $c); // bool(false)
var_dump($a === $c); // bool(false)
```

一种解决方法是在每个值对象中实现如`equals`这样的方法，该方法负责检查类型和它属性的相等性。使用PHP中内置的类型提示可以轻松实现对类型的检查，如有必要，可以使用`get_class()`函数来帮助检查类型。

为了能够用代码解释相等在你领域(Domain)中是什么意思，你需要提供一些必要的代码实现来回答这问题。比如为了比较Currency货币对象什么时候相等，你实现的比较代码中需要对两个对象中ISO代码进行比较即可。这种情况下`===`运算符可以用上：

```php
class Currency
{
	// ...
	public function equals(Currency $currency)
	{
		return $currency->isoCode() === $this->isoCode();
	}
}
```

因为`Money`对象使用了`Currency`对象，所以`equals`方法需要执行Currency的检查，同时也要检查amount数量：

```php
class Money
{
	// ...
	public function equals(Money $money)
	{
		return
		$money->currency()->equals($this->currency()) &&
		$money->amount() === $this->amount();
	}
}
```

#### 可替代性

思考一下两个价格相同的产品实体(Entity)，可以使用两个单独的Money对象或两个引用指向一个值对象的方式对这种情况进行建模。

共享同一个值对象可能会存在风险，如果其中一个实体的值对象被修改，则两个实体都会有变化，这就是非预期的副作用。比如员工A在2月20日被录用，而我们知道员工B在同一天也被录用，我们可以将员工A的聘用日期设置与员工B的录用日期相同。如果员工A的录用日期改为5月，那么员工B的录用日期也会被修改。我们正确与否，都不是我们所期望的。

由例子可以看出，当持有值对象的引用时，建议将值对象进行整体替换而不是修改值对象的值：

```php
$this−>price = new Money(100, new Currency('USD'));
//...
$this->price = $this->price->increaseAmountBy(200);
```

这种方式类似于PHP中`strtolower`函数，该函数会返回一个新字符串，而不是修改原始字符串，不使用引用，而是返回一个新的值。

#### 无副作用的行为

如果我们想要在`Money`类中包含一些行为——如增加一个`add`方法，则该方法自然而然的应当会去检查输入参数的各种条件并且维持着自身的不变性。在我们的示例中，我们只希望使用相同的货币来实现add增加：

```php
class Money
{
	// ...
	public function add(Money $money)
	{
		if ($money->currency() !== $this->currency()) {
			throw new InvalidArgumentException();
		}
		$this->amount += $money->amount();
	}
}
```
如果两种货币不匹配，则会抛出异常。否则金额数量会相加。但是这个代码有一些非预期的陷阱。现在想象一下代码中有一个神秘的方法调用了一个其他方法：

```php
class Banking
{
	public function doSomething()
	{
		$aMoney = new Money(100, new Currency('USD'));
		$this->otherMethod($aMoney);//mysterious call
		// ...
	}
}
```

目前这示例看起来一切OK。但是当`otherMethod`方法完成时我们会看到意想不到的结果。突然`$aMoney`不再包含100美元。发生了什么？如果`otherMethod`在内部调用我们先前定义的`add`方法，又会发生什么。也许你不知道add会更改Money的状态，这就是我们所说的副作用。

怎样去避免这样的问题，很简单，就是确保值对象保持不变，我们就可以避免这类问题。一个简单的方法就是对任何潜在的修改操作都返回一个新的实例，就像这样：

```php

class Money
{
	// ...
	public function add(Money $money)
	{
		if (!$money->currency()->equals($this->currency())) {
			throw new \InvalidArgumentException();
		}
		return new self(
			$money->amount() + $this->amount(),
			$this->currency()
		);
	}
}
```

通过这样简单的修改，值对象的不变得到了保障。每次两个Money实例的相加都会得到返回一个新的对象实例。其他类可以执行很多修改操作而不会影响到原始的值对象，没有副作用的代码更易于理解、易于测试和不易出错。

基本类型
---

看一下下面的代码片段：

```php
$a = 10;
$b = 10;
var_dump($a == $b);
// bool(true)
var_dump($a === $b);
// bool(true)
$a = 20;
var_dump($a);
// integer(20)
$a = $a + 30;
var_dump($a);
// integer(50);
```

尽快`$a`和`$b`是存储在不同内存位置的不同变量，但是进行比较时它们是相同的。它们持有相同的值，因此我们认为它们相等。你可以随时将`$a`的值从10修改为20，再将20减掉10，你可以不用考虑前一个值是什么，而随意替换为任意整数，因为你没修改它，你仅仅是替换了它！但如果你对这些变量使用了一些操作（如加法，即`$a+$b`），则会得到另一个新的值，该值可以分配给另一个变量或者先前定义的变量。你将$a传递给另一个函数时，除非通过引用显示传递，否则你只传递一个值，$a是否在该函数中被修改无关紧要，因为当前代码中，你仍然拥有原始的变量副本，所以值对象的行为与基本类型相同。

测试值对象
---

值对象的测试与普通对象的测试相同。但是，不变性和无副作用行为也需要进行测试。一种方法是在执行任何修改之前创建要测试的值对象的副本，使用已实现的相等性检查来断言两者是否相等。断言的原始对象和副本需要仍然相等。

让我们在`Money`类中测试`add`方法的无副作用实现：

```php
class MoneyTest extends FrameworkTestCase
{
	/**
	* @test
	*/
	public function copiedMoneyShouldRepresentSameValue()
	{
		$aMoney = new Money(100, new Currency('USD'));
		$copiedMoney = Money::fromMoney($aMoney);
		$this->assertTrue($aMoney->equals($copiedMoney));
	}

	/**
	* @test
	*/
	public function originalMoneyShouldNotBeModifiedOnAddition()
	{
		$aMoney = new Money(100, new Currency('USD'));
		$aMoney->add(new Money(20, new Currency('USD')));
		$this->assertEquals(100, $aMoney->amount());
	}
	
	/**
	* @test
	*/
	public function moniesShouldBeAdded()
	{
		$aMoney = new Money(100, new Currency('USD'));
		$newMoney = $aMoney->add(new Money(20, new Currency('USD')));
		$this->assertEquals(120, $newMoney->amount());
	}
	// ...
}
```

持久化值对象
---

值对象不是自己独立持久化的，它们通常在一个聚合(Aggregate)中被持久化。值对象不应该被作为一个记录持久化，即使在某些情况下这是一种选择。