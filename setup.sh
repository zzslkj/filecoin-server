#!/bin/bash

# 初始化文件列表
files=(
    "config/config.toml"
    "tools/check_miner/env.sh"
)
# 初始化配置文件，如果不存在则从示例文件创建， 否则删除示例文件
echo "检查配置文件..."
for target in "${files[@]}"; do
    if [ ! -f "$target" ] && [ -f "${target}.example" ]; then
        mv "${target}.example" "$target"
        echo "创建: $target 文件并根据需要进行修改"
    else
        rm -f "${target}.example"
    fi
done

# 初始化创建目录列表
dirs=(
    "logs"
    "lotus"
    #"data/miner"
)

echo "创建目录..."
for dir in "${dirs[@]}"; do
    mkdir -p "$dir"
done

