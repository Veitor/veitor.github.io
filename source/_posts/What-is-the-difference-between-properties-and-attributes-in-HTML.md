---
title: 'HTML中的properties和attributes有什么区别？'
tags:
  - 前端
categories:
  - 前端
date: 2020-06-23 08:53:24
---

当写HTML代码时，你可以在你的HTML元素中定义`attributes`，然后浏览器解析你的代码并创建一个对应的`DOM`节点。这个节点是一个`Object`，因此它具有`properties`。

<!-- more -->

例如这是一个HTML元素：

```html
<input type="text" value="Name:">
```
其拥有2个`attributes`(`type`和`value`)

浏览器解析这个代码之后，一个[HTMLInputElement](https://developer.mozilla.org/en-US/docs/Web/API/HTMLInputElement)对象将会被创建，这个对象包含了很多的`properties`，如：accept, accessKey, align, alt, attributes, autofocus, baseURI, checked, childElementCount, childNodes, children, classList, className, clientHeight等。

对于DOM节点对象，properties就是这个对象的properties，而attributes是这个对象中名为`attributes`的property的元素。

当一个HTML元素被创建为DOM节点后，节点对象的许多properties与HTML元素中相同名称或相似名称的attributes有着关联，但不是一对一的关系。例如这个HTML元素：

```html
<input id="the-input" type="text" value="Name:">
```

对应的DOM节点对象具有`id`,`type`和`value` 这几个properties：

- `id` property对于`id` attribute来说是一个反射的property：获取property会读取attribute的值，设置property会写入attribute的值。`id`是一个纯粹的反射的property，它不会修改和限制这个值。

- `type` property对于`type` attribute来说是一个反射的property：获取property会读取attribute的值，设置property会写入attribute的值。`type`不是一个纯粹的反射的property，因为它被已知的值（如一个有效的input类型）限制了。如果你这么写`<input type="foo">`，则`theInPut.getAttribute("type")`将会返回给你`foo`，但`theInput.type`返回给你`"text"`

- 相反的，`value` property不会反射 `value` attribute。而它就是输入框的当前值。当用户手动改变输入框中的值时，`value` proerty将会反射这个改变，因此如果用户输入`John`到输入框中：

```javascript
theInput.value //returns "John"
```
而
```javascript
theInput.getAttribute('value')//returns "Name:"
```

`value` property反射输入框中当前的文本内容，而`value`attribute包含了HTML代码中`value` attribute的`初始`的文本内容。

如果你想要知道当前输入框中是什么内容，那就读取property。如果你想要知道文本框的初始内容是什么，则读取attribute。或者你可以使用`defaultValue` property，它是`value` attribute纯粹的反射：

```javascript
theInput.value                 // returns "John"
theInput.getAttribute('value') // returns "Name:"
theInput.defaultValue          // returns "Name:"
```

有些properties可以直接反射attribute（rel,id），有些直接反射但名称会略有不同（`htmlFor`反射了`for` attribute，`className`反射了`class` attribute），有些反射了它们的attribute但有一些限制(src,href,disabled,multiple)等等。[这个文档](https://www.w3.org/TR/html5/infrastructure.html#reflect)说明了各种的反射类型。


> 原文：https://stackoverflow.com/questions/6003819/what-is-the-difference-between-properties-and-attributes-in-html