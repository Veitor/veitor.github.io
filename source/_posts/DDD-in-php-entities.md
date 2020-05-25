---
title: '[译]实体 - 《Domain-Driven Design in PHP》第4章'
tags:
  - ddd
  - 领域驱动设计
categories:
  - PHP
date: 2020-05-25 09:58:39
---

> 本篇博文由本博客(`http://www.veitor.net`)经原文翻译，转载请注明出处。

我们已经讨论过了尝试将领域中的任何事物首先建模成值对象。但是当领域建模时，你可能会发现通用语言中一些概念需要一个身份。

介绍
---

很明确需要身份的对象示例：

- **一个人**： 一个人总是具有一个身份，这身份总是与其姓名或身份证相同。
- **电商系统中的一个订单**： 在这样的上下文中，每个创建的订单都有其自己的身份，并且一直都是相同的。

这些概念有着随时间推移而持久的一个身份。无论概念中的数据变更多少次，其标识总保持不变。这就是它们成为Entity而不是Value Object的原因。考虑一个人的例子：

```php
namespace Ddd\Identity\Domain\Model;

class Person
{
	private $identificationNumber;

	private $firstName;

	private $lastName;

	public function __construct(
		$anIdentificationNumber, $aFirstName, $aLastName
	) {
		$this->identificationNumber = $anIdentificationNumber;
		$this->firstName = $aFirstName;
		$this->lastName = $aLastName;
	}

	public function identificationNumber()
	{
		return $this->identificationNumber;
	}

	public function firstName()
	{
		return $this->firstName;
	}

	public function lastName()
	{
		return $this->lastName;
	}
}
```
或者考虑下列订单的例子：
```php
namespace Ddd\Billing\Domain\Model\Order;

class Order
{
	private $id;

	private $amount;

	private $firstName;

	private $lastName;

	public function __construct(
		$anId, Amount $amount, $aFirstName, $aLastName
	) {
		$this->id = $anId;
		$this->amount = $amount;
		$this->firstName = $aFirstName;
		$this->lastName = $aLastName;
	}

	public function id()
	{
		return $this->id;
	}

	public function firstName()
	{
		return $this->firstName;
	}

	public function lastName()
	{
		return $this->lastName;
	}
}
```

对象 Vs. 原始类型
---

大多数时间，实体的Identity身份都是一个原始类型——通常是字符串或者整数。但是使用值对象来表示它具有一些优势：

- 值对象是不可变的，因此它们不能被修改。
- 值对象是可以拥有一些动作行为的复杂类型，而原始类型没有。例如判断相等的操作可以被封装在值对象的类里，从而是概念从隐式的变成显示的。

让我们看一下OrderID可能的实现方式，订单的身份已经被处理成了值对象：

```php
namespace Ddd\Billing\Domain\Model;

class OrderId
{
	private $id;

	public function __construct($anId)
	{
		$this->id = $anId;
	}
	
	public function id()
	{
		return $this->id;
	}

	public function equalsTo(OrderId $anOrderId)
	{
		return $anOrderId->id === $this->id;
	}
}
```

上面的示例相当简单，你也可以有其他不同的OrderId的实现。我们在第3章里提到过，你可以使构造函数__construct私有化，使用静态工厂方法来创建新的实例。因为实体标识是一个不太复杂的值对象，所以你在这不需要过于担心。

让我们回到Order，是时候修改它来引用OrderId了：

```php
class Order
{
	private $id;
	private $amount;
	private $firstName;
	private $lastName;

	public function __construct(
		OrderId $anOrderId, Amount $amount, $aFirstName, $aLastName
	) {
		$this->id = $anOrderId;
		$this->amount = $amount;
		$this->firstName = $aFirstName;
		$this->lastName = $aLastName;
	}
	public function id()
	{
		return $this->id;
	}
	public function firstName()
	{
		return $this->firstName;
	}
	public function lastName()
	{
		return $this->lastName;
	}
	public function amount()
	{
		return $this->amount;
	}
}
```
我们实体拥有了一个值对象类型的身份。让我们考虑一下创建OrderId的不同方法。

身份操作
---

处理实体身份是实体重要的一个方面。通常有四个方式来定义一个实体的身份：持久化机制提供身份、客户端提供身份、应用自己提供身份，或者另一个限界上下文提供身份。

#### 持久化机制生成身份

通常，最简单的生成身份的方式是委托持久化机制，因为大多数持久机制支持一些身份类型的生成，比如Mysql的AUTO_INCREMENT属性或者Postgres和Oracle序列。尽管如此简单，但也有一个主要的缺点：实体在被持久化之前是没有身份的。在某种程度上，如果我们继续使用持久化机制生成身份，我们将会耦合身份操作与底层持久化系统：

