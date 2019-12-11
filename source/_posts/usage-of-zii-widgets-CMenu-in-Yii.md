---
title: Yii：zii.widgets.CMenu使用方法
tags:
  - Yii
  - 菜单
url: 76.html
id: 76
categories:
  - PHP
date: 2014-04-28 07:21:43
---

Yii框架中的一个生成菜单的小物件。 先上个示例代码：

<?php
$this->widget('zii.widgets.CMenu',array(
    'activeCssClass'=>'当前热点元素的样式',
    'firstItemCssClass'=>'第一个元素的样式',
    'lastItemCssClass'=>'最后一个元素的样式',
    'encodeLable'=>'false',  //当值为false时，label标签中的html就会将样式显示出来.
    'htmlOptions'=>array('class'=>'默认样式'),
    'items'=>array(
        array('label'=>'网站概况', 'url'=>array('/admin'),'itemOptions'=>array('class'=>'li_status'),'active'=>$this->id=='admin'?true:false),
        array('label'=>'图片管理', 'url'=>array('/picture'),'template'=>'{menu}<span>this is additional infomation</span>','itemOptions'=>array('class'=>'li_picture'),'active'=>$this->id=='picture'?true:false, 'visible'=>true),
        array('label'=>'管理员管理', 'url'=>array('/manager'),'itemOptions'=>array('class'=>'li_manager'),'submenuOptions'=>array('class'=>'subclass'),'active'=>($this->id=='manager' && $this->action->id!='changepswd')?true:false, 'visible'=>false),
        array('label'=>'密码修改', 'url'=>array('/manager/changepswd'),'linkOptions'=>array('target'=>'\_blank'),'itemOptions'=>array('class'=>'li\_changepswd'),'items'=>array(array('label'=>'子栏目'))),'active'=>($this->id=='manager' && $this->action->id=='changepswd')?true:false, 'visible'=>true),
        array('label'=>'登陆', 'url'=>array('/site/login'),'itemOptions'=>array('class'=>'li_login'), 'visible'=>Yii::app()->user->isGuest),
        array('label'=>'退出 ('.Yii::app()->user->name.')', 'url'=>array('/site/logout'),'itemOptions'=>array('class'=>'li_login'), 'visible'=>!Yii::app()->user->isGuest)
    ),
));
?>

在模板中使用上面的代码，最终会生成以<ul><li></li></ul>构成的菜单列表，针对item中的每一个数组，可以进行以下设置： **label:**菜单显示的文本，可以加html进行修饰，但要将encodeLabel参数值设为false **url:**链接地址，若是字符串，则是基于网站根地址的绝对路径，比如网站地址为veitor.net，字符串url设置为"article"，则最终生成的地址为veitor.net/article，如果设置类型为数组，则效果与createUrl方法一样，比如网址还是veitor.net，设置的数组url为"array(detail/article)"，则最终生成的地址为veitor.net/?r=detail/article，控制器/方法格式的 **visible:**可见，boolean值，当然可以用函数来取值，决定什么情况下隐藏 **active:**正在访问，boolean值，如果是true，会在相应li中加入active样式，上面代码用到$this->id是个很好用的方法 **items:**定义子目录，array，通过样式可定义收缩排列或者鼠标经过时显示子目录 **template:**模板，模板中用{menu}来代表替换内容，见上代码 **linkOptions:**<a>的属性，可定义class,rel,target等属性，见上代码 **itemOptions:**<li>的属性，可定义class等属性，见上代码 **submenuOptions:**子栏目的<ul>属性，<li>和<a>属性还是和上面一样分别对item设置 **activeCssClass：**当前选中菜单的css的Class名称 **firstItemCssClass：**第一个菜单按钮的Css的Class名称 **lastItemCssClass：**最后一个菜单按钮的Css的Class名称 当然可以分别为每个Item菜单元素添加指定的Class，即在对应的Item元素上增加itemOptions设置（看上面代码）   这些就是我用CMenu的一些见解，如果你有更好的方法可以一起交流。