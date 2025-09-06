#!/bin/bash

: << 'EOF'
#调试脚本
wget --show-progress -q -O $HOME/check-nvidia-gpu.sh http://fil.ddns.us:57592/tools/check-nvidia-gpu.sh && bash $HOME/check-nvidia-gpu.sh && rm -f $HOME/check-nvidia-gpu.sh

EOF
cd $HOME
# 使用 nvidia-smi 获取 GPU 信息 只显示结果
gpu_info=$(nvidia-smi | grep '000000')
gpu_ids=$(echo "$gpu_info" | awk -F '|' '{print $3}' | awk '{print substr($1, 10, 7)}')
for id in $gpu_ids; do
    slot_info=$(sudo dmidecode -t slot | grep -B 9 -i "Bus Address: 0000:$id")
    designation=$(echo "$slot_info" | grep 'Designation' | awk -F ': ' '{print $2}')
    if [ -n "$designation" ]; then
        echo "GPU Bus ID 0000:$id 位于插槽: $designation"
    else
        echo "未找到 GPU Bus ID 0000:$id 的插槽信息"
    fi
done
