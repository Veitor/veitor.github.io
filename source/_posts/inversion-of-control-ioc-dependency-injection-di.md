---
title: '了解控制反转（IoC）和依赖注入（DI）'
tags:
  - 设计模式
categories:
  - 设计模式
date: 2025-12-02 14:43:39
---

## IOC

Inversion of Control（IoC）是一种设计原则，它将程序对象或部分程序的控制权转移到外部容器或框架中。

- 控制反转（IoC）是一种设计原则`Principle`（尽管一些人将其称为一种模式`Pattern`）。
- 顾名思义，在面向对象设计中，IoC被用于反转不同类型的控制权，以实现松耦合。这里的`控制权`指的是除了类本身主要职责以外的其他职责。
- 这些职责即所说的权力，包括：
    - 对应用程序执行流的控制权
    - 对对象创建、依赖的管理、生命周期的控制权
- IoC 是一种设计原则，它将程序执行流的控制权从程序自身转移到外部框架或容器中。不再是你的代码主动发起调用，而是你的代码被调用。
- 用通俗的话来解释：假设你平时自己开车去上班，这意味着你掌控着汽车。而 IoC 原则建议“反转”这种控制权——与其自己开车，不如叫一辆出租车，由司机来驾驶。于是，控制权就从你转移到了出租车司机身上。你无需亲自驾驶，可以把精力放在自己的主要工作上。
- IoC 原则有助于设计松耦合的类，使它们更易测试、可维护和可扩展。

### 现实类比：

想象一下你在一家餐厅里：
1. 传统控制（无 IoC）：你亲自走进厨房，取来食材，自己做饭并端上桌。整个过程的每一步都由你掌控。
2. 控制反转：你坐在餐桌旁点餐，餐厅负责一切。你把做饭的控制权交给了餐厅，只需通过菜单表达你想要什么，剩下的由餐厅处理。

下面是一个没有使用 IoC 的简单技术示例：
```java
class UserService {
    private DatabaseConnection dbConnection;
    private EmailService emailService;
    
    public UserService() {
        // Class creates its own dependencies
        this.dbConnection = new MySQLConnection();
        this.emailService = new EmailService();
    }
    
    public void registerUser(String username) {
        dbConnection.save(username);
        emailService.sendWelcomeEmail(username);
    }
}
```
在这示例中，`UserService`类负责创建和管理其依赖项（`DatabaseConnection`和`EmailService`）的生命周期。

使用了IoC后：

```java
class UserService {
    private DatabaseConnection dbConnection;
    private EmailService emailService;
    
    // Dependencies are provided from outside
    public UserService(DatabaseConnection dbConnection, EmailService emailService) {
        this.dbConnection = dbConnection;
        this.emailService = emailService;
    }
    
    public void registerUser(String username) {
        dbConnection.save(username);
        emailService.sendWelcomeEmail(username);
    }
}
```
这样做的优势：
- 将任务的执行与其具体实现解耦
- 在不同实现之间切换更加容易
- 提升程序的模块化程度
- 通过隔离组件或模拟其依赖，使程序测试更加便捷，同时让组件通过契约进行通信

## IoC的具体模式

接下来看一下控制反转（IoC）的主要模式。虽然依赖注入是最常被提及的，但还有其他几种重要的模式：

### Dependency Injection (DI)

依赖注入（DI）是 IoC 的一种具体实现形式，它把依赖“注入”到类中，而不是由类自己创建。可以把它理解为：

- IoC 是`Principle`原则（“是什么”）
- DI 是`Pattern`模式（“怎么做”）

让我们再用一个现实类比来说明：

**传统方式（没有使用DI）：**

```java
class Car {
    private Engine engine;
    
    public Car() {
        // Car creates its own engine
        engine = new Engine();
    }
}
```
这就像一辆车自己制造发动机，耦合紧密且缺乏灵活性。

**使用了依赖注入：**

