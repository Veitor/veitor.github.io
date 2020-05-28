---
title: '[译]应用 - 《Domain-Driven Design in PHP》第11章'
tags:
  - ddd
  - 领域驱动设计
categories:
  - PHP
date: 2020-05-28 08:19:43
---

> 本篇博文由本博客(`http://www.veitor.net`)经原文翻译，转载请注明出处。

应用层是将领域模型与查询或修改其状态的客户端分离的地方。Application Service是这一层的构建块。正如Vaughn Vernon所说：“Application Service是领域模型的直接客户端”。你可以将Application Service看作为外部世界（HTML表单、API客户端、命令行、框架、UI等）与领域模型之间的联系点。思考一下你系统中向人们展示的最上层的use cases，这会对你有所帮助，例如：“以游客身份进行注册”、“以登陆者的身份购买产品”等等。

<!-- more -->

在这一章，我们将会探索如何实现Application Service，理解Command pattern的作用以及确定Application Service的职责。为此，让我们思考一下`注册新用户`的用例。

为了注册新用户，我们需要：

- 从客户端得到email和password
- 检查email是否已经存在
- 创建新用户
- 把这个新用户加到现有的用户集合中
- 返回我们刚创建的新用户

请求
---

我们需要把`email`和`password`发给Application Service。这有许多种方式可以从客户端（HTML表单、API客户端甚至命令行）执行此操作。我们可以通过方法形参来发送参数（eamil和password），或者发送一个构建的带有email和password的数据结构。后一种方法（发送DTO）带来了一些有趣的功能。通过发送对象，可以在Command Bus上对其进行序列化和投入队列。

> Data Transfer Object（数据传输对象）
>
> DTO是一种在流程之间传送信息的数据结构。不要误认为它是一个功能齐全的对象。DTO除了存储和检索自己数据外，没有任何行为。DTO是一个简单对象，不应包含任何需要测试的业务逻辑。

Vaughn Vernon说：

> Application Service方法形参只使用基本类型（int，string等），并可能使用DTO。但是，作为这些方式的代替，更好的方式可能是设计一个Command对象。这不一定是对或错的，根据你的习惯和目标来决定。

对于Application Service的持有必要数据的DTO的实现像是这样的：

```php
namespace Lw\Application\Service\User;
class SignUpUserRequest
{
    private $email;
    private $password;
    public function __construct($email, $password)
    {
        $this->email = $email;
        $this->password = $password;
    }
    public function email()
    {
        return $this->email;
    }
    public function password()
    {
        return $this->password;
    }
}
```

如你所见，`SignUpUserRequest`没有任何行为，只有数据。这些数据可能来自HTML表单或API，反正我们不关心。

#### 构建一个Application Service请求

通过你最喜欢的框架创建请求应该非常简单。你可以从控制器请求中获取参数，并放在DTO中将其传递给下游Service。对于CLI同样适用：读取输入参数，并发送到下游。

使用Symfony，我们可以从`HttpFoundation`组件中的Request对象里提取我们所需要的数据：

```php
// ...
class UsersController extends Controller
{
    /**
    * @Route('/signup', name = 'signup')
    * @param Request $request
    * @return Response
    */
    public function signUpAction(Request $request)
    {
        // ...
        $signUpUserRequest = new SignUpUserRequest(
        $request->get('email'),
        $request->get('password')
        );
        // ...
    }
// ...
```

在使用`Form`组件来获取和验证参数的`Silex`应用中（译者注：`Silex`框架已经不被维护了，读者只需要稍微了解即可，主要还是使用Symfony就行）：

```php
// ...
$app->match('/signup', function (Request $request) use ($app) {
    $form = $app['sign_up_form'];
    $form->handleRequest($request);
    if ($form->isValid()) {
        $data = $form->getData();
        try {
        $app['sign_in_user_application_service']->execute(
        new SignUpUserRequest(
        $data['email'],
        $data['password']
        )
        );
        return $app->redirect(
        $app['url_generator']->generate('login')
        );
    } catch (UserAlreadyExistsException $e) {
        $form
        ->get('email')
        ->addError(
            new FormError(
                'Email is already registered by another user'
            )
        );
    } catch (Exception $e) {
        $form
        ->addError(
            new FormError(
                'There was an error, please get in touch with us'
            )
        );
        }
    }
    return $app['twig']->render('signup.html.twig', [
        'form' => $form->createView(),
    ]);
});
```

