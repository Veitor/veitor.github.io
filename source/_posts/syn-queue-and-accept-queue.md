---
title: 'SYN Queue和Accept Queue'
tags:
  - linux
categories:
  - Linux
date: 2020-07-01 11:22:06
---

## 一个Queue还是两个Queue

IPC/IP栈对一个处于`LISTEN`状态的socket有两种实现backlog queue的方式。

<!-- more -->

### 一个Queue

一个Queue能够包含两种状态的Connections：

- SYN RECEIVED
- ESTABLISHED

只有`ESTABLISHED`状态的Connection才能被应用通过syscall `accept()`方法获取到。

因此，该队列的长度由`listen()`的参数`backlog`决定。

### 一个SYN Queue 和 一个Accept Queue

这种情况下，处于`SYN RECEIVED`状态的connection将会被添加到SYN queue，然后当连接状态变成`ESTABLISHED`时再把其移动到`Accept queue`中。

因此，`Accept queue`只存储等待`accept()`调用的connection。

不像前一个示例，`linsten()` syscall的参数`backlog`此时决定了`Accept queue`的大小。

### BSD

BSD选择了一个queue作为了它的实现（尽管事实上它内部使用了两个queue）。

当queue满时，它会简单的丢弃SYN包，并让客户端重试，而不会向接收到的SYN包发送SYN/ACK包。

### Linux

从Linux 2.2起，Linux使用了两个queue：

- `backlog`表示`Accept queue`的最大长度
- `/proc/sys/net/ipv4/tcp_max_syn_backlog`表示`SYN queue`的最大长度；新内核使用的是`/proc/sys/net/core/somaxconn`（也叫`net.core.somaxconn`）