```php
CREATE TABLE `orders` (
	`id` int(11) NOT NULL auto_increment,
	`amount` decimal (10,5) NOT NULL,
	`first_name` varchar(100) NOT NULL,
	`last_name` varchar(100) NOT NULL,
	PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

再思考一下下面的代码：

```php
namespace Ddd\Identity\Domain\Model;

class Person
{
	private $identificationNumber;
	private $firstName;
	private $lastName;

	public function __construct(
		$anIdentificationNumber, $aFirstName, $aLastName
	) {
		$this->identificationNumber = $anIdentificationNumber;
		$this->firstName = $aFirstName;
		$this->lastName = $aLastName;
	}
	public function identificationNumber()
	{
		return $this->identificationNumber;
	}
	public function firstName()
	{
		return $this->firstName;
	}
	public function lastName()
	{
		return $this->lastName;
	}
}
```

如果你尝试使用你自己的ORM，你可能已经遇到过这情况了。创建一个新Person的方法是什么？如果数据库生成身份，我们是否要在构造函数中传进去？什么时候并且在哪里用身份来更新Person？如果我们最终不去持久化保存这个实体又会发生什么？

##### 代理身份

有时当使用ORM映射实体到持久化系统时，会存在一些约束，例如，在Doctrine中使用了IDENTITY生成器策略，则要求身份应是一个整数字段，这可能与领域模型中要求使用其他类型的身份会产生冲突。

处理这种情况最简单的方式使用`Layer Supertype`模式（译者注：如果一层中的组件具有相同的一组行为，就可以将这些行为提取到一个公共类或组件中，并使层中的所有组件都继承该公共类或组件。），这是身份字段创建的地方：

```php
namespace Ddd\Common\Domain\Model;

abstract class IdentifiableDomainObject
{
	private $id;
	protected function id()
	{
		return $this->id;
	}
	protected function setId($anId)
	{
		$this->id = $anId;
	}
}

namespace Acme\Billing\Domain;
use Acme\Common\Domain\IdentifiableDomainObject;
class Order extends IdentifiableDomainObject
{
	private $orderId;
	public function orderId()
	{
		if (null === $this->orderId) {
			$this->orderId = new OrderId($this->id());
		}
		return $this->orderId;
	}
}
```

##### Active Record Vs. 充血模型Data Mapper

每个项目总是会面临使用哪个ORM的问题，这有许多好的PHP ORM：Doctrine，Propel，Eloquent，Paris等。

它们大多数是ActiveRecord的实现，ActiveRecord实现通常适合CRUD的应用程序，但它不是充血模型的理想解决方案，因为：

- ActiveRecord模式假设了Entity与数据库表之间是一对一的关系。因此这将数据库表的设计与对象的设计耦合在了一起。在充血模型中，有时Entity使用的是来自不同数据库数据源的信息构建的。
- 像集合(collection)、继承(inheritance)这样的高级功能难以去实现。
- 大多数的实现强制使用继承(inheritance)、一些强加约束的构造函数，通过耦合领域模型和ORM，这会导致持久性泄漏到领域模型中。

如前一章节所述，当前最好的PHP ORM是Doctrine，是一个Data Mapper模式的实现。Data Mapper将持久化方面与领域解耦，这使之成为想要构建充血模型的最佳工具。

#### 客户端提供身份

有时当我们处理某些领域时，身份自然而然的出现了，客户端使用了领域模型。这可能是理想的状况，因为可以轻易的对身份进行建模，让我们看一下图书销售市场：

```php
namespace Ddd\Catalog\Domain\Model\Book;
class ISBN
{
	private $isbn;
	private function __construct($anIsbn)
	{
		$this->setIsbn($anIsbn);
	}
	private function setIsbn($anIsbn)
	{
		$this->assertIsbnIsValid($anIsbn, 'The ISBN is invalid.');
		$this->isbn = $anIsbn;
	}
	public static function create($anIsbn)
	{
		return new static($anIsbn);
	}
	private function assertIsbnIsValid($anIsbn, $string)
	{
		// ... Validates an ISBN code
	}
}
```

根据维基百科：国际标准书号（ISBN）是唯一的数字商业书本标识符。书的每个版本（重新印刷除外）都分配有一个ISBN。

因为ISBN是唯一的有效的身份标识，并且能够被轻松的验证，这么酷的事情发生在了领域内，这是一个由客户端提供身份的示例：

```php
class Book
{
    private $isbn;
    private $title;
    public function __construct(ISBN $anIsbn, $aTitle)
    {
        $this->isbn = $anIsbn;
        $this->title = $aTitle;
    }
}
```

现在让我们使用它：

```php
$book = new Book(
ISBN::create('...'),
'Domain-Driven Design in PHP'
);
```

#### 应用生成身份

如果客户端无法提供身份，则处理身份的操作是让应用通过UUID生成身份。如果你没有遇到上一节中类似的场景，那这是我们推荐的方法。

（译者注：这里省略掉原文中介绍UUID的长文翻译，不影响整体阅读和理解）

创建身份的首选位置是在Repository中（我们将在第10章进行深入介绍）：

```php
namespace Ddd\Billing\Domain\Model\Order;
interface OrderRepository
{
    public function nextIdentity();
    public function add(Order $anOrder);
    public function remove(Order $anOrder);
}
```

当使用Doctrine时，我们需要创建一个实现了此interface的自定义Repository。它将创建新的身份并且使用`EntityManager`来持久化和删除实体。一个小的变化是将`nextIdentity`实现放入了interface：

```php
namespace Ddd\Billing\Infrastructure\Domain\Model\Order;
use Ddd\Billing\Domain\Model\Order\Order;
use Ddd\Billing\Domain\Model\Order\OrderId;
use Ddd\Billing\Domain\Model\Order\OrderRepository;
use Doctrine\ORM\EntityRepository;

