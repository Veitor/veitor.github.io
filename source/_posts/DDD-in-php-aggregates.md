---
title: '[译]聚合 - 《Domain-Driven Design in PHP》第8章'
tags:
  - ddd
  - 领域驱动设计
categories:
  - PHP
date: 2020-05-26 15:41:43
---

> 本篇博文由本博客(`http://www.veitor.net`)经原文翻译，转载请注明出处。

聚合可能是领域驱动设计中最困难的构建块。它们很难理解，甚至难以正确设计。但是不用担心，我们在这里给你提供帮助。在进入聚合之前，我们需要先了解一些关键概念：事务和并发策略。

介绍
---

如果你的工作与电子商务应用有关，你可能会遇到过与你数据库数据不一致有关的问题。例如，一个购物订单的总金额为99.99美元，但该订单总金额与订单中每项金额之和89.99美元不匹配，那额外的10美元从哪里来的？

或者，思考一个影院售票网站的例子。有一个拥有100个座位的电影院，在电影上映时每个人都在网站上等待购买电影票，一旦你开始进行销售，电影票会迅速一抢而空，但最终你以某种方式售卖出了102张座位。你可能指定了只有100个座位，但由于某种原因还是超过了这个阈值。

你可能有过使用JIRA或Redmine等协作系统的经验。考虑一下由开发人员、QA人员和产品负责人组成的团队，如果每个人都在对User Story进行分类和拖动转移，然后再保存，会发生什么？最终的User story优先级将是团队成员中最后保存那个人的。

通常，我们以费原子方式处理持久机制时，就会出现数据不一致的情况。例如，当你想数据库发送三个查询时，其中一些查询结果有效，而一些无效。数据库的最终状态不一致。有时，你希望这三个查询一起成功或失败，而这可以通过事务来解决。但是，请小心，如你在本章中看到的那样，并非所有不一致都通过事务来解决。实际上，有时其他数据不一致需要锁定或者使用并发策略。这些工具可能会影响你的应用程序性能，因此请注意进行权衡。

你可能会认为这类数据不一致仅发生在数据库中，但事实并非如此。例如，我们使用面向文档的数据库（如Elasticsearch），则两个文档之间的数据库可能会不一致。此外，大多数NoSQL持久性存储系统都不支持ACID事务。这意味着你不能在单个操作中持久化或者更新多个文档。因此，如果我们对Elasticsearch发出不同的请求，则可能失败，从而持久保存在Elasticsearch中的数据不一致。

保持数据一致是一个挑战。不要将基础设施问题泄漏到领域中是个更大的挑战。聚合的目的是在帮助你完成这两件事的。

关键概念
---

持久化引擎（尤其是数据库）具有一些解决数据不一致的功能：ACID、约束、参照完整性、锁定、并发控制和事务。在使用聚合之前，让我们回顾一下这些概念。

这些概念大多数都在网上公开，我们要改写Oracle、PostgreSQL和Doctine的人员在其文档方面所作出的贡献。他们精心定义和解释了这些重要的术语，而不是重新发明轮子，我们整理了一些官方的解释与你分享。


（译者注：这里省略掉原文摘自数据库官网关于数据库事务的原文翻译，关于数据库事务的知识建议单独寻找相关的知识点进行查阅，或直接查看原文）

什么是聚合？
---

聚合是持有其他实体和值对象的实体，有助于保持数据一致性。Vaughn Vernon的《Implementing Domain-Driven Design》：

> 聚合是精心制作的将实体和值对象聚在一起的一致性边界。

Pramod J. Sadalage和Martin Fowler《NoSQL Distilled: A Brief Guide to the Emerging World of Polyglot Persistence》一书说到：

> 在领域驱动设计中，聚合是我们希望视为一个单元的相关对象的集合。特别是，它是用于数据操作和一致性管理的单元。通常，我们喜欢使用原子操作来更新聚合，并根据聚合与我们的数据存储进行通信。

####  Martin Fowler说了什么

来自http://martinfowler.com/bliki/DDD_Aggregate.html：

> 聚合是领域驱动设计中的一种模式。一个DDD聚合是领域对象的集合，可以将它们视为一个单元。一个示例可能是一个订单及其订单项，它们都是单独的对象，但是将订单（连通订单项）作为单个聚合很有用。
> 
> 聚合将它的组成对象之一变成聚合根，任何外部对聚合的引用都应该只能达到聚合根。聚合根可以确保整个聚合的完整性。
> 
> 聚合是你请求加载或保存整个聚合的数据存储传输的基本元素，事务不应该跨越聚合边界。
> 
> DDD聚合又是会与类的集合（如lists列表、maps映射表）混淆。DDD聚合是领域概念（订单、播放列表），然而集合是通用的。聚合通常包含多个集合以及简单的字段。术语“aggregate”是一个常见的术语，在各种不同的上下文中使用（如XML），在这种情况下，它与DDD聚合所引用的概念不同。（译者注：这里的aggregate并不是指的领域中的聚合的意思）

