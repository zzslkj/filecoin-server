#!/bin/bash
source $(dirname "$0")/env.sh
PATH=/usr/local/bin:/usr/bin:/bin

INTERVAL=60  # 定义时间间隔变量（以秒为单位）
#符号收集 ❌✅⚠️💚🔍📊 🈲

# 定义发送钉钉消息的函数 加签模式
send_dingtalk_message() {
    local webhook=$1
    local secret=$2
    local message=$3

    # 获取当前时间戳（毫秒）
    TIMESTAMP=$(($(date +%s%N)/1000000))

    # 计算签名
    STRING_TO_SIGN="${TIMESTAMP}\n${secret}"
    SIGN=$(echo -en "$STRING_TO_SIGN" | openssl dgst -sha256 -hmac "$secret" -binary | base64)

    # 对签名进行URL编码
    ENCODED_SIGN=$(echo -n "$SIGN" | sed 's/+/%2B/g; s#/#%2F#g; s/=/%3D/g')

    # 发送钉钉消息
    curl -s -X POST "${webhook}&timestamp=${TIMESTAMP}&sign=${ENCODED_SIGN}" -H 'Content-Type: application/json' -d "{\"msgtype\": \"text\", \"text\": {\"content\": \"${message}\"}}" | tr -d '\n'
}

# 定义发送 telegram 消息的函数
send_telegram_message() {
    local token=$1
    local chat_id=$2
    local message=$3
    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" -d "chat_id=$chat_id" -d "text=$message" -d parse_mode="Markdown"
}

# 初始化变量存储上次故障扇区数量
declare -A last_faulty_count
first_run=1
all_recovered_sent=false  # 标记是否已经发送过完全恢复消息

# 对每个矿工进行处理
while true; do
    MESSAGE=""
    any_changes=false      # 标记是否有任何变化
    all_recovered=true     # 标记是否全部恢复

    echo "=== 开始检查矿工故障扇区: $(date +"%F %H:%M:%S") ==="

    for miner in "${MINERS[@]}"; do
        echo "检查 Miner: $miner"
        
        # 获取故障扇区数量
        faulty_count=$(lotus-shed miner faults "$miner" | awk '/faulty sectors:/ {print NF-2}')
        faulty_count=${faulty_count:-0}
        
        # 调试
        # faulty_count=$(cat $miner.ini)

        # 输出当前状态
        echo "当前故障扇区数量: $faulty_count"

        # 检查是否有历史记录
        if [ -n "${last_faulty_count[$miner]}" ]; then
            last_count=${last_faulty_count[$miner]}
            change=$((faulty_count - last_count))
            
            if [ $change -ne 0 ]; then
                any_changes=true
                
                if [ $change -gt 0 ]; then
                    # 故障扇区增加
                    echo "⚠️  警告: $miner 新增 $change 个故障扇区"
                    MESSAGE="$MESSAGE\n$miner ⚠️ 新增 $change 个故障扇区 (当前: $faulty_count 个)"
                else
                    # 故障扇区减少（恢复）
                    recovered=$(( -change ))  # 取绝对值
                    echo "✅ 恢复: $miner 恢复 $recovered 个故障扇区"
                    MESSAGE="$MESSAGE\n$miner ✅ 恢复 $recovered 个故障扇区 (当前: $faulty_count 个)"
                fi
            else
              if [ $faulty_count -ne 0 ]; then
                # 有故障且故障扇区数量不变
                echo "ℹ️  正常: $miner 故障扇区数量无变化"
                MESSAGE="$MESSAGE\n$miner ℹ️ 故障扇区数量无变化 (当前: $faulty_count 个)"
              fi
            fi
        else
            # 首次运行
            echo "$miner 首次检测，故障扇区: $faulty_count 个"
            if [ $faulty_count -gt 0 ]; then
                MESSAGE="$MESSAGE\n$miner ℹ️ 初始故障扇区: $faulty_count 个"
                any_changes=true
            fi
        fi
        
        # 更新上次记录
        last_faulty_count[$miner]=$faulty_count
        
        # 检查是否还有故障扇区
        if [ $faulty_count -gt 0 ]; then
            all_recovered=false
            all_recovered_sent=false  # 重置完全恢复标记
        fi
        
        echo "----------------------------------------"
    done

    # 处理消息发送
    timestamp=$(date +"%F %H:%M:%S")
    
    if [ $first_run -eq 1 ]; then
        # 首次运行发送初始状态
        if [ -n "$MESSAGE" ]; then
            initial_msg="🔍 初始检测完成\n$MESSAGE\n时间: $timestamp"
            echo -e "$initial_msg"
            send_telegram_message "$TG_TOKEN" "$TG_CHAT_ID" "$(echo -e "$initial_msg")"
        fi
        first_run=0
    else
        # 非首次运行，只有变化时才发送消息
        if $any_changes; then
            change_msg="📊 故障扇区状态变化\n$MESSAGE\n时间: $timestamp"
            echo -e "$change_msg"
            send_telegram_message "$TG_TOKEN" "$TG_CHAT_ID" "$(echo -e "$change_msg")"
        fi
        
        # 检查是否全部恢复且之前没有发送过完全恢复消息
        if $all_recovered && [ "$all_recovered_sent" = "false" ]; then
            recovery_msg="💚 所有故障扇区已完全恢复！\n当前无故障扇区\n时间: $timestamp"
            echo -e "$recovery_msg"
            send_telegram_message "$TG_TOKEN" "$TG_CHAT_ID" "$(echo -e "$recovery_msg")"
            all_recovered_sent=true  # 标记已发送完全恢复消息
        fi
    fi

    echo "等待 $INTERVAL 秒后重新检查..."
    echo "========================================"
    sleep $INTERVAL
done

exit
