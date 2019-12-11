---
title: 了解Yii中Log日志机制
tags:
  - Yii
url: 97.html
id: 97
categories:
  - PHP
date: 2014-05-27 05:38:20
---

想要知道用户在你的程序中做了些什么，我们可以通过用日志的形式记录下来，前提是用户是做的跟数据库有关的操作。我们可以在任何时候进行的增删改操作都可以记录下来，对于Yii中的AR模型我们可以使用behavior（行为）来达到此目的，这样很容易的就可以把日志功能加到AR类里。 首先我们需要建一张日志表：

CREATE TABLE ActiveRecordLog (
  id INTEGER UNSIGNED NOT NULL AUTO_INCREMENT,
  description VARCHAR(255) NULL,
  action VARCHAR(20) NULL,
  model VARCHAR(45) NULL,
  idModel INTEGER UNSIGNED NULL,
  field VARCHAR(45) NULL,
  creationdate TIMESTAMP NOT NULL,
  userid VARCHAR(45) NULL,
  PRIMARY KEY(id)
)
TYPE=InnoDB;

接着我们就需要建立相应的model，可以使用gii或者shell工具等。 为了记录用户操作，我们需要创建一个behavior类，一般放在protected/behavior目录下，该类必须继承CActiveRecordBehavior类。

class ActiveRecordLogableBehavior extends CActiveRecordBehavior
{
    private $_oldattributes = array();
    /\*\*
     \* save操作
     \* @param  \[type\] $event \[description\]
     \* @return \[type\]        \[description\]
     */
    public function afterSave($event)
    {
        //非新记录，即非插入
        if (!$this->Owner->isNewRecord) {
            $newattributes = $this->Owner->getAttributes();             //获得AR类中已修改的各字段值
            $oldattributes = $this->getOldAttributes();                 //之前的旧数据
            //比较新旧数据
            foreach ($newattributes as $name => $value) {
                if (!empty($oldattributes)) {
                    $old = $oldattributes\[$name\];
                } else {
                    $old = '';
                }
                //如果该字段旧数据与新数据不一样，则进行记录
                if ($value != $old) {
                    //$changes = $name . ' ('.$old.') => ('.$value.'), ';
                    $log=new ActiveRecordLog;                                               //实例log对象
                    $log->description=  'User ' . Yii::app()->user->Name                    //设置日志内容格式，描述具体操作
                                            . ' changed ' . $name . ' for '
                                            . get_class($this->Owner)
                                            . '\[' . $this->Owner->getPrimaryKey() .'\].';
                    $log->action=       'CHANGE';                                           //设置操作类型为“修改”
                    $log->model=        get_class($this->Owner);
                    $log->idModel=      $this->Owner->getPrimaryKey();                      //获得修改的记录的主键
                    $log->field=        $name;                                              //修改的字段名
                    $log->creationdate= new CDbExpression('NOW()');                         //日志生成时间
                    $log->userid=       Yii::app()->user->id;                               //记录用户id
                    $log->save();                                                           //保存日至到数据库
                }
            }
        } else {//新纪录直接保存操作日志入库
            $log=new ActiveRecordLog;
            $log->description=  'User ' . Yii::app()->user->Name
                                    . ' created ' . get_class($this->Owner)
                                    . '\[' . $this->Owner->getPrimaryKey() .'\].';
            $log->action=       'CREATE';
            $log->model=        get_class($this->Owner);
            $log->idModel=      $this->Owner->getPrimaryKey();
            $log->field=        '';
            $log->creationdate= new CDbExpression('NOW()');
            $log->userid=       Yii::app()->user->id;
            $log->save();
        }
    }
    /\*\*
     \* 删除操作
     \* @param  \[type\] $event \[description\]
     \* @return \[type\]        \[description\]
     */
    public function afterDelete($event)
    {
        $log=new ActiveRecordLog;
        $log->description=  'User ' . Yii::app()->user->Name . ' deleted '
                                . get_class($this->Owner)
                                . '\[' . $this->Owner->getPrimaryKey() .'\].';
        $log->action=       'DELETE';
        $log->model=        get_class($this->Owner);
        $log->idModel=      $this->Owner->getPrimaryKey();
        $log->field=        '';
        $log->creationdate= new CDbExpression('NOW()');
        $log->userid=       Yii::app()->user->id;
        $log->save();
    }
    public function afterFind($event)
    {
        //保存查询出来的数据
        $this->setOldAttributes($this->Owner->getAttributes());
    }
    public function getOldAttributes()
    {
        return $this->_oldattributes;
    }
    public function setOldAttributes($value)
    {
        $this->_oldattributes=$value;
    }
}

该behavior行为类中需要使用到ActiveRecordLo类来将日志记录到数据库中，它会为为每次插入、删除记录一条日志，也会为修改的每个字段记录一条日志。 设定的行为已经写好了，那么剩下的就是需要将其绑定到对应的model模型上。我们只需在对应的model里加入以下方法就完成绑定了：

public function behaviors()
{
    return array(
        // 行为类名 =\> 类文件别名路径
        'ActiveRecordLogableBehavior'=>
            'application.behaviors.ActiveRecordLogableBehavior',
    );
}

  当然这些都是最基本的简单的记录日志操作，你还可以进行扩展，以满足更高级更多功能的需求。如有问题，留言探讨~