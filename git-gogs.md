# Git and Gogs

本地工具Git，远程仓库工具Gogs。

## Gogs

### 安装mysql

```
docker run -p 3306:3306 --restart always --name mysql -v /etc/localtime:/etc/timezone:rw -v /etc/localtime:/etc/localtime:rw -e MYSQL_ROOT_PASSWORD=123456 -dt  mysql:5.7 --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci
```

进入mysql创建gogs数据库

```
create database gogs;
```

### 创建挂载目录

```
mkdir /data/gogs/
```

### 安装gogs

```
docker run -dt -p 10022:22 -p 13000:3000 --name=gogs --restart always --privileged=true -v /data/gogs/:/data gogs/gogs
```

### 打开浏览器初始化gogs

```
192.168.1.132:13000
```

### 若初始化配置有问题可修改配置文件

```
vi /data/gogs/gogs/conf/app.ini
```



## Git

### 安装后输入全局个人信息

```
git config --global user.name "HatChin"
```

```
git config --global user.email "ws1018ws@qq.com"
```

### 创建版本库

```
mkdir git
```

进入目录初始化git

```
cd git && git init
```

瞬间Git就把仓库建好了，而且告诉你是一个空的仓库（empty Git repository），可以发现当前目录下多了一个`.git`的目录，这个目录是Git来跟踪管理版本库的，没事千万不要手动修改这个目录里面的文件，不然改乱了，就把Git仓库给破坏了。

如果没有看到`.git`目录，那是因为这个目录默认是隐藏的，用`ls -ah`命令就可以看见。

### 把文件添加到版本库

编写一个`README.md`文件，一定要放到`git`目录下（子目录也行），因为这是一个Git仓库，放到其他地方Git再厉害也找不到这个文件。

和把大象放到冰箱需要3步相比，把一个文件放到Git仓库只需要两步。

#### 第一步，用命令`git add`告诉Git，把文件添加到仓库： 

```
git add README.md
```

#### 第二步，用命令`git commit`告诉Git，把文件提交到仓库：

```
git commit -m "wrote a README file"
```

`git commit`命令，`-m`后面输入的是本次提交的说明，可以输入任意内容，当然最好是有意义的，这样你就能从历史记录里方便地找到改动记录。 

打印

```
1 file changed, 1 insertion(+)
create mode 100644 README.md
```

`1 file changed`：1个文件被改动（我们新添加的README.md文件）；`1 insertions`：插入了1行内容（README.md有两行内容）。 

#### 注:

因为`commit`可以一次提交很多文件，所以你可以多次`add`不同的文件，所以Git添加文件需要`add`，`commit`一共两步。

例：

```
git add file1.txt
git add file2.txt file3.txt
git commit -m "add 3 files."
```

### 基本操作

上述已经提交了一个`README.md`文件

再次修改`README.md`

#### 运行`git status`命令查看结果 

```
git status
```

打印

```
On branch master
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git checkout -- <file>..." to discard changes in working directory)

	modified:   README.md

no changes added to commit (use "git add" and/or "git commit -a")
```

`git status`命令可以时刻掌握仓库当前的状态，上面的命令输出表明`README.md`被修改过了，但还没有准备提交的修改。

#### 运行`git diff`命令比对 

虽然Git告诉我们`README.md`被修改了，但如果能看看具体修改了什么内容，自然是很好的。比如你休假两周从国外回来，第一天上班时，已经记不清上次怎么修改的`README.md`，所以，需要用`git diff`这个命令看看：

```
git diff
```

`git diff`顾名思义就是查看difference，显示的格式正是Unix通用的diff格式，可以从上面的命令输出看到，我们在第一行添加了一个`distributed`单词。

知道了对`README.md`作了什么修改后，再把它提交到仓库就放心多了，提交修改和提交新文件是一样的两步。

第一步是`git add`：

```
git add README.md
```

第二步`git commit`之前，我们再运行`git status`看看当前仓库的状态： 

```
git status
```

打印

```
On branch master
Changes to be committed:
  (use "git reset HEAD <file>..." to unstage)

	modified:   README.md
```

`git status`告诉我们，将要被提交的修改包括`README.md`，下一步，就可以放心地提交了：

```
git commit -m "add distributed"
```

提交后，我们再用`git status`命令看看仓库的当前状态：

```
git status
```

打印



```
On branch master
nothing to commit, working tree clean
```

### 版本退回

修改`README.md`后进行add和commit

```
git add README.md
```

```
git commit -m "en"
```

像这样不断对文件进行修改，然后不断提交修改到版本库里，就好比玩RPG游戏时，每通过一关就会自动把游戏状态存盘，如果某一关没过去，你还可以选择读取前一关的状态。有些时候，在打Boss之前，你会手动存盘，以便万一打Boss失败了，可以从最近的地方重新开始。Git也是一样，每当你觉得文件修改到一定程度的时候，就可以“保存一个快照”，这个快照在Git中被称为`commit`。一旦你把文件改乱了，或者误删了文件，还可以从最近的一个`commit`恢复，然后继续工作，而不是把几个月的工作成果全部丢失。 

