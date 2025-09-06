#!/bin/bash

# 获取当前路径
CURRENT_DIR=$(dirname "$(realpath "$0")")
PARENT_DIR="${CURRENT_DIR%/*}"
FILE_NAME=check_miner

# 结束已运行的 $FILE_NAME.sh 进程
if pgrep -f "$FILE_NAME.sh" > /dev/null; then
    echo "正在结束已运行的 $FILE_NAME.sh 进程..."
    pkill -f "$FILE_NAME.sh"
    sleep 1  # 等待进程结束
fi

# 启动脚本
echo "$(date +"%F %H:%M:%S") clear log..."
nohup "$(dirname "$(realpath "$0")")/$FILE_NAME.sh" &> /dev/null &
echo "$FILE_NAME.sh 已启动。"
exit