![](http://kingsamchen.github.io/img/syn-and-accept-queues.png)

从客户端的角度来看，一个connection在接收到`SYN/ACK`包后，其状态就成为了`ESTABLISHED`。

## 当SYN Queue满了

当接收到一个SYN包但SYN Queue满时：

- 若设置 `net.ipv4.tcp_syncookies = 0` ，则直接丢弃当前 SYN 包；
- 若设置 `net.ipv4.tcp_syncookies = 1` ，则令 `want_cookie = 1` 继续后面的处理；
    - 若 `Accept queue` 已满，并且 `qlen_young` 的值大于 1 ，则直接丢弃当前 SYN 包。`req_young_len`是`SYN Queue`中还没有重新发送的`SYN/ACK`包的连接数。
    - 若 `Accept queue` 未满，或者 `qlen_young` 的值未大于 1 ，则输出 "possible SYN flooding on port %d. Sending cookies.\n"，生成 syncookie 并在 SYN,ACK 中带上。

> 以下源码摘自linux-2.6.32版本

```c
int tcp_v4_conn_request(struct sock *sk, struct sk_buff *skb)
{
    ...
#ifdef CONFIG_SYN_COOKIES
	int want_cookie = 0;
#else
#define want_cookie 0 /* Argh, why doesn't gcc optimize this :( */
#endif
    ...
	/* TW buckets are converted to open requests without
	 * limitations, they conserve resources and peer is
	 * evidently real one.
	 */
	// 判定 SYN queue 是否已满
	if (inet_csk_reqsk_queue_is_full(sk) && !isn) {
#ifdef CONFIG_SYN_COOKIES
		if (sysctl_tcp_syncookies) {  // SYN queue 已满，并且设置了 net.ipv4.tcp_syncookies = 1 ，则设置 want_cookie = 1 以便后续处理
			want_cookie = 1;
		} else
#endif
		goto drop;    // 否则，直接丢弃当前 SYN 包
	}

	/* Accept backlog is full. If we have already queued enough
	 * of warm entries in syn queue, drop request. It is better than
	 * clogging syn queue with openreqs with exponentially increasing
	 * timeout.
	 */
	// 若此时 accept queue 也已满，并且 qlen_young 的值大于 1（即保存在 SYN queue 中未进行 SYN,ACK 重传的连接超过 1 个）
	// 则直接丢弃当前 SYN 包（相当于针对 SYN 进行了速率限制）
	if (sk_acceptq_is_full(sk) && inet_csk_reqsk_queue_young(sk) > 1)
		goto drop;
...
	// 若 accept queue 未满，或者 qlen_young 的值未大于 1
	if (want_cookie) {
#ifdef CONFIG_SYN_COOKIES
		syn_flood_warning(skb);  // 输出 "possible SYN flooding on port %d. Sending cookies.\n"
		req->cookie_ts = tmp_opt.tstamp_ok;  // 为当前 socket 设置启用 cookie 标识
#endif
		// 生成 syncookie
		isn = cookie_v4_init_sequence(sk, skb, &req->mss);
	} else if (!isn) {
	    ...
	}
	// 保存 syncookie 值
	tcp_rsk(req)->snt_isn = isn;

	// 回复 SYN,ACK ，若之前设置了 net.ipv4.tcp_syncookies = 1 则会释放对应的 socket 结构
	if (__tcp_v4_send_synack(sk, req, dst) || want_cookie)
		goto drop_and_free;
		
	// 启动 SYN,ACK 重传定时器
	inet_csk_reqsk_queue_hash_add(sk, req, TCP_TIMEOUT_INIT);
	return 0;

drop_and_release:
	dst_release(dst);
drop_and_free:
	reqsk_free(req);
drop:
	return 0;
}
```
    
## 当Accept Queue满了

当接收到一个ACK包但`Accept queue`满了时：

- 若设置 `tcp_abort_on_overflow = 1` ，则 TCP 协议栈回复 RST 包，并直接从 SYN queue 中删除该连接信息；
- 若设置 `tcp_abort_on_overflow = 0` ，则 TCP 协议栈将该连接标记为 `acked` ，但仍保留在 SYN queue 中，并启动 timer 以便重发 SYN,ACK 包；当 SYN,ACK 的重传次数超过 `net.ipv4.tcp_synack_retries` 设置的值时，再将该连接从 SYN queue 中删除；

但是，如果`Accept queue`满时，内核也会对SYN包接收速率强加一个限制：如果太多的SYN包被接受，其中将有一些会被抛弃。

此时，由客户端决定是否重发SYN包。

```c
/*
 *	Process an incoming packet for SYN_RECV sockets represented
 *	as a request_sock.
 */
struct sock *tcp_check_req(struct sock *sk, struct sk_buff *skb,
        struct request_sock *req,
        struct request_sock **prev)
{
    ...
	/* OK, ACK is valid, create big socket and
	 * feed this segment to it. It will repeat all
	 * the tests. THIS SEGMENT MUST MOVE SOCKET TO
	 * ESTABLISHED STATE. If it will be dropped after
	 * socket is created, wait for troubles.
	 */
	// 调用 net/ipv4/tcp_ipv4.c 中的 tcp_v4_syn_recv_sock 函数
	// 判定 accept queue 是否已经满，若已满，则返回的 child 为 NULL
	child = inet_csk(sk)->icsk_af_ops->syn_recv_sock(sk, skb, req, NULL);
	if (child == NULL)
		goto listen_overflow;

	// 在 accept queue 未满的情况下，将 ESTABLISHED 连接从 SYN queue 搬移到 accept queue 中
	inet_csk_reqsk_queue_unlink(sk, req, prev);
	inet_csk_reqsk_queue_removed(sk, req);

	inet_csk_reqsk_queue_add(sk, req, child);
	return child;

listen_overflow:
	// 若 accept queue 已满，但设置的是 net.ipv4.tcp_abort_on_overflow = 0
	if (!sysctl_tcp_abort_on_overflow) {
		inet_rsk(req)->acked = 1;    // 则只标记为 acked ，直接返回，相当于忽略当前 ACK
		return NULL;
	}

embryonic_reset:
	// 若 accept queue 已满，但设置的是 net.ipv4.tcp_abort_on_overflow = 1
	NET_INC_STATS_BH(sock_net(sk), LINUX_MIB_EMBRYONICRSTS);   // 变更统计信息
	if (!(flg & TCP_FLAG_RST))
		req->rsk_ops->send_reset(sk, skb);   // 发送 RST

	inet_csk_reqsk_queue_drop(sk, req, prev);    // 直接从 SYN queue 中删除该连接信息
    return NULL;
}
```

## 使用单个Queue的缺点

导致单个queue满的两个主要因素：

1. 应用调用`accept()`不够快，使得建立`ESTABLISHED`的connection塞满了queue。
2. 服务端与客户端之间的RTT(round-trip time，往返延时)比较大，处于`SYN RECEIVED`状态的connection塞满了queue。

而使用了两个queue，则SYN queue可以看出要传输的ACK包，Accept queue可以看出应用需要处理的连接数。