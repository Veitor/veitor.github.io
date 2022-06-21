---
title: 'JDK、JRE和JVM的区别'
categories:
- 计算机基础
  date: 2022-02-01 14:11:13
---

JDK（Java Deveplopment Kit）是一个用于开发java应用程序的软件开发环境。它包含了JRE（Java Runtime Environment）、解释器/加载器(Java)、编译器（javac）、打包模块(jar)、文档生成器（Javadoc）和其他java开发中所需要的工具。

`JRE`全称为`Java Runtime Environment`，并且也可以被写为`Jave RTE`。JRE为执行java程序提供了最小化的前提要求，它由Jave虚拟机（`JVM`）、核心类等组成。

下面来看一下JVM

- Java虚拟机有一个运行**规范**，该规范的实现由Sun公司和其他公司来完成，并且各公司可以各自选择实现算法。

- JVM是一个满足了JVM规范要求的计算机程序。

- 每当在命令行中运行java程序时，一个JVM实例将会被创建。

![pic](https://media.geeksforgeeks.org/wp-content/uploads/20210218150010/JDK.png)

1. JDK（Java Development Kis）是一个提供了开发和运行Java程序环境的工具套件，其包含了两个东西：
    - 开发工具（为你开发java程序提供了环境）
    - JRE（来运行你的java程序）

2. JRE（Java Runtime Environment）仅仅是为了提供在机器上**运行**（不是**开发**）java程序的一个安装包，其仅供那些只想要运行Java程序的用户所使用。

3. JVM（Java Virtual Machine）是`JDK`和`JRE`非常重要的部分，因为它被包含或内置在了两者之中。无论你使用JRE还是JDK来运行Java程序，都会使用到JVM，JVM负责逐行执行java程序，因此它也被称为`解释器`(interpreter)。

JRE的组件有：

1. 部署相关的如`deployment`、`Java Web Start`、`Java Plug-in`
2. 用户接口工具套件（User Interface ToolKits），如`Abstract Window Toolkit (AWT)`、` Swing`、` Java 2D`、` Accessibility`、` Image I/O`、` Print Service`、` Sound`、` drag`、`drop (DnD)`等。
3. 集成库，如 `Interface Definition Language (IDL)`、` Java Database Connectivity (JDBC)`、` Java Naming and Directory Interface (JNDI)`、` Remote Method Invocation (RMI)`、` Remote Method Invocation Over Internet Inter-Orb Protocol (RMI-IIOP)`等。
4. 其他的基本库，如`international support`、` input/output (I/O)`、` extension mechanism`、` Beans`、` Java Management Extensions (JMX)`、` Java Native Interface (JNI)`、` Math`、` Networking`、` Override Mechanism`、` Security`、` Serialization`、` Java for XML Processing (XML JAXP)`等。
5. 语言和通用的基础库，如`lang and util`、` management`、` versioning`、` zip`、` instrument`、` reflection`、` Collections`、` Concurrency Utilities`、` Java Archive (JAR)`、` Logging`、` Preferences API`、` Ref Objects`、`Regular Expressions`等。
6. Java虚拟机，如`Java HotSpot Client`和`Server Virual Machine`。

在了解了JRE的这些组件之后，现在我们来看JRE的工作原理，理解JRE是如何工作的。

假设Java源码为`Example.java`，其文件被编译成了一组字节码被存储在了`.class`文件中，这里是`Example.class`。

![](https://media.geeksforgeeks.org/wp-content/uploads/JRE_JDK_JVM.jpg)

下面的行为发生在运行时：

- 类加载器
- 字节码验证器
- 解释器
  - 执行字节码
  - 对底层硬件进行适当的调用
  
再来了解一下JVM如何工作的：

JVM在Java程序运行时成为JRE的一个实例，它是一个运行时解释器。它主要负责下面三个事情：

1. 加载（Loading）
2. 链接（Linking）
3. 初始化（Initialization）

让我们再回来看JRE：

- JVM充当了运行Jave程序的运行时引擎，JVM实际上调用了Java程序中的main方法。JVM是JRE的一部分。
- Java应用程序被称为WORA（Write Once Run Anywhere）。这意味着程序员可以在一个系统上开发java代码，并可以期望它在任何其他支持Java的系统上运行，而无需进行任何调整，这是因为JVM的原因。
- 当我们编译`.java`文件时，Java编译器生成的`.class`文件名（包含了字节码）与`.java`文件中的class类名相同。当我们运行`.class`文件时，其会参与到JVM的各个步骤环节中。

![](https://media.geeksforgeeks.org/wp-content/uploads/jvm-3.jpg)