#### 请求设计

当我们设计你的请求对象的时候，你应该总是遵循这些原则：使用基本类型，进行序列化设计，不要包含业务逻辑。这样，你能够省去单元测试的成本。

##### 使用基本类型

我们建议使用基本类型来构建你的请求对象，这意味着字符串、整数、布尔值等。我们只是抽象出输入参数，你应该能够独立于分发机制使用Application Service。即使非常复杂的HTML表单，也是种可以在控制器级别转换为基本类型。你不要想去将你的框架和业务逻辑混合在一起。

在某些情况下，很容易直接使用值对象，但请不要这么做。值对象定义的修改将会影响到所有客户端，并且你的客户端将于业务逻辑混合在一起。

##### 序列化

使用基本类型的一个副作用是，任何请求对象都可以轻松的被序列化为字符串，存储在消息队列或者数据库中。

##### 没有业务逻辑

避免将业务逻辑，甚至验证放在你的请求对象中。验证应该放在你的领域中的实体、值对象、或领域服务里等。验证是强制保证业务不变性和领域约束的方式。

##### 没有测试

应用请求是一个数据结构，不是对象。使用单元测试这样的数据结构就相当于测试其getter和setter这样的方法，而没有行为能够用于测试。因此尝试对请求对象和DTO进行单元测试没有太大价值。这些结构将在更复杂的测试（如集成测试或验收测试）中被覆盖。

Command是请求对象的代替方法。我们可以设计一个具有多个Application方法，每个方法都带有你放入请求中的参数。对于简单的应用程序来说是可以的，但是在下面的文章中我们会有所担心。

Application Service剖析
---

一旦我们在请求中封装了数据，就开始业务逻辑了。如Vaughn Vernon所说：保持Application Service精简，使用它们只是协调模型上的任务。

首先要做的是从请求中提取必要的信息，即`email`和`password`。在更层次上，我们需要检查是否有特定email的用户存在。如果没有，那么我们创建用户并将其添加到`UserRepository`中。在使用相同email来查找用户的情况下，我们会抛出一个异常，以便客户端可以用自己的方式处理它，如展示出错误、重试、或者忽略异常：

```php
namespace Lw\Application\Service\User;
use Ddd\Application\Service\ApplicationService;
use Lw\Domain\Model\User\User;
use Lw\Domain\Model\User\UserAlreadyExistsException;
use Lw\Domain\Model\User\UserRepository;
class SignUpUserService
{
    private $userRepository;
    public function __construct(UserRepository $userRepository)
    {
        $this->userRepository = $userRepository;
    }
    public function execute(SignUpUserRequest $request)
    {
        $email = $request->email();
        $password = $request->password();
        $user = $this->userRepository->ofEmail($email);
        if ($user) {
            throw new UserAlreadyExistsException();
        }
        $this->userRepository->add(
            new User(
                $this->userRepository->nextIdentity(),
                $email ,
                $password
            )
        );
    }
}
```
如果你想知道`UserRepository`在构造函数中正在做什么，我们接下来给你介绍。

> 处理异常
> 
> 由Application Service抛出的异常是一种传达异常情况并且传向客户端的方式。这一层的异常与业务逻辑（如找不到用户）有关，与实现细节无关（如PDOException，PRedisException后者DoctrineException）。

#### 依赖反转

处理用户不是Service的职责，正如我们在第10章Repository中看到，有一个专门的类处理User集合：`UserRepository`。这是从Application Service对Repository的依赖。我们不想将Application Service与Repository的具体实现耦合在一起，因为那样会将我们的Service与基础设施细节耦合在一起，因此我们依赖具体实现所实现的interface。

在运行时构建和传入的`UserRepository`的具体实现，如`DoctrineUserRepository`（使用Doctrine的实现）。在测试时传入特定实现也将起作用，如`NotAvailableUserRepository`可以是一个特性的实现，每次执行操作时都会抛出异常。这样，我们可以测试所有的Application Service行为。包括`sad path`（即使哪里出错了，程序也需要正确执行下去）