class DoctrineOrderRepository extends EntityRepository implements OrderRepository
{
    public function nextIdentity()
    {
        return OrderId::create();
    }
    public function add(Order $anOrder)
    {
        $this->getEntityManager()->persist($anOrder);
    }
    public function remove(Order $anOrder)
    {
        $this->getEntityManager()->remove($anOrder);
    }
}
```

让我们快速回顾`OrderId`值对象的最终实现：

```php
namespace Ddd\Billing\Domain\Model\Order;
use Ramsey\Uuid\Uuid;
class OrderId
{
    private $id;
    private function __construct($anId = null)
    {
        $this->id = $id ? :Uuid::uuid4()->toString();
    }
    public static function create($anId = null )
    {
        return new static($anId);
    }
}
```

你将在下面的章节中看到，这种方式的持久化包含值对象的实体是多么的容易。但是，根据ORM的不同，在实体中映射嵌入的值对象可能会变得棘手。

#### 其他限界上下文生成身份

这可能是复杂的身份生成策略，因为它迫使本地实体依赖于本地绑定的上下文事件，还依赖于外部绑定的上下文事件，因此在维护方面成本会很高。

另一个限界上下文提供了从本地实体中选择身份的接口，它可以将某些公开属性作为自己的属性。

当在限界上下文之间的实体需要同步时，这通常会在需要被通知的限界上下文上使用事件驱动(Event-Driven)架构，并且在原始的实体变更时需要进行事件通知。

持久化实体
---

到目前为止，最好的保存实体状态到持久库的工具是Doctrine ORM。Doctine有几种方式来指定实体的元数据(metadata)：在Entity类中写注释、通过编写XML、编写Yaml或者编写原生PHP代码。在这节中 ，我们将深入讨论为什么在映射实体中通过写注释的方式不是最好的。

#### 配置Doctine

首先，我们需要通过Composer安装Doctine（译者注：由于本书年代较为久远，最新的composer安装方式建议查看Doctine官网，这里就不再翻译旧的安装方式原文了）。

像这样进行配置：

```php
require_once '/path/to/vendor/autoload.php';
use Doctrine\ORM\Tools\Setup;
use Doctrine\ORM\EntityManager;
$paths = ['/path/to/entity-files'];
$isDevMode = false;
// the connection configuration
$dbParams = [
	'driver' => 'pdo_mysql',
	'user' => 'the_database_username',
	'password' => 'the_database_password',
	'dbname' => 'the_database_name',
];
$config = Setup::createAnnotationMetadataConfiguration($paths, $isDevMode);
$entityManager = EntityManager::create($dbParams, $config);
```

#### 映射实体

Doctrine官网上的演示代码使用的是annotations注释形式。所以我们也使用注释形式并讨论为什么要尽可能的避免使用这形式。

我们将使用前面章节讨论过的`Order`类。

##### 使用注释形式映射实体

为了映射`Order`实体到持久化仓库，`Order`的代码需要被修改加上Doctine注释内容：

```php
use Doctrine\ORM\Mapping\Entity;
use Doctrine\ORM\Mapping\Id;
use Doctrine\ORM\Mapping\GeneratedValue;
use Doctrine\ORM\Mapping\Column;
/** @Entity */
class Order
{
	/** @Id @GeneratedValue(strategy="AUTO") */
	private $id;
	/** @Column(type="decimal", precision="10", scale="5") */
	private $amount;
	/** @Column(type="string") */
	private $firstName;
	/** @Column(type="string") */
	private $lastName;
	public function __construct(
		Amount $anAmount,
		$aFirstName,
		$aLastName
	) {
		$this->amount = $anAmount;
		$this->firstName = $aFirstName;
		$this->lastName = $aLastName;
	}
	public function id()
	{
		return $this->id;
	}
	public function firstName()
	{
		return $this->firstName;
	}
	public function lastName()
	{
		return $this->lastName;
	}
	public function amount()
	{
		return $this->amount;
	}
}
```
随后，持久化一个实体到持久库中像下面这样简单：

```php
$order = new Order(
new Amount(15, Currency::EUR()),
    'AFirstName',
    'ALastName'
);
$entityManager->persist($order);
$entityManager->flush();
```

乍一眼，代码看起来如此简单，这应该是最简单的方式来映射信息了。但是这是有代价的，最终代码会有什么奇怪的地方？

首先，领域关注点中被混入了infrastructure基础设施内容。Order是领域概念，而Table、Column等是基础设施概念。

结果这个实体在代码中被annotations紧密的与映射信息耦合在了一起。如果要使用其他Entity manager和不同的映射元数据来持久化实体时，这是不可能的了。

Annotations紧密的耦合导致了副作用，所以我们最好不要使用注释形式。

那最好的映射信息的方式是什么呢？最好的方式是允许你从实体中分离映射信息出来。这可以通过xml映射、yaml映射或者php映射实现，本书中将讨论xml映射。

##### 使用xml映射实体

为了使用XML映射`Order`实体，Doctrine的代码配置应该被稍微修改一下：

```php
require_once '/path/to/vendor/autoload.php';
use Doctrine\ORM\Tools\Setup;
use Doctrine\ORM\EntityManager;
$paths = ['/path/to/mapping-files'];
$isDevMode = false;
// the connection configuration
$dbParams = [
    'driver' => 'pdo_mysql',
    'user' => 'the_database_username',
    'password' => 'the_database_password',
    'dbname' => 'the_database_name',
];
$config = Setup::createXMLMetadataConfiguration($paths, $isDevMode);
$entityManager = EntityManager::create($dbParams, $config);
```

映射文件应该放置在Doctrine搜寻映射文件的路径中，映射文件名应该以完全限定的类名命名，并用点替换反斜杠\：

`Acme\Billing\Domain\Model\Order`类对应着名称为`Acme.Billing.Domain.Model.Order.dcm.xml`的xml文件。

#### 映射实体身份

我们的身份`OrderId`是一个值对象，如我们前面几节看到，有不同方法如Doctrine、嵌入的、自定义类型等方法来映射值对象。

Doctrine2.5中一个有趣的新特性可以使用对象作为实体的身份（译者注：由于原文年代久远，读者请根据实际版本的Doctrine操作），因为它们实现了魔术方法`__toString()`。所以我们添加`__toString()`方法到我们的身份值对象中来：

```php
namespace Ddd\Billing\Domain\Model\Order;
use Ramsey\Uuid\Uuid;
class OrderId
{
    // ...
    public function __toString()
    {
        return $this->id;
    }
}
```

检查Doctrine自定义类型的实现，它们继承自GuidType，所以它们内部的表现形式是UUID。我们需要指定数据库的原生转换，然后我们需要在使用自定义类型前对其进行注册，你可以参考Doctrine官网关于“自定义类型”相关的文档。（译者注：建议这部分先了解一下Doctrine中自定义类型的实现）

```php
use Doctrine\DBAL\Platforms\AbstractPlatform;
use Doctrine\DBAL\Types\GuidType;
class DoctrineOrderId extends GuidType
{
    public function getName()
    {
        return 'OrderId';
    }
    public function convertToDatabaseValue(
        $value, AbstractPlatform $platform
    ) {
        return $value->id();
    }
    public function convertToPHPValue(
        $value, AbstractPlatform $platform
    ) {
        return new OrderId($value);
    }
}
```

最后，我们注册自定义类型：

```php
require_once '/path/to/vendor/autoload.php';
// ...
\Doctrine\DBAL\Types\Type::addType(
    'OrderId',
    'Ddd\Billing\Infrastructure\Domain\Model\DoctrineOrderId'
);
$config = Setup::createXMLMetadataConfiguration($paths, $isDevMode);
$entityManager = EntityManager::create($dbParams, $config);
```

##### 最终映射文件

让我们看一下最终的映射文件。有趣的是看一下id如何与我们自定义的类型OrderId进行映射的：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<doctrine-mapping
xmlns="http://doctrine-project.org/schemas/orm/doctrine-mapping"
xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
xsi:schemaLocation="
http://doctrine-project.org/schemas/orm/doctrine-mapping
https://raw.github.com/doctrine/doctrine2/master/doctrine-mapping.xsd">
    <entity
    name="Ddd\Billing\Domain\Model\Order"
    table="orders">
        <id name="id" column="id" type="OrderId" />
        <field
            name="amount"
            type="decimal"
            nullable="false"
            scale="10"
            precision="5"
        />
        <field
            name="firstName"
            type="string"
            nullable="false"
        />
        <field
            name="lastName"
            type="string"
            nullable="false"
        />
    </entity>
</doctrine-mapping>
```

