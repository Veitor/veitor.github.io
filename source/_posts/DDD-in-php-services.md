---
title: '[译]服务 - 《Domain-Driven Design in PHP》第5章'
tags:
  - ddd
  - 领域驱动设计
categories:
  - PHP
date: 2020-05-25 09:58:39
---

> 本篇博文由本博客(`http://www.veitor.net`)经原文翻译，转载请注明出处。

你已经了解了实体和值对象了。作为基本构建块，他们应该包含了任何应用的大部分业务逻辑。但是，在一些场景中值对象和实体并不是一个最好的解决方案。让我们看一下Eric Evans在他的《Domain-Driven Design: Tackling Complexity in the Heart of Software:》书中说的话：

> 当领域中的一个重要过程或转化不是实体或者值对象的自然职责时，增加一个操作作为一个单独的接口，此时该接口被声明为Service领域服务。根据模型的通用语言定义接口，并确保名称是通用语言中的一部分，是服务成为无状态。

<!-- more -->

因此，当有一些操作，并且实体和值对象不是最佳的选择时，你应该考虑将这些操作建模为领域服务。在领域驱动设计中，通常会遇到三种不同类型的服务：

- 应用服务（Application Services）：对标量类型进行操作，并将该类型数据转换为领域类型。一个标量类型可以被视为领域模型中的任一未知类型。这包含了原始类型和不属于领域的类型。我们也会在本章中提供简单概述，但如果要深入了解请查看第11章内容Application。

- 领域服务（Domain Service）：只对属于领域的类型进行操作。它们包含了通用语言中的有意义的概念。它们持有不适合在值对象和实体中出现的操作。

- 基础设施服务（Infrastructure Service）：满足基础架构问题的操作。例如发送邮件、记录日志数据等。就六边形架构而言，它们位于领域层之外。

应用服务
---

应用服务是位于外部世界和领域逻辑的中间者。其目的是将外部世界的命令转换为有意义的领域中的指令。

让我们思考一下`用户在我们平台中注册`的用例。由外部到内部来看：从分发机制（delivery mechanism）开始，我们需要为领域操作编写输入请求。使用Symfony之类的框架作为分发机制，代码如下：

```php
class SignUpController extends Controller
{
    public function signUpAction(Request $request)
    {
        $signUpService = new SignUpUserService(
            $this->get('user_repository')
        );
        try {
            $response = $signUpService->execute(new SignUpUserRequest(
                $request->request->get('email'),
                $request->request->get('password')
            ));
        } catch (UserAlreadyExistsException $e) {
            return $this->render('error.html.twig', $response);
        }
        return $this->render('success.html.twig', $response);
    }
}
```

如你所见，我们创建了应用服务的一个新实例，传入所有依赖的信息，在这个用例中，是一个`UserRepository`。`UserRepository`是一个可以使用任何技术（如Mysql、redis、Elasticsearch等）实现的interface。然后，我们为应用服务创建一个请求对象，为了从业务逻辑中抽象出分发机制。在这例子中，是一个web请求。最后，我们执行应用服务，获取响应，并使用响应来渲染结果。在领域方面，让我们看一下应用服务可能的实现，该实现协调了满足用户注册用例的逻辑：

```php
class SignUpUserService
{
    private $userRepository;
    public function __construct(UserRepository $userRepository)
    {
        $this->userRepository = $userRepository;
    }
    public function execute(SignUpUserRequest $request)
    {
        $user = $this->userRepository->userOfEmail($request->email);
        if ($user) {
            throw new UserAlreadyExistsException();
        }
        $user = new User(
            $this->userRepository->nextIdentity(),
            $request->email,
            $request->password
        );
        $this->userRepository->add($user);
        return new SignUpUserResponse($user);
    }
}
```
代码中的所有东西都是与我们想要解决的领域问题相关，而不是与我们想要解决问题时使用的特定技术有关。利用这一点，我们可以将高级策略和低级实现细节分开。承载分发机制与领域之间联系信息的数据结构被称之为`DTO`，我们在第2章架构风格中介绍过：

```php
class SignUpUserRequest
{
    public $email;
    public $password;
    public function __construct($email, $password)
    {
        $this->email = $email;
        $this->password = $password;
    }
}
```

对于返回的内容有许多的不同策略。但是现在，我们不应该return我们的实体，以至于不让它们在应用服务的外部被修改。这就是为啥通常都返回另一个DTO，而不是整个实体。看一下简单示例：

