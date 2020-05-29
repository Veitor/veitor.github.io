---
title: '[译]工厂 - 《Domain-Driven Design in PHP》第9章'
tags:
  - ddd
  - 领域驱动设计
categories:
  - PHP
date: 2020-05-27 08:28:58
---

> 本篇博文由本博客(`http://www.veitor.net`)经原文翻译，转载请注明出处。

工厂是一个强有力的抽象。它们帮助客户端从如何与领域交互的细节中解耦出来。客户端不需要知道如何去构建一个复杂的对象和聚合，所以你可以使用工厂来创建整个聚合，从而让其具有不变性。

<!-- more -->

聚合根上的工厂方法
===

工厂方法模式是一个经典的模式：

定义一个创建对象的接口，但将其类型的选择权留给了子类，在运行时创建对象。

在聚合根中添加工厂方法会隐藏任何从外部客户端创建聚合的内部实现细节。这也将负责聚合完整性的职责挪到了聚合根里。

在有一个`User`实体和`Wish`实体的领域模型中，`User`扮演者聚合根的角色，没有`User`就没有`Wish`。`User`实体应当管理它的聚合。

将`Wish`的控制权移到`User`实体中的方法是将工厂方法放在聚合根里：

```php
class User
{
    // ...
    public function makeWish(WishId $wishId, $email, $content)
    {
        $wish = new WishEmail(
            $wishId,
            $this->id(),
            $email,
            $content
        );
        DomainEventPublisher::instance()->publish(
            new WishMade($wishId)
        );
        return $wish;
    }
}
```

客户端不需要知道聚合根内部是如何处理创建逻辑的：

```php
$wish = $aUser->makeWish(
    $wishRepository->nextIdentity(),
    'user@example.com',
    'I want to be free!'
);
```

强制不变性
===

聚合根内的工厂方法也是一个放置不变性的好地方。

在有`Forum`和`Post`实体的领域模型中，`Post`是聚合根`Forum`的一部分，发布一个`Post`看起来是这样的：

```php
class Forum
{
    // ...
    public function publishPost(PostId $postId, $content)
    {
        $post = new Post($this->id, $postId, $content);
        DomainEventPublisher::instance()->publish(
            new PostPublished($postId)
        );
        return $post;
    }
}
```

在于领域专家讨论过后，我们得到一个结论就是当`Forum`关闭时，不能发布`Post`，这是一个不变性，我们应该直接在创建`Post`时来强制执行：

```php
class Forum
{
    // ...
    public function publishPost(PostId $postId, $content)
    {
        if ($this->isClosed()) {
            throw new ForumClosedException();
        }
        $post = new Post($this->id, $postId, $content);
        DomainEventPublisher::instance()->publish(
            new PostPublished($postId)
        );
        return $post;
    }
}
```

服务上的工厂
===
在服务中也可以解耦创建对象的逻辑。

## 构建规约

在我们服务中使用规约(Specifications)来展示如何在服务中使用工厂是一个好的例子。

看个例子，从外部世界的一个请求，我们想要基于添加到系统中最新的`Posts`来构建一个feed：

```php
namespace Application\Service;
use Domain\Model\Post;
use Domain\Model\PostRepository;
class LatestPostsFeedService
{
    private $postRepository;
    public function __construct(PostRepository $postRepository)
    {
        $this->postRepository = $postRepository;
    }
    /**
    * @param LatestPostsFeedRequest $request
    */
    public function execute($request)
    {
        $posts = $this->postRepository->latestPosts($request->since);
        return array_map(function(Post $post) {
            return [
                'id' => $post->id()->id(),
                'content' => $post->body()->content(),
                'created_at' => $post-> createdAt()
            ];
        }, $posts);
    }
}
```
Repository中的查找方法`latestPosts`有一些限制，因为它们会无线增加Repository复杂性。如我们在第10章中讨论的，使用规约(Specifications)是更好的方法。

幸运的是，我们有一个不错的`query`方法在`PostRepository`中，该仓储库使用了规约模式并运行良好：

