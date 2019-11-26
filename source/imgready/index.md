---
title: imgreadydemo
url: 82.html
id: 82
date: 1970-01-01 00:00:00
---

img ready demo <!\-\- /\*demo style\*/ body { font:12px 'Microsoft Yahei', Tahoma, Arial; _font-family:Tahoma, Arial; } a { color:#0259C4; } a:hover { color:#900; } .tips { color:#CCC; } h1 { font-family:'Constantia';} #path { width:36em; padding:5px; border:2px solid #0259C4; background:#FAFAFA;-webkit-border-radius:3px; -moz-border-radius:3px; border-radius:3px; } #path:focus { background:#FFFFF7; outline:0; } #submit { padding:5px 10px; border:2px solid #0259C4; background:#0259C4; color:#FFF; -webkit-border-radius:3px; -moz-border-radius:3px; border-radius:3px; cursor:pointer; } #submit.disabled { background:#D7D7D7; color:#ABABAB; border-color:#ABABAB; cursor:default; } --> // <!\[CDATA\[ /* demo script */ window.onload = function () { var $ = function (id) { return document.getElementById(id); }; var Timer = function (){ this.startTime = (new Date()).getTime(); }; Timer.prototype.stop = function(){ return (new Date()).getTime() - this.startTime; }; var imgUrl, checkboxFn, path = $('path'), submit = $('submit'), checkbox = $('checkbox'), clsCache = $('clsCache'), status = $('status'), statusReady = $('statusReady'), statusLoad = $('statusLoad'), imgWrap = $('imgWrap'); submit.disabled = false; submit.onclick = function () { var that = this, time = new Timer(); imgUrl = path.value; status.style.display = 'block'; statusLoad.innerHTML = statusReady.innerHTML = 'Loading...'; // 参数: 图片地址, 尺寸就绪事件, 完全加载事件, 加载错误事件 imgReady(imgUrl, function () { statusReady.innerHTML = '耗时 ' + (time.stop() / 1000) +' 秒. 宽度: ' + this.width + '; 高度: ' + this.height; checkboxFn(); }, function () { statusLoad.innerHTML = '耗时 ' + (time.stop() / 1000) +' 秒. 宽度: ' + this.width + '; 高度: ' + this.height; }, function () { statusLoad.innerHTML = statusReady.innerHTML = '耗时 ' + (time.stop() / 1000) +' 秒. 加载错误！'; }); }; clsCache.onclick = function () { var value = path.value; path.value = (value.split('?')\[1\] ? value.split('?')\[0\] : value) + '?' + new Date().getTime(); status.style.display = 'none'; imgWrap.innerHTML = ''; return false; }; checkbox.onclick = checkbox.onchange = checkboxFn = function () { imgWrap.innerHTML = imgUrl && checkbox.checked ? '<img src="' + imgUrl + '" />' : ''; }; checkbox.checked = false; $('down').onclick = function () { window.open(this.getAttribute('data-href') || this.href); return false; } }; // \]\]>  

imgReady
========

图片头数据加载就绪事件

**下载：** [imgReady.js](http://www.planeart.cn/demo/imgReady/imgReady.js) **相关文章：** [再谈javascript图片预加载技术](http://www.planeart.cn/?p=1121) **演示：**

  显示图片 [清空缓存](#)_（浏览器会缓存加载过后的图片）_

**通过文件头信息获取尺寸：** **通过加载完毕后获取尺寸：**