Application Service可能也会依赖于Domain Service（如`GetBadgesByUser`）。在运行时，这样的服务的实现可能会非常复杂，想象一下一个通过HTTP协议与一个限界上下文集成的`HttpGetBadgesByUser`。

根据抽象的不同，我们将使得底层基础设施的实现被修改时，而不会影响到Application Service。

#### 实例化Application Service

仅仅实例化你的Application Service非常容易，但是根据依赖关系的构建复杂程度，构建依赖关系可能很棘手。因此，大多数框架都带有依赖注入容器。如果没有，你最终的控制器可能会像这样：

```php
$redisClient = new Predis\Client([
'scheme' => 'tcp',
'host' => '10.0.0.1',
'port' => 6379
]);

$userRepository = new RedisUserRepository($redisClient);
$signUp = new SignUpUserService($userRepository);
$signUp->execute(new SignUpUserRequest(
    'user@example.com',
    'password'
));
```
我们决定对`UserRepository`使用`Redis`实现。在前面的代码中，我们构建了创建一个内部使用Redis的Repository所需的所有依赖。这些依赖项包括：`Predis`客户端，以及所有连接到我们redis服务器的参数。这不仅效率低下，并且在控制器之间可能会重复编写。

你可以把构建逻辑改为工厂方法，也可以使用依赖注入容器（现在大多数框架都有）。

> 使用依赖注入容器不好吗？
>
> 一点也不。依赖注入容器只是一种工具。它们通过把构建依赖项的复杂性进行抽象化来为我们提供帮助。它们对于构建基础设施对象非常有用。Symfony提供了一个完整的方案。

> 考虑一下这个事实：将容器作为一个整体传入Service中是不好的做法。这就像将Application Service的整个上下文与领域耦合在一起。如果Service需要特定的对象，请从你的框架层面来构建它们，并将它们作为依赖项传递给Service，但不要让Service知道整个上下文。

让我们看一下在`Silex`中如何构建依赖项：

```php
$app = new \Silex\Application();
$app['redis_parameters'] = [
    'scheme' => 'tcp',
    'host' => '127.0.0.1',
    'port' => 6379
];
$app['redis'] = $app->share(function ($app) {
    return new Predis\Client($app['redis_parameters']);
});
$app['user_repository'] = $app->share(function($app) {
    return new RedisUserRepository(
        $app['redis']
    );
});
$app['sign_up_user_application_service'] = $app->share(function($app) {
    return new SignUpUserService(
        $app['user_repository']
    );
});
// ...
$app->match('/signup' ,function (Request $request) use ($app) {
    // ...
    $app['sign_up_user_application_service']->execute(
        new SignUpUserRequest(
            $request->get('email'),
            $request->get('password')
        )
    );
    // ...
});
```

如你缩减，`$app`作为服务容器。我们注册了所有的组件及其依赖项。`sign_up_user_application_service`取决于上面的定义。修改`user_repository`的实现就像返回其他内容（Mysql，MongoDB等）一样容易，所以我们根本不需要修改Service代码。

在Symfony中像这样：

```xml
<?xml version=" 1.0" ?>
<container xmlns="http://symfony.com/schema/dic/services"
xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
xsi:schemaLocation="
http://symfony.com/schema/dic/services
http://symfony.com/schema/dic/services/services-1.0.xsd">
    <services>
        <service
        id="sign_up_user_application_service"
        class="SignUpUserService">
            <argument type="service" id="user_repository" />
        </service>
        <service
        id="user_repository"
        class="RedisUserRepository">
            <argument type="service">
                <service class="Predis\Client" />
            </argument>
        </service>
    </services>
</container>
```

现在已经在Symfony服务容器中定义了Application Service所需要的依赖，则获取它们非常容易。所有分发机制（Web控制器、Rest控制器、甚至命令行）共享相同的依赖定义。在实现`ContainerAware`接口的类上都可以使用该服务，获取服务就像调用`$this->get('sign_up_user_application_service')`一样简单。

总而言之，你如何构建服务（adhoc点对点、使用容器服务、使用工厂等）并不重要。但是，请务必将你的Application Service配置放在基础设施边界之外。

##### 定制一个Application Service

定制你的Application Service的主要方式是通过选择你传入的依赖项。根据你服务容器的能力，这可能会有些棘手。因此你还可以添加一个setter方法来动态更改依赖项。例如，你可能需要改变一个输出依赖项，以便可以设置默认依赖关系，然后再修改它。如果逻辑变得太复杂，则可以创建一个Application Service工厂来处理你这种情况。