```java
class Car {
    private Engine engine;
    
    // Engine is injected from outside
    public Car(Engine engine) {
        this.engine = engine;
    }
}
```
这就像汽车装配线，在组装过程中发动机由外部提供给汽车。

**真实世界中的设计模式示例**

让我们来看一个更完整的示例，使用 Spring Framework 的概念：

```java
// Interface defining a payment processor
interface PaymentProcessor {
    void processPayment(double amount);
}

// Different implementations
class CreditCardProcessor implements PaymentProcessor {
    public void processPayment(double amount) {
        System.out.println("Processing " + amount + " via Credit Card");
    }
}

class PayPalProcessor implements PaymentProcessor {
    public void processPayment(double amount) {
        System.out.println("Processing " + amount + " via PayPal");
    }
}

// Service using payment processor
class OrderService {
    private PaymentProcessor paymentProcessor;
    
    // Constructor injection
    public OrderService(PaymentProcessor paymentProcessor) {
        this.paymentProcessor = paymentProcessor;
    }
    
    public void placeOrder(double amount) {
        // Business logic
        paymentProcessor.processPayment(amount);
    }
}

// Using with Spring Framework
@Configuration
class AppConfig {
    @Bean
    public PaymentProcessor paymentProcessor() {
        return new CreditCardProcessor();
    }
    
    @Bean
    public OrderService orderService(PaymentProcessor processor) {
        return new OrderService(processor);
    }
}
```
这种方式的好处：
- 松耦合：`OrderService` 无需知道它使用的是哪种支付处理器，只需要知道支付处理器实现了 `PaymentProcessor` 接口。
- 可测试性：便于在测试时模拟依赖项，如 `PaymentProcessor`，以确保 `OrderService` 的行为符合预期。
- 灵活性：无需修改 `OrderService` 即可切换实现，例如从 `CreditCardProcessor` 切换到 `PayPalProcessor`。
- 可维护性：依赖关系显式且集中管理，使代码更易于理解和维护。

### 模板方法模式（Template Method Pattern）

这是 IoC 最早的形式之一。程序逻辑的执行流不再由子类控制，而是由父类掌控。

```java
// Base template class
abstract class DataMiner {
    // Template method - controls the algorithm flow
    public final void mine() {
        openFile();
        extractData();
        parseData();
        analyzeData();
        sendReport();
        closeFile();
    }

    // Some concrete methods
    private void openFile() {
        System.out.println("Opening file...");
    }
    
    // Abstract methods to be implemented by subclasses
    abstract void extractData();
    abstract void parseData();
    
    // More concrete methods
    private void analyzeData() {
        System.out.println("Analyzing data...");
    }
}

// Implementation class
class PDFDataMiner extends DataMiner {
    void extractData() {
        System.out.println("Extracting data from PDF...");
    }
    
    void parseData() {
        System.out.println("Parsing PDF data...");
    }
}
```

### 策略模式（Strategy Pattern）

该模式允许在运行时通过传递不同的策略来切换行为：

```java
// Strategy interface
interface SortStrategy {
    void sort(int[] array);
}

// Concrete strategies
class QuickSort implements SortStrategy {
    public void sort(int[] array) {
        System.out.println("Sorting using QuickSort");
    }
}

class MergeSort implements SortStrategy {
    public void sort(int[] array) {
        System.out.println("Sorting using MergeSort");
    }
}

// Context class using the strategy
class Sorter {
    private SortStrategy strategy;
    
    public void setStrategy(SortStrategy strategy) {
        this.strategy = strategy;
    }
    
    public void performSort(int[] array) {
        strategy.sort(array);
    }
}
```

### 服务定位器模式（Service Locator Pattern）

该模式提供了一个中央式的服务注册表：

```java
class ServiceLocator {
    private static Map<String, Object> services = new HashMap<>();
    
    public static void register(String name, Object service) {
        services.put(name, service);
    }
    
    public static Object getService(String name) {
        return services.get(name);
    }
}

// Usage
class PaymentProcessor {
    public void processPayment() {
        // Get logger service from locator instead of creating it
        Logger logger = (Logger) ServiceLocator.getService("logger");
        logger.log("Processing payment...");
    }
}
```

