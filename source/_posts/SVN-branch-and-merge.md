---
title: SVN分支与合并透析
tags:
  - SVN
url: 273.html
id: 273
categories:
  - 程序与生活
  - 经验分享
date: 2014-09-05 05:30:52
---

**1.创建分支的意义** 创 建分支的意义，比如我们在一个基础平台上进行开发，每个技术小组负责一个子项目，而基础平台也是有可能会继续更改的，这个时候，如果不创建分支，子项目之 间会相互影响，影响最大的就是后期的测试和版本发布，子项目A已经结束，但测试却受到正在进行的子项目B的影响，测试通不过，就别说版本发布了。所以，我 们需要从目前的项目（主干trunk）中创建分支（branch），隔离子项目间的相互影响。 **2.svn创建分支原理** 在 svn中，创建分支，实际上就是一个版本拷贝(对应copy to...注意：绝不是简单在客户端上copy一个目录，而是svn仓库中copy，文件版本号会增加。），两边做任何修改发生的版本变化，是一套机制。 举例：目前主干版本是100，分支版本是101，主干中增加一个文件，版本为102，分支中再增加一个文件，版本就为103了。两边的版本号是一套，不会 重复。 **3.svn创建分支的方法** **TortoiseSVN：**右键点击工程目录->TortoiseSVN->Branch/tag..菜单，From WC at Url自动为工程svn url，比如[https://localhost:8443/svn/fbysss/prj1/trunk](https://localhost:8443/svn/fbysss/prj1/trunk)，to Url填写[https://localhost:8443/svn/fbysss/prj1/branches/branch1](https://localhost:8443/svn/fbysss/prj1)。点OK按钮，分支就创建好了。 **Subclipse：**Team->Branch/tag..，跟上面类似. **SVN命令模式：**svn copy trunk\_path  branch\_path  -m '描述' 举例：svn copy [https://localhost:8443/svn/fbysss/prj1](https://localhost:8443/svn/fbysss/prj1/trunk)[/trunk ](https://localhost:8443/svn/fbysss/prj1) [https://localhost:8443/svn/fbysss/prj1/branches/branch1](https://localhost:8443/svn/fbysss/prj1) -m "第一个分支" **注意一点：**trunk和branch不能互为子目录，否则就乱套了。 **4.分支合并** **1）从分支合并到主干** 分支开发结束之后，往往需要合并回主干去测试、发布，但分支和主干可能有很多冲突的地方，在合并时经常需要手工解决。 **被操作对象：**主干 **From****：**主干的打出分支时的版本 **To：**分支的Head版本（最新版本）   怎么理解这个From和To呢?似乎跟我们的想当然不太一样：因为我们理解，把分支合并到主干，肯定是From分支，To主干。怎么搞反了呢？ 实际上，**Svn****认为，我们要合并的，是从主干的某个版本开始，到分支的某个版本结束。两边的版本号实际上是一套系统，不会有重复。**我们从TortoiseSVN Help中也能找到证据：

If you are using this method to merge a feature branch back to trunk, you need to ........
In the From: field enter the full folder URL of the trunk. This may sound wrong, but remember that the trunk is the start point to which you want to add the branch changes. You may also click ... to browse the repository.
In the To: field enter the full folder URL of the feature branch.

  **2）从主干合并到分支** 试想这样的情况：一个项目里面，要独立出来一个子项目，需要单独发布版本，用到了基础框架代码，而基础框架在主干中不断修改完善，这就需要从主干合并到分支。 **被操作对象：**分支 **From：**分支的第一个版本（最旧版本） **To：**主干的Head版本（最新版本） 相当于从分支的第一个版本开始一直到主干最后一个版本结束合并之后，替换分支。 **3）从分支合并到分支** 有 这样的需求：一个项目中有很多分支，这些分支需要分期上线，有多个工作并行，但每一期之间不能相互影响，这就可以打出几个tag（也是分支），从主干 copy而来。其他主干根据排期分别合并到这些tag中来。比如有prjTag1和prjTag2，model1、model2需要合并到prjTag1 中，model3、model4需要合并到prjTag2中。拿prjTag1举例： 在prjTag1的work copy中，merge   **From****：**主干的打出分支时的版本 **To：**分支的Head版本（最新版本） **注意：**From不是本Tag的某个版本，而是之前主干打出分支时的版本，最终Merge到prjTag1的work copy，而prjTag1是找不到当初打分支时的版本的。 原文地址：http://blog.csdn.net/fbysss/article/details/5437157