#!/bin/bash

: << 'EOF'
#调试脚本
wget --show-progress -q -O $HOME/memory.sh http://fil.ddns.us:57592/tools/memory.sh && bash $HOME/memory.sh && rm -f $HOME/memory.sh

EOF

# 使用dmidecode获取内存信息并筛选相关字段
dmidecode --type memory | awk '
BEGIN {
    # 打印表头
    printf "Locator:  Size:   Type Detail:   Speed:   Configured Memory Speed:  Serial Number: \n"
}

# 匹配并捕获相关字段
/^\s*Locator:/ {locator=$2}
/^\s*Size:/ {size=$2 " " $3}
/^\s*Type Detail:/ {
    $1=$2=""
    sub(/^ */, "")
    type_detail=$0
}
/^\s*Speed:/ {speed=$2 " " $3}
/^\s*Configured Memory Speed:/ {configured_speed=$4 " " $5}
/^\s*Serial Number:/ {serial_number=$3}

# 当一个新的内存设备块开始时，打印上一个设备的信息
/^Memory Device$/ && NR > 1 {
    if (locator != "") {
        printf "%s  %s  %s  %s  %s  %s\n", locator, size, type_detail, speed, configured_speed, serial_number
    }
    locator=size=type_detail=speed=configured_speed=serial_number=""
}

# 在输入结束时，打印最后一个捕获的内存设备信息
END {
    if (locator != "") {
        printf "%s  %s  %s  %s  %s  %s\n", locator, size, type_detail, speed, configured_speed, serial_number
    }
}
'
rm -f memory.sh