测试实体
---

测试实体相对简单，因为它们是原生的PHP类，并且具有从领域概念派生出来的行为动作。测试的重点应该是实体保护的不变性，因为实体的行为可能会围绕这些不变性进行建模。

例如，为了简单起见，假设博客需要一个领域建模，则可能是：

```php
class Post
{
    private $title;
    private $content;
    private $status;
    private $createdAt;
    private $publishedAt;
    
    public function __construct($aContent, $title)
    {
        $this->setContent($aContent);
        $this->setTitle($title);
        $this->unpublish();
        $this->createdAt(new DateTimeImmutable());
    }
    private function setContent($aContent)
    {
        $this->assertNotEmpty($aContent);
        $this->content = $aContent;
    }
    private function setTitle($aPostTitle)
    {
        $this->assertNotEmpty($aPostTitle);
        $this->title = $aPostTitle;
    }
    private function setStatus(Status $aPostStatus)
    {
        $this->assertIsAValidPostStatus($aPostStatus);
        $this->status = $aPostStatus;
    }
    private function createdAt(DateTimeImmutable $aDate)
    {
        $this->assertIsAValidDate($aDate);
        $this->createdAt = $aDate;
    }
    private function publishedAt(DateTimeImmutable $aDate)
    {
        $this->assertIsAValidDate($aDate);
        $this->publishedAt = $aDate;
    }
    public function publish()
    {
        $this->setStatus(Status::published());
        $this->publishedAt(new DateTimeImmutable());
    }
    public function unpublish()
    {
        $this->setStatus(Status::draft());
        $this->publishedAt = null ;
    }
    public function isPublished()
    {
        return $this->status->equalsTo(Status::published());
    }
    public function publicationDate()
    {
        return $this->publishedAt;
    }
}
class Status
{
    const PUBLISHED = 10;
    const DRAFT = 20;
    private $status;
    
    public static function published()
    {
        return new self(self::PUBLISHED);
    }
    public static function draft()
    {
        return new self(self::DRAFT);
    }
    private function __construct($aStatus)
    {
        $this->status = $aStatus;
    }
    public function equalsTo(self $aStatus)
    {
        return $this->status === $aStatus->status;
    }
}
```
为了测试这个领域模型，我们必须确保测试覆盖所有的Post不变性：

