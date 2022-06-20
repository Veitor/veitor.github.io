---
title: 了解PHP设计模式之观察者模式
tags:
  - 设计模式
url: 91.html
id: 91
categories:
  - PHP
  - 设计模式
date: 2014-05-11 04:22:54
---

观察者模式是一种事件系统，意味着这一模式允许某个类观察另一个类的状态，当被观察的类状态发生改变的时候，观察类可以收到通知并且做出相应的动作，观察者模式提供了避免组件之间紧密耦合的另一种方式。

在观察者模式中，被观察者称为subject,观察者称为observer,为了表达这些内容，SPL（Standard PHP Libaray）提供了SplSubject(被观察者)和SplObserver(观察者)两个接口。在编写观察者模式时，只要实现这两个接口即可。接口如下：

```php
 //被观察者接口
interface SplSubject{
   public function attach(SplObserver $observer);//注册观察者（注册的观察者：当我（被观察者）的某个状态改变时，需要通知的对象）
   public function detach(SplObserver $observer);//释放观察者
   public function notify();//通知所有注册的观察者的方法
}
  //观察者接口
  interface SplObserver{
   public function update(SplSubject $subject);//观察者进行更新状态
  }
```

<!-- more -->

这一模式的概念是SplSubject类维护了一个特定状态，当这个状态发生变化时，它就会调用notify()方法。调用notify()方法时，所有之前使用attach()方法注册的SplObserver实例的update方法都会被调用。 以下是实现代码：

```php
  <?php
//被观察者实现类
class DemoSubject implements SplSubject {
  private $observers;    //存放观察者的类
  private $value;
  public function __construct() {
    $this->observers = array();
  }
//注册观察者
  public function attach(SplObserver $observer) {
    $this->observers\[\] = $observer;
  }
 //释放观察者
  public function detach(SplObserver $observer) {
    if($idx = array_search($observer,$this->observers,true)) {
      unset($this->observers\[$idx\]);
    }
  }
 //通知所有观察者，执行观察者类中的update方法
  public function notify() {
    foreach($this->observers as $observer) {
      $observer->update($this);
    }
  }
/*设置状态，当状态发生任何变化时，都会调用notify方法通知所有的观察者，即调用观察者类中的update方法*/
  public function setState($value) {
    $this->value = $value;
    $this->notify();
  }
//
  public function getValue() {
    return $this->value;
  }
}
//观察者简单类
class DemoObserver implements SplObserver {
  //接收被观察者发送的通知
  public function update(SplSubject $subject) {
    echo 'The new value is '. $subject->getValue();
  }
}
$subject = new DemoSubject();//初始化被观察者
$observer = new DemoObserver();//初始化一个观察者
$subject->attach($observer);//添加一个观察者
$subject->setState(5);//被观察者修改状态。
?>;
```

输出结果为： The new value is 5 观察者模式的优点在于，挂接到被观察者上的观察者可多可少，并且不需要提前知道哪个观察者会响应被观察者发出的响应事件。 这种设计模式在很多PHP框架中都被使用到，如Yii等。