#### 维基百科说了什么

来自https://en.wikipedia.org/wiki/Domain-driven_design#Building_blocks_of_DDD：

> 聚合：由根实体（也称为聚合根）绑在一起的对象的集合。聚合根禁止外部对象持有其成员的引用，通过这一点来保证聚合中所做的更改的一致性。
>
> 例如，驾驶汽车时，你不必担心车轮的移动、发动起的燃烧等细节。你只是在开车，这种情况下，汽车是其他几个对象的聚合，并充当着聚合根。

为什么选择聚合？
---
读者可能想知道使用聚合和聚合设计来做什么？实际上，这是一个很好的问题。让我们对其进行探讨。关系模型使用数据表存储数据，这些表由行组成，其中每行通常代表应用程序中所关注概念的一个实例。此外，每一行都可以指向同一数据库的其他表上的其他行，并且可以通过使用引用完整性来保持此关系之间的一致性。这个模式很好，但是，它缺少了一个非常基本的词：对象。

确实，当我们谈论关系模型时，我们只是在谈论数据表、行与行之间的关系。当我们谈论面向对象模型时，我们主要在谈论对象的组成。因此每次我们从关系数据库中获取数据（一行数据）时，都会运行一个转换过程，负责构建我们可以使用的内存中的表示形式。相反方向也同样是这样，没当我们需要在数据库中存储一个对象时，我们都要运行另一个转换过程，来将该对象转换为给定表中的一行数据。这种从对象到行行或表的转换，意味着你可以对数据库运行不同的查询。这样，在不使用任何特定工具（如事务）的情况下，不能保证数据被一致性的持久化。这个问题就是所谓的`阻抗不匹配（impedance mismatch）`。

> **阻抗不匹配**
>
> 对象关系阻抗不匹配是一组概念性的技术难题，当以面向对象的编程语言使用关系数据库(RDBMS)时，尤其是在对象或类定义时以直接映射到数据库表上，通常会遇到这样的问题。

阻抗不匹配不是一个容易解决的问题，因此我们强烈建议你尝试自行解决。这将是一项艰巨的任务，这根本不值得投入付出。所幸的是，有一些已经注意到这个转换问题的类库了，它们通常被称为关系对象映射器（Object-Relational Mappers，ORM，这个之前我们已经讨论过），这些类库的主要关注点是简化从关系模型到面向对象模型的转换过程。

这个问题也影响NoSQL引擎，而不仅仅是数据库。大多数NoSQL使用document。实体会转换为document的表示形式，例如Json、XML、二进制文件等，然后持久化。与RDBMS数据库的主要区别在于，如果实体（如Order）具有其他相关实体（如OrderLines），则可以更轻松的设计一个包含所有信息的Json document。通过这种方法，只需要向NoSQL发送一个请求，就不需要事务了。

但是，如果你使用NoSQL或RDBMS来获取和持久化实体，你可能需要一次或多次查询。为了确保数据一致性，这些查询需要作为一次请求执行，作为单词操作可以保证数据一致。

一致是什么意思？这意味着持久化到我们数据库中的所有数据必须复合所有业务规则，也成为不变性。业务不变性的一个示例可能是Github上的用户如何拥有无限的公共存储库而没有私有存储库。但是，如果该用户每月支付12美元，那么他们最多可以拥有10个私有存储库。

关系数据库提供了三个主要工具来帮助我们实现数据一致性: 

- 参照完整性：外键，null值检查等
- 事务：将多个查询作为一个操作，事务问题与代码库中的分支合并问题相同，保留分支会降低性能（内存、CPU、空间索引等），如果同时太多人接触（并发）相同的数据，则会发生冲突，并且事务将提交失败。
- 锁：锁定行或者锁表。围绕相同表或相同行的查询必须等待阻塞被移除。锁会对应用程序的性能产生负面影响。

假设我们有一个要业务扩展到其他国家和地区的电商程序，并且发展势头良好，销售额增加。有一个明显的副作用是数据库增加了额外的负载，如前面所述，有两种方式。

扩大规模意味着我们改善了现有的硬件基础架构（如添加更好的CPU、内存、硬盘），向外扩展意外着添加更多的计算机，以集群方式可以完成特定工作，这样，我们可以有个数据库集群。

但是，关系数据库并非旨在水平扩展，因为我们无法对其进行配置，以将一组行保存到指定的计算机上，而将另一组行保存到另一台计算机上。关系数据库易于扩展，但关系模型不能水平扩展。

在NoSQL中，数据一致性要困难一些：事务和应用完整性通常不支持，而锁是支持的，但不鼓励使用。