```php
class PostTest extends PHPUnit_Framework_TestCase
{
	/** @test */
	public function aNewPostIsNotPublishedByDefault()
	{
		$aPost = new Post(
			'A Post Content',
			'A Post Title'
		);
		$this->assertFalse(
			$aPost->isPublished()
		);
		$this->assertNull(
			$aPost->publicationDate()
		);
	}
	/** @test */
	public function aPostCanBePublishedWithAPublicationDate()
	{
		$aPost = new Post(
			'A Post Content',
			'A Post Title'
		);
		$aPost->publish();
		$this->assertTrue(
			$aPost->isPublished()
		);
		$this->assertInstanceOf(
			'DateTimeImmutable',
			$aPost->publicationDate()
		);
	}
}
```

#### DateTimes

因为`Datetimes`在实体中被广泛使用，因此我们认为必须指出具有日期类型字段的单元测试实体的方法很重要。如果帖子是最近15天内创建的，请思考一下以下内容：

```php
class Post
{
    const NEW_TIME_INTERVAL_DAYS = 15;
    // ...
    private $createdAt;
    public function __construct($aContent, $title)
    {
        // ...
        $this->createdAt(new DateTimeImmutable());
    }
    // ...
    public function isNew()
    {
        return
        (new DateTimeImmutable())
            ->diff($this->createdAt)
            ->days <= self::NEW_TIME_INTERVAL_DAYS;
    }
}
```
`isNew()`方法需要比较两个`Datetimes`，它是比较今天日期与帖子创建的日期。我们计算差值是否小于指定的天数。那我们如何单元测试`isNew()`方法？正如我们在演示中的那样，很难去重现在单元测试中重现这个特定流程，那我们还有其他选择吗？

##### 传入所有日期作为参数

一种方法是传入所有日期作为参数：

```php
class Post
{
    // ...
    public function __construct($aContent, $title, $createdAt = null)
    {
        // ...
        $this->createdAt($createdAt ?: new DateTimeImmutable());
    }
    // ...
    public function isNew($today = null)
    {
        return
        ($today ? :new DateTimeImmutable())
            ->diff($this->createdAt)
            ->days <= self::NEW_TIME_INTERVAL_DAYS;
    }
}
```
这是最容易进行单元测试的方法。只要传入不同的不同的日期就能测试100%的覆盖率的所有场景。但是如果你思考一下那些创建并获取`isNew()`方法结果的客户端，事情就没有那么美好了。由于总是传入今天的日期，结果显得有点怪异：

```php
$aPost = new Post(
    'Hello world!',
    'Hi',
    new DateTimeImmutable()
);
$aPost->isNew(
    new DateTimeImmutable()
);
```