在实际工作中，我们脑子里怎么可能记得一个几千行的文件每次都改了什么内容，不然要版本控制系统干什么。版本控制系统肯定有某个命令可以告诉我们历史记录，在Git中，我们用`git log`命令查看 

#### 查看历史记录

```
git log
```

打印

```
commit 99a22a9319043968017b495d5bae2f87857c9642 (HEAD -> master)
Author: HatChin <ws1018ws@qq.com>
Date:   Tue May 28 16:27:44 2019 +0800

    minna

commit 92a0adda3881d778bdc5d2ebefc73d4358469520
Author: HatChin <ws1018ws@qq.com>
Date:   Tue May 28 16:26:13 2019 +0800

    add distributed
commit 08ce3f74fd7dd7499d0c2b83dab5f16c63257feb
Author: HatChin <ws1018ws@qq.com>
Date:   Tue May 28 16:19:38 2019 +0800

    zzz
```

[HEAD表示当前版本]

如果嫌信息太多可以选择

```
git log --pretty=oneline
```

打印

```
99a22a9319043968017b495d5bae2f87857c9642 (HEAD -> master) minna
92a0adda3881d778bdc5d2ebefc73d4358469520 add distributed
08ce3f74fd7dd7499d0c2b83dab5f16c63257feb zzz
2a668b97f388cf64fef14e47cf793af0aaa1a9b5 README.md
494d604c1658e625cfd5191899410a6cad81cfed en
412e52be596eaf1cda3651570e1deec5a2930482 jj
```

需要友情提示的是，你看到的一大串类似`1094adb...`的是`commit id`（版本号），和SVN不一样，Git的`commit id`不是1，2，3……递增的数字，而是一个SHA1计算出来的一个非常大的数字，用十六进制表示，而且你看到的`commit id`和我的肯定不一样，以你自己的为准。为什么`commit id`需要用这么一大串数字表示呢？因为Git是分布式的版本控制系统，后面我们还要研究多人在同一个版本库里工作，如果大家都用1，2，3……作为版本号，那肯定就冲突了。 

#### 回退到上上个版本，也就是`zzz`的那个版本 

`git`中`HEAD`为当前版本

```
git reset --hard HEAD~2
```

上述`HEAD`后面`~2`就代表是前两个版本，以此类推

查看历史记录

```
git log
```

发现已经回退

#### 从上上版本回到刚才的最新版本

该方法需要在刚才的控制台中找到原先最新版本的sha值

```
git reset --hard 99a22a9319043968017b495d5bae2f87857c9642
```

查看历史记录

```
git log
```

发现已经还原

若找不到刚才的sha值

可以使用命令

```
git reflog
```

打印

```
99a22a9 (HEAD -> master) HEAD@{0}: reset: moving to 99a22a9319043968017b495d5bae2f87857c9642
08ce3f7 HEAD@{1}: reset: moving to HEAD~2
99a22a9 (HEAD -> master) HEAD@{2}: commit: minna
92a0add HEAD@{3}: commit: add distributed
08ce3f7 HEAD@{4}: commit: zzz
2a668b9 HEAD@{5}: commit: README.md
494d604 HEAD@{6}: commit: en
412e52b HEAD@{7}: commit (initial): jj
```

Git的版本回退速度非常快，因为Git在内部有个指向当前版本的`HEAD`指针，当你回退版本的时候，Git仅仅是把HEAD指向不同版本： 

举例

```
┌────┐
│HEAD│
└────┘
   │
   └──> ○ version 3
        │
        ○ version 2
        │
        ○ version 1
```

修改指向

```
┌────┐
│HEAD│
└────┘
   │
   │    ○ version 3
   │    │
   └──> ○ version 2
        │
        ○ version 1
```

### 工作区和暂存区

#### 工作区(`Working Directory`)

就是你在电脑里能看到的目录，刚刚创建的`git`文件夹就是一个工作区

#### 暂存区(`Repository`)

工作区有一个隐藏目录`.git`，这个不算工作区，而是Git的版本库。

Git的版本库里存了很多东西，其中最重要的就是称为stage（或者叫index）的暂存区，还有Git为我们自动创建的第一个分支`master`，以及指向`master`的一个指针叫`HEAD`。

我们把文件往Git版本库里添加的时候，是分两步执行的：

第一步是用`git add`把文件添加进去，实际上就是把文件修改添加到暂存区；

第二步是用`git commit`提交更改，实际上就是把暂存区的所有内容提交到当前分支。

因为我们创建Git版本库时，Git自动为我们创建了唯一一个`master`分支，所以，现在，`git commit`就是往`master`分支上提交更改。

