#!/bin/bash
FILE_NAME=check_miner
# 结束已运行的 $FILE_NAME.sh 进程
if pgrep -f "$FILE_NAME.sh" > /dev/null; then
    echo "正在结束已运行的 $FILE_NAME.sh 进程..."
    pkill -f "$FILE_NAME.sh"
    sleep 1  # 等待进程结束
fi