执行
---

这有两种方式来调用Application Service：每个用例具有一个单独的执行方法的类；在一个类中有多个用例。

#### 一个Application Service一个类

这是我们首选的方式，并可能适合所有场景：

```php
class SignUpUserService
{
    // ...
    public function execute(SignUpUserRequest $request)
    {
        // ...
    }
}
```

一个Application Service使用专门的一个类可以使代码对外部的修改更为健壮（单一职责原则）。修改这个类的理由很少，因为Service只做这一件事。Application Service所做的事情越少，则越容易被测试。实现一个通用的Application Service约定会使这个类修饰更加容易（参阅第10章 Repository的小节）。由于所有依赖项都专门针对单个用例，因此这也将导致更高的内聚性。

`execution`方法可以具有一个更具有表达性的名字，如`signUp`。但是，使用`Command Patter`（命令模式）在Application Service之间标准化了共同的约定，从而使得修饰简单，这对事务很方便。

#### 多个Application Service一个类

有时，将紧密关系的Appication Service放一个类下归到一组可能是个好主意：

```php
class UserService
{
    // ...
    public function signUp(SignUpUserRequest $request)
    {
        // ...
    }
    public function signIn(SignUpUserRequest $request)
    {
        // ...
    }
    public function logOut(LogOutUserRequest $request)
    {
        // ...
    }
}
```
我们不推荐使用这方式，因为并不是所有的Application Service具有100%的紧密关系。一些Application Service需要不同的依赖，最终你将得到一个依赖了它们所不需要的依赖的Application Service。另一个问题是这个类成长很快，因为它违反了“单一职责原则”，因此会有多种原因被修改，甚至可能破坏这个类。

返回值
---

在注册之后，我们可能考虑将用户跳转到资料页。返回必要信息给控制器的自然的方式是直接从`Service`将`User`实体返回：

```php
class SignUpUserService
{
    // ...
    public function execute(SignUpUserRequest $request)
    {
        $user = new User(
            $this->userRepository->nextIdentity(),
            $email,
            $password
        );
        $this->userRepository->add($user);
        return $user;
    }
}
```
然后，我们在控制其中获取`id`并跳转到其他地方。但是，请三思而后行！我们想控制器返回了功能齐全的实体，这将允许分发机制绕过应用层直接与领域进行交互。

想象一下提供了`updateEmailAddress`方法的`User`实体。在未来的某个时候，可能会有人考虑使用这个方法：

```php
$app-> match( '/signup' , function (Request $request) use ($app) {
    // ...
    $user = $app['sign_up_user_application_service']->execute(
        new SignUpUserRequest(
        $request->get('email'),
        $request->get('password'))
    );
    $user->updateEmailAddress('shouldnotupdate@email.com');
    // ...
});
```
不仅如此，展示层所需要的数据与领域层的数据不同，我们不想把领域层和展示层进行耦合。相反，我们希望它能自由发展。

为了能这样，我们需要一个解耦这两个层的灵活的方式。

#### 来自聚合实例的DTO

我们能够返回带有展示层所需要的信息的无害数据结构。正如我们前面所见，DTO适合这场景。我们只需要在Application Service中编写它们并把它门返回给客户端：

```php
class UserDTO
{
    private $email ;
    // ...
    public function __construct(User $user)
    {
        $this->email = $user->email ();
    // ...
    }
    public function email ()
    {
        return $this->email ;
    }
}
```
`UserDTO`将在展示层行从`User`实体暴露我们需要的任何只读数据，从而避免暴露行为：

```php
class SignUpUserService
{
    public function execute(SignUpUserRequest $request)
    {
        // ...
        $user = // ...
        return new UserDTO($user);
    }
}
```
任务完成，现在我们可以将参数传给模板引擎，并将其转换为小部件、标签或者子模板，或者在展示层做一些对数据的操作：

```php
$app->match('/signup' , function (Request $request) use ($app) {
    /**
    * @var UserDTO $user
    */
    $userDto=$app['sign_up_user_application_service']->execute(
        new SignUpUserRequest(
            $request->get('email'),
            $request->get('password')
        )
    );
    // ...
});
```
但是，让Application Service决定如何构建DTO揭示了另一个限制。由于构建DTO仅取决于Application Service，因此很难适合不同的客户端。对于同一个用例，考虑一下在Web控制器跳转时所需的数据与REST响应所需的数据，它们完全不一样。