阻抗不匹配不会严重影响NoSQL数据库。NoSQL数据库与聚合设计完美匹配，因为它们使我们能够轻松的、原子的存储和检索单个单元。比如，使用键值对存储（如redis）时，可以将聚合序列化并存储在特定的key上。在诸如Elasticsearch之类的面向文档的存储中，聚合被序列化为Json文档并被持久化。

出于这个原因，当用单个形式（一个document文档）持久化存储任何对象时，很容易将这些单个单元分布在几台称为NoSQL数据库集群的机器上，称为节点。众所周知，这些数据库易于分发，这意味着数据库易于水平扩展。

一些历史
---
在21世纪初，注入Amazon和Google之类的公司迅猛发展，为了巩固其增长，他们使用了集群技术：不仅拥有更好的服务器，而且还依赖于更多的服务器协同工作。

在这种情况下，决定如何存储数据是关键，如果采用实体并将其信息分布在集群的多个节点中，则控制事务所需的工作量很大。如果要获取实体也同样有这样的问题。因此如果你可以以持久化在集群节点中的方式设计实体，那事情就变得容易很多，这就是聚合设计如此重要的原因之一。

如果你想要了解更多关于领域驱动设计的历史，可以看这本书《NoSQL Distilled: A Brief Guide to the Emerging World of Polyglot Persistence.》

聚合的剖析
---
聚合是一个持有其他实体和值对象的实体。其父实体被称之为聚合根。

一个没有任何子实体和值对象的实体也是一个聚合。这就是为什么在一些书中，使用术语“聚合”而不是“实体”的原因。当我们使用它们时，聚合和实体是一回事。

聚合的主要目的是保持你领域模型的一致性。聚合集中了大多数的业务逻辑。聚合是以原子方式持久化在你的数据库中。不管聚合根中有多少实体和值对象，它们都将作为单个原子的被持久化，让我们看个例子。

一个电商程序、网站。用户可以下单，其中订单上有很多行都标明了每个商品的单价、数量和这一行的金额，订单自己也有个总金额，这是每行金额的综合。

如果更新一行中的金额而不更新订单的总金额会怎么样？数据不一致。要解决这个问题，对聚合中任何实体和值对象的修改需要通过聚合根来进行。我们见过的许多PHP开发人员都喜欢直接在客户端构建对象并处理它们之间的关系，然后将业务逻辑放到实体中：

```php
$order = ...
$orderLine = new OrderLine(
    'Domain-Driven Design in PHP', 24.99
);
$order->addOrderLine($orderLine);
```
示例中，新手或者普通开发者通常首先构建子对象，然后使用setter方法将它们与父对象关联。你再看一下这个做法：

```php
$order = ...
$orderLine = $order->addOrderLine(
    'Domain-Driven Design in PHP', 24.99
);
```
或
```php
$order = ...
$order->addOrderLine(
    'Domain-Driven Design in PHP', 24.99
);
```
这些方式非常有趣，因为它们遵循两个软件设计原则：Tell-Don't-Ask和Demeter定律。

Martin Fowler说：

> Tell-Don't-Ask是一个原则，可以帮助人们记住面向对象是将数据与对该数据操作的功能绑定在一起。它提醒我们，我们应该告诉对象去做什么，而不是向对象获取数据并对数据执行操作。这么做是鼓励将行为放到对象中去操作数据。

维基百科：

> Demeter定律是用于开发软件的设计指南。一般情况下，该定律是松散耦合的案例，可以这么简要总结：
> - 每个单元应当对其他单元的了解应当有限
> - 每个单元只能与它的朋友交谈，不要与陌生人交谈。
> - 只与你的最直接的朋友交谈。
> 
> 其基本理念是，根据“信息隐藏”原理，给定的对象应尽可能少的猜测和考虑其他任何事物（包括其子组件）的结构或属性。


让我们继续考虑订单的案例，你已经学习了如何通过根实体操作了。现在，让我们更新订单中某行的产品数量，这样增加了订单每行金额、订单总金额。非常棒！是时候将订单的修改保存起来了。

如果你正在使用MySQL，你可能会想到我们需要用两个`Update`语句：一个对order表，一个对order_lines表。如果这两个查询不在一个事务中会发生什么？

让我们假设`UPDATE`语句更新订单的一行数据工作正常，但是由于网络问题，更新订单总金额失败。在这种情况下，你的领域模型中出现了数据不一致的情况，事务可以帮助你保持这种一致性。

如果你使用的是Elasticsearch，情况就不一样了。你可以使用一个内部持有每个产品项的Json文档来与订单进行映射，所以只需要一次请求。但是，如果你打算将一个订单与一个文档映射，并且订单中的每个订单项与其他文档映射，那么你可能会遇到麻烦，因为Elasticsearch不支持事务！

