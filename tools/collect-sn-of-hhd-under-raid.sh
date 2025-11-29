#!/bin/bash
# 收集RAID控制器下硬盘的SN信息
# bash $HOME/collect-sn-of-hhd-under-raid.sh IP name (IP可选、name可选 默认为down)
# 会挂载nfs路径 IP/name
# 依赖 perccli64 工具
# 导出的格式方便导入到Excel中处理
# 磁盘型号	磁盘SN	磁盘WWN


# 实例用法
: << 'EOF'
# 设置下载服务器路径
export WEB_SERVER_IP=jump.ddns.us:57592 # HK-jump2025
export WEB_SERVER_IP=hd.kenny.us.kg:57592 # hd.kenny.us.kg

# 运行硬件信息收集工作 写入NFS共享服务器 172.20.1.248:/filecoin/down
export WEB_SERVER_IP=hd.kenny.us.kg:57592 # hd.kenny.us.kg
wget --show-progress -q -O $HOME/collect-sn-of-hhd-under-raid.sh http://$WEB_SERVER_IP/tools/collect-sn-of-hhd-under-raid.sh && bash $HOME/collect-sn-of-hhd-under-raid.sh 172.20.1.248 && rm -f $HOME/collect-sn-of-hhd-under-raid.sh

# 只本地显示 不写入记录
wget --show-progress -q -O $HOME/collect-sn-of-hhd-under-raid.sh http://$WEB_SERVER_IP/tools/collect-sn-of-hhd-under-raid.sh && bash $HOME/collect-sn-of-hhd-under-raid.sh && rm -f $HOME/collect-sn-of-hhd-under-raid.sh

EOF
# 记录日志函数
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1"
    #echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"
}

# perccli64 工具安装
if [ ! -f "/usr/local/bin/perccli64" ]; then
    export WEB_SERVER_IP=hd.kenny.us.kg:57592 # hd.kenny.us.kg
    wget --show-progress -q -O $HOME/perccli64 http://$WEB_SERVER_IP/tools/perccli64 && install -C $HOME/perccli64 /usr/local/bin/perccli64 && rm -f $HOME/perccli64

    echo "安装完成: /usr/local/bin/perccli64"
else
    echo "perccli64 已存在，无需安装。"
fi

# 设置 NFS共享路径所在服务器IP
export NFS_SERVER_IP=$1


# 可选变量 NFS共享路径的名字 
if [ -n "$NFS_SERVER_IP" ]; then
    export NFS_SERVER_PATH="${2:-down}"
    export OUTPUT_PATH=/mnt/$NFS_SERVER_IP/$NFS_SERVER_PATH

    # 挂载NFS路径
    if ! mountpoint -q $OUTPUT_PATH; then
        log "Inof: 挂载NFS路径 $NFS_SERVER_IP"
        mkdir -p "$OUTPUT_PATH"
        mount -t nfs -o proto=tcp,actimeo=0,async,rsize=65536,wsize=65536,noatime "$NFS_SERVER_IP:/filecoin/$NFS_SERVER_PATH" "$OUTPUT_PATH"
    else
        log "Inof: NFS路径 $NFS_SERVER_IP 已挂载"
    fi
    # 设置输出文件路径
    OUTPUT_FILE="$OUTPUT_PATH/disk_list_$(hostname -s).log"
    rm -f "$OUTPUT_FILE"

    # 设置tee命令将输出追加到文件
    TEE_CMD="tee -a $OUTPUT_FILE" 
else
    # 本地显示输出
    TEE_CMD="tee"
fi


# 收集硬盘SN信息
log "开始收集RAID控制器下硬盘SN信息..."

perccli64 show | awk '/^ *[0-9]+ / {print $1}' | while read ctl; do
    perccli64 /c${ctl} /eall /sall show all \
    | awk -v ctl=$ctl '
    /^Drive \/c/ {
        if (disk && model && sn && wwn) {
            print disk "\t" model "\t" sn "\t" wwn
        }
        disk=$2
        model=""
        sn=""
        wwn=""
    }

    /^Model Number/ {
        model=""
        found=0
        for (i=1; i<=NF; i++) {
            if ($i=="Number") found=1
            if (found && $i!="Number" && $i!="=") {
                model=(model==""?$i:model" "$i)
            }
        }
    }

    /^SN =/ { sn=$3 }
    /^WWN =/ { wwn=$3 }

    END {
        if (disk && model && sn && wwn) {
            print disk "\t" model "\t" sn "\t" wwn
        }
    }'
done | eval $TEE_CMD

# 完成后卸载NFS路径
if [ -n "$NFS_SERVER_IP" ]; then
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

fi

log "Inof: Done"

exit