让我们允许客户端通过传入特定的DTO Assembler来定义如何构建DTO：

```php
class SignUpUserService
{
    private $userDtoAssembler;
    public function __construct(
        UserRepository $userRepository,
        UserDTOAssembler $userDtoAssembler
    ) {
        $this->userRepository = $userRepository;
        $this->userDtoAssembler = $userDtoAssembler;
    }
    public function execute(SignUpUserRequest $request)
    {
        $user = // ...
        return $this->userDtoAssembler->assemble($user);
    }
}
```

现在客户端可以通过传入特定的`UserDAOAssembler`来自定义响应了。

#### DTO Transformers

在某些情况下，为更复杂的响应（如JSON、XML、CSV等）生成中间DTO可能是一种不必要的开销。我们可以在buffer中输出展示，然后在分发端获取。

Transformers有助于减少通过将高层级领域概念转换为低层级客户端细节产生的开销。让我们看一下这个例子：

```php
interface UserDataTransformer
{
    public function write(User $user);
    /**
    * @return mixed
    */
    public function read();
}
```
考虑为给定的产品生成不同数据展示的案例。通常，产品信息通过Web界面（HTML）提供的，但是我们也有兴趣提供其他格式的，如XML、JSON、或CSV。这可能会启用与其他Service的集成。

针对博客考虑一下相似的案例。有些人会通过RSS消费我们的文章，Application Service用例保持不变，展示也不需要。

DTO是一种干净简单的解决方案，可以传递给用于不同展示形式的模板引擎，但这可能会是数据转换最后一部的逻辑变得复杂，因为这一类模板的逻辑可能会成为维护、测试和理解的难题。

在特定情况下，Data Transformers可能是更好的方法。Data Transformers只是一个黑盒，其将领域概念（如聚合、实体等）作为输入，只读的展示层（XML、JSON、CSV等）作为输出。这些transformers很容易被测试：

```php
class JsonUserDataTransformer implements UserDataTransformer
{
    private $data;
    public function write(User $user)
    {
        // More complex logic could be placed here
        // As using JMSSerializer, native json, etc.
        $this->data = json_encode($user);
    }
    /**
    * @return string
    */
    public function read()
    {
        return $this->data;
    }
}
```
那样非常简单。想知道XML和CSV看起来咋样？让我们看看Data Transformer如何与我们的Application Service集成的：

```php
class SignUpUserService
{
    private $userRepository;
    private $userDataTransformer;
    public function __construct(
        UserRepository $userRepository,
        UserDataTransformer $userDataTransformer
    ) {
        $this->userRepository = $userRepository;
        $this->userDataTransformer = $userDataTransformer;
    }
    public function execute(SignUpUserRequest $request)
    {
        $user = // ...
        $this->userDataTransformer()->write($user);
    }
    /**
    * @return UserDataTransformer
    */
    public function userDataTransformer()
    {
        return $this->userDataTransformer;
    }
}
```
这个与DTO Assembler方式类似，但是这次没有返回具体的值。Data Transformer被用于持有数据和与数据进行交互。

DTO的主要问题是编写它们的开销。大多数时间，你的领域概念和DTO展示形式是相同的结构。大多数时间，你会觉得不值得花时间进行这种映射。也就是说，展示和聚合之间的关系不是1:1。你可以在一个展示中展示两个聚合。你也可以用多种方式展示同一个聚合。如何执行始终取决于你的用例。

但是，Martin Fowler说：

> 当你在展示层中的模型与你的领域模型之间存在严重不匹配时，使用DTO之类的方法很有用。在这种情况下，让展示形式指定一个facade/gateway是有意义的，因为facade/gateway从领域模型映射，并展示一个方便进行展示的界面。它非常适合Presentation Model（展示模型）。这是值得去做的，但是仅对于具有这种不匹配的屏幕才值得做（这种情况下，这不是多余的工作，因为无论如何你都必须在屏幕上进行操作）。