使用Repository可以获取和持久化一个聚合。如果两个实体不属于同一个聚合，则每个实体都有其自己的Repository。如果两个实体间存在业务上的不变性，并且属于同一个聚合，则你只需要一个Repository，该Repository将是根实体的。

聚合的缺点是什么？当处理事务时，可能会出现性能问题和操作错误。

聚合设计规则
---
在设计聚合时，要遵循一些规则和注意事项，以获取所有的好处并最大程度减少负面影响。如果你现在不了解所有内容请不要担心。我们将向你展示一个小型应用程序，在程序中我们将使用到的规则跟你解释。

#### 设计基于业务真实不变性的聚合

首先，什么是不变性？不变性是在代码执行期间必须真实和一致的规则。例如，堆栈是一种LIFO（后进先出）的数据结构，我们可以将元素push进去和pop出来。我们还可以查询堆栈中有多少个元素。这就是所谓的堆栈大小。看一下不使用任何特定PHP数组的函数（如array_pop）的纯PHP实现：

```php
class Stack
{
    private $data;
    public function __construct()
    {
        $this->data = [];
    }
    public function push($value)
    {
        $this->data[] = $value;
    }
    public function size()
    {
        $size = 0;
        for ($i = 0; $i < count($this->data); $i++) {
            $size++;
        }
        return $size;
    }
    /**
    * @return mixed
    */
    public function pop()
    {
        $topIndex = $this->size() - 1;
        $top = $this->data[$topIndex];
        unset($this->data[$topIndex]);
        return $top;
    }
}
```

看一下`size`方法，实现的非常完美且有效。但是有着CPU密集型且高昂的调用成本。所幸的是，我们可以通过引入一个私有属性来追踪内部数组元素的数量来改进此方法：

```php
class Stack
{
    private $data;
    private $size;
    public function __construct()
    {
        $this->data = [];
        $this->size = 0;
    }
    public function push($value)
    {
        $this->data[] = $value;
        $this->size++;
    }
    public function size()
    {
        return $this->size;
    }
    /**
    * @return mixed
    */
    public function pop()
    {
        $topIndex = $this->size--;
        $top = $this->data[$topIndex];
        unset($this->data[$topIndex]);
        return $top;
    }
}

```
有了这些改变，`size`方法现在操作快速，因为它只返回了size字段的值。为此，我们引入了一个名为size的新整数属性。 创建新堆栈时，size的值为0，并且堆栈中没有元素。 当我们使用push方法将新元素添加到堆栈中时，我们会增大size字段的值。 同样，当使用pop方法从堆栈中删除一个值时，我们会减小size的值。

通过增大和减小size的值，我们使该字段与堆栈内部的实际元素数量保持一致。在调用任何堆栈类的方法前后，size的值的大小都是与堆栈内部实际元素数量是一致的。那么，size的值始终等于堆栈中元素数量，这是一个不变性，我们可以将其记为`$this->size === count($this->data)`

真实的业务不变性是一种业务规则，必须始终是正确的，并且在聚合中保持一致性。一致性是指更新聚合必须是原子操作。聚合中包含的所有数据必须是原子方式存储，如果我们不遵循此规则，则可能持久化了一个无效的聚合。

Vaughn Venon说：

> 正确设计的聚合可以以任何业务所需的方式进行修改的，业务不变性在单个事务中完全一致。一个正确设计的限界上下文在所有用例中的每次事务中，只修改一个聚合。此外，如果不使用事务分析，我们无法正确的思考聚合设计。

如前面所说，电商程序中，订单总金额必须与订单中每一项的金额总和相同。这是一个不变性或者是一个业务规则。我们必须在同一个事务中将Order和OrderLines保存到数据库。这迫使我们使得Order和OrderLine成为同一个聚合的一部分，其中Order将是聚合根。因为Order是聚合根，所以对OrderLine相关的所有操作都必须通过Order进行。因此不需要在Order之外实例化OrderLine对象，然后在通过setter方法将OrderLine添加到Order中。相反，我们必须在Order上使用工厂方法。

使用这些方法，我么只有一个入口可以对聚合执行操作：Order。这意味着没有机会调用打破该规则的方法。每次通过Order添加或更新OrderLine时，订单总金额都会在内部重新计算，所遇操作都通过聚合根帮助我们保持聚合的一致性。这样，很难去打破不变性。

#### 小聚合 Vs. 大聚合

对于我们所经手过的项目来说，将近95%的聚合都是由一个单一的根实体和一些值对象构成。没有其他实体必须与其在同一个聚合中，因此在大多数情况下，没有真正的业务不变性可以保持不变性。

注意那些不一定会让两个实体成为一个聚合（其中一个实体是聚合根）的`has-a`或者`has-many`关系。我们可以看到，可以通过引用实体身份标识来处理它们之间的关系。

