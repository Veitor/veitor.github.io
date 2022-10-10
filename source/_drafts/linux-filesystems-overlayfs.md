---
title: 'Overlay Filesystem - 联合文件系统'
tags:
  - Linux
categories:
  - Linux
date: 2022-10-08 09:13:28
---

https://docs.kernel.org/filesystems/overlayfs.html#overlay-objects

# Overylay Filesystem

`overlay-filesystem` 有时也被称为 `union-filesystems`（联合文件系统），一个overlay-filesystem展示的是一个文件系统覆盖在另一个文件系统上的结果。

# Overlay对象

覆盖文件系统的方式是“混乱”的，因为在某个filesystem中的某个对象不总是显示为归属于该filesystem。在很多情况下，在联合文件系统中访问的某个对象难以与在原始文件系统中访问相应的对象进行区分。这通过[`stat(2)`](https://man7.org/linux/man-pages/man2/lstat.2.html)的`st_dev`字段看起来最为明显。

当对象为目录时将会从overlay-filesystem报告std_dev，当对象为非目录时会从提供对象的lower文件系统或upper文件系统报告std_dev信息。类似的，`st_ino`只有与`st_dev`相结合时才会变得唯一，而且非目录对象的这两个信息可以随着生命周期进行更改。许多应用和工具会忽略这些值且不受影响。

当所有的覆盖层覆盖了相同的底层文件系统时，这是一个特殊情况，所有的对象将从覆盖层文件系统报告`st_dev`、从底层文件系统报告`st_ino`。

# Upper和Lower

一个联合文件系统结合了两个文件系统 —— `upper`文件系统和`lower`文件系统。当一个名称在两个系统中都存在时，在`upper`文件系统的对象是可见的，然而在`lower`文件系统中的对象会被隐藏，当对象为目录时，将会与`upper`中的对象进行合并。

使用`directory tree(目录树)`而不是`filesystem（文件系统）`来指代`upper`和`lower`可能会更准确，因为两个目录树可能在同一个filesytem中，并且不需要为`upper`和`lower`提供文件系统的root根。

Linux所支持的大量文件系统可以是lower文件系统，但是并非所有由Linux挂载的文件系统都需要具有Overlay文件系统的特性来进行工作。lower文件系统不需要可写，lower文件系统甚至可以成为另一个overlay文件系统。upper文件系统通常是可写的，如果其是可写的，其必须支持`trusted.*`和/或者`user.*`扩展的属性的创建，并且在`readdir`响应中提供有效的`d_type`信息，因此`NFS`不适合这样的。

两个只读的filesystem的只读overlay覆盖层可以使用任意的文件系统类型。

# 目录

覆盖大多数时候涉及到目录。如果一个给定的名字出现在了`upper`和`lower`文件系统，并且指向了一个非目录，那么`lower`中的对象将被隐藏，该名称只指向`upper`中的对象。

当`upper`和`lower`对象都是目录时，则形成一个合并的目录。

在mount时，两个给定的目录将做为mount命令的选项`lowerdir`和`upperdir`，将这两个目录结合为一个合并目录（merged directory）：

```shell
mount -t overlay overlay -olowerdir=/lower,upperdir=/upper,workdir=/work /merged
```

参数`workdir`指定的位置需要是与`upperdir`在同一个文件系统上的空目录。

随后每一次对合并目录（merged directory）的查看搜寻，都将在每个实际的目录中进行，并且搜寻后的合并结果被缓存在属于联合文件系统（overlay filesystem）的[dentry](https://blog.csdn.net/u010039418/article/details/115254325)中。如果每个实际的查询都找到了目录，其都会被存储留下并且一个合并目录将被创建，否则只有其中一个被存储留下（要么是upper中的要么是lower中的）。

只有每个实际目录中name列表被合并，想metadata元信息、扩展的属性等只显示报告upper目录的，lower目录的这些信息将被隐藏。

# whiteout和opaque的目录

为了在不改变lower文件系统的情况下支持`rm`和`rmdir`命令，联合文件系统（overlay filesystem）需要在upper文件系统中记录被删除的文件。这通过使用whiteout和opaque的目录来完成（非目录总是opaque）。

一个whiteout将被创建为`字符设备(character device)`，并带有`0/0`设备号。当一个whiteout在合并目录的upper层发现，任何在lower层匹配的名称都将被忽略，并且whiteout其自己也是隐藏不可见的。

一个目录通过设置xattr`"trusted.overlay.opaque"`为`y`来使其变为`opaque`。upper文件系统中包含opaque目录的位置，在lower文件系统中该位置带有相同名称的目录将被忽略。