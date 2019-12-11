---
title: wordpress文章带图片同步到新浪微博
url: 234.html
id: 234
categories:
  - PHP
date: 2014-08-18 14:13:59
tags:
---

[![1392117921664](http://storage.veitor.net/uploads/2014/08/1392117921664.jpg)](http://storage.veitor.net/uploads/2014/08/1392117921664.jpg) 今天终于能把个人博客上的文章及文中图片一起同步到新浪微博了，在此发文纪念一下，并带图同步到我的微博测试。并且与大家一起分享一下经验，想必也有很多朋友在同步到微博的时候，遇到了传图的问题。 此前我都是使用多说评论框的接口同步到微博的，但为了能拥有自己的微博来源小尾巴，就自己开发一个。 首先你当然得有微博开放平台的帐号，并申请通过了网站应用审核。其次就是调用API接口了。 新浪微博有个高级接口，能发布一条微博并指定上传图片的url，这个接口由于需要申请使用，比较麻烦，还不如自己用另一个接口来实现锻炼一下自己。这里我使用的是https://upload.api.weibo.com/2/statuses/upload.json 这个接口（[详情见这](http://open.weibo.com/wiki/2/statuses/upload)）

必选

类型及范围

说明

source

false

string

采用OAuth授权方式不需要此参数，其他授权方式为必填参数，数值为应用的AppKey。

access_token

false

string

采用OAuth授权方式为必填参数，其他授权方式不需要此参数，OAuth授权后获得。

status

true

string

要发布的微博文本内容，必须做URLencode，内容不超过140个汉字。

visible

false

int

微博的可见性，0：所有人能看，1：仅自己可见，2：密友可见，3：指定分组可见，默认为0。

list_id

false

string

微博的保护投递指定分组ID，只有当visible参数为3时生效且必选。

pic

true

binary

要上传的图片，仅支持JPEG、GIF、PNG格式，图片大小小于5M。

lat

false

float

纬度，有效范围：-90.0到+90.0，+表示北纬，默认为0.0。

long

false

float

经度，有效范围：-180.0到+180.0，+表示东经，默认为0.0。

annotations

false

string

元数据，主要是为了方便第三方应用记录一些适合于自己使用的信息，每条微博可以包含一个或者多个元数据，必须以json字串的形式提交，字串长度不超过512个字符，具体内容可以自定。

rip

false

string

开发者上报的操作用户真实IP，形如：211.156.0.1。

文档规定的参数有以上这些，我只用到了source、status和pic三个参数就行了，当然你可以获得access_token来代替source（本文使用source讲解）。 上传图片等流媒体文件需要使用**multipart/form-data**编码方式，这和我们平常使用的表单上传文件类似。提交时会向服务器端发出这样的数据（如下代码，已经去除部分不相关的头信息）。

POST / HTTP/1.1
Content-Type:application/x-www-form-urlencoded
Accept-Encoding: gzip, deflate
Host: weibo.com
Content-Length: 21
Connection: Keep-Alive
Cache-Control: no-cache
txt1=hello&amp;txt2=world

对于普通的HTML Form POST请求，它会在头信息里使用Content-Length注明内容长度。头信息每行一条，空行之后便是Body，即“内容”（entity）。它的Content-Type是application/x-www-form-urlencoded，这意味着消息内容会经过URL编码，就像在GET请 求时URL里的QueryString那样。txt1=hello&txt2=world 最早的HTTP POST是不支持文件上传的，给编程开发带来很多问题。但是在1995年，ietf出台了rfc1867,也就是《RFC 1867 -Form-based File Upload in HTML》，用以支持文件上传。所以Content-Type的类型扩充了multipart/form-data用以支持向服务器发送二进制数据。因此发送post请求时候，表单 属性enctype共有二个值可选，这个属性管理的是表单的MIME编码： ①application/x-www-form-urlencoded(默认值) ②multipart/form-data 其实form表单在你不写enctype属性时，也默认为其添加了enctype属性值，默认值是enctype=”application/x- www-form-urlencoded”. 通过form表单提交文件操作如下：

<form method="post"action="http://w.sohu.com/t2/upload.do" enctype=”multipart/form-data”>
<inputtype="text" name="desc">
<inputtype="file" name="pic">
</form>

浏览器会发送以下数据：

POST /t2/upload.do HTTP/1.1
User-Agent: SOHUWapRebot
Accept-Language: zh-cn,zh;q=0.5
Accept-Charset: GBK,utf-8;q=0.7,*;q=0.7
Connection: keep-alive
Content-Length: 60408
Content-Type:multipart/form-data; boundary=ZnGpDtePMx0KrHh_G0X99Yef9r8JZsRJSXC
Host: weibo.com
--ZnGpDtePMx0KrHh_G0X99Yef9r8JZsRJSXC
Content-Disposition: form-data;name="desc"
Content-Type: text/plain; charset=UTF-8
Content-Transfer-Encoding: 8bit
--ZnGpDtePMx0KrHh_G0X99Yef9r8JZsRJSXC
Content-Disposition: form-data;name="pic"; filename="photo.jpg"
Content-Type: application/octet-stream
Content-Transfer-Encoding: binary
\[图片二进制数据\]
--ZnGpDtePMx0KrHh_G0X99Yef9r8JZsRJSXC--

先分析一下上面的内容，**然后我们来根据这内容来构造发送的数据。** 第7行指定发送编码是multipart/form-data，并且指定boundary值为“ZnGpDtePMx0KrHh_G0X99Yef9r8JZsRJSXC”，这个值可以随机产生，不难理解，boundary就是来分隔数据的。并且每段分隔时boundary值前面需要加“--”，最后结尾处在boundary值的前后加"--"（看上面代码最后一行）。 每段boundary之内，先是数据描述，再是数据的主体。 [![QQ截图20140818215404](http://storage.veitor.net/uploads/2014/08/QQ截图20140818215404.jpg)](http://storage.veitor.net/uploads/2014/08/QQ截图20140818215404.jpg)   **现在放上我构造的代码，自己琢磨一下就明白了：**

function post\_to\_sina\_weibo($post\_ID) {
  if( wp\_is\_post\_revision($post\_ID) ) return;
    $get\_post\_info = get\_post($post\_ID);
    //发布的文章内容，带所有标签格式
    $get\_post\_centent = get\_post($post\_ID)->post_content;
    //用正则表达式抠图
    preg\_match\_all('/<img.*?(?: |\\\t|\\\r|\\\n)?src=\[\\'"\]?(.+?)\[\\'"\]?(?:(?: |\\\t|\\\r|\\\n)+.*?)?>/sim', $get\_post\_centent, $strResult, PREG\_PATTERN\_ORDER);
   if(count($strResult\[1\]) > 0)
        $imgUrl = $strResult\[1\]\[0\];//获得第一张图url地址
   else
        $imgUrl = null;
    //去掉文章内的html编码的空格、换行、tab等符号
    $get\_post\_centent = str\_replace("\\t", " ", str\_replace("\\n", " ", str\_replace("&nbsp;", " ", $get\_post_centent)));
    //获取文章标题
    $get\_post\_title = get\_post($post\_ID)->post_title;
    if ( $get\_post\_info->post\_status == 'publish' && $\_POST\['original\_post\_status'\] != 'publish' ) {
    //使用wordpress内置request请求类，在wp\_includes/wp\_http.php里
    $request = new WP_Http;
    //微博文字，格式为“【文章标题】文章摘要132字，全文地址：XXXX”
    $status = '【' . strip\_tags( $get\_post\_title ) . '】 ' . mb\_strimwidth(strip\_tags( apply\_filters('the\_content', $get\_post\_centent)),0, 132,'...') . ' 全文地址:' . get\_permalink($post_ID) ;
    //如果没图片则请求这个api
    $api_url = 'https://api.weibo.com/2/statuses/update.json';
    //body内容，source参数为你的appkey，详情见wordpress的WP_http类
    $body = array( 'status' => $status, 'source'=>'706960568');
    //请将xxxxxxxxx替换成你的，xxxxxxxxxx为“用户名：密码”的base64编码
    $headers = array( 'Authorization' => 'Basic ' . 'xxxxxxxxxxxxxxxx' );
    //重要步骤，如果文章有图片则构造发送数据包
    if($imgUrl!==null)
    {
    	$body\['pic'\] = $imgUrl;
    	uksort($body, 'strcmp');
        $str_b=uniqid('------------------');
        $str\_m='--'.$str\_b;
        $str\_e=$str\_m. '--';
        $tmpbody='';
        //对参数遍历，进行构造内容，仔细阅读，你会发现和上面讲的类似
        foreach($body as $k=>$v){
            if($k=='pic'){
                $img\_c=file\_get_contents($imgUrl);
                $url_a=explode('?', basename($imgUrl));
                $img\_n=$url\_a\[0\];
                $tmpbody.=$str_m."\\r\\n";
                $tmpbody.='Content-Disposition: form-data; name="'.$k.'"; filename="'.$img_n.'"'."\\r\\n";
                $tmpbody.="Content-Type: image/unknown\\r\\n\\r\\n";
                $tmpbody.=$img_c."\\r\\n";
            }else{
                $tmpbody.=$str_m."\\r\\n";
                $tmpbody.='Content-Disposition: form-data; name="'.$k."\\"\\r\\n\\r\\n";
                $tmpbody.=$v."\\r\\n";
            }
        }
        $tmpbody.=$str_e;
        $body = $tmpbody;
        //图片处理结束，使用uploade API
    	$api_url = 'https://upload.api.weibo.com/2/statuses/upload.json';
        //设置Content-Type编码为multipart/form-data
    	$headers\['Content-Type'\] = 'multipart/form-data; boundary='.$str_b;
    }
    //请求接口发送数据，详见wordpress自带的WP_http类
    $result = $request->post( $api_url , array( 'body' => $body, 'headers' => $headers ) );
}
//最后将这个函数挂到pulish_post钩子上，发表文章后就会触发这个函数
add\_action('publish\_post', 'post\_to\_sina_weibo', 0);

  这段代码理论上来说你可以拿去直接用了，只需按注释上说的修改几个参数为自己的就行了。 这也是我研究琢磨出来的，有任何疑问可以一起探讨。