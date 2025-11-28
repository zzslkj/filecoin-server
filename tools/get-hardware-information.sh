#!/bin/bash
# 收集本机硬件信息
# bash $HOME/get-hardware-information.sh IP name (IP可选、name可选 默认为down)
# 会挂载nfs路径 IP/name

: << 'EOF'
# 运行硬件信息收集工作
wget --show-progress -q -O $HOME/get-hardware-information.sh http://hd.kenny.us.kg:57592/tools/get-hardware-information.sh && bash $HOME/get-hardware-information.sh && rm -f $HOME/get-hardware-information.sh

# 运行硬件信息收集工作 写入NFS共享服务器 172.20.1.248:/filecoin/down
export WEB_SERVER_IP=jump.ddns.us:57592 # HK-jump2025
wget --show-progress -q -O $HOME/get-hardware-information.sh http://$WEB_SERVER_IP/bash/get-hardware-information.sh && bash $HOME/get-hardware-information.sh 172.20.1.248 && rm -f $HOME/get-hardware-information.sh

#只本地显示
export WEB_SERVER_IP=jump.ddns.us:57592 # HK-jump2025
wget --show-progress -q -O $HOME/get-hardware-information.sh http://$WEB_SERVER_IP/bash/get-hardware-information.sh && bash $HOME/get-hardware-information.sh && rm -f $HOME/get-hardware-information.sh

EOF

# 设置 NFS共享路径所在服务器IP
export NFS_SERVER_IP=$1

# 检查 NFS_SERVER_IP 是否设置
#if [ -z "$NFS_SERVER_IP" ]; then
#    echo "Error: ❌ 必须设置 NFS_SERVER_IP 环境变量！" >&2
#    exit 1
#fi

# 可选变量 NFS共享路径的名字 
if [ -n "$NFS_SERVER_IP" ]; then
    export NFS_SERVER_PATH="${2:-down}"
    export OUTPUT_PATH=/mnt/$NFS_SERVER_IP/$NFS_SERVER_PATH
    export OUTPUT_FILE="system_hardware_info.txt"
fi

# 记录日志函数
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1"
    #echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"
}