##### Test Class
另一种方法是使用Test Class模式，其思路是使用一个新的类来继承Post类，我们可以通过新的类来实现特定的场景。这个新的类仅用于单元测试的目的。坏消息是，我们必须稍微修改一些原始的Post类，提取一些方法并将某些字段和方法从private改为protected。一些开发人员可能仅处于测试原因而担心增加类的属性的可见性。但是，我们认为在大多数情况下这是值得的：

```php
class Post
{
    protected $createdAt;
    
    public function isNew()
    {
        return
        ($this->today())
            ->diff($this->createdAt)
            ->days <= self::NEW_TIME_INTERVAL_DAYS;
    }
    protected function today()
    {
        return new DateTimeImmutable();
    }
    protected function createdAt(DateTimeImmutable $aDate)
    {
        $this->assertIsAValidDate($aDate);
        $this->createdAt = $aDate;
    }
}
```
如你所见，我们已经提取了获取今天日期的逻辑到了`today()`方法中。通过使用`Template Method`模式，我们可以在测试类中改变该方法的逻辑行为。其他相似的场景如`createdAt`方法等。现在它们的可见性是protected，因此可以在测试类中进行重写覆盖：

```php
class PostTestClass extends Post
{
    private $today;
    protected function today()
    {
        return $this->today;
    }
    public function setToday($today)
    {
        $this->today = $today;
    }
}
```

有了这些修改，我们现在可以通过测试`PostTestClass`类来测试我们原始的`Post`类了：

```php
class PostTest extends PHPUnit_Framework_TestCase
{
    // ...
    /** @test */
    public function aPostIsNewIfIts15DaysOrLess()
    {
        $aPost = new PostTestClass(
            'A Post Content' ,
            'A Post Title'
        );
        $format = 'Y-m-d';
        $dateString = '2016-01-01';
        $createdAt = DateTimeImmutable::createFromFormat(
            $format,
            $dateString
        );
        $aPost->createdAt($createdAt);
        $aPost->setToday(
            $createdAt->add(
                new DateInterval('P15D')
            )
        );
        $this->assertTrue(
            $aPost->isNew()
        );
        $aPost->setToday(
            $createdAt->add(
                new DateInterval('P16D')
            )
        );
        $this->assertFalse(
            $aPost->isNew()
        );
    }
}
```

##### 外部的Fake

另一种方法是使用新的类或者静态方法封装对`DateTimeImmutable`构造函数或命名构造函数的调用，这样我们可以根据特定的测试场景将这些方法的结果修改成不同的行为。

```php
class Post
{
    // ...
    private $createdAt;
    public function __construct($aContent, $title)
    {
        // ...
        $this->createdAt(MyCustomDateTimeBuilder::today());
    }
    // ...
    public function isNew()
    {
        return
        (MyCustomDateTimeBuilder::today())
            ->diff($this->createdAt)
            ->days <= self::NEW_TIME_INTERVAL_DAYS;
    }
}
```

对于获取今天的`DateTime`，我们现在可以静态调用`MyCustomeDateTimeBuilder::today()`，这个类也有一些setter方法来fake一些返回结果：

```php
class PostTest extends PHPUnit_Framework_TestCase
{
    // ...
    /** @test */
    public function aPostIsNewIfIts15DaysOrLess()
    {
        $createdAt = DateTimeImmutable::createFromFormat(
            'Y-m-d',
            '2016-01-01'
        );
        MyCustomDateTimeBuilder::setReturnDates(
            [
                $createdAt,
                $createdAt->add(
                    new DateInterval('P15D')
                ),
                $createdAt->add(
                    new DateInterval('P16D')
                )
            ]
        );
        $aPost = new Post(
            'A Post Content' ,
            'A Post Title'
        );
        $this->assertTrue(
            $aPost->isNew()
        );
        $this->assertFalse(
            $aPost->isNew()
        );
    }
}
```
这方法的主要问题是它与对象静态耦合，要根据你的用例创建一个灵活的fake对象也挺棘手的。

##### 反射

你可以使用自定义日期和反射的方式来构建一个新的Post类。下面的例子使用了`Mimic`库，该库用于对象原型设计、数据水合(hydration)、和数据展示的功能库：

```php
namespace Domain;
use mimic as m;
class ComputerScientist {
    private $name;
    private $surname;
    public function __construct($name, $surname)
    {
        $this->name = $name;
        $this->surname = $surname;
    }
    public function rocks()
    {
        return $this->name . ' ' . $this->surname . ' rocks!';
    }
}
assert(m\prototype('Domain\ComputerScientist')
instanceof Domain\ComputerScientist);
m\hydrate('Domain\ComputerScientist', [
    'name' =>'John' ,
    'surname'=>'McCarthy'
])->rocks(); //John McCarthy rocks!
assert(m\expose(
    new Domain\ComputerScientist('Grace', 'Hopper')) ==
    [
    'name' => 'Grace' ,
    'surname' => 'Hopper'
    ]
)
```
如果你想要知道更多关于测试模式和方法，可以看一下Gerard Meszaros的《xUnit Test Patterns: Refactoring Test Code》一书。

