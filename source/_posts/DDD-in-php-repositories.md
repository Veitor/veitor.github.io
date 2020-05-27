---
title: '[译]仓储 - 《Domain-Driven Design in PHP》第10章'
tags:
  - ddd
  - 领域驱动设计
categories:
  - PHP
date: 2020-05-27 09:42:09
---

> 本篇博文由本博客(`http://www.veitor.net`)经原文翻译，转载请注明出处。


为了与领域对象进行交互，你需要持有该对象的引用。实现这样的一种方式是通过创建对象来实现。或者，你可以贯穿关联，在面向对象编程中，对象持有与其他对象的引用，这使它们贯穿，从而有助于我们的模型的展现。但是，你需要有一种机制来获取第一个对象：聚合根。

<!-- more -->

仓储扮演者存储的角色，在这里可以获取到与存储时完全相同状态的对象。在领域驱动设计中，每一个聚合类型通常都有一个唯一的关联的仓储，用于该聚合的持久化和获取需求。但是，在需要共享一个聚合对象层级结构的情况下，这个类型可能共享一个仓储。

一旦你从仓储中成功获得聚合，你做的每个修改都会被持久化，不需要再存回仓储。

定义
---

Martin Fowler这样定义仓储：

> 领域与数据映射层之间的机制，就像是内存领域对象的集合。客户端构造查询规约，然后提交给仓储。可以像从简单的对象集合中那样将对象添加到仓储或从仓储中删除对象，并且仓储内部封装的映射代码将在背后执行适当的操作。从概念上讲，仓储封装了持久化在数据仓库的对象和一些操作，从而提供了持久层面向对象的视角。仓储也支持在领域和数据映射层之间实现清晰的分离和单项的依赖。

仓储不是DAO
---

Data Access Object(DAO)是持久化领域对象到数据库的通用模式。这很容易将DAO模式与仓储混淆起来，最重要的不同点是仓储展现了集合，然而DAO更接近数据库，并且通常以数据表为主。通常，DAO包含特定领域对象的CRUD方法，让我们看一下DAO通用接口大致像这样：

```php
interface UserDAO
{
    /**
    * @param string $username
    * @return User
    */
    public function get($username);
    public function create(User $user);
    public function update(User $user);
    /**
    * @param string $username
    */
    public function delete($username);
}
```
一个DAO接口可能有多种实现，从使用原生SQL查询到ORM构造器。DAO的主要问题是它们的职责没有明确定义。DAO通常被认为是数据库的网关，因此使用许多特定方法来查询数据库可以大大降低内聚性，这相对容易：

```php
interface BloatUserDAO
{
    public function get($username);
    public function create(User $user);
    public function update(User $user);
    public function delete($username);
    public function getUserByLastName($lastName);
    public function getUserByEmail($email);
    public function updateEmailAddress($username, $email);
    public function updateLastName($username, $lastName);
}
```

如你所见，实现越多的新方法，就越难去测试DAO，而且它将与`User`对象紧密耦合。这问题将随着时间推移而明显，越多的协同开发者将会使得成为一个大泥球（Big Ball of Mud）。

面向集合的仓储
---
仓储通过实现通用接口来模拟集合，作为一个集合，一个仓储不应该泄露任何持久化行为的意图，比如仓储到库中。

底层的持久性机制必须支持这种需求，你不需要在对象的真个生命周期处理对它们的修改，该集合应用对象的最新状态，这意味着每次访问时，你都会获得最新的对象状态。

仓储库实现了一个具体的集合类型——Set。一个Set是具有不包含重复条目的不变量的数据结构。如果你尝试添加已经存在与Set中的元素，则不会添加进去。这在我们的用例中很有用，因为每个聚合都具有与实体相关的唯一身份标识。

看一下例子：