如上所述，聚合是一个事务的边界。边界越小，提交多个并发事务时发生冲突的机会就越少。设计聚合时，应该努力将其创建的较小。如果没有真实的不变性要保护，则意味着所有单个实体都将自己形成一个聚合。这是实现最佳性能的最佳方案。为什么，因为锁的问题和事务失败问题都会被最小化。

如果你决定使用大的聚合，则保持数据一致性将会更容易，但也可能没作用。当具有大的聚合的应用在生产环境中运行时，当多个用户执行操作时，它们会遇到问题。使用乐观并发策略时，主要处理的问题是事务的失败问题。当使用锁机制时，主要问题在于速度慢和超时问题。

让我们考虑一些极端的例子。当使用乐观并发策略时，想象一下整个领域都是版本化的，并且任何实体上的每个操作都会为整个领域创建一个新版本。这种情况下，如果两个用户在根本无法关联的不同实体上执行不同的操作，则第二个请求将因为版本不同而导致事务失败。另一方面，在使用悲观并发策略时，请设想一下在每个操作上锁定数据库的情况。这将阻塞所有用户的操作，知道缩被释放。这意味着许多请求要将进行排队等待，并且有时可能会导致超时。这两个示例均使数据保持一致，但是应用程序不能有多个用户同时使用。

最后，当设计大的聚合时，由于它们可能持有实体的集合（collection），因此考虑将这些集合加载到内存时对性能所产生的影响是非常重要的。即使使用如Doctrine之类的ORM，它可以延迟加载集合（lazy load），但是如果集合太大，也是无法放到内存中的。

#### 通过身份标识引用其他实体

当两个实体不足以形成一个聚合，但还是存在一定的关系时。最好的方式是使用另一个实体的身份标识作为引用。（身份标识已经在第4章中讲过了）

考虑一下`User`和它们的`Orders`，假设我们没有在它们之间发现真实的不变性（译者注：在用户和订单之间没有存在必要的一致性的业务规则），`User`和`Order`不会成为同一个聚合中的一部分。如果你想知道哪个用户拥有特定的订单，你可以通过用户`UserId`来查询`Order`，`UserId`是一个持有用户身份标识的值对象。我们通过`UserRepository`获取整个User实体。这段代码通常存在应用服务层（Application Service）。

这里说明一下，每个聚合都有自己的Repository。如果你需要获取一个特定的聚合，并且你也需要获取另一个相关联的聚合。你需要在领域服务（Domain Service）或应用服务（Application Service）中来做这些事。应用服务将依赖于Repository来获取所需的聚合。

从一个聚合跳到另一个聚合通常被称之为traversing或者navigating你的领域（译者注：跨越、横跨领域）。使用ORM，通过映射实体之间的所有关系很容易做到。但是这非常危险，因为你可以轻松的在特定功能中滥用查询。你不应该这么做，不要映射所有实体之间的关系。相反，你应该仅当两个实体形成一个聚合时，才在ORM中映射一个聚合内的实体之间的关系。如果不是这种情况，则请使用对应的Repository来获取引用的聚合。（译者注：在使用ORM映射实体对象时，只对在同一个聚合内的实体之间进行映射）

#### 每个事务和请求中只修改一个聚合

考虑以下情况：你发出了一个请求，该请求进入你的控制器，并且打算更新两个不同的聚合。每个聚合在各自聚合中保持数据一致。但是，如果请求在第一次聚合更新后突然停止（因服务器重启、内存不足等），并且第二个聚合未更新，将会发生什么？那是数据一致性问题吗？可能是吧，让我们考虑一下方案。

Vaughn Vernon的《Implementing Domain-Driven Design》书中说：

> 在经过适当设计的衔接上下文中，每个事务仅修改一个聚合实例。而且，如果不使用事务，我们无法正确的思考聚合设计。将修改限制为每个事务仅一个聚合听起来过于严格，但是根据经验来说，在大多数情况下应该是这样的。它解决了使用聚合的真正原因。

如果在单个请求中需要更新两个聚合，则可能这两个聚合是一个聚合，并且都需要在同一事务中进行更新。如果不是，你可以将整个请求包装在一个事务中，但由于性能问题和事务错误问题，我们不建议你先考虑这么做。（译者注：两个聚合如果可以设计为一个聚合，则用同一个事务。否则把整个请求放在一个事务中进行处理，这事务中还包含了每个聚合中的事务。）

如果不需要将不同聚合的更新放在一个事务中，则意味着我们可以假设一次更新与另一次更新之间存在一些延迟。这种情况下，一种领域驱动设计的方式是使用领域事件。这么做时，第一个聚合更新将触发领域事件，该事件将与该聚合在同一事务中被持久化，然后发布事件到我们的消息队列中，随后监听进程从队列中获取事件并执行第二次聚合更新。这种方法促进了最终一致性，减小了事务边界的大小，提高了性能，减少了事务错误。