你可以简单理解为

```
需要提交的文件修改通通放到暂存区，然后，一次性提交暂存区的所有修改。
```

##### 实践

###### 修改`README.md`并且创建`LICENSE`(内容随便写)

###### 查看状态

```
git status
```

打印

```
On branch master
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git checkout -- <file>..." to discard changes in working directory)

        modified:   README.md

Untracked files:
  (use "git add <file>..." to include in what will be committed)

        LICENSE

no changes added to commit (use "git add" and/or "git commit -a")
```

Git非常清楚地告诉我们，`README.md`被修改了，而`LICENSE`还从来没有被添加过，所以它的状态是`Untracked`。

###### 添加后再查看

现在，使用两次命令`git add`，把`README.md`和`LICENSE`都添加后，用`git status`再查看一下：

 ```
git add README.md LICENSE
 ```

```
git status
```

###### 提交到分支

`git add`命令实际上就是把要提交的所有修改放到暂存区（Stage），然后，执行`git commit`就可以一次性把暂存区的所有修改提交到分支。 

```
git commit -m "Cao"
```

###### 查看状态

```
git status
```

打印

```
On branch master
nothing to commit, working tree clean
```

### 修改和撤销修改

#### 修改

修改完后执行`git add`后便将文件放入缓存区等待提交，所以`git add`后再进行修改的话就需要再次`git add`。不然再次修改的结果不会被提交至分支，因为第二次修改后没有进行`git add`放入缓存区。 

第一次修改 -> `git add` -> 第二次修改 -> `git add` -> `git commit` 

#### 撤销修改

在`README.md` 中误加一条`shabi`

##### git add之前

删掉`shabi`一条

###### 查看

```
git status
```

打印

```
On branch master
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git checkout -- <file>..." to discard changes in working directory)

        modified:   README.md

no changes added to commit (use "git add" and/or "git commit -a")
```

###### 丢弃工作区的修改可以使用命令

```
git checkout -- README.md
```

###### 两种情况

命令`git checkout -- README.md`意思就是，把`README.md`文件在工作区的修改全部撤销，这里有两种情况：

一种是`README.md`自修改后还没有被放到暂存区，现在，撤销修改就回到和版本库一模一样的状态；

一种是`README.md`已经添加到暂存区后，又作了修改，现在，撤销修改就回到添加到暂存区后的状态。

总之，就是让这个文件回到最近一次`git commit`或`git add`时的状态。

###### 注：

`git checkout -- file`命令中的`--`很重要，没有`--`，就变成了“切换到另一个分支”的命令。

##### git add之后

```
git add README.md
```

###### 查看

```
git status
```

打印

```
On branch master
Changes to be committed:
  (use "git reset HEAD <file>..." to unstage)

        modified:   README.md
```

###### 撤销缓存区的提交可以使用命令

```
git reset HEAD README.md
```

打印

```
Unstaged changes after reset:
M       README.md
```

`git reset`命令既可以回退版本，也可以把暂存区的修改回退到工作区。当我们用`HEAD`时，表示最新的版本。

###### 查看

```
git status
```

打印

```
On branch master
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git checkout -- <file>..." to discard changes in working directory)

        modified:   README.md

no changes added to commit (use "git add" and/or "git commit -a")
```

###### 丢弃工作区的修改可以使用命令

```
git checkout -- README.md
```

###### 查看

```
git status
```

打印

```
On branch master
nothing to commit, working tree clean
```

### 删除文件

先添加一个`test`文件并提交

```
touch test
```

```
git add test
```

```
git commit -m "delete"
```

#### 删除

一般情况下，通常直接在文件管理器中把没用的文件删了，或者用`rm`命令删了。

```
rm -rf test
```

但Git知道有文件被删除了，造成工作区和版本库不一致了。

使用`git status`命令会立刻提示出哪些文件被删除了 

```
git status
```

打印

```
On branch master
Changes not staged for commit:
  (use "git add/rm <file>..." to update what will be committed)
  (use "git checkout -- <file>..." to discard changes in working directory)

        deleted:    test
        
no changes added to commit (use "git add" and/or "git commit -a")
```

##### git删除

```
git rm test
```

##### 误删

误删可以使用其恢复

```
git checkout -- test
```

### 远程仓库

#### SSH互信

##### 步骤一

```
ssh-keygen -t rsa -C "ws1018ws@qq.com"
```

之后一路回车

如果一切顺利的话，可以在用户主目录里找到`.ssh`目录，里面有`id_rsa`和`id_rsa.pub`两个文件，这两个就是SSH Key的秘钥对，`id_rsa`是私钥，不能泄露出去，`id_rsa.pub`是公钥，可以放心地告诉任何人 

##### 步骤二

进入GOGS的“SSH Keys”页面。然后，点“Add SSH Key”，填上任意Title，在Key文本框里粘贴`id_rsa.pub`文件的内容：