验证
---

验证在我们领域模型中非常重要，它不仅检查属性的正确性，也检查整个对象以及这些对象组成的正确性。为了使得模型保持有效状态，需要不同级别的验证。仅仅因为对象的属性有效并不意味着该对象是有效的。

#### 属性验证

一些人理解验证是一个服务验证给定对象的状态的过程。在这种情况下，验证符合契约模式的做法，该做法由前置条件、后置条件和不变式组成。一种保护单个属性的方法是使用第3章讲到的值对象。为了使我们设计更加灵活的被修改，我们仅关注断言必须满足领域前置条件。在这里，我们将使用guard作为一种验证前置条件的简单方法：

```php
class Username
{
    const MIN_LENGTH = 5;
    const MAX_LENGTH = 10;
    const FORMAT = '/^[a-zA-Z0-9_]+$/';
    private $username;
    public function __construct($username)
    {
        $this->setUsername($username);
    }
    private setUsername($username)
    {
        $this->assertNotEmpty($username);
        $this->assertNotTooShort($username);
        $this->assertNotTooLong($username);
        $this->assertValidFormat($username);
        $this->username = $username;
    }
    private function assertNotEmpty($username)
    {
        if (empty($username)) {
            throw new InvalidArgumentException('Empty username');
        }
    }
    private function assertNotTooShort($username)
    {
        if (strlen($username) < self::MIN_LENGTH) {
            throw new InvalidArgumentException(sprintf(
                'Username must be %d characters or more',
                self::MIN_LENGTH
            ));
        }
    }
    private function assertNotTooLong($username)
    {
        if (strlen( $username) > self::MAX_LENGTH) {
            throw new InvalidArgumentException(sprintf(
                'Username must be %d characters or less',
                self::MAX_LENGTH
            ));
        }
    }
    private function assertValidFormat($username)
    {
        if (preg_match(self:: FORMAT, $username) !== 1) {
            throw new InvalidArgumentException(
                'Invalid username format'
            );
        }
    }
}
```

如上示例，为了构建一个Username值对象，这有四个前置条件必须被满足：

- 必须不为空
- 必须至少5个字符
- 必须少于10个字符
- 必须只能含字母、数字、下划线

如果所有的前置条件满足，属性将被赋值并且对象将被成功创建。否则一个`InvalidArgumentException`将会被抛出，执行被挂起，客户端将会显示错误。

一些开发者可能会考虑这种验证防御性编程（Defensive programming）。但是，我们不检查输入是否为字符串或者不允许为空，我们无法避免人们错误的使用我们的代码，但是我们能够控制领域状态的正确性。如第3章值对象中所示，验证可以帮助我们提高安全性。

防御性编程不是坏事情，一般来说，当开发用于其他项目的第三方库或组件的时候，这是有意义的。但是，当开发你自己的限界上下文时，可以通过提高单元测试覆盖率来避免这些额外过度的检查（如检查基本类型、类型提示等），这会降低开发速度。

#### 整体对象验证

当一个对象由有效的属性组成时，作为整体来看，也可能是无效的。将这种验证添加到对象本身看上去挺不错，但通常这是一种反模式(anti-pattern)。更高级别的验证的变化速度与对象本身逻辑的变化速度不同，最好将这些职责分开来。

验证会将发现的任何错误告诉客户端，或者收集结果以后供客户端获取查询，因为有时我们不希望在遇到错误时就终止执行代码逻辑。

一个抽象且可重用的验证器像这个样子：

```php
abstract class Validator
{
    private $validationHandler;
    
    public function __construct(ValidationHandler $validationHandler)
    {
        $this->validationHandler = $validationHandler;
    }
    protected function handleError($error)
    {
        $this->validationHandler->handleError($error);
    }
    abstract public function validate();
}
```

作为一个具体的示例，我们想要验证整个`Location`对象，有效的国家、城市和邮政编码值对象的组成。但是，这些单个值可能处于无效状态，也许城市不属于该国，或者邮政编码不是该城市的。

```php
class Location
{
    private $country;
    private $city;
    private $postcode;
    public function __construct(
        Country $country, City $city, Postcode $postcode
    ) {
        $this->country = $country;
        $this->city = $city;
        $this->postcode = $postcode;
    }
    public function country()
    {
        return $this->country;
    }
    public function city()
    {
        return $this->city;
    }
    public function postcode()
    {
        return $this->postcode;
    }
}
```
验证器在`Location`对象中检查其有状态，分析两个属性间的关系和意义：