示例应用：User和Wishes
---

现在你知道了聚合设计的基本规则。

了解聚合的最佳方式是看代码。因此我们看一个web程序的场景，该场景中，用户可以许一些愿望。比如我想给我的妻子发一封电子邮件，说明如果我因为事故去世，该如何处理我的github帐户，或者我想发送电子邮件给告诉我妻子我有多爱她。（你可以在我们的github帐户仓库中看到这个示例应用）所以这里我们有用户和他们的愿望两个概念。让我们考虑这么一个用例：“作为用户，我想许一个愿望”。如何去为这个用例建模？请遵循良好的实践，让我们尝试设计小的聚合。这种情况下，需要使用两个不同的聚合，每个实体分别为User和Wish，对于它们之间的关系，我们应该使用身份标识进行引用，例如`UserId`。


#### 两个聚合不存在不变性

我们将在这节讨论应用服务，但是现在，让我们看一下创建愿望的不同方式。第一种方式特别适合新手，像是这样：

```php
class MakeWishService
{
    private $wishRepository;
    public function __construct(WishRepository $wishRepository)
    {
        $this->wishRepository = $wishRepository;
    }
    public function execute(MakeWishRequest $request)
    {
        $userId = $request->userId();
        $address = $request->address();
        $content = $request->content();
        $wish = new Wish(
            $this->wishRepository->nextIdentity(),
            new UserId($userId),
            $address,
            $content
        );
        $this->wishRepository->add($wish);
    }
}
```
这样的代码性能会是最好的，这种用例的最小的操作数是1，这很好。通过当前的实现，我们可以根据需求创建任意数量的愿望，也不错。

但是，可能存在潜在的问题：我们可以为领域中不存在的用户创建愿望。无论我们使用什么技术来持久化聚合，这都是一个问题。即使使用内存方式实现持久，也可以创建没有对应用户的愿望。

这是坏的业务逻辑。当然，可以使用数据库中的外键解决此问题（从wish的user_id到user的id）。但是如果我们不使用具有外键的数据库怎么办？如果是NoSQL数据库（如redis或Elasticsearch）怎么办？

如果我们要解决这问题，以使得相同代码在不同的具体实现中正常工作，则需要检查用户是否存在。最简单的方法可能是在同一个应用服务中进行：

```php
class MakeWishService
{
    // ...
    public function execute(MakeWishRequest $request)
    {
        $userId = $request->userId();
        $address = $request->address();
        $content = $request->content();
        $user = $this->userRepository->ofId(new UserId($userId));
        if (null === $user) {
            throw new UserDoesNotExistException();
        }
        $wish = new Wish(
            $this->wishRepository->nextIdentity(),
            $user->id(),
            $address,
            $content
        );
        $this->wishRepository->add($wish);
    }
}
```
这可以运行，但是在应用服务中执行这个检查有一些问题：这个检查在委托链中很高，如果不存在这个应用服务中的其他代码片段想（如领域服务或另一个实体）要为不存在的用户创建愿望，也是可以实现的：

```php
// Somewhere in a Domain Service or Entity
$nonExistingUserId = new UserId('non-existing-user-id');
$wish = new Wish(
    $this->wishRepository->nextIdentity(),
    $nonExistingUserId,
    $address,
    $content
);
```
如果你已经阅读了第9章工厂内容，你就会知道怎么解决了。工厂帮助我们保持业务不变性，这正是我们这里所需要的。

这里有一个隐藏的不变性，就是我们不允许非有效的用户创建愿望。让我们看看工厂如何提供帮助：

```php
abstract class WishService
{
    protected $userRepository;
    protected $wishRepository;
    public function __construct(
        UserRepository $userRepository,
        WishRepository $wishRepository
    ) {
        $this->userRepository = $userRepository;
        $this->wishRepository = $wishRepository;
    }
    protected function findUserOrFail($userId)
    {
        $user = $this->userRepository->ofId(new UserId($userId));
        if (null === $user) {
            throw new UserDoesNotExistException();
        }
        return $user;
    }
    protected function findWishOrFail($wishId)
    {
        $wish = $this->wishRepository->ofId(new WishId($wishId));
        if (!$wish) {
            throw new WishDoesNotExistException();
        }
        return $wish;
    }
    protected function checkIfUserOwnsWish(User $user, Wish $wish)
    {
        if (!$wish->userId()->equals($user->id())) {
            throw new \InvalidArgumentException(
                'User is not authorized to update this wish'
            );
        }
    }
}
class MakeWishService extends WishService
{
    public function execute(MakeWishRequest $request)
    {
        $userId = $request->userId();
        $address = $request->address();
        $content = $request->content();
        $user = $this->findUserOrFail($userId);
        $wish = $user->makeWish(
            $this->wishRepository->nextIdentity(),
            $address,
            $content
        );
        $this->wishRepository->add($wish);
    }
}
```
如你所看到的，`Users`创建了`Wishes`。`makeWish`是用于创建愿望的工厂方法，该方法返回带有`UserId`的新创建的`Wish`：