#### 关联本地仓库和远程仓库

```
git remote add origin http://39.105.150.112:33000/Fuck_Girl/cao.git
```

#### 把本地库的所有内容推送到远程库

```
git push -u origin master
```

`git push`命令，实际上是把当前本地`master`分支推送到远程 

由于远程库是空的，我们第一次推送`master`分支时，加上了`-u`参数，Git不但会把本地的`master`分支内容推送的远程新的`master`分支，还会把本地的`master`分支和远程的`master`分支关联起来，在以后的推送或者拉取时就可以简化命令。 

#### 第一次push成功后便可以使用

```
git push origin master
```

把本地`master`分支的最新修改推送至GitHub 

####  从远程库克隆

```
git clone http://39.105.150.112:33000/Fuck_Girl/clone.git
```

### 分支管理

#### 创建与合并分支

##### 创建

创建`dev`分支，然后切换到`dev`分支

```
git checkout -b dev
```

`git checkout`命令加上`-b`参数表示创建并切换，相当于以下两条命令 

```
git branch dev
```

```
git checkout dev
```

注：`git branch`命令会列出所有分支，当前分支前面会标一个`*`号 

修改`README.md`并提交

```
git add README.md
```

```
git commit -m "gan"
```

##### 查看分支区别

切换回`master`分支

```
git checkout master
```

查看`README.md`文件

发现内容未被修改

##### 合并

```
git merge dev
```

打印

```
Updating 8dc0fc2..7fef8ee
Fast-forward
 README.md | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)
```

`git merge`命令用于***合并指定分支到当前分支***。合并后，再查看README.md的内容，就可以看到，和`dev`分支的最新提交是完全一样的。

注意到上面的`Fast-forward`信息，Git告诉我们，这次合并是“快进模式”，也就是直接把`master`指向`dev`的当前提交，所以合并速度非常快。

合并完成后，就可以放心地删除`dev`分支了 

###### 删除分支

```
git branch -d dev
```

因为创建、合并和删除分支非常快，所以Git鼓励你使用分支完成某个任务，合并后再删掉分支，这和直接在`master`分支上工作效果是一样的，但过程更安全。 

#### 解决冲突

##### 创建并切换分支

```
git checkout -b jb
```

修改`README.md`最后一行并提交

```
git add README.md
```

```
git commit -m "jb"
```

##### 切换到`master`分支

```
git checkout master
```

打印出

```
Switched to branch 'master'
Your branch is ahead of 'origin/master' by 1 commit.
  (use "git push" to publish your local commits)
```

Git还会自动提示我们当前`master`分支比远程的`master`分支要超前1个提交。 

修改`README.md`并提交

```
git add README.md
```

```
git commit -m "CAOCAOCAO"
```

##### 现在，`master`分支和`feature1`分支各自都分别有新的提交。这种情况下，Git无法执行“快速合并”，只能试图把各自的修改合并起来，但这种合并就可能会有冲突。

##### 测试

###### 合并

```
git merge jb
```

打印

```
Auto-merging README.md
CONFLICT (content): Merge conflict in README.md
Automatic merge failed; fix conflicts and then commit the result.
```

###### 果然冲突了！Git告诉我们，`readme.md`文件存在冲突，必须手动解决冲突后再提交。`git status`也可以告诉我们冲突的文件 

```
git status
```

打印

```
On branch master
Your branch is ahead of 'origin/master' by 2 commits.
  (use "git push" to publish your local commits)

You have unmerged paths.
  (fix conflicts and run "git commit")
  (use "git merge --abort" to abort the merge)

Unmerged paths:
  (use "git add <file>..." to mark resolution)

        both modified:   README.md

no changes added to commit (use "git add" and/or "git commit -a")
```

###### 直接查看readme.md内容

```
cat readme.md
```

打印

```
# clone
<<<<<<< HEAD
cco
333
=======
cbo
331
>>>>>>> jb
```

Git用`<<<<<<<`，`=======`，`>>>>>>>`标记出不同分支的内容

###### 修改`readme.md`后保存并提交

```
git add README.md
```

```
git commit -m "PPP"
```

###### 用带参数的`git log`也可以看到分支的合并情况 

```
git log --graph --pretty=oneline --abbrev-commit
```

##### 注:

当Git无法自动合并分支时，就必须首先解决冲突。解决冲突后，再提交，合并完成。

解决冲突就是把Git合并失败的文件手动编辑为我们希望的内容，再提交。

#### 分支管理策略

通常，合并分支时，如果可能，Git会用`Fast forward`模式，但这种模式下，删除分支后，会丢掉分支信息。

如果要强制禁用`Fast forward`模式，Git就会在merge时生成一个新的commit，这样，从分支历史上就可以看出分支信息。

##### 使用`--no-ff`方式的`git merge` 

###### 创建并切换`dev`分支 

