---
title: 优酷真实视频地址解析
tags:
  - 优酷
url: 330.html
id: 330
categories:
  - JS
  - 程序与生活
  - 经验分享
date: 2014-10-08 08:41:55
---

序：优酷之前更新了次算法(很久之前了，呵呵。。。)，故此很多博客的解析算法已经无法使用。很多大牛也已经更新了新的解析方法。我也在此写篇解析过程的文章。(本文使用语言为C#) 由于优酷视频地址时间限制，在你访问本篇文章时，下面所属链接有可能已经失效，望见谅。 例：[http://v.youku.com/v\_show/id\_**XNzk2NTI0MzMy**.html](http://v.youku.com/v_show/id_XNzk2NTI0MzMy.html)

1:获取视频vid
=========

在视频url中标红部分。一个[正则表达式](http://www.cnblogs.com/zhaojunjie/p/3344909.html)即可获取。

string getVid(string url)
{
    string strRegex = "(?<=id_)(\\\w+)";
    Regex reg = new Regex(strRegex);
    Match match = reg.Match(url);
    return match.ToString();
}

 

2:获取视频元信息
=========

[http://v.youku.com/player/getPlayList/VideoIDS/](http://v.youku.com/player/getPlayList/VideoIDS/XNzk2NTI0MzMy/Pf/4/ctype/12/ev/1)[**XNzk2NTI0MzMy**/Pf/4/ctype/12/ev/1](http://v.youku.com/player/getPlayList/VideoIDS/XNzk2NTI0MzMy/Pf/4/ctype/12/ev/1) 将前述vid嵌入到上面url中访问即可得到视频信息文件。由于视频信息过长不在此贴出全部内容。下面是部分重要内容的展示。(获取文件为json文件，可直接解析)

{ "data": \[ {
            "ip": 996949050,
            "ep": "NQXRTAodIbrd1vnC8+JxB4emuRs41w7DWho=",
            "segs": {
                "hd2": \[
                    {
                        "no": "0",
                        "size": "34602810",
                        "seconds": 205,
                        "k": "248fe14b4c1b37302411f67a",
                        "k2": "1c8e113cecad924c5"
                    },
                    {
                        "no": "1",
                    },\] }, } \],}

上面显示的内容后面都会使用到。其中**segs包含hd3,hd2,flv,mp4,3gp**等各种格式，并且每种格式下均分为若干段。本次选用清晰度较高的hd2(视频格式为flv)

**3:拼接m3u8地址**
==============

[http://pl.youku.com/playlist/m3u8?ctype=12&ep={0}&ev=1&keyframe=1&oip={1}&sid={2}&token={3}&type={4}&vid={5}](http://pl.youku.com/playlist/m3u8?ctype=12&ep=%7b0%7d&ev=1&keyframe=1&oip=%7b1%7d&sid=%7b2%7d&token=%7b3%7d&type=%7b4%7d&vid=%7b5%7d) 以上共有6个参数，其中vid和oip已经得到，分别之前的vid和json文件中的ip字段，即(**XNzk2NTI0MzMy**和**1991941296**)，但是ep,sid,token需要重新计算(json文件中的ep值不能直接使用)。type即为之前选择的segs。

3.1计算ep,sid,token
-----------------

计算方法单纯的为数学计算，下面给出计算的函数。三个参数可一次性计算得到。其中涉及到Base64编码解码知识，[点击查看](http://www.cnblogs.com/zhaojunjie/p/3946427.html)。

private static string myEncoder(string a, byte\[\] c, bool isToBase64)
        {
            string result = "";
            List<Byte> bytesR = new List<byte>();
            int f = 0, h = 0, q = 0;
            int\[\] b = new int\[256\];
            for (int i = 0; i < 256; i++)
                    b\[i\] = i;
            while (h < 256)
            {
                f = (f + b\[h\] + a\[h % a.Length\]) % 256;
                int temp = b\[h\];
                b\[h\] = b\[f\];
                b\[f\] = temp;
                h++;
            }
            f = 0; h = 0; q = 0;
            while (q < c.Length)
            {
                h = (h + 1) % 256;
                f = (f + b\[h\]) % 256;
                int temp = b\[h\];
                b\[h\] = b\[f\];
                b\[f\] = temp;
                byte\[\] bytes = new byte\[\] { (byte)(c\[q\] ^ b\[(b\[h\] + b\[f\]) % 256\]) };
                bytesR.Add(bytes\[0\]);
                result += System.Text.ASCIIEncoding.ASCII.GetString(bytes);
                q++;
            }
            if (isToBase64)
            {
                Byte\[\] byteR = bytesR.ToArray();
                result = Convert.ToBase64String(byteR);
            }
            return result;
        }
        public static void getEp(string vid, string ep, ref string pNew, ref string token, ref string sid)
        {
            string template1 = "becaf9be";
            string template2 = "bf7e5f01";
            byte\[\] bytes = Convert.FromBase64String(ep);
            ep = ystem.Text.ASCIIEncoding.ASCII.GetString(bytes);
            string temp = myEncoder(template1, bytes, false);
            string\[\] part = temp.Split('_');
            sid = part\[0\];
            token = part\[1\];
            string whole = string.Format("{0}_{1}_{2}", sid, vid, token);
            byte\[\] newbytes = System.Text.ASCIIEncoding.ASCII.GetBytes(whole);
            epNew = myEncoder(template2, newbytes, true);
        }

 

计算得到ep,token,sid分别为cCaVGE6OUc8H4ircjj8bMiuwdH8KXJZ0vESH/7YbAMZuNaHQmjbTwg==, 3825, 241273717793612e7b085。注意，此时ep并不能直接拼接到url中，需要对此做一下url编码ToUrlEncode(ep)。最终ep为cCaVGE6OUc8H4ircjj8bMiuwdH8KXJZ0vESH%2f7YbAMZuNaHQmjbTwg%3d%3d

3.2视频格式及清晰度
-----------

视频格式和选择的segs有密切关系。如本文选择的hd2，格式即为flv，下面是segs,视频格式和清晰度的对照。之前对此部分理解有些偏差，多谢[削着苹果走路](http://home.cnblogs.com/u/xzpgzl/)提醒。[](http://www.cnblogs.com/xzpgzl/)

“segs”,”视频格式”,”清晰度”
"hd3", "flv", "1080P"
"hd2", "flv", "超清"
"mp4", "mp4", "高清"
"flvhd", "flv", "高清"
"flv", "flv", "标清"
"3gphd", "3gp", "高清"

 

3.3拼接地址
-------

　　最后的m3u8地址为

[http://pl.youku.com/playlist/m3u8?ctype=12&ep=cCaVGE6OUc8H4ircjj8bMiuwdH8KXJZ0vESH%2f7YbAMZuNaHQmjbTwg%3d%3d&ev=1&keyframe=1&oip=996949050&sid=241273717793612e7b085&token=3825&type=hd2&vid=XNzk2NTI0MzMy](http://pl.youku.com/playlist/m3u8?ctype=12&ep=cCaVGE6OUc8H4ircjj8bMiuwdH8KXJZ0vESH%2f7YbAMZuNaHQmjbTwg%3d%3d&ev=1&keyframe=1&oip=996949050&sid=241273717793612e7b085&token=3825&type=hd2&vid=XNzk2NTI0MzMy)

4:获取视频地址
========

将上述m3u8文件下载后，其中内容即为真实地址，不过还需要稍微处理一下。部分内容如下：

#EXTM3U
#EXT-X-TARGETDURATION:12
#EXT-X-VERSION:3
#EXTINF:6.006,
http://59.108.137.14/65666E0ED34581E6B96293A18/0300010F005430BCBA49631468DEFEC61C5678-3A78-37BA-1971-21A0D4EEA0E7.flv?ts\_start=0&ts\_end=5.906&ts\_seg\_no=0&ts_keyframe=1
#EXTINF:5.464,
http://59.108.137.14/65666E0ED34581E6B96293A18/0300010F005430BCBA49631468DEFEC61C5678-3A78-37BA-1971-21A0D4EEA0E7.flv?ts\_start=5.906&ts\_end=11.37&ts\_seg\_no=1&ts_keyframe=1
#EXTINF:5.505,
http://59.108.137.14/65666E0ED34581E6B96293A18/0300010F005430BCBA49631468DEFEC61C5678-3A78-37BA-1971-21A0D4EEA0E7.flv?ts\_start=11.37&ts\_end=16.875&ts\_seg\_no=2&ts_keyframe=1
#EXTINF:9.26,
http://59.108.137.14/65666E0ED34581E6B96293A18/0300010F005430BCBA49631468DEFEC61C5678-3A78-37BA-1971-21A0D4EEA0E7.flv?ts\_start=16.875&ts\_end=26.135&ts\_seg\_no=3&ts_keyframe=1
#EXTINF:11.136,
http://59.108.137.14/65666E0ED34581E6B96293A18/0300010F005430BCBA49631468DEFEC61C5678-3A78-37BA-1971-21A0D4EEA0E7.flv?ts\_start=26.135&ts\_end=37.271&ts\_seg\_no=4&ts_keyframe=1
#EXTINF:8.258,
http://59.108.137.14/65666E0ED34581E6B96293A18/0300010F005430BCBA49631468DEFEC61C5678-3A78-37BA-1971-21A0D4EEA0E7.flv?ts\_start=37.271&ts\_end=45.529&ts\_seg\_no=5&ts_keyframe=1
#EXTINF:9.843,
http://59.108.137.14/65666E0ED34581E6B96293A18/0300010F005430BCBA49631468DEFEC61C5678-3A78-37BA-1971-21A0D4EEA0E7.flv?ts\_start=45.529&ts\_end=55.372&ts\_seg\_no=6&ts_keyframe=1
#EXTINF:10.26,
http://59.108.137.14/65666E0ED34581E6B96293A18/0300010F005430BCBA49631468DEFEC61C5678-3A78-37BA-1971-21A0D4EEA0E7.flv?ts\_start=55.372&ts\_end=65.632&ts\_seg\_no=7&ts_keyframe=1

其中每条url只包含6s左右视频，但是可将url中参数部分去掉即可得到实际的长度。但是每条去掉后需合并一下相同的url，如上述列表可得到url片段 [http://59.108.137.14/65666E0ED34581E6B96293A18/0300010F005430BCBA49631468DEFEC61C5678-3A78-37BA-1971-21A0D4EEA0E7.flv](http://59.108.137.14/65666E0ED34581E6B96293A18/0300010F005430BCBA49631468DEFEC61C5678-3A78-37BA-1971-21A0D4EEA0E7.flv) 将m3u8中所有的url片段全部下载即可大功告成。 [![QQ截图20141008164115](http://storage.veitor.net/uploads/2014/10/QQ截图20141008164115.jpg)](http://storage.veitor.net/uploads/2014/10/QQ截图20141008164115.jpg) 原文地址：[http://www.cnblogs.com/zhaojunjie/p/4009192.html](http://www.cnblogs.com/zhaojunjie/p/4009192.html)