```php
class User
{
    // ...
    /**
    * @return Wish
    */
    public function makeWish(WishId $wishId, $address, $content)
    {
        return new Wish(
            $wishId,
            $this->id(),
            $address,
            $content
        );
    }
    // ...
}
```

为什么我们return一个Wish，而不是将新的Wish添加到内部的集合中。在这种情况下，`User`和`Wish`不符合聚合的要求，因为没有真实的业务变量可以保护。用户可以根据需要添加和删除任意数量的愿望。如果需要，可以在数据库中以不同的事务单独更新愿望和用户。

遵循前面解释的有关聚合设计的原则。我们的目标应该是小聚合。现在就是，每个实体都有自己的Repository，Wish使用标识（这里为UserId）引用对应的User。可以通过WishRepository中的查询方法查找该用户的所有愿望，并可以轻松的进行分页，而不是会先任何性能问题。

```php
interface WishRepository
{
    /**
    * @param WishId $wishId
    *
    * @return Wish
    */
    public function ofId(WishId $wishId);
    /**
    * @param UserId $userId
    *
    * @return Wish[]
    */
    public function ofUserId(UserId $userId);
    /**
    * @param Wish $wish
    */
    public function add(Wish $wish);
    /**
    * @param Wish $wish
    */
    public function remove(Wish $wish);
    /**
    * @return WishId
    */
    public function nextIdentity();
}
```
该方法一个有趣的方面是，我们不必在最喜欢的ORM中映射`User`与`Order`之间的关系。因为我们使用`UserId`从`Wish`中引用了`User`，所以我们只需要Repository。让我们考虑一下如何使用Doctrine：

```yaml
Lw\Domain\Model\User\User:
    type: entity
    id:
        userId:
            column: id
            type: UserId
    table: user
    repositoryClass:
      Lw\Infrastructure\Domain\Model\User\DoctrineUser\Repository
    fields:
        email:
          type: string
        password:
          type: string
          
Lw\Domain\Model\Wish\Wish:
    type: entity
    table: wish
    repositoryClass:
      Lw\Infrastructure\Domain\Model\Wish\DoctrineWish\Repository
    id:
        wishId:
            column: id
            type: WishId
    fields:
        address:
          type: string
        content:
          type: text
        userId:
            type: UserId
            column: user_id
```

没有定义关系，在创建一个新愿望之后，让我们写一些代码来更新这个愿望：

```php
class UpdateWishService extends WishService
{
    public function execute(UpdateWishRequest $request)
    {
        $userId = $request->userId();
        $wishId = $request->wishId();
        $email = $request->email();
        $content = $request->content();
        $user = $this->findUserOrFail($userId);
        $wish = $this->findWishOrFail($wishId);
        $this->checkIfUserOwnsWish($user, $wish);
        $wish->changeContent($content);
        $wish->changeAddress($email);
    }
}
```

由于`User`和`Wish`构不成聚合。因此，为了更新愿望，我们首先需要使用`WishRepository`来检索它。一些额外的检查确保只有该愿望的作者才能更新它。如你所见，`$wish`已经是我们领域中存在的实体，因此无需使用存储库再次将其添加回去。但是，为了使修改能够被持久化，我们的ORM必须了解更新的信息，并在工作完成后将剩余的修改刷新到数据库中。不用担心，我们将在第11章应用中进行仔细研究。为了完成该示例，我们看一下如何删除愿望：

```php
class RemoveWishService extends WishService
{
    public function execute(RemoveWishRequest $request)
    {
        $userId = $request->userId();
        $wishId = $request->wishId();
        $user = $this->findUserOrFail($userId);
        $wish = $this->findWishOrFail($wishId);
        $this->checkIfUserOwnsWish($user, $wish);
        $this->wishRepository->remove($wish);
    }
}
```
正如你看到的，你应该重构一部分代码，例如构造函数和所有权检查，是为了在两个应用服务中能够重用这些逻辑。最后我们该如何获得特定用户的所有愿望：

```php
class ViewWishesService extends WishService
{
    /**
    * @return Wish[]
    */
    public function execute(ViewWishesRequest $request)
    {
        $userId = $request->userId();
        $wishId = $request->wishId();
        $user = $this->findUserOrFail($userId);
        $wish = $this->findWishOrFail($wishId);
        $this->checkIfUserOwnsWish($user, $wish);
        return $this->wishRepository->ofUserId($user->id());
    }
}
```