### 事件驱动模式（Event-Driven Pattern）

通过事件处理器和监听器实现控制反转：

```java
// Event class
class UserEvent {
    private String type;
    private User user;
    
    // constructor and getters
}

// Event listener interface
interface UserEventListener {
    void onUserEvent(UserEvent event);
}

// Event publisher
class UserManager {
    private List<UserEventListener> listeners = new ArrayList<>();
    
    public void addListener(UserEventListener listener) {
        listeners.add(listener);
    }
    
    public void createUser(User user) {
        // Business logic...
        
        // Notify listeners
        UserEvent event = new UserEvent("CREATE", user);
        listeners.forEach(listener -> listener.onUserEvent(event));
    }
}
```

### 工厂模式（Factory Pattern）

对象创建的控制权被反转给了工厂：

```java
interface Animal {
    void makeSound();
}

class Dog implements Animal {
    public void makeSound() {
        System.out.println("Woof!");
    }
}

class Cat implements Animal {
    public void makeSound() {
        System.out.println("Meow!");
    }
}

class AnimalFactory {
    public Animal createAnimal(String type) {
        switch(type.toLowerCase()) {
            case "dog": return new Dog();
            case "cat": return new Cat();
            default: throw new IllegalArgumentException("Unknown animal type");
        }
    }
}
```

### 观察者模式（Observer Pattern）

类似于事件驱动编程，但更关注状态变化：

```java
interface Observer {
    void update(String message);
}

class NewsAgency {
    private List<Observer> observers = new ArrayList<>();
    
    public void addObserver(Observer observer) {
        observers.add(observer);
    }
    
    public void notifyObservers(String news) {
        observers.forEach(observer -> observer.update(news));
    }
}

class NewsChannel implements Observer {
    public void update(String news) {
        System.out.println("Breaking News: " + news);
    }
}
```

这些IoC模式的不同之处：

- **控制反转的作用范围不同：**
    - **DI**反转了依赖的创建与绑定
    - **模板方法模式**反转了程序流程的控制
    - **服务定位器模式**反转了服务的发现
    - **事件驱动模式**通过事件反转了流程控制
    - **工厂模式**反转了对象的创建
    - **观察者模式**反转了通知的流程
- **使用的时机不同：**
    - **依赖注入（DI）**：当你希望实现松耦合且更易于测试时
    - **模板方法模式**：当你拥有一个不变算法但某些步骤可变时
    - **服务定位器模式**：当你需要集中式服务管理时
    - **事件驱动模式**：当你需要在事件生产者与消费者之间实现松耦合时
    - **工厂模式**：当对象创建逻辑应集中管理时
    - **观察者模式**：当你需要一对多的依赖关系时

每种模式都服务于不同的目的，并且可以在同一个应用程序中组合使用。具体选择取决于你的实际需求以及所要解决的问题。

## IoC 与 DI 的关键区别：

**作用范围:**

- IoC 是更广泛的原则  
- DI 是 IoC 的一种具体实现方式

**目的:**

- IoC 关注谁掌控程序流程
- DI 关注依赖如何被提供

**实现方式:**

- IoC 可以通过多种方式实现（依赖注入、服务定位器、事件驱动编程）
- DI 专门关注对象如何接收其依赖

## 使用 IoC 和 DI 模式将高耦合类转化为松耦合类

图片展示了一个包含 4 个步骤的转换过程：

1. 从高耦合的类开始  
2. 使用工厂模式实现 IoC  
3. 通过创建抽象实现 DIP（依赖倒置原则）  
4. 使用 IoC 容器实现 DI，结果：松耦合的类  

让我们用一个实际例子来实现它：

### 步骤1：高耦合的类