# 收集硬件信息
get_hardware() {

    # 获取主机名
    hostname=$(hostname | tr -d '[:space:]')

    # 获取服务器型号
    MOBO_MODEL=$(cat /sys/class/dmi/id/product_name)

    # 获取机器码
    current_serial=$(dmidecode -s system-serial-number)

    # 获取完整的CPU信息
    CPU_FULL=$(lscpu | grep "Model name:" | awk -F ': ' '{print $2}')

    # 提取CPU型号的关键部分（假设关键部分在第三个字段）
    CPU_MODEL=$(echo $CPU_FULL | awk '{print $3}')

    # 获取单路还是双路 CPU
    CPU_COUNT=$(lscpu | grep "^Socket(s):" | awk '{print $2}')
    if [ "$CPU_COUNT" -eq 1 ]; then
        CPU_CONFIG="x1"
    else
        CPU_CONFIG="x2"
    fi

    # 获取内存信息
    memory_info=$(dmidecode --type memory | awk '
        BEGIN {
            delete size_count
            delete type_count  
            delete speed_count
            total_count = 0
            total_capacity = 0  # 新增：总容量统计
        }

        /^\s*Size:/ && $2 != "No" { 
            size = $2 "G"
            size_count[size]++
            has_memory = 1
            
            # 新增：累加总容量（转换为GB）
            if ($3 == "GB") {
                total_capacity += $2
            } else if ($3 == "MB") {
                total_capacity += $2 / 1024
            } else if ($3 == "TB") {
                total_capacity += $2 * 1024
            }
        }
        
        /^\s*Type Detail:/ {
            $1=$2=""
            sub(/^ */, "")
            type_detail = $0
            
            if (type_detail ~ /LRDIMM/) {
                type_count["LRDIMM"]++
            } else if (type_detail ~ /Registered/ || type_detail ~ /Buffered/) {
                type_count["Registered"]++
            } else if (type_detail ~ /Unbuffered/) {
                type_count["Unbuffered"]++
            } else if (type_detail != "None" && has_memory) {
                type_count["Other"]++
            }
        }
        
        # 捕获速度信息
        /^\s*Configured Memory Speed:/ { 
            if ($4 != "Unknown" && has_memory) {
                speed = $4
                speed_count[speed]++
            }
        }
        
        /^\s*Speed:/ { 
            if ($2 != "Unknown" && has_memory) {
                speed = $2
                speed_count[speed]++
            }
        }

        # 当一个新的内存设备块开始时，重置标志并增加有效计数
        /^Memory Device$/ {
            if (NR > 1 && has_memory) {
                total_count++
            }
            has_memory = 0
        }

        END {
            if (has_memory) {
                total_count++
            }
            
            common_size = "Unknown"
            max_size = 0
            for (s in size_count) if (size_count[s] > max_size) { max_size = size_count[s]; common_size = s }
            
            common_type = "Unknown"  
            max_type = 0
            for (t in type_count) if (type_count[t] > max_type) { max_type = type_count[t]; common_type = t }
            
            common_speed = "Unknown"
            max_speed = 0
            for (sp in speed_count) if (speed_count[sp] > max_speed) { max_speed = speed_count[sp]; common_speed = sp }
            
            # 输出格式：类型信息 + 总容量
            printf "%s %s %s x %d Total:%dG\n", common_size, common_type, common_speed, total_count, total_capacity
        }
    ')

    # 获取硬盘信息
    DISK_INFO=$(lsblk -d -o NAME,SIZE,MODEL | grep -E '^(sd|nvme)' | sed 's/  */ /g' | \
        cut -d' ' -f2- | sort | uniq -c | \
        awk '{for(i=2;i<=NF;i++) printf "%s ", $i; printf "x%d ", $1}' | sed 's/ $//')



    # 显卡统计
    # 初始化数组
    declare -A gpu_counts

    # 处理NVIDIA显卡
    if command -v nvidia-smi &> /dev/null; then
        while IFS=, read -r index bus_id name; do
            # 清理变量
            index=$(echo "$index" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            bus_id=$(echo "$bus_id" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            name=$(echo "$name" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            
            # 转换总线ID格式
            pci_id=$(echo "$bus_id" | sed 's/^00000000://')
            
            # 获取厂家信息
            vendor=""
            if [[ -n "$pci_id" ]]; then
                subsystem=$(lspci -v -s "$pci_id" 2>/dev/null | grep -i "subsystem" | head -1)
                if [[ -n "$subsystem" ]]; then
                    if echo "$subsystem" | grep -q "Device 1b4c:1454"; then
                        vendor="Dell"
                    elif echo "$subsystem" | grep -q "Device 1462:"; then
                        vendor="MSI"
                    else
                        vendor=$(echo "$subsystem" | grep -o '\[[^]]*\]' | head -1 | tr -d '[]')
                    fi
                fi
            fi
            
            # 构建显示名称
            if [[ -n "$vendor" ]]; then
                display_name="$name ($vendor)"
            else
                display_name="$name"
            fi
            
            # 计数
            ((gpu_counts["$display_name"]++))
            
        done < <(nvidia-smi --query-gpu=index,pci.bus_id,name --format=csv,noheader 2>/dev/null | sed 's/\r//g')
    fi

    # 处理非NVIDIA显卡
    while IFS= read -r line; do
        if echo "$line" | grep -qi "nvidia"; then
            continue
        fi
        device_name=$(echo "$line" | cut -d: -f3- | sed 's/^[[:space:]]*//;s/ Electronics Systems Ltd.//g;s/ Integrated//g;s/ Graphics Controller//g;s/ (rev.*)//g')
        ((gpu_counts["$device_name"]++))
    done < <(lspci 2>/dev/null | grep -i vga)

    # 构建结果字符串
    result=""
    for gpu_name in "${!gpu_counts[@]}"; do
        count=${gpu_counts["$gpu_name"]}
        if [[ -n "$result" ]]; then
            result="$result $gpu_name x$count"
        else
            result="$gpu_name x$count"
        fi
    done


    # 获取显卡型号的关键部分
    GPU_MODELS=$(nvidia-smi -L | grep -oP 'GeForce RTX \K[0-9]+' | tr '\n' ' ')

    # 使用 nvidia-smi 获取 GPU 插槽信息
    gpu_info=$(nvidia-smi | grep '000000')
    gpu_ids=$(echo "$gpu_info" | awk -F '|' '{print $3}' | awk '{print substr($1, 10, 7)}')
    slots=""
    for id in $gpu_ids; do
        slot_info=$(sudo dmidecode -t slot | grep -B 9 -i "Bus Address: 0000:$id")
        designation=$(echo "$slot_info" | grep 'Designation' | awk -F ': ' '{print $2}')
        if [ -n "$designation" ]; then
            slot_name=$(echo "$designation" | sed 's/PCIe Slot //')
            slots="${slots} ${slot_name} "
        fi
    done
    slots=$(echo "$slots" | sed 's/ $//')


    #log "Inof: $hostname"
    #log "Inof: $MOBO_MODEL"
    #log "Inof: $current_serial"
    #log "Inof: $CPU_MODEL"
    #log "Inof: $CPU_CONFIG"
    #log "Info: $memory_info"
    #log "Inof: $DISK_INFO"
    #log "Inof: $result"
    #log "Inof: Gpu:$GPU_MODELS"
    #log "Inof: slots:$slots"

    #export MESSAGE=
    MESSAGE="$hostname\t$MOBO_MODEL\t$current_serial\t$CPU_MODEL\t$CPU_CONFIG\t$memory_info\t$DISK_INFO\t$result\t$GPU_MODELS\t$slots"
    #log "Inof: $MESSAGE"
    MESSAGE_Test="$hostname $MOBO_MODEL $current_serial $CPU_MODEL $CPU_CONFIG $memory_info $DISK_INFO $result $GPU_MODELS $slots"
    #log "Inof: $MESSAGE"

}

# 调用收集硬件信息主程序
get_hardware

if [ -z "$NFS_SERVER_IP" ]; then
    # 当没有定义服务器IP的情况下 不进行NFS 写入文件操作
    echo  log "Error: 没有定义服务器IP 不写入记录"
    log "Inof: $MESSAGE_Test"
    exit 1
fi

# 挂载NFS路径
if ! mountpoint -q $OUTPUT_PATH; then
    log "Inof: 挂载NFS路径 $NFS_SERVER_IP"
    mkdir -p "$OUTPUT_PATH"
    mount -t nfs -o proto=tcp,actimeo=0,async,rsize=65536,wsize=65536,noatime "$NFS_SERVER_IP:/filecoin/$NFS_SERVER_PATH" "$OUTPUT_PATH"
else
    log "Inof: NFS路径 $NFS_SERVER_IP 已挂载"
fi

# 检查文件中是否已经存在该主机名的条目
if grep -q "^$hostname" "$OUTPUT_PATH/$OUTPUT_FILE"; then
    log "Inof: 条目已存在 $OUTPUT_PATH/$OUTPUT_FILE"
else
    echo -e "$MESSAGE" >> $OUTPUT_PATH/$OUTPUT_FILE
    log "Info: 收集本机硬件信息信息 追加到 $OUTPUT_PATH/$OUTPUT_FILE"
fi

# 卸载NFS路径
if mountpoint -q $OUTPUT_PATH; then
    log "Info: 卸载NFS路径 $OUTPUT_PATH"
    umount $OUTPUT_PATH
fi

# 清理NFS挂载时新建的目录
if ! mountpoint -q $OUTPUT_PATH; then
    log "Inof: 清理挂载时新建的目录 $OUTPUT_PATH"
    rm -r "$OUTPUT_PATH"
fi

log "Inof: Done"
lscpu |grep name

exit