```php
class LatestPostsFeedService
{
    // ...
    public function execute($request)
    {
        $posts = $this->postRepository->query($specification);
    }
}
```

对于规约模式，使用一个具体的实现是一个糟糕的主意：

```php
class LatestPostsFeedService
{
    public function execute($request)
    {
        $posts = $this->postRepository->query(
            new SqlLatestPostSpecification($request->since)
        );
    }
}
```

将高层的应用服务与低层的规约模式耦合在一起，这会将多层混合并破坏了关注点的分离。此外，这将是我们的服务与具体基础设施实现耦合的最坏的方法。你使用这个Service时将无法使用除了SQL之外的实现方案，如果我们想通过内存实现方案来测试我们的Service怎么办？

解决此问题的方法是使用抽象工厂模式将规约创建与service本身解耦，根据OODesign.com：

> 抽象工厂提供了创建一些相关对象的接口，而无需指定它们的类。

因为我们可能会有多种规约模式的实现，所以我们先需要用工厂创建一个接口：

```php
namespace Domain\Model;
interface PostSpecificationFactory
{
    public function createLatestPosts(DateTimeImmutable $since);
}
```

然后我们需要为每个`PostRepository`实现创建一个工厂。一个内存实现的`PostRepository`的例子是这样的：

```php
namespace Infrastructure\Persistence\InMemory;
use Domain\Model\PostSpecificationFactory;
class InMemoryPostSpecificationFactory
implements PostSpecificationFactory
{
    public function createLatestPosts(DateTimeImmutable $since)
    {
        return new InMemoryLatestPostSpecification($since);
    }
}
```

一旦我们把创建逻辑集中在这一个地方，那就很容易让这个业务逻辑与服务进行解耦：

```php
class LatestPostsFeedService
{
    private $postRepository;
    private $postSpecificationFactory;
    
    public function __construct(
        PostRepository $postRepository,
        PostSpecificationFactory $postSpecificationFactory
    ) {
            $this->postRepository = $postRepository;
        $this->postSpecificationFactory = $postSpecificationFactory;
    }
    public function execute($request)
    {
        $posts = $this->postRepository->query(
            $this->postSpecificationFactory->createLatestPosts(
                $request->since
            )
        );
    }
}
```

现在，测试通过内存实现的`PostRepository`是如此的简单：

```php
namespace Application\Service;
use Domain\Model\Body;
use Domain\Model\Post;
use Domain\Model\PostId;
use Infrastructure\Persistence\InMemory\InMemoryPostRepositor;
class LatestPostsFeedServiceTest extends PHPUnit_Framework_TestCase
{
    /**
    * @var \Infrastructure\Persistence\InMemory\InMemoryPostRepository
    */
    private $postRepository;
    /**
    * @var LatestPostsFeedService
    */
    private $latestPostsFeedService;
    public function setUp()
    {
        $this->latestPostsFeedService = new LatestPostsFeedService(
            $this->postRepository = new InMemoryPostRepository()
        );
    }
    /**
    * @test
    */
    public function shouldBuildAFeedFromLatestPosts()
    {
        $this->addPost(1, 'first', '-2 hours');
        $this->addPost(2, 'second', '-3 hours');
        $this->addPost(3, 'third', '-5 hours');
        $feed = $this->latestPostsFeedService->execute(
            new LatestPostsFeedRequest(
                new \DateTimeImmutable('-4 hours')
            )
        );
        $this->assertFeedContains([
            ['id' => 1, 'content' => 'first'],
            ['id' => 2, 'content' => 'second']
        ], $feed);
    }
    private function addPost($id, $content, $createdAt)
    {
        $this->postRepository->add(new Post(
            new PostId($id),
            new Body($content),
            new \DateTimeImmutable($createdAt)
        ));
    }
    private function assertFeedContains($expected, $feed)
    {
        foreach ($expected as $index => $contents) {
            $this->assertArraySubset($contents, $feed[$index]);
            $this->assertNotNull($feed[$index]['created_at']);
        }
    }
}
```

## 构建聚合

实体与持久机制无关。你不要将你的持久化细节与你的实体进行耦合并污染你的实体。看一下这个Application Service：