```php
class SignUpUserResponse
{
    public $id;
    public $email;
    public function __construct(User $user)
    {
        $this->id = $user->id();
        $this->email = $user->email();
    }
}
```
对于创建你的响应，你可以使用getter方法或者直接公开对象实例的属性。应用服务应该注意事务范围和安全性。但是你将在第11章“应用程序”中深入了解与应用服务有关的更多内容。

领域服务
---
在与领域专家的整个对话中，你会遇到通用语言中的概念。这些概念不能被巧妙的表示为实体或值对象，例如：

- 用户可以自己登录系统
- 一个购物车能够自己成为一个订单

这是两个具体概念，它们都不能自然的以实体或者值对象的形式来表示。为了进一步强调这一点，我们尝试这样建模：

```php
class User
{
    public function signUp($aUsername, $aPassword)
    {
        // ...
    }
}

class Cart
{
    public function createOrder()
    {
        // ...
    }
}
```
第一个用例的实现，我们不知道给定的用户名和密码与被调用的user实例是否有关。显然，此操作不适合这个实体；相反，应将其提取到一个单独的类中，使其意图明确。

有了这一点，我们可以创建一个完全负责验证用户身份的领域服务：

```php
class SignUp
{
    public function execute($aUsername, $aPassword)
    {
        // ...
    }
}
```

同样，第二个例子我们可以一个领域服务专门用于从提供的购物车中创建订单：

```php
class CreateOrderFromCart
{
    public function execute(Cart $aCart)
    {
        // ...
    }
}
```

领域服务被定义为一个操作，这些操作不适合在实体或值对象中表示。作为领域中操作的概念，由客户端使用领域服务，而不用管其之前的历史记录，因为领域本身不拥有任何状态，所以领域服务是无状态的。

领域服务和基础设施服务
---