```
git checkout -b dev
```

###### 修改readme.md文件，并提交一个新的commit 

```
git add README.md
```

```
git commit -m "test"
```

###### 切换回`master` 

```
git checkout master
```

###### 合并`dev`分支，--no-ff`参数就表示禁用`Fast forward`： 

```
git merge --no-ff -m "merge with no-ff" dev
```

因为本次合并要创建一个新的commit，所以加上`-m`参数，把commit描述写进去

###### 查看合并历史

```
git log --graph --pretty=oneline --abbrev-commit
```

#### Bug分支

Git提供了一个`stash`功能，可以把当前工作现场“储藏”起来，等以后恢复现场后继续工作。

```
git stash
```

##### 首先确定要在哪个分支上修复bug，假定需要在`master`分支上修复，就从`master`创建临时分支。

```
git checkout master
```

```
git checkout -b bug
```

##### 修改readme.md文件，并提交一个新的commit 

```
git add README.md
```

```
git commit -m "fast"
```

##### 切回master

```
git checkout master
```

##### 合并bug分支

```
git merge --no-ff -m "debug" bug
```

##### 回到`dev`分支工作

```
git checkout dev
```

```
git status
```

##### 用`git stash list`命令查看

```
git stash list
```

工作现场还在，Git把stash内容存在某个地方了，但是需要恢复一下。

###### 步骤一:

是用`git stash apply`恢复，但是恢复后，stash内容并不删除。

```
git stash apply
```

###### 步骤二：

你需要用`git stash drop`来删除。

```
git stash drop
```

###### 或者直接用`git stash pop `恢复并删除

```
git stash pop
```

再用`git stash list `便看不到内容了

```
git stash list
```

多次stash，恢复的时候，先用`git stash list`查看，然后恢复指定的stash

```
git stash apply stash@{0}
```

#### Feature分支

软件开发中，总有无穷无尽的新的功能要不断添加进来。

添加一个新功能时，你肯定不希望因为一些实验性质的代码，把主分支搞乱了，所以，每添加一个新功能，最好新建一个feature分支，在上面开发，完成后，合并，最后，删除该feature分支。

现在，你终于接到了一个新任务：开发代号为Vulcan的新功能，该功能计划用于下一代星际飞船。

##### 于是准备开发：

```
git checkout -b feature-vulcan
```

##### 5分钟后，开发完毕：

```
git add vulcan.py
```

```
git status
```

打印

```
On branch feature-vulcan
Changes to be committed:
  (use "git reset HEAD <file>..." to unstage)

	new file:   vulcan.py
```



```
git commit -m "add feature vulcan"
```

打印

```
[feature-vulcan 287773e] add feature vulcan
 1 file changed, 2 insertions(+)
 create mode 100644 vulcan.py
```

##### 切回`dev`，准备合并：

```
git checkout dev
```

一切顺利的话，feature分支和bug分支是类似的，合并，然后删除。

但是！

就在此时，接到上级命令，因经费不足，新功能必须取消！

虽然白干了，但是这个包含机密资料的分支还是必须就地销毁：

```
git branch -d feature-vulcan
```

打印

```
error: The branch 'feature-vulcan' is not fully merged.
If you are sure you want to delete it, run 'git branch -D feature-vulcan'.
```

销毁失败。Git友情提醒，`feature-vulcan`分支还没有被合并，如果删除，将丢失掉修改，如果要强行删除，需要使用大写的`-D`参数。。

现在我们强行删除：

##### 强行删除

```
git branch -D feature-vulcan
```

打印

```
Deleted branch feature-vulcan (was 287773e).
```

终于删除成功！

#### 多人协作

当你从远程仓库克隆时，实际上Git自动把本地的`master`分支和远程的`master`分支对应起来了，并且，远程仓库的默认名称是`origin`。

##### 查看远程库的信息

```
git remote
```

或者，用`git remote -v`显示更详细的信息： 

```
git remote -v
```

上面显示了可以抓取和推送的`origin`的地址。如果没有推送权限，就看不到push的地址。 

##### 推送分支

推送分支，就是把该分支上的所有本地提交推送到远程库。推送时，要指定本地分支，这样，Git就会把该分支推送到远程库对应的远程分支上 

```
git push origin master
```

如果要推送其他分支，比如`dev`，就改成： 

```
git push origin dev                                                                             
```

##### 抓取分支

多人协作时，大家都会往`master`和`dev`分支上推送各自的修改。

现在，模拟一个你的小伙伴，可以在另一台电脑（注意要把SSH Key添加到GitHub）或者同一台电脑的另一个目录下克隆：

```
git clone http://39.105.150.112:33000/Fuck_Girl/clone.git
```

现在，你的小伙伴要在`dev`分支上开发，就必须创建远程`origin`的`dev`分支到本地，于是他用这个命令创建本地`dev`分支： 

```
git checkout -b dev origin/dev
```