```php
class SignUpUserService
{
    private $userRepository;
    public function __construct(UserRepository $userRepository)
    {
        $this->userRepository = $userRepository;
    }
    /**
    * @param SignUpUserRequest $request
    */
    public function execute( $request)
    {
        $email = $request->email();
        $password = $request->password();
        $user = $this->userRepository->userOfEmail($email);
        if (null !== $user) {
            throw new UserAlreadyExistsException();
        }
        $this->userRepository->persist(new User(
            $this->userRepository->nextIdentity(),
            $email,
            $password
        ));
        return $user;
    }
}
```
想象一下`User`实体是这样的：

```php
class User
{
    private $userId;
    private $email;
    private $password;
    public function __construct(UserId $userId, $email, $password)
    {
        // ...
    }
    // ...
}
```

再想象一下，我们使用Doctrine作为我们基础设施的持久性机制，Doctrine要求id作为纯字符串变量才能正常工作。在我们的实体中，`$userId`是一个`UserId`值对象。因为Doctrine，增加一个额外的`id`到我们的`User`实体中会将我们的持久化机制与我们的领域模型耦合。我们在第4章中（实体）看到，通过在基础设施层中把`User`实体封装一下，使用代理Id（Surrogate ID）就能解决这问题：

```php
class DoctrineUser extends User
{
    private $surrogateUserId;
    public function __construct(UserId $userId, $email, $password)
    {
        parent:: __construct($userId, $email, $password);
        $this->surrogateUserId = $userId->id();
    }
}
```

由于在我们的应用服务中创建`DoctrineUser`将会使持久层与我们的领域再次耦合，我们需要使用抽象工厂来将创建逻辑与服务进行解耦。

我们可能在我们领域中这样创建接口：

```php
interface UserFactory
{
    public function build(UserId $userId, $email, $password);
}
```

然后，我们在基础设施层来实现这个接口：

```php
class DoctrineUserFactory implements UserFactory
{
    public function build(UserId $userId, $email, $password)
    {
        return new DoctrineUser($userId, $email, $password);
    }
}
```

一旦解耦，我们只需要在应用服务中注入工厂即可：

```php
class SignUpUserService
{
    private $userRepository;
    private $userFactory;
    public function __construct(
        UserRepository $userRepository,
        UserFactory $userFactory
    ) {
        $this->userRepository = $userRepository;
        $this->userFactory = $userFactory;
    }
    /**
    * @param SignUpUserRequest $request
    */
    public function execute($request)
    {
        // ...
        $user = $this->userFactory->build(
            $this->userRepository->nextIdentity(),
            $email,
            $password
        );
        $this->userRepository->persist($user);
        return $user;
    }
}
```

测试工厂
===
当你编写测试时，你会看到一个常用的模式。这是因为构建实体和复杂的聚合可能是一个非常繁琐且重复的过程。复杂性、重复性不可避免的出现在了你的测试中。看下面的这个实体：

```php
class Author
{
    private $username;
    private $email ;
    private $fullName;
    public function __construct(
        Username $aUsername,
        FullName $aFullName,
    Email $anEmail
    ) {
        $this->username = $aUsername;
        $this->email = $anEmail ;
        $this->fullName = $aFullName;
    }
    // ...
}
```
在你系统的某个地方，你将写出这样的一个测试：

```php
class MyTest extends PHPUnit_Framework_TestCase
{
    /**
    * @test
    */
    public function itDoesSomething()
    {
        $author = new Author(
            new Username('johndoe'),
            new FullName('John', 'Doe' ),
            new Email('john@doe.com' )
        );
        //do something with author
    }
}
```
限界上下文内的服务共享者如实体、聚合、值对象这样的概念。想象一下在整个测试中一遍又一遍重复相同的构建逻辑的混乱情况。从测试中提取构建构建的逻辑非常方便并且能够防止重复编写。

## Object Mother

`Object Mother`是工厂的容易被记住的名字，它为测试创建`fixed fixture`。与前面的示例类似，我们可以将重复的逻辑提取到`Object Mother`，以便在测试之间重复使用：