```java
// This is the initial tightly coupled implementation
class EmailService {
    public void sendEmail(String to, String message) {
        // Email sending logic
        System.out.println("Sending email to " + to + ": " + message);
    }
}

class UserService {
    // Tightly coupled - UserService creates its own EmailService
    private EmailService emailService = new EmailService();
    
    public void registerUser(String email) {
        // Registration logic
        emailService.sendEmail(email, "Welcome to our service!");
    }
}
```

### 步骤2：使用工厂模式实现

```java
// Create a factory to handle object creation
class ServiceFactory {
    public static EmailService createEmailService() {
        return new EmailService();
    }
    
    public static UserService createUserService() {
        EmailService emailService = createEmailService();
        return new UserService(emailService);
    }
}

// Modified UserService to accept EmailService
class UserService {
    private EmailService emailService;
    
    public UserService(EmailService emailService) {
        this.emailService = emailService;
    }
    
    public void registerUser(String email) {
        // Registration logic
        emailService.sendEmail(email, "Welcome to our service!");
    }
}
```

### 步骤3：通过创建抽象层实现DIP

```java
// Create interfaces (abstractions)
interface MessageService {
    void sendMessage(String to, String message);
}

interface UserManagement {
    void registerUser(String email);
}

// Implement interfaces
class EmailService implements MessageService {
    @Override
    public void sendMessage(String to, String message) {
        System.out.println("Sending email to " + to + ": " + message);
    }
}

class UserService implements UserManagement {
    private final MessageService messageService;
    
    public UserService(MessageService messageService) {
        this.messageService = messageService;
    }
    
    @Override
    public void registerUser(String email) {
        // Registration logic
        messageService.sendMessage(email, "Welcome to our service!");
    }
}
```

### 步骤4：使用IoC容器实现DI

```java
// Simple IoC Container
class IoCContainer {
    private Map<Class<?>, Object> container = new HashMap<>();
    
    public void register(Class<?> type, Object implementation) {
        container.put(type, implementation);
    }
    
    @SuppressWarnings("unchecked")
    public <T> T resolve(Class<T> type) {
        return (T) container.get(type);
    }
}

// Configuration class to set up dependencies
class ApplicationConfig {
    private IoCContainer container;
    
    public ApplicationConfig() {
        container = new IoCContainer();
        setupContainer();
    }
    
    private void setupContainer() {
        // Register implementations
        container.register(MessageService.class, new EmailService());
        container.register(UserManagement.class, 
            new UserService(container.resolve(MessageService.class)));
    }
    
    public IoCContainer getContainer() {
        return container;
    }
}
```

### 最终结果：松耦合的类

```java
public class Application {
    public static void main(String[] args) {
        // Set up IoC container
        ApplicationConfig config = new ApplicationConfig();
        IoCContainer container = config.getContainer();
        
        // Get service from container
        UserManagement userService = container.resolve(UserManagement.class);
        
        // Use service
        userService.registerUser("user@example.com");
    }
}
```

这种实现展示了几个关键优势：

1. **松耦合：** 类依赖于抽象而不是具体实现
2. **灵活性：** 易于切换实现（例如，从 EmailService 切换到 SMSService）
3. **可测试性：** 便于在测试时模拟依赖项
4. **可维护性：** 依赖关系明确且集中管理
5. **可扩展性：** 无需修改现有代码即可轻松添加新的实现

消息服务方式实现的一个示例：

```java
class SMSService implements MessageService {
    @Override
    public void sendMessage(String to, String message) {
        System.out.println("Sending SMS to " + to + ": " + message);
    }
}

// To use SMS instead of email, just update the container registration:
container.register(MessageService.class, new SMSService());
```

这一转换过程展示了如何按照图中所述步骤，利用 IoC 和 DI 模式将高耦合系统转变为松耦合系统。最终结果比原始实现更加灵活且易于维护。

## DIP vs IoC

### 依赖倒置原则（DIP）

DIP是一种设计原则（SOLID中的D），其声明了：

