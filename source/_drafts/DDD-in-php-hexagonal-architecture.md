---
title: '[译]六边形架构 - 《Domain-Driven Design in PHP》附录'
tags:
  - ddd
  - 领域驱动设计
categories:
  - PHP
date: 2020-05-27 15:40:44
---

> 本篇博文由本博客(`http://www.veitor.net`)经原文翻译，转载请注明出处。

将业务和Web框架解耦
---

我们已经看到从一种持久策略改为另一种持久策略是多么容易。但是，持久化并不是我们六边形架构的唯一优势。用户与程序交互方面呢？

你的CTO已经在你的团队规划准备迁移到Symfony框架了，因此在你当前的Zend框架中开发新功能时，我们希望使得即将到来的迁移工作简单一点，这很棘手：

```php
class IdeaController extends Zend_Controller_Action
{
    public function rateAction()
    {
        $ideaId = $this->request->getParam('id');
        $rating = $this->request->getParam('rating');
        $ideaRepository = new RedisIdeaRepository();
        $useCase = new RateIdeaUseCase($ideaRepository);
        $response = $useCase->execute($ideaId, $rating);
        $this->redirect('/idea/' . $ideaId);
    }
}
interface IdeaRepository
{
    // ...
}
class RateIdeaUseCase
{
    private $ideaRepository;
    public function __construct(IdeaRepository $ideaRepository)
    {
        $this->ideaRepository = $ideaRepository;
    }
    public function execute($ideaId, $rating)
    {
        try {
            $idea = $this->ideaRepository->find($ideaId);
        } catch(Exception $e) {
            throw new RepositoryNotAvailableException();
    }
    if (!$idea) {
        throw new IdeaDoesNotExistException();
    }
    try {
        $idea->addRating($rating);
        $this->ideaRepository->update($idea);
    } catch(Exception $e) {
        throw new RepositoryNotAvailableException();
    }
        return $idea;
    }
}
```
让我们回顾一下修改。我们的控制器里没有任何业务逻辑。我们已经将所有的业务逻辑放入了一个名为`RateIdeaUseCase`的新对象中。这个对象也被称为Controller、Interactor或者Application Service。

神奇的地方由`execute`方法完成的。所有的依赖项（如RedisIdeaRepository）都作为参数传入构造函数。我们的UseCase中对`IdeaRepository`的所有引用都指向该接口，而不是具体实现。

这真的很cool。如果你查看`RateIdeaUseCase`里的内容，会发现没有关于MySQL或Zend框架的任何内容，没有任何引用，没有任何实例，没有注释，什么都没有。它不关心你的基础设施代码，它只关心业务逻辑。

此外，我们还调整了抛出的异常。业务流程也有异常，`NotAvailableRepository`和`IdeaDoseNotExist`是其中两个，基于被抛出的那个异常，我们可以在框架层面作出不同的响应。

有时，`UseCase`接收的参数数量可能太多。为了对它们进行组织，使用数据传输对象(DTO)构建UseCase请求很常见。让我们看一下：

```php
class IdeaController extends Zend_Controller_Action
{
public function rateAction()
{
$ideaId = $this->request->getParam('id');
$rating = $this->request->getParam('rating');
$ideaRepository = new RedisIdeaRepository();
$useCase = new RateIdeaUseCase($ideaRepository);
$response = $useCase->execute(
new RateIdeaRequest($ideaId, $rating)
);
$this->redirect('/idea/' . $response->idea->getId());
}
}
class RateIdeaRequest
{
    public $ideaId;
    public $rating;
    public function __construct($ideaId, $rating)
    {
        $this->ideaId = $ideaId;
        $this->rating = $rating;
    }
}
class RateIdeaResponse
{
    public $idea;
    public function __construct(Idea $idea)
    {
    $this->idea = $idea;
    }
}
class RateIdeaUseCase
{
    // ...
    public function execute($request)
    {
        $ideaId = $request->ideaId;
        $rating = $request->rating;
        // ...
        return new RateIdeaResponse($idea);
    }
}
```

这里的主要修改是引入了两个新对象，即Reuqest和Response。它们不是强制的，业务UseCase没有请求和响应。另一个重要的细节是如何构建此Request。这种情况下，我们从ZF框架获取参数来构造请求对象。

好的，但是等等。真正的好处是什么？从一个框架更改为另一个框架，或者从一种分发机制执行UseCase更加容易了。