```php
class AuthorObjectMother
{
    public static function createOne()
    {
        return new Author(
            new Username('johndoe'),
            new FullName('John', 'Doe'),
            new Email('john@doe.com )
        );
    }
}

class MyTest extends PHPUnit_Framework_TestCase
{
    /**
    * @test
    */
    public function itDoesSomething()
    {
        $author = AuthorObjectMother::createOne();
    }
}
```

你会注意到你拥有的测试和用例越多，工厂所拥有的方法就越多。

由于`Object Mother`并不是太灵活，因此它们的复杂性往往会迅速增长。所幸的是你还有更灵活的测试该方法。

## Test Data Builder

Test Data Builder只是一个普通的构建器，其默认值专用于你的测试，因此你不必在特定的测试用例上指定不相关的参数：

```php
class AuthorBuilder
{
    private $username;
    private $email ;
    private $fullName;
    private function __construct()
    {
        $this->username = new Username('johndoe');
        $this->email = new Email('john@doe.com');
        $this->fullName = new FullName('John', 'Doe');
    }
    public static function anAuthor()
    {
        return new self();
    }
    public function withFullName(FullName $aFullName)
    {
        $this->fullName = $aFullName;
        return $this;
    }
    public function withUsername(Username $aUsername)
    {
        $this->username = $aUsername;
        return $this;
    }
    public function withEmail(Email $anEmail)
    {
        $this->email = $anEmail ;
        return $this;
    }
    public function build()
    {
        return new Author($this->username, $this->fullName, $this->email);
    }
}
class MyTest extends PHPUnit_Framework_TestCase
{
    /**
    * @test
    */
    public function itDoesSomething()
    {
        $author = AuthorBuilder::anAuthor()
        ->withEmail(new Email('other@email.com'))
        ->build();
    }
}
```

我们甚至可以结合使用Test Data Builder来构建更复杂的聚合，例如`Post`：

```php
class Post
{
    private $id;
    private $author;
    private $body;
    private $createdAt;
    public function __construct(
        PostId $anId, Author $anAuthor, Body $aBody
    ) {
        $this->id = $anId;
        $this->author = $anAuthor;
        $this->body = $aBody;
        $this->createdAt = new DateTimeImmutable();
    }
}
```

让我们看`Post`对应的Test Data Builder。对于默认的`Author`，我们可以重用`AuthorBuilder`来进行构建：

```php
class PostBuilder
{
    private $postId;
    private $author;
    private $body;
    private function __construct()
    {
        $this->postId = new PostId();
        $this->author = AuthorBuilder::anAuthor()->build();
        $this->body = new Body('Post body');
    }
    public static function aPost()
    {
        return new self();
    }
    public function withAuthor(Author $anAuthor)
    {
        $this->author = $anAuthor;
        return $this;
    }
    public function withPostId(PostId $aPostId)
    {
        $this->postId = $aPostId;
        return $this;
    }
    public function withBody(Body $body)
    {
        $this->body = $body;
        return $this;
    }
    public function build()
    {
        return new Post($this->postId, $this->author, $this->body);
    }
}
```

这样的解决方案可以足够灵活的来覆盖到各种测试用例，包括构建内部实体的可能性：

```php
class MyTest extends PHPUnit_Framework_TestCase
{
    /**
    * @test
    */
    public function itDoesSomething()
    {
        $post = PostBuilder::aPost()
            ->withAuthor(AuthorBuilder::anAuthor()
            ->withUsername(new Username('other'))
            ->build())
            ->withBody(new Body('Another body'))
            ->build();
        //do something with the post
    }
}
```

总结
===

工厂是将构建逻辑与业务逻辑解耦的强大工具。工厂方法模式不仅有助于将创建职责移到聚合根中，而且还可以使其具有不变性。在我们的服务中使用抽象工厂模式可以使我们将领域逻辑与基础设施创建的细节分离，一个常见的用例就是规约模式和其各自持久机制的实现。我们也看到工厂模式也在我们的测试中派上用场，尽管我们可以将构建逻辑提取到Object Mother工厂中，但是Test Data Builder更强大灵活。