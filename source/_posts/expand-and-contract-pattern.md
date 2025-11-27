---
title: '为数据库schema变更使用扩展和收缩模式'
tags:
  - 数据库
categories:
  - 数据库
date: 2025-11-25 16:10:53
---

![expand-and-contract-pattern-cover.png](https://storage.veitor.net/2025/11/expand-and-contract-pattern-cover.png@articleCover)

## 引言

数据库表结构的设计会随着与之交互的软件变化而不可避免地演进。能够安全、可靠地将表结构过渡到新需求至关重要。

虽然数据库迁移工具通常可以更新实际的数据结构，但数据本身也必须转换到新格式、迁移到不同的表或列，并更新以符合新的预期。这些过程虽然不一定复杂，但在客户端仍在使用的线上系统中执行时尤为敏感。

幸运的是，有一种称为`扩展与收缩模式`的多步骤流程，可在不中断系统服务的情况下，安全地逐步将客户端迁移到使用新的数据结构。本指南将探讨扩展与收缩模式是什么，它如何实现新旧结构之间的无缝过渡，以及如何将其应用于各种数据库转换。


## 什么是扩展与收缩模式？

扩展与收缩模式是一种数据库管理员和软件开发人员可用来将数据从旧数据结构迁移到新数据结构而不影响系统正常运行时间的流程。它通过一系列独立的步骤来应用变更，旨在后台引入新结构、为线上使用准备数据，然后无缝切换到新结构。

该流程可用于修改许多正在使用的接口，但对数据库表结构变更尤其有用。除了将数据和客户端迁移到新数据结构之外，扩展与收缩模式还有一个优势：如果在过程中的任何阶段出现问题，或者需求发生变化，你都可以轻松地回滚变更。

<!-- more -->

## 如何使用扩展与收缩模式？

本节将概述如何实际运用扩展与收缩模式以及它能实现的目标。各个步骤需要协调客户端应用程序与数据库内部使用的schema。理解每一步的目的以及为何应独立于其他步骤执行至关重要。

**注意**：步骤2和步骤3的执行顺序取决于你的需求、设计和偏好。通常，在迁移数据之前先扩展客户端接口是合适的，但在某些情况下，在更改任何客户端行为之前先迁移数据可能更有用。

### 步骤1：部署新的schema

![step-1.png](https://storage.veitor.net/2025/11/step-1.png)

扩展与收缩模式的第一步是设计一个满足新需求的新schema。理想情况下，这应涉及对现有结构的小幅修改。较大的变更应拆分为更小、独立的步骤，每个步骤都可以依次经历此流程。

由于现有结构当前正被客户端使用，你不能直接修改任何列。相反，你需要与现有结构并行地实现变更。例如，如果你想将一个 `name` 列拆分为 `first_name` 和 `last_name`，你应该添加这两个新列，而不是修改原来的 `name` 列。

对于列级别的变更，这通常意味着向表中添加具有所需特性的新列，同时保持当前列不变。对于更复杂的变更，这可能意味着创建一个全新的表来表示新的数据结构。

将代表你新设计的数据结构部署到数据库中。确保任何新列都没有会导致当前客户端行为失败的约束。例如，你可能需要使新列可为空（nullable）和/或提供默认值。

此时，数据库客户端应能够像以前一样访问原始结构。

### 步骤2：扩展客户端接口

![step-2.png](https://storage.veitor.net/2025/11/step-2.png)

在将新数据库 schema 与原有 schema 并行部署之后，下一步是扩展客户端，使其能够识别新增的列和表。客户端代码仍然从原有数据结构读取所有值；然而，在执行写操作时，客户端现在会同时在原有结构和新结构中新增或修改数据。

此时，客户端正主动把数据写入新结构，同时保持对旧结构的写入。这为你提供了验证两个组件之间新接口的机会，并确保后续所有数据都会持久化到新数据结构中。由于客户端仍继续写入旧结构，且所有读操作仍只引用原有结构，因此客户端的外部行为应完全保持不变。

### 步骤3：迁移现有数据到新的schema

![step-3.png](https://storage.veitor.net/2025/11/step-3.png)

新的数据模式已在数据库中就位，但它尚未包含原始模式所持有的任何实际数据。为了让新模式真正可用，你需要将现有列或表中的数据迁移到新结构中。

在某些情况下，这一步可能只需将现有值复制到新结构即可；但通常，你可能需要以某种方式修改数据，以弥补两种模式之间的差异。这可能包括修改数据类型、拆分值、回填默认值等。

务必仔细思考这一步，以确保你所做的更改是正确的，并且在语义上与原始含义等价。有时这一点会很明显。例如，如果你的原始 `color` 列以字符串形式存储值，而新列改为存储与另一张表中颜色相对应的 ID，那么转换过程应该相当直接。

然而，在其他时候，情况可能就没那么清晰。例如，如果你有一个 `name` 列，并希望将其拆分为 `first_name` 和 `last_name`，那么这两个部分之间的分界点可能并不明确。举个例子，虽然你可能很有把握地将 `John Smith` 拆分开，但你的数据迁移脚本在处理 “Juan Carlos Ferdinand Garcia” 时可能就无法正确处理。请花额外的时间思考新字段与原始字段之间的关系，并判断你的系统是否需要新的信息才能正确迁移某些记录。

### 步骤4：测试新接口

![step-4.png](https://storage.veitor.net/2025/11/step-4.png)

一旦数据迁移完成，且客户端同时向新旧结构写入数据，你就可以对新接口进行测试。此时，生产客户端仍以原有数据结构为“唯一真实来源”，但你可以并行运行查询和客户端，验证新结构是否按预期工作。

本阶段通常包括功能测试，确保新结构能够执行生产客户端所需的所有查询，并返回正确结果。如果条件允许，还应进行性能测试；不过，若直接在承载生产流量的服务器上测试，可能会引发问题。此时可选择在备用或只读副本服务器上进行测试。若性能不达标，可能需要新建索引或调整查询语句。

这是你在新接口正式承载生产流量前，最后一次验证其行为的机会。务必确保其满足需求，再进入下一步。

### 步骤5：将读取操作切换到新接口

![step-5.png](https://storage.veitor.net/2025/11/step-5.png)

此时，你已准备就绪，可以开始将生产流量逐步迁移到新的数据库结构。这意味着要修改客户端行为，使其在读取时使用新 schema，而不再依赖原有 schema。

这一步标志着正式切换流量，新结构将全权负责处理生产请求；不过，客户端仍会继续同时向新旧两种数据结构写入数据。

根据 schema 变更的具体性质，这一步也可能是你首次面临回滚时可能丢失数据的风险。虽然旧数据结构仍在接收客户端的写入，但它并不会存储任何仅存在于新设计中的数据。一旦决定回退到旧设计，新表中收集到的独有数据将会丢失，或者需要额外工作才能重新整合。

在实践中，这一步通常会分阶段进行，以便以受控方式逐步迁移多个客户端。稍后我们将讨论一些有助于完成此过程的策略。

### 步骤6：停止向原始结构写入

![step-6.png](https://storage.veitor.net/2025/11/step-6.png)

确认新结构运行正常后，可再次更新数据库客户端，停止对原结构的写入。

此时，客户端已完全使用新 schema。

### 步骤7：从系统中移除旧结构

![step-7.png](https://storage.veitor.net/2025/11/step-7.png)

当所有客户端都已更新，停止向原 schema 写入后，你就可以安全地删除原有数据结构。这是扩展与收缩模式的最后一步，标志着向新结构的迁移彻底完成。

## 扩展与收缩模式示例

为了更好地说明如何使用扩展与收缩模式来变更数据表结构、迁移数据并在不停机的情况下重新配置客户端，我们将通过一个示例展示如何应用这一策略。

假设你有一个名为 `equipment` 的表，用于管理整个公园区域内使用的游乐设施。该表包含以下列：

```
Table equipment
---------------
id INT
item_type STRING
installed_on DATETIME
city STRING
park STRING
playground INT
```
目前，`equipment` 表通过 `city`、`park` 和 `playground` 列来记录设备的安装位置（其中 `playground` 列用于在公园内有多个游乐场时指定具体的游乐场）。然而，我们发现这些信息更适合单独放在一张表中。新设计方案如下：

```
Table equipment
---------------
id INT
item_type STRING
installed_on DATETIME
playground INT FOREIGN KEY (playground.id)


Table playground
----------------
id INT
city STRING
park STRING
sq_ft INT
```
为实现这一变更，团队创建了一个新的 `playground` 表，用于存放与特定公园内特定游乐场相关的信息。该表将游乐场相关的所有信息独立出来，与设备信息分离。

团队采取的第一步是在原有 `equipment` 表旁边创建新的 `playground` 表：
```
Table equipment
---------------
id INT
item_type STRING
installed_on DATETIME
city STRING
park STRING
playground INT


Table playground
----------------
id INT
city STRING
park STRING
sq_ft INT
```

接下来，客户端应用被更新，通过配置应用写入 Redis 服务器上以列表形式定义的 feature flag `DATABASE:equipment_location:write` 所返回的所有表，从而将任何新增的游乐场相关数据同时写入 `equipment` 表和 `playground` 表。在添加此变更的同时，他们还实现了另一个 feature flag，该 flag 会检查 `DATABASE:equipment_location:read` 的值，以决定从哪个数据源读取数据。

客户端代码变更后，最新的两条记录被同时记录在两个位置：

`equipment` 表：

| id | item_type        | installed_at | city      | park                  | playground |
|----|------------------|--------------|-----------|-----------------------|------------|
| 1  | "slide"          | 2018-12-30   | Westfield | Gloria Maynard Park   | 1          |
| 2  | "swing"          | 2016-05-07   | Westfield | Gloria Maynard Park   | 1          |
| 3  | "seesaw"         | 2012-08-18   | Westfield | Gloria Maynard Park   | 2          |
| 4  | "swing"          | 2015-02-17   | Westfield | Gloria Maynard Park   | 2          |
| 5  | "swing"          | 2019-04-02   | Westfield | Clear View Park       | 4          |
| 6  | "seesaw"         | 2017-08-03   | Westfield | Clear View Park       | 5          |
| 7  | "slide"          | 2014-07-03   | Fairmont  | Lincoln Woods         | 6          |
| 8  | "monkey bars"    | 2019-11-22   | Fairmont  | Lincoln Woods         | 6          |
| 9  | "merry-go-round" | 2018-07-28   | Fairmont  | Lincoln Woods         | 7          |
| 10 | "merry-go-round" | 2021-03-18   | Westfield | Clear View Park       | 4          |
| 11 | "swing"          | 2021-03-18   | Fairmont  | Lincoln Woods         | 6          |

`playground` 表：
| id | city        | park              | sq_ft |
|----|-------------|-------------------|-------|
| 4  | "Westfield" | "Clear View Park" | 200   |
| 6  | "Fairmont"  | "Lincoln Woods"   | 180   |

由于所有新数据都已同时写入两个位置，团队可以专注于将旧数据迁移到新结构。他们编写了一个脚本，从 equipment 表中提取现有记录来填充 playground 表。该脚本还引用外部数据源，为每个游乐场补全其面积（平方英尺）。最终得到的结果大致如下：

`equipment` 表：
| id | item_type        | installed_at | city      | park                | playground |
|----|------------------|--------------|-----------|---------------------|------------|
| 1  | "slide"          | 2018-12-30   | Westfield | Gloria Maynard Park | 1          |
| 2  | "swing"          | 2016-05-07   | Westfield | Gloria Maynard Park | 1          |
| 3  | "seesaw"         | 2012-08-18   | Westfield | Gloria Maynard Park | 2          |
| 4  | "swing"          | 2015-02-17   | Westfield | Gloria Maynard Park | 2          |
| 5  | "swing"          | 2019-04-02   | Westfield | Clear View Park     | 4          |
| 6  | "seesaw"         | 2017-08-03   | Westfield | Clear View Park     | 5          |
| 7  | "slide"          | 2014-07-03   | Fairmont  | Lincoln Woods       | 6          |
| 8  | "monkey bars"    | 2019-11-22   | Fairmont  | Lincoln Woods       | 6          |
| 9  | "merry-go-round" | 2018-07-28   | Fairmont  | Lincoln Woods       | 7          |
| 10 | "merry-go-round" | 2021-03-18   | Westfield | Clear View Park     | 4          |
| 11 | "swing"          | 2021-03-18   | Fairmont  | Lincoln Woods       | 6          |

`playground`表：
| id | city        | park                  | sq_ft |
|----|-------------|-----------------------|-------|
| 4  | "Westfield" | "Clear View Park"     | 200   |
| 6  | "Fairmont"  | "Lincoln Woods"       | 180   |
| 1  | "Westfield" | "Gloria Maynard Park" | 500   |
| 2  | "Westfield" | "Gloria Maynard Park" | 380   |
| 5  | "Westfield" | "Clear View Park"     | 850   |
| 7  | "Fairmont"  | "Lincoln Woods"       | 444   |

两张表现在都已同步。需要注意的是，新的 `playground` 表包含了 `equipment` 表中没有的信息（即 sq_ft 列）。如果此时回滚变更，你可以恢复到之前的表结构，但会丢失已采集的每个游乐场的面积数据。

当团队准备就绪后，他们在 Redis 服务器上把 `DATABASE:equipment_location:read` 变量的值改为从新 `playground` 表读取位置信息。客户端应用开始只从 `equipment` 表读取设备相关信息，并使用新的 `playground` 表来获取所有位置信息。

一旦确认一切运行正常，他们就可以修改 `DATABASE:equipment_location:write` 变量，将 `equipment` 表从写入目标列表中移除。最后，他们可以删除 `equipment` 表中的旧列，清理 schema，完成整个迁移。

`equipment` 表：
| id | item_type        | installed_at | playground |
|----|------------------|--------------|------------|
| 1  | "slide"          | 2018-12-30   | 1          |
| 2  | "swing"          | 2016-05-07   | 1          |
| 3  | "seesaw"         | 2012-08-18   | 2          |
| 4  | "swing"          | 2015-02-17   | 2          |
| 5  | "swing"          | 2019-04-02   | 4          |
| 6  | "seesaw"         | 2017-08-03   | 5          |
| 7  | "slide"          | 2014-07-03   | 6          |
| 8  | "monkey bars"    | 2019-11-22   | 6          |
| 9  | "merry-go-round" | 2018-07-28   | 7          |
| 10 | "merry-go-round" | 2021-03-18   | 4          |
| 11 | "swing"          | 2021-03-18   | 6          |

`playground` 表：
| id | city        | park                  | sq_ft |
|----|-------------|-----------------------|-------|
| 4  | "Westfield" | "Clear View Park"     | 200   |
| 6  | "Fairmont"  | "Lincoln Woods"       | 180   |
| 1  | "Westfield" | "Gloria Maynard Park" | 500   |
| 2  | "Westfield" | "Gloria Maynard Park" | 380   |
| 5  | "Westfield" | "Clear View Park"     | 850   |
| 7  | "Fairmont"  | "Lincoln Woods"       | 444   |

## 总结

在本问中，我们探讨了如何将扩展与收缩模式作为工具箱的一部分，安全地将数据库及其数据过渡到新的 schema。我们了解了该模式的运作方式及其带来的优势，最后通过一个示例展示了数据库变更在现实世界中是如何实施的。

扩展与收缩模式的核心价值在于“零停机”与“可回滚”：  
1. 零停机——新旧结构并存，读写切换分阶段完成，用户无感知。  
2. 可回滚——任何一步出错，都能迅速退回旧结构，把损失降到最低。  

只要遵循“先扩后收”的节奏：  
- 先加字段/表（扩），  
- 再双写双读，  
- 接着迁移历史数据，  
- 最后切流量、删旧字段（收），  

就能把一次高风险的“大爆炸”式迁移，拆成一系列低风险、可验证的小步骤。  