我们认为长期的愿景都将值得投入。在大中型项目中，界面展示和领域概念以不同的节奏速度进行变化。你可能希望它们将彼此分离以减少更新的摩擦。使用DTO或者Data Transformers，你可以自由的发展模型，而不必一直考虑破坏布局。

复合布局上的多个Application Service
---

大多数时间，没有一个布局会像一个Application Service那么简单。我们的项目具有非常复杂的界面。

考虑一个网站主页，我们如何渲染这么多的片段和用例？有几个选项，我们来看一下。

#### AJAX内容集成

你可以让浏览器直接使用不同的API地址，然后通过AJAX或Hijax在布局上合并数据。这样可以避免在你的控制器中混进多个Application Service，但是这可能会降低性能，具体取决于触发的请求数。

#### ESI内容集成

`Edge Side Includes`（ESI）是一种标记语言，与之前的方法类似，但是这是在服务器端。它需要额外的精力来配置像NGINX或Varnish。

#### Symfony子请求

如果你使用Symfony，子请求可能是一个有趣的选择。

（译者注：这里省去关于Symfony子请求的译文，原文也是摘自Symfony官网的，因此建议读者去Symfony官网查看最新的内容）

#### 一个控制器，多个Application Service

最后一个选项，是在同一个控制器中使用多个Application Service，控制器逻辑会有些dirty，因为它处理与合并了响应给视图。

测试Application Service
---

因为你对测试Application Service本身的行为感兴趣，因此不需要将其转换为具有针对真实数据库的复杂设置的集成测试。你的测试低级细节不感兴趣，因此大多数情况下，单元测试就够了：

```php
class SignUpUserServiceTest extends \PHPUnit_Framework_TestCase
{
    /**
    * @var \Lw\Domain\Model\User\UserRepository
    */
    private $userRepository;
    /**
    * @var SignUpUserService
    */
    private $signUpUserService;
    public function setUp()
    {
        $this->userRepository = new InMemoryUserRepository();
        $this->signUpUserService = new SignUpUserService(
        $this->userRepository
    );
    }
    /**
    * @test
    * @expectedException
    * \Lw\Domain\Model\User\UserAlreadyExistsException
    */
    public function alreadyExistingEmailShouldThrowAnException()
    {
        $this->executeSignUp();
        $this->executeSignUp();
    }
    private function executeSignUp()
    {
        return $this->signUpUserService->execute(
            new SignUpUserRequest(
                'user@example.com',
                'password'
            )
        );
    }
    /**
    * @test
    */
    public function afterUserSignUpItShouldBeInTheRepository()
    {
        $user = $this->executeSignUp();
        $this->assertSame(
            $user,
            $this->userRepository->ofId($user->id())
        );
    }
}
```

我们为`UserRepository`使用了基于内存的实现。这就是所谓的Fake：Repository的全功能实现，它将是我们的测试成为一个单元。我们不需要去数据库来测试这个类的行为。那会使我们的测试进行的很慢。

检查领域事件提交可能也有意思。如果创建用户触发了用户注册的事件，则确保触发该事件是个好主意：

```php
class SignUpUserServiceTest extends \PHPUnit_Framework_TestCase
{
    // ...
    /**
    * @test
    */
    public function itShouldPublishUserRegisteredEvent()
    {
        $subscriber = new SpySubscriber();
        $id = DomainEventPublisher::instance()->subscribe($subscriber);
        $user = $this->executeSignUp();
        $userId = $user->id();
        DomainEventPublisher::instance()->unsubscribe($id);
        $this->assertUserRegisteredEventPublished(
            $subscriber, $userId
        );
    }
    private function assertUserRegisteredEventPublished(
        $subscriber, $userId
    ) {
        $this->assertInstanceOf(
            'UserRegistered', $subscriber->domainEvent
        );
        $this->assertTrue(
        $subscriber->domainEvent->userId()->equals($userId)
        );
    }
}

class SpySubscriber implements DomainEventSubscriber
{
    public $domainEvent;
    public function handle($aDomainEvent)
    {
        $this->domainEvent = $aDomainEvent;
    }
    public function isSubscribedTo($aDomainEvent)
    {
        return true;
    }
}
```


事务
---

事务是与持久化机制有关的实现细节。领域层不应该知道这种底层实现细节。在这个层级上思考一下开始、提交、或者回滚一个事务是一种`big smell`。这个细节属于基础设施层。