现在，他就可以在`dev`上继续修改，然后，时不时地把`dev`分支`push`到远程： 

```
git add fuck
```

```
git commit -m "add jb"
```

```
git push origin dev
```

你的小伙伴已经向`origin/dev`分支推送了他的提交，而碰巧你也对同样的文件作了修改，并试图推送： 

```
git add fuck
```

```
git commit -m "add jb2"
```

```
git push origin dev
```

打印

```
To http://39.105.150.112:33000/Fuck_Girl/clone.git
 ! [rejected]        dev -> dev (fetch first)
error: failed to push some refs to 'http://39.105.150.112:33000/Fuck_Girl/clone.git'
hint: Updates were rejected because the remote contains work that you do
hint: not have locally. This is usually caused by another repository pushing
hint: to the same ref. You may want to first integrate the remote changes
hint: (e.g., 'git pull ...') before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.

```

推送失败，因为你的小伙伴的最新提交和你试图推送的提交有冲突，解决办法也很简单，Git已经提示我们，先用`git pull`把最新的提交从`origin/dev`抓下来，然后，在本地合并，解决冲突，再推送：

 ```
git pull
 ```

打印

```
remote: Enumerating objects: 4, done.
remote: Counting objects: 100% (4/4), done.
remote: Compressing objects: 100% (2/2), done.
remote: Total 3 (delta 0), reused 0 (delta 0)
Unpacking objects: 100% (3/3), done.
From http://39.105.150.112:33000/Fuck_Girl/clone
   0c03db8..08a2fc8  dev        -> origin/dev
There is no tracking information for the current branch.
Please specify which branch you want to merge with.
See git-pull(1) for details.

    git pull <remote> <branch>

If you wish to set tracking information for this branch you can do so with:

    git branch --set-upstream-to=origin/<branch> dev
```

`git pull`也失败了，原因是没有指定本地`dev`分支与远程`origin/dev`分支的链接，根据提示，设置`dev`和`origin/dev`的链接。

关联本地dev与远程仓库

```
git branch --set-upstream-to=origin/dev dev
```

再pull 

```
git pull
```