```php
class LocationValidator extends Validator
{
    private $location;
    public function __construct(
        Location $location, ValidationHandler $validationHandler
    ) {
        parent:: __construct($validationHandler);
        $this->location = $location;
    }
    public function validate()
    {
        if (!$this->location->country()->hasCity(
            $this->location->city()
        )) {
            $this->handleError('City not found');
        }
        if (!$this->location->city()->isPostcodeValid(
            $this->location->postcode()
        )) {
            $this->handleError('Invalid postcode');
        }
    }
}
```
一旦所有的属性被设置好，我们就能够验证实体。在表面上看，Location对象似乎是在自我验证，但是并非如此。`Location`对象委托了验证给到一个具体的验证器实例，将这两个职责划清了：

```php
class Location
{
    // ...
    public function validate(ValidationHandler $validationHandler)
    {
        $validator = new LocationValidator($this, $validationHandler);
        $validator->validate();
    }
}
```

##### 解耦验证消息

我们通过最少修改现有例子，来将验证消息与验证器解耦：

```php
class LocationValidationHandler implements ValidationHandler
{
    public function handleCityNotFoundInCountry();
    public function handleInvalidPostcodeForCity();
}
class LocationValidator
{
    private $location;
    private $validationHandler;
    public function __construct(
        Location $location,
        LocationValidationHandler $validationHandler
    ) {
        $this->location = $location;
        $this->validationHandler = $validationHandler;
    }
    public function validate()
    {
        if (!$this->location->country()->hasCity(
        $this->location->city()
        )) {
            $this->validationHandler->handleCityNotFoundInCountry();
        }
        if (! $this->location->city()->isPostcodeValid(
            $this->location->postcode()
        )) {
            $this->validationHandler->handleInvalidPostcodeForCity();
        }
    }
}
```
我们也需要修改验证方法的入参：

```php
class Location
{
    // ...
    public function validate(
        LocationValidationHandler $validationHandler
    ) {
        $validator = new LocationValidator($this, $validationHandler);
        $validator->validate();
    }
}
```

#### 验证对象组合

验证对象组合很复杂。要实现这样的目标首选的方法是使用领域服务（Domain Service）。然后该服务与仓储(Repository)进行通信来获取有效的聚合。由于可能会创建复杂的对象，因此聚合可能处于中间状态，因此需要实现验证其他聚合。我们可以使用领域事件来通知系统的其他部分，告知他们某个特性元素已经通过验证。


实体和领域事件
---
我们将在第6章探索领域事件。但是，这里重点是强调一下在实体上执行的操作可能会发起领域事件。这个方法用于将领域中的变化信息传递到应用的其他部分，甚至传递到其他应用，你会在第12章集成限界上下文中看到。

```php
class Post
{
    // ...
    public function publish()
    {
        $this->setStatus(
        Status::published()
    );
        $this->publishedAt(new DateTimeImmutable());
        DomainEventPublisher::instance()->publish(
            new PostPublished($this->id)
        );
    }
    public function unpublish()
    {
        $this->setStatus(
            Status::draft()
        );
        $this-> publishedAt = null;
        DomainEventPublisher::instance()->publish(
            new PostUnpublished($this->id)
        );
    }
    // ...
}
```
下面例子中，当我们的新实体被创建时，领域事件会被发起：

```php
class User
{
    // ...
    public function __construct(UserId $userId, $email, $password)
    {
        $this->setUserId($userId);
        $this->setEmail($email);
        $this->setPassword($password);
        DomainEventPublisher::instance()->publish(
            new UserRegistered($this->userId)
        );
    }
}
```

总结
---

领域中的某些概念需要身份，对其内部状态的修改不会修改其自身的唯一身份。我们已经了解了将身份建模为值对象所带来的好处，如不可变性、添加额外的逻辑行为等。我们还展示了提供几种身份的方法：

- 持久机制：容易实现，但你在持久化对象之前是没有身份的，这会延迟事件的发起，并使得事件传播复杂化。
- 代理身份：一些ORMORM要求你实体中要有一个额外的字段，来与持久化机制做映射。
- 客户端提供：有时身份适合领域中的某个概念，则你可以将其在你的领域中建模。
- 应用提供：你可以使用第三方库生成ID。
- 限界上下文提供：最复杂的策略。其他限界上下文提供一个生成ID的接口。

我们已经讨论了使用Doctrine作为持久机制。我们也看到了使用ActiveRecord模式的缺点，最后，我们也检查了不同层面的实体验证：

- 属性验证：通过前置条件、后置条件、不变性检查对象内部的状态。
- 整体的对象验证：寻找对象的一致性，将验证提取到外部服务是一个好习惯。
- 对象的组合：复杂的对象组合能够通过领域服务验证，来与应用其他部分通信的一个好方法是通过领域事件。