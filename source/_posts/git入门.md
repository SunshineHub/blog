---
title: git入门
cover: /images/git入门/20180929052702235.png
date: 2018-8-28 10:36:53
subtitle: 带你git入门。
author: 
  name: WangCh
  link: https://github.com/SunshineHub
tags:
 - git 
categories:
 - git
---
## 1. 介绍
Git is a free and open source distributed version control system designed to handle everything from small to very large projects with speed and efficiency.

Git 是一个开源免费的分布式版本控制系统，旨在提高大小项目的速度和效率。

## 2. 与SVN的区别

1. 本地版本控制系统:(解决个人的版本管理)
2. 分布式版本控制 与 集中式版本控制
3. git 版本存储的是快照,svn 是差异文件
4. git 速度更快,效率更高
5. git 切换分支（只是切换指针）

## 3. 安装 Windows版 Git - msysgit

[https://gitforwindows.org/](https://gitforwindows.org/)
## 4. GIT 常规操作流程
克隆项目 -> 修改文件 -> 提交修改到暂存区 -> 提交修改到本地仓库 -> 提交到远程

```bash
git clone http://192.168.4.254/xx   #克隆
修改文件
git add .  #添加到暂存区
git commit -m "这是第一次提交" #提交本地
git push -u origin master  #提交远程
```

+ git status 查看即时状态
+ git log 查看日志

温馨提示：
> Git在执行提交的时候，不是直接将工作树的状态保存到数据库，而是将设置在中间索引区域的状态保存到数据库。因此，要提交文件，首先需要把文件加入到索引区域中

> 所以，凭借中间的索引，可以避免工作树中不必要的文件提交，还可以将文件修改内容的一部分加入索引区域并提交。

## 5. Git 更新代码

```
git pull
```

## 6. Git 合并修改记录 

#### Fast-forward 方式

![https://backlog.com/git-tutorial/cn/img/post/intro/capture_intro5_1_1.png](https://backlog.com/git-tutorial/cn/img/post/intro/capture_intro5_1_1.png)

在执行pull之后，进行下一次push之前，如果其他人进行了推送内容到远程数据库的话，那么你的push将被拒绝。

![https://backlog.com/git-tutorial/cn/img/post/intro/capture_intro5_1_2.png](https://backlog.com/git-tutorial/cn/img/post/intro/capture_intro5_1_2.png)

这种情况下，在读取别人push的变更并进行合并操作之前，你的push都将被拒绝。这是因为，如果不进行合并就试图覆盖已有的变更记录的话，其他人push的变更（图中的提交C）就会丢失。

#### Confict (冲突)

在上一个页面我们提及到，执行合并即可自动合并Git修改的部分。但是，也存在无法自动合并的情况。

如果远程数据库和本地数据库的同一个地方都发生了修改的情况下，因为无法自动判断要选用哪一个修改，所以就会发生冲突。

Git会在发生冲突的地方修改文件的内容，如下图。所以我们需要手动修正冲突。

![https://backlog.com/git-tutorial/cn/img/post/intro/capture_intro5_1_3.png](https://backlog.com/git-tutorial/cn/img/post/intro/capture_intro5_1_3.png)

如下图所示，修正所有冲突的地方之后，执行提交。

![https://backlog.com/git-tutorial/cn/img/post/intro/capture_intro5_1_4.png](https://backlog.com/git-tutorial/cn/img/post/intro/capture_intro5_1_4.png)

冲突解决办法：
```bash
git pull //更新代码
解决冲突
git add . 
git commit -m "解决了冲突"
git push origin master
```

## 7. 分支

分支是为了将修改记录的整体流程分叉保存。分叉后的分支不受其他分支的影响，所以在同一个数据库里可以同时进行多个修改。

![https://backlog.com/git-tutorial/cn/img/post/stepup/capture_stepup1_1_1.png](https://backlog.com/git-tutorial/cn/img/post/stepup/capture_stepup1_1_1.png)

```bash
git checkout -b hotfix316 //从当前分支签出分支(创建分支)
git branch //查看分支
修改hotfix316的分支
开始准备合并到master分支
git checkout master //切换分支
git merge hotfix316//合并hotfix316分支到master分支
git commit -am "提交代码" //这里的a参数相当于add
git push origin master //提交到远程
```

## 8. 回滚文件

```bash
git reset --hard HEAD
git reset --mixed HEAD
git reset --soft HEAD
git rm --cached
git checkout -- . #丢失还未提交的数据
```

## 9. 标签

（用于发版打标签）

```bash
git tag v1.0.0 #创建一个轻标签
git tag -am "新版本注释" v1.0.1 #创建一个注解标签
git tag -d v1.0.0 删除一个标签
```

## 10. 忽略文件 - .gitignore

```bash
*.a
!lib.a
/TODO
build/
doc/*.txt
```

## 11. 暂存机制 - stash

```bash
git stash
git stash list
git stash pop
```

## 12. 差异比较

```stash
git diff HEAD^ HEAD
```

## 13. 杂项命令

```bash
git log --stat #宏观差异日志
git log -p #详细差异日志
git commit --amend #修改提交
git rm <filename>
git rm --cached #删除暂存区
git config --global auto.crlf false #设置windows不替换\n为\r\n
gitk --all #GUI工具
```

## 14. GitLab地址

+ http://192.168.4.254/

#### 参考注:
 [猴子都能懂的GIT入门](https://backlog.com/git-tutorial/cn/)  
 [gitbook](https://git-scm.com/book/zh/v2)  
 [bootcss git 指南](http://www.bootcss.com/p/git-guide/)