这很简单，但是在应用服务章节中我们会更深入的介绍，就目前而言，返回一个愿望的集合就行了。

让我们总结一下这种非聚合的做法。我们找不到任何真实的业务不变性来将`User`和`Wish`看做一个聚合。这就是为什么它们各自是个聚合的原因。`User`有自己的`UserRepository`,`Wish`也有自己的`WishRepository`。每个`Wish`都拥有对`User`的`UserId`的引用，即便这样，我们也不需要使用事务。就性能和可伸缩性问题而言，这是最佳方案。然而，并不是一切都是这么顺利，如果存在真实的业务不变性会怎样？

#### 每个用户不能超过三个愿望

我们的应用程序取得了巨大的成功，现在时候从中获取一些收益了。我们现在希望每个用户最多创建三个愿望。作为用户，如果你希望创建更多愿望，需要付费成为高级帐户。让我们看看如何修改代码来遵循这个新业务规则（先不考虑付费账户）。

看一下下面的代码，除了上一节提到的将业务逻辑放入实体内，这样的代码也能工作：

```php
class MakeWishService
{
    // ...
    public function execute(MakeWishRequest $request)
    {
        $userId = $request->userId();
        $address = $request->email();
        $content = $request->content();
        $count = $this->wishRepository->numberOfWishesByUserId(
            new UserId($userId)
        );
        if ($count >= 3) {
            throw new MaxNumberOfWishesExceededException();
        }
        $wish = new Wish(
            $this->wishRepository->nextIdentity(),
            new UserId($userId),
            $address,
            $content
        );
        $this->wishRepository->add($wish);
    }
}
```
这看起来可以，真的是太简单了！但是我们遇到了另一个问题，首先应用服务做的是协调工作，这里不应该包含业务逻辑。相反，更好的方法是将最多三个愿望的业务检查放到`User`中，那里可以更好的控制`User`和`Wish`之间的关系。

第二个问题是，这样的代码在竞争条件下不起作用。暂时忘记领域驱动设计一会儿，想一下这段代码在流量繁忙的时候会有什么问题。用户有没有可能打破只能许三个愿望的规则？为什么在进行一些压力测试之后，你的测试人员会如此开心？

你的测试人员尝试创建两次愿望，则使得用户拥有两个愿望。想象一下，他们在浏览器中打开了两个tab页，填写了每个页面的表单后，并设法同时提交两个表单。突然，在两次请求之后，用户最终在数据库中有了四个愿望！这到底哪里错了？

从调试的角度进行考虑，两个不同请求同时走到了`if($count>3){}`语句，所以两个请求都返回false。因此两个请求都创建了愿望，并且都添加到了数据库中，结果是用户拥有了四个愿望！

我知道你在想什么，因为我们没有把所有的东西放在一个事务中。好吧，假设ID为1的用户已经有两个愿望，因此还有一个愿望可以创建。创建两个不同愿望的两个HTTP请求同时到达。我们为每个请求启动一个数据库事务（我们将在第11章应用中介绍如何处理事务和请求）。

> 译者注：这里应当有配图，后续补充上。记得提醒我，可能会忘记。

ID为1的用户有四个愿望，这怎么发生的。如果你使用SQL并在两个不同的连接中逐行执行，你将看到wishs在两个结束时如何具有四行数据。因此这似乎与事务保护无关，我们如何解决这问题？如之前所说，并发控制会有所帮助。

对于在数据库技术方面的高级开发人员，可以调整隔离级别。但是我们认为这么做太复杂了，因为可以通过其他方法来解决该问题，而不是总是先去处理数据库上的问题。

> 译者注：这里省略两小节关于数据库悲观并发控制策略和乐观并发控制策略的内容，有需要的话我再翻译过来，否则建议可以参阅其他关于数据库并发控制的文章。

我们将在第11章应用深入，这里做个总结：

- Application Service返回一个DTO构建访问聚合的信息
- Application Service返回一个由聚合返回的DTO
- Application Service使用一个写入聚合的Output，这样的Output会处理转换为DTO或者其他格式

事务
---

我们还没在示例中看到`beginTransaction`,`commit`,或者`rollback`，这是因为事务在Application service层被处理。别担心，你将在第11章看到这些。

总结
---
聚合都是关于持久性和事务的。实际上，你不考虑如何被持久化就无法设计聚合。设计正确聚合的基本原则是：尽可能的小、找到真实的业务不变性、使用领域事件推动最终一致性、通过身份标识引用其他聚合、一个请求修改一个聚合。回顾了两个实体形成一个聚合时如何修改代码，我们使用了工厂方法来丰富了实体。最后，在我们看到的大多数PHP应用中，只有5%的实体是由两个或更多的实体组成的聚合。在设计和实现聚合时与你的同事一起讨论。