处理事务的最好的方式是不处理它们。我们可以使用修饰器把我们的Application Service包装起来，以自动处理事务会话。

我们已经在仓储中实现了：

```php
interface TransactionalSession
{
    /**
    * @return mixed
    */
    public function executeAtomically(callable $operation);
}
```
这个接口需要一个回调函数并执行它。根据你的持久化机制，你可以获得不同的实现。

让我们看一下Doctrine ORM怎么实现的：

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

```php
/** @var EntityManager $em */
$nonTxApplicationService = new SignUpUserService(
    $em->getRepository('BoundedContext\Domain\Model\User\User')
);
$txApplicationService = new TransactionalApplicationService(
    $nonTxApplicationService,
    new DoctrineSession($em)
);
$response = $txApplicationService->execute(
    new SignUpUserRequest(
        'user@example.com',
        'password'
    )
);
```
既然我们已经有了针对事务会话的Doctrine实现，那么为我们的Application Service创建一个修饰器会很棒。通过这种做法，我们使事务请求对领域透明：

```php
class TransactionalApplicationService implements ApplicationService
{
    private $session;
    private $service;
    public function __construct(
        ApplicationService $service, TransactionalSession $session
    ) {
        $this->session = $session;
        $this->service = $service;
    }
    public function execute(BaseRequest $request)
    {
        $operation = function () use ($request) {
            return $this->service->execute($request);
        };
        return $this->session->executeAtomically($operation);
    }
}
```
使用Doctrine session的一个很好的作用就是它会自动管理flush方法，因此你无需在领域或这基础设施中添加flush。

安全
---
如果你想知道一般如何管理和处理用户凭证和安全性的，除非这是你的领域职责，否则我们建议让框架来处理它。用户会话是分发机制的关注点，用这样的概念污染领域的话会使开发变得更加困难。

领域事件
---

领域事件监听器必须在Application Service之前被配置好，否则没人会注意到。某些情况下，必须先明确配置监听器，然后才能执行Application Service：

```php
// ...
$subscriber = new SpySubscriber();
DomainEventPublisher::instance()->subscribe($subscriber);
$applicationService = // ...
$applicationService->execute(...);
```
多数情况下，这可以通过配置依赖注入容器完成。

Command Handlers
---

一个执行Application Servic的有趣方式是通过Command Bus（命令总线）的类库。不错的一个是`Tactician`（译者注：github上能够找到）。

我们的Application Service是服务层，我们的请求对象非常像命令。如果有一种机制可以连接所有的Application Service，然后基于请求执行正确的Application Service，那不是很好吗？这实际上就是Command Bus（命令总线）。

#### Tactician库和其他可选项

Tactician是一个命令总线的类库，允许你对你的Application Service使用命令模式。这对于Application Service非常方便。

让我们看一下Tactician网站的示例：

```php
// You build a simple message object like this:
class PurchaseProductCommand
{
    protected $productId;
    protected $userId;
    // ...and constructor to assign those properties...
}
// And a Handler class that expects it:
class PurchaseProductHandler
{
    public function handle(PurchaseProductCommand $command)
    {
        // use command to update your models, etc
    }
}
// And then in your Controllers, you can fill in the command using your favorite
// form or serializer library, then drop it in the CommandBus and you're done!
                                                                $command = new PurchaseProductCommand(42, 29);
                                                                $commandBus->handle($command);

```
Tactician是`$commandBus`服务，它为正确找到Handlers和method做了所有的工作，从而避免了许多重复代码。这里，Commands和Handlers只是普通的类，但是你可以配置最合适你app的那一种。

总而言之，我们可以得出结论，Commands只是请求对象，Command Handler就是Application Service。

（译者注：这里省略掉几段关于Tactician类库的介绍和好处等原文，读者可以直接上Tactician官网进行了解）

总结
---

Application Service代表着你限界上下文的应用层。这些高层级的用例应该相对简单和瘦小，因为它们的目的是负责协调领域层的事物。Application Service应该是领域逻辑交互的入口，我们已经看到，Request和Command可以让事情井井有条。DTO和Data Transformers让我们能够将数据表示与领域概念分离；使用依赖注入容器构建Application Service非常简单；我们还有许多在复杂布局组合Application Service的可选方法。