这回`git pull`成功，但是合并有冲突，需要手动解决，解决的方法和分支管理中的[解决冲突](http://www.liaoxuefeng.com/wiki/896043488029600/900004111093344)完全一样。解决后，提交，再push。

```
git status
```

打印

```
On branch dev
Your branch and 'origin/dev' have diverged,
and have 1 and 1 different commits each, respectively.
  (use "git pull" to merge the remote branch into yours)

You have unmerged paths.
  (fix conflicts and run "git commit")
  (use "git merge --abort" to abort the merge)

Unmerged paths:
  (use "git add <file>..." to mark resolution)

        both added:      fuck

no changes added to commit (use "git add" and/or "git commit -a")
```

直接查看fuck内容

```
cat fuck
```

打印

```
<<<<<<< HEAD
cao
=======
jb
>>>>>>> 08a2fc8af4a39a893afa68a6227c59c75bbf035e
```

Git用`<<<<<<<`，`=======`，`>>>>>>>`标记出不同分支的内容

修改`fuck`后保存并提交

```
git add fuck
```

```
git commit -m "PPP"
```

推送

```
 git push origin dev
```

#### Rebase

多人在同一个分支上协作时，很容易出现冲突。即使没有冲突，后push的童鞋不得不先pull，在本地合并，然后才能push成功。

每次合并再push后，分支变成了这样：

```
git log --graph --pretty=oneline --abbrev-commit
```

打印

```
* d1be385 (HEAD -> master, origin/master) init hello
*   e5e69f1 Merge branch 'dev'
|\  
| *   57c53ab (origin/dev, dev) fix env conflict
| |\  
| | * 7a5e5dd add env
| * | 7bd91f1 add new env
| |/  
* |   12a631b merged bug fix 101
|\ \  
| * | 4c805e2 fix bug 101
|/ /  
* |   e1e9c68 merge with no-ff
|\ \  
| |/  
| * f52c633 add merge
|/  
*   cf810e4 conflict fixed
```

总之看上去很乱，有强迫症的童鞋会问：为什么Git的提交历史不能是一条干净的直线？

其实是可以做到的！

Git有一种称为rebase的操作，有人把它翻译成“变基”。

在和远程分支同步后，我们对`hello.py`这个文件做了两次提交。用`git log`命令看看： 

```
git log --graph --pretty=oneline --abbrev-commit
```

打印

```
* 582d922 (HEAD -> master) add author
* 8875536 add comment
* d1be385 (origin/master) init hello
*   e5e69f1 Merge branch 'dev'
|\  
| *   57c53ab (origin/dev, dev) fix env conflict
| |\  
| | * 7a5e5dd add env
| * | 7bd91f1 add new env
...
```

注意到Git用`(HEAD -> master)`和`(origin/master)`标识出当前分支的HEAD和远程origin的位置分别是`582d922 add author`和`d1be385 init hello`，本地分支比远程分支快两个提交。

现在我们尝试推送本地分支：

```
git push origin master
```

打印

```
To github.com:michaelliao/learngit.git
 ! [rejected]        master -> master (fetch first)
error: failed to push some refs to 'git@github.com:michaelliao/learngit.git'
hint: Updates were rejected because the remote contains work that you do
hint: not have locally. This is usually caused by another repository pushing
hint: to the same ref. You may want to first integrate the remote changes
hint: (e.g., 'git pull ...') before pushing again.
hint: See the 'Note about fast-forwards' in 'git push --help' for details.
```

很不幸，失败了，这说明有人先于我们推送了远程分支。按照经验，先pull一下：

 ```
git pull
 ```

查看状态

```
git status
```

打印

```
On branch master
Your branch is ahead of 'origin/master' by 3 commits.
  (use "git push" to publish your local commits)

nothing to commit, working tree clean
```

加上刚才合并的提交，现在我们本地分支比远程分支超前3个提交。 

用`git log`查看 

```
git log --graph --pretty=oneline --abbrev-commit
```

打印

```
*   e0ea545 (HEAD -> master) Merge branch 'master' of github.com:michaelliao/learngit
|\  
| * f005ed4 (origin/master) set exit=1
* | 582d922 add author
* | 8875536 add comment
|/  
* d1be385 init hello
...
```

对强迫症童鞋来说，现在事情有点不对头，提交历史分叉了。如果现在把本地分支push到远程，有没有问题？

有！

什么问题？

不好看！

有没有解决方法？

有！

这个时候，rebase就派上了用场。我们输入命令`git rebase`试试：

```
$ git rebase
First, rewinding head to replay your work on top of it...
Applying: add comment
Using index info to reconstruct a base tree...
M	hello.py
Falling back to patching base and 3-way merge...
Auto-merging hello.py
Applying: add author
Using index info to reconstruct a base tree...
M	hello.py
Falling back to patching base and 3-way merge...
Auto-merging hello.py
```

输出了一大堆操作，到底是啥效果？再用`git log`看看：

```
$ git log --graph --pretty=oneline --abbrev-commit
* 7e61ed4 (HEAD -> master) add author
* 3611cfe add comment
* f005ed4 (origin/master) set exit=1
* d1be385 init hello
...
```

原本分叉的提交现在变成一条直线了！这种神奇的操作是怎么实现的？其实原理非常简单。我们注意观察，发现Git把我们本地的提交“挪动”了位置，放到了`f005ed4 (origin/master) set exit=1`之后，这样，整个提交历史就成了一条直线。rebase操作前后，最终的提交内容是一致的，但是，我们本地的commit修改内容已经变化了，它们的修改不再基于`d1be385 init hello`，而是基于`f005ed4 (origin/master) set exit=1`，但最后的提交`7e61ed4`内容是一致的。

这就是rebase操作的特点：把分叉的提交历史“整理”成一条直线，看上去更直观。缺点是本地的分叉提交已经被修改过了。

最后，通过push操作把本地分支推送到远程：

```
Mac:~/learngit michael$ git push origin master
Counting objects: 6, done.
Delta compression using up to 4 threads.
Compressing objects: 100% (5/5), done.
Writing objects: 100% (6/6), 576 bytes | 576.00 KiB/s, done.
Total 6 (delta 2), reused 0 (delta 0)
remote: Resolving deltas: 100% (2/2), completed with 1 local object.
To github.com:michaelliao/learngit.git
   f005ed4..7e61ed4  master -> master
```

再用`git log`看看效果：

```
$ git log --graph --pretty=oneline --abbrev-commit
* 7e61ed4 (HEAD -> master, origin/master) add author
* 3611cfe add comment
* f005ed4 set exit=1
* d1be385 init hello
...
```

远程分支的提交历史也是一条直线。

### 标签

#### 创建标签

##### 切换到需要打标签的分支上 

```
git checkout master 
```

##### 使用命令`git tag <name>`就可以打一个新标签

```
git tag v1.0
```

##### 可以用命令`git tag`查看所有标签

```
git tag
```

##### 注:默认标签是打在最新提交的commit上的。[HEAD]

有时候，如果忘了打标签，比如，现在已经是周五了，但应该在周一打的标签没有打，怎么办？ 

```
方法是找到历史提交的commit id，然后打上标签
```

```
git log --pretty=oneline --abbrev-commit
```

```
git tag v0.9 1187388
```

##### 查看标签 

```
git tag
```

打印

```
v0.9
v1.0
```

##### 注:

注意，标签不是按时间顺序列出，而是按字母排序的。

##### 可以用`git show <tagname>`查看标签信息 

```
git show v0.9
```

打印

```
commit 11873883db2194ae130cf24611cee28e3b8f8af1 (tag: v0.9)
Merge: 6326ad3 fd26d3c
Author: HatChin <ws1018ws@qq.com>
Date:   Tue Jun 4 13:48:23 2019 +0800

    merge with no-ff
```

可以看到，`v0.9`确实打在`merge with no-ff`次提交上。

还可以创建带有说明的标签，用`-a`指定标签名，`-m`指定说明文字：

```
git tag -a v0.1 -m "JB" 5a61c1e
```

用命令`git show <tagname>`可以看到说明文字：

```
git show v0.1
```

打印

```
tag v0.1
Tagger: HatChin <ws1018ws@qq.com>
Date:   Tue Jun 4 16:15:45 2019 +0800

JB

commit 5a61c1ef2dcefd0943d64846c97efcb65b2da25c (tag: v0.1)
Author: HatChin <ws1018ws@qq.com>
Date:   Mon Jun 3 14:15:07 2019 +0800

    3333

diff --git a/README.md b/README.md
index 6b7aaf8..3049562 100644
--- a/README.md
+++ b/README.md
@@ -1,3 +1,3 @@
 # clone
-cao
-123
+cbo
+331
```

#### 操作标签

如果标签打错了，也可以删除 

```
git tag -d v0.1
```

因为创建的标签都只存储在本地，不会自动推送到远程。所以，打错的标签可以在本地安全删除。 

##### 如果要推送某个标签到远程，使用命令`git push origin <tagname>`

```
git push origin v1.0
```

打印

```
Total 0 (delta 0), reused 0 (delta 0)
To github.com:michaelliao/learngit.git
 * [new tag]         v1.0 -> v1.0
```

##### 一次性推送全部尚未推送到远程的本地标签

```
git push origin --tags
```

##### 如果标签已经推送到远程，要删除远程标签就麻烦一点，先从本地删除

```
git tag -d v0.9
```

##### 然后，从远程删除。删除命令也是push，但是格式如下

```
git push origin :refs/tags/v0.9
```

打印

```
To http://39.105.150.112:33000/Fuck_Girl/clone.git
 - [deleted]         v0.9
```

### 忽略特殊文件

有些时候，你必须把某些文件放到Git工作目录中，但又不能提交它们，比如保存了数据库密码的配置文件啦，等等，每次`git status`都会显示`Untracked files ...`，有强迫症的童鞋心里肯定不爽。

好在Git考虑到了大家的感受，这个问题解决起来也很简单，在Git工作区的根目录下创建一个特殊的`.gitignore`文件，然后把要忽略的文件名填进去，Git就会自动忽略这些文件。

```
touch .gitignore
```

不需要从头写`.gitignore`文件，GitHub已经为我们准备了各种配置文件，只需要组合一下就可以使用了。所有配置文件可以直接在线浏览：<https://github.com/github/gitignore>

忽略文件的原则是：

1. 忽略操作系统自动生成的文件，比如缩略图等；
2. 忽略编译生成的中间文件、可执行文件等，也就是如果一个文件是通过另一个文件自动生成的，那自动生成的文件就没必要放进版本库，比如Java编译产生的`.class`文件；
3. 忽略你自己的带有敏感信息的配置文件，比如存放口令的配置文件。

举个例子：

假设你在Windows下进行Python开发，Windows会自动在有图片的目录下生成隐藏的缩略图文件，如果有自定义目录，目录下就会有`Desktop.ini`文件，因此你需要忽略Windows自动生成的垃圾文件：

```
# Windows:
Thumbs.db
ehthumbs.db
Desktop.ini
```

然后，继续忽略Python编译产生的`.pyc`、`.pyo`、`dist`等文件或目录：

```
# Python:
*.py[cod]
*.so
*.egg
*.egg-info
dist
build
```

加上你自己定义的文件，最终得到一个完整的`.gitignore`文件，内容如下：

```
# Windows:
Thumbs.db
ehthumbs.db
Desktop.ini

# Python:
*.py[cod]
*.so
*.egg
*.egg-info
dist
build

# My configurations:
db.ini
deploy_key_rsa
```

最后一步就是把`.gitignore`也提交到Git，就完成了！当然检验`.gitignore`的标准是`git status`命令是不是说`working directory clean`。

有些时候，你想添加一个文件到Git，但发现添加不了，原因是这个文件被`.gitignore`忽略了

举例：

```
git add App.class
```

打印

```
The following paths are ignored by one of your .gitignore files:
App.class
Use -f if you really want to add them.
```

如果你确实想添加该文件，可以用`-f`强制添加到Git： 

```
git add -f App.class
```

或者你发现，可能是`.gitignore`写得有问题，需要找出来到底哪个规则写错了，可以用`git check-ignore`命令检查：

```
git check-ignore -v App.class
```





参考教程

```
https://www.liaoxuefeng.com/wiki/896043488029600
```





