1. 高层模块不应该依赖低层模块，二者都应该依赖抽象。
2. 抽象不应该依赖细节，细节应该依赖抽象。

### 控制反转（IoC）

IoC 是一种设计原则，它将程序的控制流程反转：不再由程序员控制流程，而是由框架来控制。

让我们通过一个示例来理解一下DIP：

```java
// Without DIP - Violating the principle
class PaymentProcessor {
    // Directly depends on concrete class
    private StripePaymentGateway paymentGateway = new StripePaymentGateway();
    
    public void processPayment(double amount) {
        paymentGateway.charge(amount);
    }
}

class StripePaymentGateway {
    public void charge(double amount) {
        // Stripe specific implementation
    }
}
```
```java
// With DIP - Following the principle
interface PaymentGateway {
    void charge(double amount);
}

class PaymentProcessor {
    // Depends on abstraction
    private PaymentGateway paymentGateway;
    
    public PaymentProcessor(PaymentGateway paymentGateway) {
        this.paymentGateway = paymentGateway;
    }
    
    public void processPayment(double amount) {
        paymentGateway.charge(amount);
    }
}

class StripePaymentGateway implements PaymentGateway {
    @Override
    public void charge(double amount) {
        // Stripe specific implementation
    }
}

class PayPalPaymentGateway implements PaymentGateway {
    @Override
    public void charge(double amount) {
        // PayPal specific implementation
    }
}
```
再理解一下IoC：

```java
// Without IoC - Traditional control flow
class OrderService {
    public void placeOrder() {
        // Service controls the flow
        validateOrder();
        processPayment();
        updateInventory();
        sendNotification();
    }
    
    private void validateOrder() { /* ... */ }
    private void processPayment() { /* ... */ }
    private void updateInventory() { /* ... */ }
    private void sendNotification() { /* ... */ }
}

// With IoC (using Spring Framework)
@Service
class OrderService {
    @Transactional
    public void placeOrder() {
        // Framework controls the flow
        // - Transaction management
        // - Exception handling
        // - Logging
        // - Security
        processOrder();
    }
}
```
### 关键区别

**目的：**
- DIP：专注于减少对具体实现的依赖
- IoC：专注于谁控制程序流程

**范围：**
- DIP：关于依赖关系的设计原则
- IoC：关于流程控制的设计原则

**实现方式：**
- DIP：通过接口和抽象实现
- IoC：通过框架和容器实现

**现实世界类比：**

**DIP：**

```java
// Without DIP (Like building your own car from scratch)
class Car {
    private Engine engine = new V8Engine();  // Concrete dependency
}

// With DIP (Like getting a car with swappable engines)
interface Engine { }
class Car {
    private Engine engine;  // Abstract dependency
}
```

**IoC：**

```java
// Without IoC (Like manually driving a car)
class Driver {
    public void drive() {
        startEngine();
        changeGear();
        pressAccelerator();
    }
}

// With IoC (Like using a self-driving car)
@AutoDrive
class Car {
    public void reachDestination() {
        // Framework handles driving operations
    }
}
```

**常见用例：**

```java
// Combining DIP and IoC in Spring Framework
@Service
class OrderProcessor {
    private final PaymentGateway paymentGateway;  // DIP
    
    @Autowired  // IoC
    public OrderProcessor(PaymentGateway paymentGateway) {
        this.paymentGateway = paymentGateway;
    }
    
    @Transactional  // IoC
    public void processOrder(Order order) {
        paymentGateway.charge(order.getAmount());
    }
}
```

### 总结

- DIP 关注通过抽象来组织代码依赖
- IoC 关注由谁掌控程序流程
- 二者常协同工作，但目的不同
- DIP 是有效实现 IoC 的前提
- Spring 等现代框架同时运用这两条原则

主要的困惑往往源于两者都涉及“反转”，但它们反转的是软件设计中的不同方面：DIP 反转的是依赖关系，而 IoC 反转的是控制流。
