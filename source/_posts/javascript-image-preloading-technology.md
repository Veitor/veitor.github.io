---
title: 再谈javascript图片预加载技术
tags:
  - 预加载
url: 80.html
id: 80
categories:
  - JS
date: 2014-05-04 14:22:07
---

lightbox类效果为了让图片居中显示而使用预加载，需要等待完全加载完毕才能显示，体验不佳（如filick相册的全屏效果）。javascript无法获取img文件头数据，真的是这样吗？本文通过一个巧妙的方法让javascript获取它。 这是大部分人使用预加载获取图片大小的例子：

var imgLoad = function (url, callback) {
	var img = new Image();
	img.src = url;
	if (img.complete) {
		callback(img.width, img.height);
	} else {
		img.onload = function () {
			callback(img.width, img.height);
			img.onload = null;
		};
	};
};

  可以看到上面必须等待图片加载完毕才能获取尺寸，其速度不敢恭维，我们需要改进。 web应用程序区别于桌面应用程序，响应速度才是最好的用户体验。如果想要速度与优雅兼得，那就必须提前获得图片尺寸，如何在图片没有加载完毕就能获取图片尺寸？ 十多年的上网经验告诉我：浏览器在加载图片的时候你会看到图片会先占用一块地然后才慢慢加载完毕，并且不需要预设width与height属性，因为浏览器能够获取图片的头部数据。基于此，只需要使用javascript定时侦测图片的尺寸状态便可得知图片尺寸就绪的状态。 当然实际中会有一些兼容陷阱，如width与height检测各个浏览器的不一致，还有webkit new Image()建立的图片会受以处在加载进程中同url图片影响，经过反复测试后的最佳处理方式：

// 更新：
// 05.27: 1、保证回调执行顺序：error > ready > load；2、回调函数this指向img本身
// 04-02: 1、增加图片完全加载后的回调 2、提高性能
/\*\*
 \* 图片头数据加载就绪事件 \- 更快获取图片尺寸
 \* @version	2011.05.27
 \* @author	TangBin
 \* @see		http://www.planeart.cn/?p=1121
 \* @param	{String}	图片路径
 \* @param	{Function}	尺寸就绪
 \* @param	{Function}	加载完毕 (可选)
 \* @param	{Function}	加载错误 (可选)
 \* @example imgReady('http://www.google.com.hk/intl/zh-CN/images/logo_cn.png', function () {
		alert('size ready: width=' + this.width + '; height=' + this.height);
	});
 */
var imgReady = (function () {
	var list = \[\], intervalId = null,
	// 用来执行队列
	tick = function () {
		var i = 0;
		for (; i < list.length; i++) {
			list\[i\].end ? list.splice(i--, 1) : list\[i\]();
		};
		!list.length && stop();
	},
	// 停止所有定时器队列
	stop = function () {
		clearInterval(intervalId);
		intervalId = null;
	};
	return function (url, ready, load, error) {
		var onready, width, height, newWidth, newHeight,
			img = new Image();
		img.src = url;
		// 如果图片被缓存，则直接返回缓存数据
		if (img.complete) {
			ready.call(img);
			load && load.call(img);
			return;
		};
		width = img.width;
		height = img.height;
		// 加载错误后的事件
		img.onerror = function () {
			error && error.call(img);
			onready.end = true;
			img = img.onload = img.onerror = null;
		};
		// 图片尺寸就绪
		onready = function () {
			newWidth = img.width;
			newHeight = img.height;
			if (newWidth !== width || newHeight !== height ||
				// 如果图片已经在其他地方加载可使用面积检测
				newWidth * newHeight > 1024
			) {
				ready.call(img);
				onready.end = true;
			};
		};
		onready();
		// 完全加载完毕的事件
		img.onload = function () {
			// onload在定时器时间差范围内可能比onready快
			// 这里进行检查并保证onready优先执行
			!onready.end && onready();
			load && load.call(img);
			// IE gif动画会循环执行onload，置空onload即可
			img = img.onload = img.onerror = null;
		};
		// 加入队列中定期执行
		if (!onready.end) {
			list.push(onready);
			// 无论何时只允许出现一个定时器，减少浏览器性能损耗
			if (intervalId === null) intervalId = setInterval(tick, 40);
		};
	};
})();

调用例子：

imgReady('http://pic1.hualongxiang.com/attachment/photo/Mon\_1405/343656\_7b0313991240910abfa97883b96b9.jpg', function () {
	alert('size ready: width=' + this.width + '; height=' + this.height);
});

是不是很简单？这样的方式获取摄影级别照片尺寸的速度往往是onload方式的几十多倍，而对于web普通(800×600内)浏览级别的图片能达到秒杀效果。看了这个再回忆一下你见过的web相册，是否绝大部分都可以重构一下呢？好了，请观赏令人愉悦的 DEMO ： http://www.planeart.cn/demo/imgReady/ （通过测试的浏览器：Chrome、Firefox、Safari、Opera、IE6、IE7、IE8）   原文地址：http://www.planeart.cn/?p=1121