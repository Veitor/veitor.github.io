---
title: '领域驱动设计中的认证和授权'
tags:
  - ddd
  - 领域驱动设计
categories:
  - PHP
date: 2020-08-27 08:49:59
---

认证(Authentication)和授权(Authorization)是一个应用中常见的场景。但在DDD中实现认证/授权的最佳方式是什么？

在下面我将基于一个虚拟的用例来展示两种实现方式。

# 基本要求

这些概念最好了解一下：

- [Application Service](http://martinfowler.com/eaaCatalog/serviceLayer.html)
- [Hexagonal Architecture](https://zhuanlan.zhihu.com/p/84223605)

<!-- more -->

# 用例

假设我们想开发一个**博客平台**。

我们在下面定义了**博客平台**上下文(Context)中的通用语言(Ubiquitous Languate)：

- **Author:** 博客平台中的用户，它是一个带有`authorId`唯一标识的Entity。
- **Blog:** 博客平台中含有博文的特定区域，它是一个带有`blogId`唯一标识的Entity。
- **Collaborator:** 可以在给定的Blog中创建博文的Author。
- **Authentication:** 识别一个Author的过程。
- **Authorization:** 检查在给定的Blog中Author是否是Collaborator。

我们将要开发的用例是Blog的Collaborator可以在Blog中创建博文。为了能够比较两种实现方式，该用例可以在Web、REST和Console中执行。

> 注意：为了把注意力放在重要概念上，示例代码中对dependencies、getters等概念已经简化了。

## 版本1：在Application Srvice外进行

这种方式下，一旦发起对`Application Service`的请求，则它将被执行，且没有任何Authentication和Authorization的过程。

### Application Service

```php
// Request
class AddPostRequest()
{
   public function authorId() {…}
   public function blogId() {…}
   public function title() {…}
   public function text() {…}
}
// Application Service
class AddPostService()
{
   public function execute($request)
   {
       $authorId = $request->authorId();
       $blogId   = $request->blogId();
       $title    = $request->title();
       $text     = $request->text();
       if (!$blog = $this->blogRepository->blogOfId($blogId)) {
             throw new BlogNotFoundException();
       }
 
       $post = $blog->buildPost(
          $this->postRepository->nextIdentity(),
          $authorId,
          $title,
          $text
       );
       $this->postRepository->save($post);
   }
}
```

### Web

在控制器中（或框架的其他hook中），用例执行之前，对当前用户进行认证检查，同时也检查其是否是Blog的collaborator。

为了检查这些，我们在Controller中使用`Domain Service`：

```php
class PostController
{
   public newPostAction()
   {
       if (!$this->sessionService()->isAuthenticated()) {
           throw new UnauthenticatedUserException();
       }
       $blogId = $this->request->get(‘blog_id’);
       $userId = $this->sessionService()->currentUserId();
   
       $isCollaborator = $this->permissionService()->isCollaborator(
           $userId, $blogId
       );
       if (!$isCollaborator) {
           throw new UnauthorizedUserException();
       }
       // executes AddPostService use case
   }
}
```

### REST

REST方式中，会使用header中的Authorization获取token，需要检查这个token是否属于某个用户，并且这用户是否是Blog的collaborator。

为了检查这些，我们在Controller中使用`Domain Service`：

```php
class PostRestFulController
{
   public newPostAction()
   {
       $authorizationValue = $this->authorizationHeader();
       $userId = $this->oauthService()->userId($authorizationValue);
       $blogId = $this->request->get(‘blog_id’);
       if (!$userId) {
           throw new UnauthenticatedUserException();
       }
       $isCollaborator = $this->permissionService()->isCollaborator(
           $userId, $blogId
       );
       if (!$isCollaborator) {
           throw new UnauthorizedUserException();
       }
       // execute AddPostService use case
    }
}
```

### Console

Console下，执行用例没有检查authentication和authorization。`userId`来自命令行的参数。

```php
> blog add-post — user-id 1 — blog-id 1 — title Foo …

class PostConsole
{
    public newPostCommand()
    {
       // gets values from console parameters
       // execute AddPostService use case
    }
}
```

### 总结

- Authentication/Authorization检查是在Application Service之外的Controller或框架的其他hook中进行。
- Authentication/Authorization必须在Application Service用例执行前进行。
- 根据应用的入口（如Web、REST、Console）来使用authentication服务，实例中使用的是*OauthService*、*SessionService*。

## 版本2：在Application Service内进行

我们可以在用例内使用通用语言，来隐式的执行authentication/authorization。

### Application Service

它将使用一个名为*CollaboratorService*的*Domain Service*来检查authentication和authorization。*CollaboratorService*返回Author的值对象。

```php
interface CollaboratorService
{
    public function authorFrom($authorId, $blogId);
}
// Request
class AddPostRequest
{
    public function authorId() {…}
    public function blogId() {…}
    public function title() {…}
    public function text() {…}
}
// Application Service
class AddPostService
{
    public function execute($request)
    {
       $authorId = $request->authorId();
       $blogId   = $request->blogId();
       $title    = $request->title();
       $text     = $request->text();
       $author = $this->collaboratorService->authorFrom(
           $authorId, 
           $blogId
       );
       if (!$author) {
           throw new InvalidAuthorException();
       }
       if (!$blog = $this->blogRepository->blogOfId($blogId)) {
           throw new BlogNotFoundException();
       }
 
       $post = $blog->buildPost(
           $this->postRepository->nextIdentity(),
           $author,
           $title,
           $text
       );
 
       $this->postRepository->save($post);
    }
}
```

### Web

*Controller*不需要检查authentication/authorization，但它需要创建用例请求和传入*authorId*参数，一个通用场景是从session中读取*userId*。剩下的参数从http请求中读取到。

随后*CollaboratorService*的实现直接与userId进行交互。

```php
class UserIdCollaboratorService implements CollaboratorService
{
    public function authorFrom($authorId, $blogId) { … }
}
class PostController
{
    public newPostAction()
    {
        $authorId = $this->sessionService()->userId();
        // executes ApplicationService use case
    }
}
```

### REST

REST下使用http headr头中Authorization获取用户的token，在REST入口中，认证机制可能是OAuth、JTW等。*CollaboratorService*的实现可能与那个token进行交互。

```php
class OAuthCollaboratorService implements CollaboratorService
{
     public function authorFrom($authorId, $blogId) { … }
}
class PostRestFulController
{
     public newPostAction()
     {
         $authorId = $this->authorizationHeader();
         // executes ApplicationService use case
     }
}
```

### Console

*authorId*参数来自命令行，因此如果给出的*author-id*属于这个blog则不会有任何异常抛出：

```shell
blog add-post — author-id 1 — blog-id 1 — title Foo
```

*CallaboratorService*的实现可能与Web或其他实现一样：

```php
class ConsoleCollaboratorService implements CollaboratorService
{
     public function authorFrom($authorId, $blogId) { … }
}
class PostConsole
{
     public newPostCommand()
     {
        // gets values from console parameters
        // executes AddPostService use case
     }
}
```

### 总结

- 所有对authentication/authorization的检查都在*Application Service*中的*CollaboratorService*中隐式的完成。
- *Application Service*中*authorId*参数的输入某种程度上是多态的，因为它接收来自Web的直接的id或来自REST的token。也许这也是允许我们将authentication/auuthorization放进*Application Service*之内的关键点。
- *CollaboratorService*根据认证机制需要几种不同的实现。


> 原文：https://medium.com/@martinezdelariva/authentication-and-authorization-in-ddd-671f7a5596ac