```php
namespace Domain\Model;
class Post
{
    const EXPIRE_EDIT_TIME = 120; // seconds
    private $id;
    private $body;
    private $createdAt;
    public function __construct(PostId $anId, Body $aBody)
    {
        $this->id = $anId;
        $this->body = $aBody;
        $this->createdAt = new \DateTimeImmutable();
    }
    public function editBody(Body $aNewBody)
    {
        if($this->editExpired()) {
            throw new RuntimeException('Edit time expired');
        }
        $this->body = $aNewBody;
    }
    private function editExpired()
    {
        $expiringTime= $this->createdAt->getTimestamp() +
        self::EXPIRE_EDIT_TIME;
        return $expiringTime < time();
    }
    public function id()
    {
        return $this->id;
    }
    public function body()
    {
        return $this->body;
    }
    public function createdAt()
    {
        return $this->createdAt;
    }
}
class Body
{
    const MIN_LENGTH = 3;
    const MAX_LENGTH = 250;
    private $content;
    public function __construct($content)
    {
        $this->setContent(trim($content));
    }
    private function setContent($content)
    {
        $this->assertNotEmpty($content);
        $this->assertFitsLength($content);
        $this->content = $content;
    }
    private function assertNotEmpty($content)
    {
        if(empty($content)) {
            throw new DomainException('Empty body');
        }
    }
    private function assertFitsLength($content)
    {
        if(strlen($content) < self::MIN_LENGTH) {
            throw new DomainException('Body is too short');
        }
        if(strlen($content) > self::MAX_LENGTH) {
            throw new DomainException('Body is too long');
        }
    }
    public function content()
    {
        return $this->content;
    }
}
class PostId
{
    private $id;
    public function __construct($id = null)
    {
        $this->id = $id ?: uniqid();
    }
    public function id()
    {
        return $this->id;
    }
    public function equals(PostId $anId)
    {
        return $this->id === $anId->id();
    }
}
```

如果我们想要持久化`Post`实体，一个简单的内存实现的`PostRepository`像这样：

```php
class SimplePostRepository
{
    private $post = [];
    public add(Post $aPost)
    {
        $this->posts[(string) $aPost->id()] = $aPost;
    }
    public function postOfId(PostId $anId)
    {
        if (isset($this->posts[(string) $anId])) {
            return $this->posts[(string) $anId];
        }
        return null;
    }
}
```
然后按你所想的处理集合：

```php
$id = new PostId();
$repository = new SimplePostRepository();
$repository->add(new Post($id, 'Random content'));

// later ...
$post = $repository->postOfId($id);
$post->editBody('Updated content');

// even later ...
$post = $repository->postOfId($id);
assert('Updated content' === $post->body());
```

如你所见，从集合的角度来看，Repository不需要用于保存的方法。对对象的修改由基础设施层正确处理。面向集合的仓储是不需要添加之前已经保存过的聚合的。这主要是发生在基于内存的仓储中，但是我们也有使用持久化机制仓储进行存储的方法。我们待会儿再看。次完，我们将在第11章应用中更深入介绍这一点。

设计一个仓储的第一步是为其定义一个面向集合的接口。接口需要定义一些常用的方法，如：

```php
interface PostRepository
{
    public function add(Post $aPost);
    public function addAll(array $posts);
    public function remove(Post $aPost);
    public function removeAll(array $posts);
    // ...
}
```
对于实现这样的接口，你可以使用一个抽象类。通常，让我们谈论接口时，我们通常指的是概念，而不是仅仅是PHP interface接口。为了简化设计，不要添加你不需要的方法。仓储的定义和其对应的聚合应该放置在同一个模块中。

有时，删除并不会从数据库中屋里删除聚合。这种策略（聚合的状态字段被更新为已删除）被称为软删除。为什么这方法有趣？审核修改和性能会很有趣。这种情况下，你可以将聚合标记为禁用或逻辑删除。可以通过去掉删除方法或提供禁用行为来更新这个仓储。

仓储另一个重要的方面是查找方法，像这样：

```php
interface PostRepository
{
    // ...
    /**
    * @return Post
    */
    public function postOfId(PostId $anId);
    /**
    * @return Post[]
    */
    public function latestPosts(DateTimeImmutable $sinceADate);
}
```

如我们在第4章实体中建议的，我们更喜欢应用生成的身份标识。为聚合生成一个新身份标识的最好的位置就是在其Repository中。因此为一个`Post`获取一个全局唯一ID，包含这逻辑的位置在`PostRepository`中：

```php
interface PostRepository
{
    // ...
    /**
    * @return PostId
    */
    public function nextIdentity();
}
```

负责构建每个`Post`实例的代码调用`nextIdentity`来获得唯一标识符`PostId`：

```php
$post = newPost($postRepository->nextIdentity(), $body);
```

一些开发者将实现作为模块的子包放在靠近接口定义的地方。但是，由于我们希望清晰的分离关注点，因此建议你将其放在基础设施层中。

#### 基于内存的实现

Uncle Bob在《Screaming Architecture》中写到：

> 良好的软件架构可以推迟对框架、数据库、服务器以及其他环境问题和工具的决策。好的架构是你不必在项目的后续阶段就决定使用Mysql、Hibernate、Rails还是Spring。一个好的架构可以轻易的改变你对这些决定的想法，好的架构会强调用例，并将外围问题分离。

