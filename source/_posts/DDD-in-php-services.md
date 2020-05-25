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