在对领域服务建模时，通常会遇到基础设施依赖的问题。例如，在需要处理哈希密码的情况下，你可以使用[Separated Interface](https://martinfowler.com/eaaCatalog/separatedInterface.html)，这允许接口定义多种哈希机制。使用此模式仍然可以为你提供领域和基础设施之间关注点的分离：

```php
namespace Ddd\Auth\Domain\Model;
interface SignUp
{
    public function execute($aUsername, $aPassword);
}
```

使用上面领域中定义的接口，我们可以在Infrastructure层中创建一个实现：

```php
namespace Ddd\Auth\Infrastructure\Authentication;
class DefaultHashingSignUp implements Ddd\Auth\Domain\Model\SignUp
{
    private $userRepository;
    
    public function __construct(UserRepository $userRepository)
    {
        $this->userRepository = $userRepository;
    }
    public function execute($aUsername, $aPassword)
    {
        if (!$this->userRepository->has($aUsername)) {
            throw UserDoesNotExistException::fromUsername($aUsername);
        }
        $aUser = $this->userRepository->byUsername($aUsername);
        if (!$this->isPasswordValidForUser($aUser, $aPassword)) {
            throw new BadCredentialsException($aUser, $aPassword);
        }
        return $aUser;
    }
    private function isPasswordValidForUser(
        User $aUser, $anUnencryptedPassword
    ) {
        return password_verify($anUnencryptedPassword,$aUser->hash());
    }
}
```

这是我们另一个基于MD5算法的实现：

```php
namespace Ddd\Auth\Infrastructure\Authentication;
use Ddd\Auth\Domain\Model\SignUp
class Md5HashingSignUp implements SignUp
{
    const SALT = 'S0m3S4lT' ;
    private $userRepository;
    public function __construct(UserRepository $userRepository)
    {
        $this->userRepository = $userRepository;
    }
    public function execute($aUsername, $aPassword)
    {
        if (!$this->userRepository->has($aUsername)) {
            throw new InvalidArgumentException(
            sprintf('The user "%s" does not exist.', $aUsername)
            );
        }
        $aUser = $this->userRepository->byUsername($aUsername);
        if ($this->isPasswordInvalidFor($aUser, $aPassword)) {
            throw new BadCredentialsException($aUser, $aPassword);
        }
        return $aUser;
    }
    private function salt()
    {
        return md5(self::SALT);
    }
    private function isPasswordInvalidFor(
        User $aUser, $anUnencryptedPassword
    ) {
        $encryptedPassword = md5(
            $anUnencryptedPassword . '_' .$this->salt()
        );
        return $aUser->hash() !== $encryptedPassword;
    }
}
```
这样我们可以在Infrastructure层允许对领域服务的interface有多种实现。每个基础设施服务将会负责处理一种不同的哈希机制。根据实现，其用法可以通过ID容器轻松管理，例如Symfony的依赖注入组件（译者注：这里建议大家可以先去了解一下`依赖注入`相关的概念）：

```xml
<?xml version="1.0"?>
<container
xmlns="http://symfony.com/schema/dic/services"
xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
xsi:schemaLocation="
http://symfony.com/schema/dic/services
http://symfony.com/schema/dic/services/services-1.0.xsd">
    <services>
        <service id="sign_in" alias="sign_in.default" />
        <service id="sign_in.default"
        class="Ddd\Auth\Infrastructure\Authentication
        \DefaultHashingSignUp">
            <argument type="service" id="user_repository"/>
        </service>
        <service id="sign_in.md5"
        class="Ddd\Auth\Infrastructure\Authentication
        \Md5HashingSignUp">
            <argument type="service" id="user_repository"/>
        </service>
    </services>
</container>
```

如果未来我们希望处理新的哈希机制，我们可以简单的去实现领域服务接口。然后在依赖注入容器中声明领域服务，然后用新创建的服务别名替换之前用的服务别名。

#### 代码重用问题

尽管之前描述的实现明确定义了关注点分离，但每次我们希望实现新的哈希机制时，都需要重复密码验证算法。解决此问题的另一种方法是分离这两个职责，从而提高代码的复用性。相反，我们可以对已有的哈希算法使用策略模式，将密码哈希逻辑提取到专门的类里：

```php
namespace Ddd\Auth\Domain\Model;
class SignUp
{
    private $userRepository;
    private $passwordHashing;
    public function __construct(
        UserRepository $userRepository, PasswordHashing $passwordHashing
    ) {
        $this->userRepository = $userRepository;
        $this->passwordHashing = $passwordHashing;
    }
    public function execute($aUsername, $aPassword)
    {
        if (!$this->userRepository->has($aUsername)) {
            throw new InvalidArgumentException(
                sprintf('The user "%s" does not exist.', $aUsername)
            );
        }
        $aUser = $this->userRepository->byUsername($aUsername);
        if ($this->isPasswordInvalidFor($aUser, $aPassword)) {
            throw new BadCredentialsException($aUser, $aPassword);
        }
        return $aUser;
    }
    private function isPasswordInvalidFor(User $aUser, $plainPassword)
    {
        return !$this->passwordHashing->verify(
            $plainPassword,
            $aUser->hash()
        );
    }
}
interface PasswordHashing
{
    /**
    * @param string $password
    * @param string $hash
    * @return boolean
    */
    public function verify($plainPassword, hash);
}
```
定义不同的哈希策略如同实现`PasswordHashing`接口一样简单：

```php
namespace Ddd\Auth\Infrastructure\Authentication;
class BasicPasswordHashing
implements \Ddd\Auth\Domain\Model\PasswordHashing
{
    public function verify($plainPassword, $hash)
    {
        return password_verify($plainPassword, $hash);
    }
}
class Md5PasswordHashing
implements Ddd\Auth\Domain\Model\PasswordHashing
{
    const SALT = 'S0m3S4lT' ;
    public function verify($plainPassword, $hash)
    {
        return $hash === $this-> calculateHash($plainPassword);
    }
    private function calculateHash($plainPassword)
    {
        return md5($plainPassword . '_' .$this-> salt());
    }
    private function salt()
    {
        return md5(self::SALT);
    }
}
```

测试领域服务
---

前面的多个领域服务用户认证示例，能够轻松被测试。但是，通常测试`Template Method`实现有些棘手，我们使用原生密码哈希实现来进行测试：

```php
class PlainPasswordHashing implements PasswordHashing
{
    public function verify($plainPassword, $hash)
    {
        return $plainPassword === $hash;
    }
}
```

现在我们可以在领域服务中测试所有的用例了：

```php
class SignUpTest extends PHPUnit_Framework_TestCase
{
    private $signUp;
    private $userRepository;
    protected function setUp()
    {
        $this->userRepository = new InMemoryUserRepository();
        $this->signUp = new SignUp(
            $this->userRepository,
            new PlainPasswordHashing()
        );
    }
    /**
    * @test
    * @expectedException InvalidArgumentException
    */
    public function itShouldComplainIfTheUserDoesNotExist()
    {
        $this->signUp->execute('test-username', 'test-password');
    }
    /**
    * @test
    * @expectedException BadCredentialsException
    */
    public function itShouldTellIfThePasswordDoesNotMatch()
    {
        $this->userRepository->add(
        new User(
            'test-username',
            'test-password'
        )
    );
    $this->signUp->execute('test-username', 'no-matching-password')
    }
    /**
    * @test
    */
    public function itShouldTellIfTheUserMatchesProvidedPassword()
    {
        $this->userRepository->add(
            new User(
                'test-username',
                'test-password'
            )
        );
        $this->assertInstanceOf(
            'Ddd\Domain\Model\User\User',
            $this->signUp->execute('test-username', 'test-password')
        );
    }
}
```

贫血模型 Vs. 充血模型
---

你必须要注意不要在你的系统中过度使用领域服务。这么做会导致实体与值对象被剥离出所有行为而成了纯粹的数据容器。这与面向对象编程的目标是相反的，该目标可以被认为是将数据和行为组合到成为对象的语义化单元中，目的是表达现实世界中的概念和问题。领域服务的过度使用会被认为是反模式，称为贫血领域模型。

通常，在开始一个新项目或功能时，很容易陷入对数据建模的陷阱。通常这包括认为数据表与展现形式是直接一对一的关系。但是，这种想法并非始终都是正确的。

假设我们的任务是为订单处理系统建模，如果我们先对数据进行建模，我们可能会得到一个如下的SQL语句：

```sql
CREATE TABLE `orders` (
    `ID` INTEGER NOT NULL AUTO_INCREMENT,
    `CUSTOMER_ID` INTEGER NOT NULL,
    `AMOUNT` DECIMAL(17, 2) NOT NULL DEFAULT '0.00',
    `STATUS` TINYINT NOT NULL DEFAULT 0,
    `CREATED_AT` DATETIME NOT NULL,
    `UPDATED_AT` DATETIME NOT NULL,
    PRIMARY KEY (`ID`)
) ENGINE=INNODB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

基于此，创建Order类展现形式相对容易，此表现形式包括必要的访问方法，可以被用于从底层订单数据表中获取或设置数据。

```php
class Order
{
    const STATUS_CREATED = 10;
    const STATUS_ACCEPTED = 20;
    const STATUS_PAID = 30;
    const STATUS_PROCESSED = 40;
    
    private $id;
    private $customerId;
    private $amount;
    private $status;
    private $createdAt;
    private $updatedAt;
    
    public function __construct(
        $customerId,
        $amount,
        $status,
        DateTimeInterface $createdAt,
        DateTimeInterface $updatedAt
    ) {
        $this->customerId = $customerId;
        $this->amount = $amount;
        $this->status = $status;
        $this->createdAt = $createdAt;
        $this->updatedAt = $updatedAt;
    }
    public function setId($id)
    {
        $this->id = $id;
    }
    public function getId()
    {
        return $this->id;
    }
    public function setCustomerId($customerId)
    {
        $this->customerId = $customerId;
    }
    public function getCustomerId()
    {
        return $this->customerId;
    }
    public function setAmount($amount)
    {
        $this->amount = $amount;
    }
    public function getAmount()
    {
        return $this->amount;
    }
    public function setStatus($status)
    {
        $this->status = $status;
    }
    public function getStatus()
    {
        return $this->status;
    }
    public function setCreatedAt(DateTimeInterface $createdAt)
    {
        $this->createdAt = $createdAt;
    }
    public function getCreatedAt()
    {
        return $this->createdAt;
    }
    public function setUpdatedAt(DateTimeInterface $updatedAt)
    {
        $this->updatedAt = $updatedAt;
    }
    public function getUpdatedAt()
    {
        return $this->updatedAt;
    }
}
```

这个示例用例将可能是这样来更新订单状态的：

```php
// Fetch an order from the database
$anOrder = $orderRepository->find( 1 );
// Update order status
$anOrder->setStatus(Order::STATUS_ACCEPTED);
// Update updatedAt field
$anOrder->setUpdatedAt(new DateTimeImmutable());
// Save the order to the database
$orderRepository->save($anOrder);
```
关于代码重用，这个代码有着类似与初始用户身份认证方案的问题。为了解决这问题，建议使用服务层，从而使得操作明确且可重用。现在可以将之前的实现封装到单独的类中：

```php
class ChangeOrderStatusService
{
    private $orderRepository;
    
    public function __construct(OrderRepository $orderRepository)
    {
        $this->orderRepository = $orderRepository;
    }
    public function execute($anOrderId, $anOrderStatus)
    {
        // Fetch an order from the database
        $anOrder = $this->orderRepository->find($anOrderId);
        // Update order status
        $anOrder->setStatus($anOrderStatus);
        // Update updatedAt field
        $anOrder->setUpdatedAt(new DateTimeImmutable());
        // Save the order to the database
        $this->orderRepository->save($anOrder);
    }
}
```

或者是像这样更新订单数量：

```php
class UpdateOrderAmountService
{
    private $orderRepository;
    
    public function __construct(OrderRepository $orderRepository)
    {
        $this->orderRepository = $orderRepository;
    }
    public function execute( $orderId, $amount)
    {
        $anOrder = $this->orderRepository->find(1);
        $anOrder->setAmount($amount);
        $anOrder->setUpdatedAt(new DateTimeImmutable());
        $this->orderRepository->save($anOrder);
    }
}
```

客户端代码将大大减少：

```php
$updateOrderAmountService = new UpdateOrderAmountService(
    $orderRepository
);
$updateOrderAmountService->execute(1, 20.5);
```
实现此方法可以让代码很大程度上可以重用。那些希望更新订单数量的人只需要获取`UpdateOrderAmountService`的实例并使用适当的参数调用execute方法即可。

但是，选择此方式会破坏面向对象设计原则，并且在没有任何优势的情况下会产生构建领域模型的成本。

#### 贫血领域模型破坏了封装性

如果我们重新使用用于在Service层中定义服务的代码，我们可以看到，作为Order实体的客户端，我们需要了解其内部展现形式的每个细节。这一发现违反了面向对象编程的基本原则，即数据与后续行为结合在一起。

#### 贫血领域模型给代码重用带来了错觉

假设有一个实例，其中客户端绕过了`UpdateOrderAmountService`，而是直接获取该实例，更新后并直接持久化保存到了`OrderRepository`。然后将不会执行`UpdateOrderAmountService`中可能已经执行的所有其他业务逻辑。这可能导致订单以不一致的状态存储。要想不变性得到保障，最佳的方法是让真正的领域模型来处理它。在此示例中，Order实体是确保这一点的最佳位置：

```php
class Order
{
    // ...
    public function changeAmount($amount)
    {
        $this->amount = $amount;
        $this->setUpdatedAt(new DateTimeImmutable());
    }
}
```
注意将该方法放入实体并使用通用语言来对该方法进行命名，系统实现很好的代码重用。现在希望更改订单金额的任何人都可以直接调用`Order::changeAmount`方法。

这使得类变得很丰富，对于代码的重用来说，类中具有行为就是我们的目标。这通常被称之为充血领域模型。

#### 如何去避免贫血领域模型

避免陷入贫血领域模型的方式是，当开始新项目或功能时，先考虑行为。数据库、ORM等都只是实现的细节，我们应尽可能的在开发过程的最后阶段再做出使用这些工具的决定，通过这样，我们可以专注于一个重要的真实属性：行为。

与实体一样，领域服务也可以触发领域事件（第6章的内容）。但是，当事件由领域服务触发而非实体触发时，它再次表明你可能正在创建一个贫血领域模型。

总结
---

如我们所见，服务代表了我们系统内的操作，并且我们可以区分它们的三个版本：

- 应用服务：帮助将外边真实世界的请求协调到领域中。这些服务不应该包含领域逻辑。事务在应用层级进行处理。将你的服务放入事务修饰器中将会让你的代码对事务无感知。
- 领域服务：仅使用领域概念进行操作。记住要尽量晚点再考虑实现细节，先考虑行为，因为领域服务的滥用将导致贫血领域模型和不良的面向对象设计。
- 基础设施服务：在基础设施层进行操作，做一些如发送邮件或记录日志的事情。

我们最重要的建议是，在你决定创建领域服务之前，应该考虑所有的做法。首先尝试将业务逻辑移到实体或值对象内，和同事一次又一次的检查，如果在此之后，如果认为创建领域服务是最佳选择时再去这么做。

