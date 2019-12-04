---
title: 微服务模式：Saga
tags:
  - CQRS
  - Event Sourcing
  - 微服务
url: 584.html
id: 584
categories:
  - 架构
date: 2018-12-05 01:46:00
---

# 背景

你已经应用了[一个服务一个数据库](http://www.veitor.net/article/580.html)的模式，每个服务都有自己的数据库。但是一些事务需要跨服务，因此你需要一种机制来保证跨服务的数据一致性。假设你正在建设一个电子商城，客户有其信用额度。应用必须确保新订单不会超过该客户的可用额度限制。因为订单和客户信息在不同的数据库中，因此应用不能简单的使用ACID事务。

<!-- more -->

问题
==

如何处理跨服务的数据一致性问题？

限制
==

*   2PC不能用

方案
==

将跨服务的事务实现为Saga。在Saga中每个本地事务更新数据库后并发布一个事件来触发下一个本地事务。如果一个本地事务因不符合业务规则而失败，则Saga将执行一系列修正事务，来撤销之前本地事务的修改。

![saga.jpg](http://storage.veitor.net/2018/12/3652855247.jpg "saga.jpg")

实现Saga的两种方式：

*   编排（Choreography）：每个本地事务发送领域事件来触发其他服务中的本地事务。
*   编制（Orchestration）：一个编制器（对象）告诉参与者该执行什么本地事务。

示例：基于编排的Saga模式
==============

![Saga_Choreography_Flow.001.jpeg](http://storage.veitor.net/2018/12/2143801791.jpeg "Saga_Choreography_Flow.001.jpeg")

使用基于编排Saga的电商程序在创建订单时包含以下步骤：

1.  `订单服务`创建一个待确认状态的订单并且发布一个`OrderCreated`事件；
2.  `客户服务`接收到了该事件，并尝试去为该订单查询信用。它将发布一个`CreditReserved`事件或者`CreditLimitExcedded`事件。
3.  `订单服务`接收到事件后将改变订单状态为通过或取消。

示例：基于编制的Saga模式
==============

![Saga_Orchestration_Flow.001.jpeg](http://storage.veitor.net/2018/12/951589825.jpeg "Saga_Orchestration_Flow.001.jpeg")

使用基于编制Saga的电商程序在创建订单时包含以下步骤：

1.  `订单服务`创建一个待确认状态的订单，同时创建了一个`CreateOrderSaga`；
2.  `CreateOrderSaga`发送一个`ReserveCredit`命令到客户服务；
3.  `客户服务`尝试为该订单查询信用并发送回复。
4.  `CreateOrderSaga`接受到回复后发送`ApproveOrder`或`RejectOrder`命令到订单服务；
5.  `订单服务`将订单状态修改为通过或取消。

> 基于编制的Saga又被称为`流程管理器(Process Manager)`，因为一个聚合状态的整个流程变化都由Saga来控制。如上步骤示例，可以看出Saga会对前一步骤创建出来的Event作出响应，所以基于编制的Saga流程管理又类似于Event Dispatcher，会分发和处理相应的领域事件。

结果
==

这模式有以下好处：

*   它能让应用不使用分布式事务而实现跨服务的数据一致性。

但也有以下缺点：

*   编程模型会变得更复杂。开发者必须要设计修正事务来明确撤销之前在saga中做的改动。

还有以下问题需要去解决：

*   为了可靠性，一个服务必须以原子方式更新数据库和发布事件。它不能使用跨数据库和消息broker的分布式事务这种传统方式，相反，它必须使用下列模式中的一种。

相关模式
====

*   一个服务一个数据库
*   以下模式是以原子更新状态和发布事件消息的：
    
    *   事件溯源（Event Sourcing）
    *   应用事件（Application Event）
*   一个基于编排的saga能使用聚合和领域事件发布事件。