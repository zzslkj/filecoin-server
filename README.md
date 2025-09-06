# filecoin-server

## 安装与更新

### 安装

```bash

#在 down 文件夹的父目录下执行：
git clone --depth 1 https://github.com/zzslkj/filecoin-server.git down-temp
#这个方法只执行一次，只下载最新的文件，不包含 .git 文件夹和历史记录。
# --depth 1：只克隆最新一次提交（Commit）的历史，大大减少下载量。
# down-temp：先克隆到一个临时文件夹，避免冲突。

#然后，将文件复制到你的 down 文件夹：
# 复制临时文件夹里的所有文件(不包括.git文件夹)到你的down目录
cp -r down-temp/. down/ # Linux/macOS/Git Bash
```

### 更新

```bash
# 到 down-temp 目录 更新文件
git fetch --depth 1 origin # 获取最新信息（可省略，因为pull已经fetch过了）
git reset --hard origin/master #【核心】强制将本地分支重置到远程分支的状态
git status # 查看状态，确认已经是最新
```

## 初始化

- 首次下载需要执行初始化脚本

```bash
# 初始化该工作目录的配置文件
bash setup.sh

```