在应用的早期阶段，可以使用快速的内存实现。你可以使用它来完善系统的其他部分，从而使数据库决策推迟到正确的时间点。内存存储实现非常简单，快速且容易实现。

对于我们`Post`仓储，一个内存实现的hash map足够提供我们所需要的功能点：

```php
namespace Infrastructure\Persistence\InMemory;
use Domain\Model\Post;
use Domain\Model\PostId;
use Domain\Model\PostRepository;
class InMemoryPostRepository implements PostRepository
{
    private $posts = [];
    public function add(Post $aPost)
    {
        $this->posts[$aPost->id()->id()] = $aPost;
    }
    public function remove(Post $aPost)
    {
        unset($this->posts[$aPost->id()->id()]);
    }
    public function postOfId(PostId $anId)
    {
        if (isset($this->posts[$anId->id()])) {
            return $this->posts[$anId->id()];
        }
        return null;
    }
    public function latestPosts(\DateTimeImmutable $sinceADate)
    {
        return $this->filterPosts(
            function (Post $post) use($sinceADate) {
                return $post->createdAt() > $sinceADate;
            }
        );
    }
    private function filterPosts(callable $fn)
    {
        return array_values(array_filter($this->posts, $fn));
    }
    public function nextIdentity()
    {
        return new PostId();
    }
}
```

#### Doctrine ORM

我们在过去的章节中已经讨论过`Doctrine`。Doctrine是数据库存储和对象映射的类库。它默认带有Symfony框架的bundle，同时拥有其他特性，允许你很容易将你的应用与你的持久层解耦，这多亏了`Data Mapper pattern`数据映射模式。

同时，ORM位于强大的数据库抽象层智商，该层可以通过Doctrine Query Language(DQL)实现与数据库交互。这受到`Java Hibernate`框架的启发。

如果你想要使用Doctrine ORM，首要的任务是通过`composer`安装：

```php
composer require doctrine/orm
```

> （编者注：由于本书年代久远，建议关于Doctrine的部分参考其官网文档，以了解最新的使用方法）

##### 对象映射

在你的领域对象和数据库之间的映射可以被视为实现的细节。领域在生命周期中不应该知道这些持久化的细节信息。因此，映射信息应该定义为领域之外的基础设施层的一部分，并作为Repository的实现。

###### Doctrine自定义映射类型

我们的一个`Post`实体由像`Body`和`PostId`的值对象组成。如我们在值对象那一章中，一个好的办法是自定义映射类型或者使用Doctrine内嵌值。这将使得对象映射更简单：

```php
namespace Infrastructure\Persistence\Doctrine\Types;
use Doctrine\DBAL\Types\Type;
use Doctrine\DBAL\Platforms\AbstractPlatform;
use Domain\Model\Body;
class BodyType extends Type
{
    public function getSQLDeclaration(
        array $fieldDeclaration, AbstractPlatform $platform
    ) {
        return $platform->getVarcharTypeDeclarationSQL(
            $fieldDeclaration
        );
    }
    /**
    * @param string $value
    * @return Body
    */
    public function convertToPHPValue(
        $value, AbstractPlatform $platform
    ) {
        return new Body($value);
    }
    /**
    * @param Body $value
    */
    public function convertToDatabaseValue(
        $value, AbstractPlatform $platform
    ) {
        return $value->content();
    }
    public function getName()
    {
        return 'body';
    }
}
namespace Infrastructure\Persistence\Doctrine\Types;
use Doctrine\DBAL\Types\Type;
use Doctrine\DBAL\Platforms\AbstractPlatform;
use Domain\Model\PostId;
class PostIdType extends Type
{
    public function getSQLDeclaration(
        array $fieldDeclaration, AbstractPlatform $platform
    ) {
        return $platform->getGuidTypeDeclarationSQL(
        $fieldDeclaration
    );
    }
    /**
    * @param string $value
    * @return PostId
    */
    public function convertToPHPValue(
        $value, AbstractPlatform $platform
    ) {
        return new PostId($value);
    }
    /**
    * @param PostId $value
    */
    public function convertToDatabaseValue(
        $value, AbstractPlatform $platform
    ) {
        return $value->id();
    }
    public function getName()
    {
        return 'post_id';
    }
}
```
不要忘记在`PostId`值对象上实现`__toString`魔术方法，因为Doctrine要求这样：

```php
class PostId
{
    // ...
    public function __toString()
    {
    return $this->id;
    }
}
```

