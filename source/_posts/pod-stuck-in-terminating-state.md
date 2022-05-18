---
title: Pod长时间处于Terminating状态的问题
tags:
  - Kubernetes
categories:
  - Kubernetes
date: 2022-05-18 11:33:00
---

问题描述
---

当一个Pod被执行删除操作后，却长时间的处于`Terminating`状态，发生这样的情况可能是因为：

- Pod有一个与其关联的`finalizer`，这个`finalizer`的任务没有完成。
- Pod对中断信号没有响应

当我们执行`kubectl get pods`命令时，你将会看到这样的信息：

```shell
NAME                     READY     STATUS             RESTARTS   AGE
nginx-7ef9efa7cd-qasd2   1/1       Terminating        0          1h
```

排查和处理步骤
---

#### 1. 收集一些信息

```shell
kubectl get pod -n [NAMESPACE] -p [POD_NAME] -o yaml
```

#### 2. 检查finalizer

首先我们需要先查看pod有没有关联的finalizer，如果有关联的finalizer，那么很可能就是finalizer的问题。

获取并查看pod的配置信息：

```shell
kubectl get pod -n [NAMESPACE] -p [POD_NAME] -o yaml > /tmp.txt
```

然后在`/tmp.txt`内容中查找`metadata`配置块下是否有`finalizer`字段，如果有，则采用[解决方案A](#方案A：移除finalizer)

#### 3. 检查node的状态

也可能是pod所在的node节点因为一些原因而导致的问题。

如果你从`/tmp.txt`内容中发现某个node节点上的所有pod都处于`Terminating`状态，那么就是该node节点的问题。

#### 4. 尝试删除pod

pod没有被终止可能是进程对信号没有响应，具体的原因需要结合具体的应用和上下文来看。通常可能包括：

- 在执行的用户空间代码中存在对中断信号无响应`tight loop`循环

- 在应用运行时（runtime）的一个维护过程（例如垃圾回收）

在这种情况下，采用[解决方案B](#方案B：强行删除Pod)可能行的通

#### 5. 重启kubelet

如果其他方法都不起作用，则尝试在pod运行的node节点上重启kubelet。见[解决方案C](#方案C：重启kubelet)

解决方案
---

#### 方案A：移除finalizer

从对应的pod上移除其所有的finalizer：

```shell
kubectl patch pod [POD_NAME] -p '{"metadata":{"finalizers":null}}'
```

#### 方案B：强行删除Pod

请注意，这是一个变通的方法，而不是一个有效的解决方案，目前网上大多数文章都优先推荐了该方法。在执行该方法时应该谨慎小心，注意确保不会产生额外的其他问题。关于强行删除StatefulSet的Pod的信息请见[这里](https://kubernetes.io/docs/tasks/run-application/force-delete-stateful-set-pod/)

```shell
kubectl delete pod --grace-period=0 --force --namespace [NAMESPACE] [POD_NAME]
```

#### 方案C：重启kubelet

如果你可以通过ssh连接登录到node节点，则可以将节点上的kubelet进程重启，如果你没有这权限，那么就需要相关有权限的人来操作。

在你重启kubelet之前，最好检查一下kubelet日志来确认一下是否有异常问题。

#### 验证结果

如果当执行`kubectl get pods`再也没显示刚才处于Terminating的Pod，则说明该问题处理完成了。

```shell
$ kubectl get pod -n mynamespace -p nginx-7ef9efa7cd-qasd2
NAME                     READY     STATUS             RESTARTS   AGE
```


进一步处理和探究
---

#### 1. 检查确认finalizer的工作任务是否需要被执行完成才会好

这需要看finalizer都做些哪些工作任务来判断，通常finalizer的任务未完成可能是因为与Volume有关的任务。

#### 2. 确定根本原因

这也是需要看finalizer都做些什么任务来判断的，并且还需要一些特定上下文的信息。如果你有访问node节点的权限，检查一下kubelet的日志，控制器会在里面记录一些有用的信息供你排查。

相关参考信息
---

- [Finalizers](https://kubernetes.io/docs/tasks/access-kubernetes-api/custom-resources/custom-resource-definitions/#finalizers)
- [Container Lifecycle Hooks](https://kubernetes.io/docs/concepts/containers/container-lifecycle-hooks/)
- [Termination of Pods](https://kubernetes.io/docs/concepts/workloads/pods/pod/#termination-of-pods)
- [Unofficial Kubernetes Pod Termination](https://unofficial-kubernetes.readthedocs.io/en/latest/concepts/abstractions/pod-termination/)
- [Kubelet logs](https://kubernetes.io/docs/tasks/debug-application-cluster/debug-cluster/#looking-at-logs)