Doctrine提供了多种映射格式，如Yaml、Xml或者注释。XML是我们的首选，因为它提供了IDE自动提示：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<doctrine-mapping
xmlns="http://doctrine-project.org/schemas/orm/doctrine-mapping"
xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
xsi:schemaLocation="
http://doctrine-project.org/schemas/orm/doctrine-mapping
http://raw.github.com/doctrine/doctrine2/master/doctrine-mapping.xsd">
    <entity name="Domain\Model\Post" table="posts">
        <id name="id" type="post_id" column="id">
            <generator strategy="NONE" />
        </id>
        <field name="body" type="body" length="250" column="body"/>
        <field name="createdAt" type="datetime" column="created_at"/>
    </entity>
</doctrine-mapping>
```

##### Entity Manager

`Entity Manager`是ORM功能的中心访问点，启动它很容易：

```php
use Doctrine\DBAL\Types\Type;
use Doctrine\ORM\EntityManager;
use Doctrine\ORM\Tools;
Type::addType(
    'post_id',
    'Infrastructure\Persistence\Doctrine\Types\PostIdType'
);
Type::addType(
    'body',
    'Infrastructure\Persistence\Doctrine\Types\BodyType'
);
$entityManager = EntityManager::create(
    [
        'driver' => 'pdo_sqlite',
        'path'=> __DIR__ . '/db.sqlite',
    ],
    Tools\Setup::createXMLMetadataConfiguration(
        ['/Path/To/Infrastructure/Persistence/Doctrine/Mapping'],
        $devMode = true
    )
);
```

根据你的需求来进行配置！

##### DQL实现

在这个Repository的案例中，我们只需要`EntityManager`来从数据库直接获取领域对象：

```php
namespace Infrastructure\Persistence\Doctrine;
use Doctrine\ORM\EntityManager;
use Domain\Model\Post;
use Domain\Model\PostId;
use Domain\Model\PostRepository;
class DoctrinePostRepository implements PostRepository
{
    protected $em;
    public function __construct(EntityManager $em)
    {
        $this->em = $em;
    }
    public function add(Post $aPost)
    {
        $this->em->persist($aPost);
    }
    public function remove(Post $aPost)
    {
        $this->em->remove($aPost);
    }
    public function postOfId(PostId $anId)
    {
        return $this->em->find('Domain\Model\Post', $anId);
    }
    public function latestPosts(\DateTimeImmutable $sinceADate)
    {
        return $this->em->createQueryBuilder()
            ->select('p')
            ->from('Domain\Model\Post', 'p')
            ->where('p.createdAt > :since')
            ->setParameter(':since', $sinceADate)
            ->getQuery()
            ->getResult();
    }
    public function nextIdentity()
    {
        return new PostId();
    }
}
```

如果你看过其他的一些Doctrine示例，你可能会发现，在persist或者remove之后，flush会被调用。但是在我们的看来，不应该调用`flush`。刷新和处理事务被委托给了Application Service。这就是为什么你可以使用Doctrine的原因，考虑到刷新所有的改变都将在请求结束后进行，就性能而言，一次flush调用是最佳的。

#### 面向持久化的仓储

有时面向集合的Repository与我们的持久机制不太适合。如果你没有一个工作单元，那么追踪一个聚合的修改是一件难事。保存修改的唯一方法是通过显示的调用`save`。

面向持久化的仓储的接口定义与面向集合的仓储的定义的方式类似：

```php
interface PostRepository
{
    public function nextIdentity();
    public function postOfId(PostId $anId);
    public function save(Post $aPost);
    public function saveAll(array $posts);
    public function remove(Post $aPost);
    public function removeAll(array $posts);
}
```

在这例子中，我们现在有了`saveAll`方法，提供了与之前`addAll`相似的功能。但重点是客户端如何使用它是有所区别的。在面向集合的仓储中，你只有要使用`add`方法一次：当聚合被创建时。在面向持久化的仓储中，你不仅需要在创建聚合后使用一次`save`，还需要对已存在的聚合修改后再调用一次：

```php
$post = new Post(/* ... */);
$postRepository->save($post);
// later ...
$post = $postRepository->postOfId($postId);
$post->editBody(new Body('New body!'));
$postRepository->save($post);
```
除了这些差别，细节都在实现中了。

##### Redis的实现
`Redis`是一个被用于缓存或存储的内存性键值对。

根据你的情况，我们可以考虑将redis作为聚合的存储。

一开始，确保你有一个连接到Redis的PHP客户端，一个比较推荐的是`Predis`：
```php
composer require predis/predis:~1.0
namespace Infrastructure\Persistence\Redis;
use Domain\Model\Post;
use Domain\Model\PostId;
use Domain\Model\PostRepository;
use Predis\Client;
class RedisPostRepository implements PostRepository
{
    private $client;
    public function __construct(Client $client)
    {
        $this->client = $client;
    }
    public function save(Post $aPost)
    {
        $this->client->hset(
            'posts',
            (string) $aPost->id(), serialize($aPost)
        );
    }
    public function remove(Post $aPost)
    {
        $this->client->hdel('posts', (string) $aPost->id());
    }
    public function postOfId(PostId $anId)
    {
        if($data = $this->client->hget('posts', (string) $anId)) {
            return unserialize($data);
        }
        return null;
    }
    public function latestPosts(\DateTimeImmutable $sinceADate)
    {
        $latest = $this->filterPosts(
            function(Post $post) use ($sinceADate) {
              return $post->createdAt() > $sinceADate;
            }
        );
        $this->sortByCreatedAt($latest);
        return array_values($latest);
    }
    private function filterPosts(callable $fn)
    {
        return array_filter(array_map(function ($data) {
            return unserialize($data);
        },
        $this->client->hgetall('posts')), $fn);
    }
    private function sortByCreatedAt(&$posts)
    {
        usort($posts, function (Post $a, Post $b) {
            if ($a->createdAt() == $b->createdAt()) {
                return 0;
            }
            return ($a->createdAt() < $b->createdAt()) ? -1 : 1;
        });
    }
    public function nextIdentity()
    {
        return new PostId();
    }
}
```

##### SQL的实现

在一个经典案例中，我们可以通过使用原生SQL查询为我们的`PostRepository`创建一个简单的`PDO`实现：

```php
namespace Infrastructure\Persistence\Sql;
use Domain\Model\Body;
use Domain\Model\Post;
use Domain\Model\PostId;
use Domain\Model\PostRepository;
class SqlPostRepository implements PostRepository
{
    const DATE_FORMAT = 'Y-m-d H:i:s';
    private $pdo;
    public function __construct(\PDO $pdo)
    {
        $this->pdo = $pdo;
    }
    public function save(Post $aPost)
    {
        $sql ='INSERT INTO posts ' .
            '(id, body, created_at) VALUES ' .
            '(:id, :body, :created_at)';
        $this->execute($sql, [
            'id' => $aPost->id()->id(),
            'body' => $aPost->body()->content(),
            'created_at' => $aPost->createdAt()->format(
            self::DATE_FORMAT
        )
        ]);
    }
    private function execute($sql, array $parameters)
    {
        $st = $this->pdo->prepare($sql);
        $st->execute($parameters);
        return $st;
    }
    public function remove(Post $aPost)
    {
        $this->execute('DELETE FROM posts WHERE id = :id', [
            'id' => $aPost->id()->id()
        ]);
    }
    public function postOfId(PostId $anId)
    {
        $st =$this->execute('SELECT * FROM posts WHERE id = :id',[
            'id' => $anId->id()
        ]);
        if($row = $st->fetch(\PDO::FETCH_ASSOC)) {
            return $this->buildPost($row);
        }
        return null;
    }
    private function buildPost($row)
    {
        return new Post(
            new PostId($row['id']),
            new Body($row['body']),
            new \DateTimeImmutable($row['created_at'])
        );
    }
    public function latestPosts(\DateTimeImmutable $sinceADate)
    {
        return $this->retrieveAll(
            'SELECT * FROM posts WHERE created_at > :since_date', [
                'since_date' => $sinceADate->format(self::DATE_FORMAT)
            ]
        );
    }
    private function retrieveAll($sql, array $parameters = [])
    {
        $st = $this->pdo->prepare($sql);
        $st->execute($parameters);
        return array_map(function ($row) {
            return $this->buildPost($row);
        }, $st->fetchAll(\PDO::FETCH_ASSOC));
    }
    public function nextIdentity()
    {
        return new PostId();
    }
    public function size()
    {
        return $this->pdo->query('SELECT COUNT(*) FROM posts')
        ->fetchColumn();
    }
}
```

我们不需要做任何映射配置，因此在同一类中有一个初始化schema的方法非常有用。一起改变的事物应该保持在一起：

```php
class SqlPostRepository implements PostRepository
{
    // ...
    public function initSchema()
    {
        $this->pdo->exec(<<<SQL
            DROP TABLE IF EXISTS posts;
            CREATE TABLE posts (
            id CHAR(36) PRIMARY KEY,
            body VARCHAR (250) NOT NULL,
            created_at DATETIME NOT NULL
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        SQL);
    }
}
```

##### 额外的行为

```php
interface PostRepository
{
    // ...
    public function size();
}
```

实现像是这样：

```php
class DoctrinePostRepository implements PostRepository
{
    // ...
    public function size()
    {
        return $this->em->createQueryBuilder()
            ->select('count(p.id)')
            ->from('Domain\Model\Post', 'p')
            ->getQuery()
            ->getSingleScalarResult();
    }
}
```
向Repository中添加额外的行为可能非常有好处。这样的一个例子能够统计出对给定的集合中所有元素的数量。你可能会考虑增加一个名为`count`的方法，但是，当我们尝试模仿集合时，更好的名称应该是`size`：

你还可以将特定的计算、统计、读取优化查询、复杂命令（INSERT、UPDATE或者DELETE）放如Repository。但是，所有的行为仍然要遵循集合所具有的特征。我们鼓励你将尽可能多的逻辑移到特定的领域的无状态的领域服务中，而不是简单的将这些职责放在Repository中。

在某些情况下，对于一些简单少量的信息你不需要获得整个聚合。为了这样，你可以在Repository中添加作为快捷访问这些信息的方法。你应该确保只能通过遍历聚合根来访问可以获取的数据。因此，你不应该被允许访问聚合根的私有或内部区域，因为这将违反已经指定的约束规定。

对于一些用例，你可能需要由多个聚合类型组成的特定的查询，每个类型返回特定的信息。这些查询可以运行，并且作为一个值对象被返回。对于Repository来说返回值对象是很常见的。

如果你发现自己创建了许多针对用例优化过的查找方法，则可能会引入了常见的 `code smell`。这可能表明聚合边界判断有问题。但是，如果你确信边界是正确的，那么时候探索CQRS了。

查询仓储
---

通过比较，如果考虑仓储的查询能力，则它们与集合有些不同。Repository执行查询时通常处理的不是在内存中的对象。将领域对象所有实例加载到内存中并对其执行查询是不可行的。

一个好的解决方案是传入一个`criterion`，并让Repository处理实现细节以成功执行操作。它可能会将criterion转换为SQL或者ORM查询，或者遍历内存中的集合。但是这并不重要，因为实现可以处理它。

#### 规约模式

`criterion`对象的一个通用实现是规约模式（Specification pattern）。规约是一个简单的谓词，它接受领域对象并返回一个bool值。给定的一个领域对象，如果指定了规约，则将返回true，否则返回false：

```php
interface PostSpecification
{
    /**
    * @return boolean
    */
    public function specifies(Post $aPost);
}
```
我们只需要添加一个`query`方法到我们的Repository中：

```php
interface PostRepository
{
    // ...
    public function query($specification);
}
```

##### 内存实现

如果我们想要通过使用内存实现规约的方式来在我们的`PostRepository`中复制`latestPosts`，可能像这样：

```php
namespace Infrastructure\Persistence\InMemory;
use Domain\Model\Post;
interface InMemoryPostSpecification
{
    /**
    * @return boolean
    */
    public function specifies(Post $aPost);
}
```

`latestPosts`的内存实现像这样：

```php
namespace Infrastructure\Persistence\InMemory;
use Domain\Model\Post;
class InMemoryLatestPostSpecification
implements InMemoryPostSpecification
{
    private $since;
    public function __construct(\DateTimeImmutable $since)
    {
        $this->since = $since;
    }
    public function specifies(Post $aPost)
    {
        return $aPost->createdAt() > $this->since;
    }
}
```
对于我们仓储的实现的`query`方法像是这样：

```php
class InMemoryPostRepository implements PostRepository
{
    // ...
    /**
    * @param InMemoryPostSpecification $specification
    *
    * @return Post[]
    */
    public function query($specification)
    {
        return $this->filterPosts(
            function (Post $post) use($specification) {
                return $specification->specifies($post);
            }
        );
    }
}
```
从仓储中获取最新的帖子，就像创建上面的实现一样简单：

```php
$latestPosts = $postRepository->query(
    new InMemoryLatestPostSpecification(new \DateTimeImmutable('-24'))
);
```

##### SQL的实现

标准规约非常适合内存的实现。但是，由于我们没有为SQL实现预加载所有领域对象到内存中，因此我们针对这种情需要特定的规约：

```php
namespace Infrastructure\Persistence\Sql;
interface SqlPostSpecification
{
    /**
    * @return string
    */
    public function toSqlClauses();
}
```

SQL实现这个规约像这样：

```php

namespace Infrastructure\Persistence\Sql;
class SqlLatestPostSpecification implements SqlPostSpecification
{
    private $since;
    public function __construct(\DateTimeImmutable $since)
    {
        $this->since = $since;
    }
    public function toSqlClauses()
    {
        return "created_at >'" .
            $this->since->format('Y-m-d H:i:s') .
        "'";
    }
}
```
这是一个如何查询`SQLPostRepository`的实现：

```php
class SqlPostRepository implements PostRepository
{
    // ...
    /**
    * @param SqlPostSpecification $specification
    *
    * @return Post[]
    */
    public function query($specification)
    {
        return $this->retrieveAll(
            'SELECT * FROM posts WHERE ' .
            $specification->toSqlClauses()
        );
    }
    private function retrieveAll($sql, array $parameters = [])
    {
        $st = $this->pdo->prepare($sql);
        $st->execute($parameters);
        return array_map(function ($row) {
            return $this->buildPost($row);
        }, $st->fetchAll(\PDO::FETCH_ASSOC));
    }
}
```

管理事务
---

领域模型不是管理事务的地方。在领域模型上的操作应该与持久机制无关。解决此问题的常用方法是在用用层放一个Facade（外观模式），从而将相关的用例分组在一起。当从UI层调用Facade方法时，业务方法开始一个事务。完成后，Facade将通过提交事务来结束交互。如果发生任何错误，事务将回滚：

```php
class SomeApplicationServiceFacade
{
    private $em;
    public function __construct(EntityManager $em)
    {
        $this->em = $em;
    }
    public function doSomeUseCaseTask()
    {
        try {
            $this->em->getConnection()->beginTransaction();
            // Use domain model
            $this->em->getConnection()->commit();
        } catch (Exception $e) {
            $this->em->getConnection()->rollback();
            throw $e;
        }
    }
}
```
Facade产生的问题是，我们必须一遍又一遍重复相同的样板代码。如果我们统一执行用例的方法，则可以使用Decorator（修饰器模式）将它们包装在一个事务中：

```php
interface ApplicationService
{
    /**
    * @param $request
    * @return mixed
    */
    public function execute(BaseRequest $request);
    }
    
class SomeApplicationService implements ApplicationService
{
    public function execute(BaseRequest $request)
    {
        // do something
    }
}
```
我们不想将我们的应用层与具体的事务过程耦合在一起，因此我们可以为其创建一个简单的接口：

```php
interface TransactionalSession
{
    /**
    * @param callable $operation
    * @return mixed
    */
    public function executeAtomically(callable $operation);
}
```

修饰器模式的实现可以使得任意应用服务的事务变得如此容易：

```php
class TransactionalApplicationService implements ApplicationService
{
    private $session;
    private $service;
    public function __construct(
        ApplicationService $service,
        TransactionalSession $session
    ) {
        $this->session = $session;
        $this->service = $service;
    }
    public function execute(BaseRequest $request)
    {
        $operation = function() use($request) {
            return $this->service->execute($request);
        };
        return $this->session->executeAtomically(
            $operation->bindTo($this)
        );
    }
}
```

然后，我们可以选择创建一个Doctrine事务会话的实现：

```php
class DoctrineSession implements TransactionalSession
{
    private $entityManager;
    public function __construct(EntityManager $entityManager)
    {
        $this->entityManager = $entityManager;
    }
    public function executeAtomically(callable $operation)
    {
        return $this->entityManager->transactional($operation);
    }
}
```

现在我们在一个事务中执行我们的用例了：

```php
$useCase = new TransactionalApplicationService(
    new SomeApplicationService(
        // ...
    ),
    new DoctrineSession(
        // ...
    )
);
$response = $useCase->execute();
```

测试仓储
---

为了确保仓储可以在生产环境中运行，我们需要测试它的实现。为此，我们必须测试系统边界，以确保我们的期望是正确的。

对于Doctrine测试，配置将更加复杂：

```php
use Doctrine\DBAL\Types\Type;
use Doctrine\ORM\EntityManager;
use Doctrine\ORM\Tools;
use Domain\Model\Post;
class DoctrinePostRepositoryTest extends \PHPUnit_Framework_TestCase
{
    private $postRepository;
    public function setUp()
    {
        $this->postRepository = $this->createPostRepository();
    }
    private function createPostRepository()
    {
        $this->addCustomTypes();
        $em = $this->initEntityManager();
        $this->initSchema($em);
        return new PrecociousDoctrinePostRepository($em);
    }
    private function addCustomTypes()
    {
        if (!Type::hasType('post_id')) {
            Type::addType(
                'post_id',
                'Infrastructure\Persistence\Doctrine\Types\PostIdType'
            );
        }
        if (!Type::hasType('body')) {
            Type::addType(
                'body',
                'Infrastructure\Persistence\Doctrine\Types\BodyType'
            );
        }
    }
    protected function initEntityManager()
    {
        return EntityManager::create(
            ['url' => 'sqlite:///:memory:'],
            Tools\Setup::createXMLMetadataConfiguration(
                ['/Path/To/Infrastructure/Persistence/Doctrine/Mapping'],
                $devMode = true
            )
        );
    }
    private function initSchema(EntityManager $em)
    {
        $tool = new Tools\SchemaTool($em);
        $tool->createSchema([
            $em->getClassMetadata('Domain\Model\Post')
        ]);
    }
    // ...
}
class PrecociousDoctrinePostRepository extends DoctrinePostRepository
{
    public function persist(Post $aPost)
    {
        parent::persist($aPost);
        $this->em->flush();
    }
    public function remove(Post $aPost)
    {
        parent::remove($aPost);
        $this->em->flush();
    }
}
```
一旦我们设置好了环境和配置，我们就可以测试Repository的行为了：

```php
class DoctrinePostRepositoryTest extends \PHPUnit_Framework_TestCase
{
    // ...
    /**
    * @test
    */
    public function itShouldRemovePost()
    {
        $post = $this->persistPost('irrelevant body');
        $this->postRepository->remove($post);
        $this->assertPostExist($post->id());
    }
    private function assertPostExist($id)
    {
        $result = $this->postRepository->postOfId($id);
        $this->assertNull($result);
    }
    private function persistPost(
        $body,
        \DateTimeImmutable $createdAt = null
    ) {
        $this->postRepository->add(
            $post = new Post(
                $this->postRepository->nextIdentity(),
                new Body($body),
                $createdAt
            )
        );
    return $post;
    }
}
```
按照我们先前设置的断言，如果我们保存一个`Post`，我们希望它是处于一个特定的状态。

现在我们可以通过给定的日期来查询最新的帖子了：

```php
class DoctrinePostRepositoryTest extends \PHPUnit_Framework_TestCase
{
    // ...
    /**
    * @test
    */
    public function itShouldFetchLatestPosts()
    {
        $this->persistPost(
            'a year ago', new \DateTimeImmutable('-1 year')
        );
        $this->persistPost(
            'a month ago', new \DateTimeImmutable('-1 month')
        );
        $this->persistPost(
            'few hours ago', new \DateTimeImmutable('-3 hours')
        );
        $this->persistPost(
            'few minutes ago', new \DateTimeImmutable('-2 minutes')
        );
        $posts = $this->postRepository->latestPosts(
            new \DateTimeImmutable('-24 hours')
        );
        $this->assertCount(2, $posts);
        $this->assertEquals(
            'few hours ago', $posts[0]->body()->content()
        );
        $this->assertEquals(
            'few minutes ago', $posts[1]->body()->content()
        );
    }
}
```

使用内存实现测试你的服务
---

配置一个完整的持久化Reposiotry可能会很复杂，并且导致执行缓慢。你应该关注一下如何快速测试。现在完成整个数据库的配置，然后查询将极大的降低你的速度。在内存中的实现可能有助于你将持久化决策推迟到最后，我们可以像以前一样进行测试。但是这次，我们将使用功能齐全的快速简单内存实现：

```php
class MyServiceTest extends \PHPUnit_Framework_TestCase
{
    private $service;
    public function setUp()
    {
        $this->service = new MyService(
            new InMemoryPostRepository()
        );
    }
}
```

总结
---

一个Repository是一种充当存储位置的机制。DAO和Repository之间的区别在于，DAO遵循数据库优先的方式，使用许多底层方法来降低查询数据库的内聚性。根据底层持久化机制，我们已经看到了不同的Repository方法了：

- 面向集合的Repository：倾向于使用领域模型。从客户端的角度来看，面向集合的Repository就像是一个collection(Set)。不需要对实体修改时进行显示的持久性方法调用，因为Repository可以跟踪对象上的内容修改。我们探索了如何使用Doctrine作为面向集合的Repository的持久机制。

- 面向持久化的Repository：需要一个显示的持久化方法调用，因为它们不会追踪对象的变化。我们探索了Redis和原生SQL的实现。

在此过程中，我们发现规约模式（Specifications）可以帮助我们在补习生灵活性和内聚性的情况下查询数据库。我们还研究了如何通过简单、快速的内存实现的Repository来管理事务以及如何测试我们的服务。