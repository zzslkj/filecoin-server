#!/bin/bash
export WEB_SERVER_IP=fil.ddns.us:57592 # fil.ddns.us:57592

: << 'EOF'
#下载 i.sh
wget --show-progress -q -O $HOME/i.sh http://fil.ddns.us:57592/i.sh && bash $HOME/i.sh && rm -f $HOME/i.sh

EOF

#修改允许SSH登录
wget http://$WEB_SERVER_IP/pub/hs_20241124.pub
#wget http://$WEB_SERVER_IP/pub/lotus_up_FIL.pub

#导入生成的文件
rm -f /root/.ssh/*
cat /root/*.pub >> /root/.ssh/authorized_keys
#删除多余配置文件
rm -rf /etc/ssh/sshd_config.d/*
rm -rf /root/*.pub
#允许root登录
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g'  /etc/ssh/sshd_config
#修改成允许Pubkey登录
sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/g'  /etc/ssh/sshd_config
#修改路径
#sed -i 's/#AuthorizedKeysFile     .ssh/authorized_keys .ssh/authorized_keys2/AuthorizedKeysFile     .ssh/authorized_keys .ssh/authorized_keys2/g'  /etc/ssh/sshd_config
systemctl restart sshd

# 禁用 keyboard interactive 登录
sed -i 's/#ChallengeResponseAuthentication no/ChallengeResponseAuthentication no/g'  /etc/ssh/sshd_config
sed -i 's/#ChallengeResponseAuthentication yes/ChallengeResponseAuthentication no/g'  /etc/ssh/sshd_config
sed -i 's/ChallengeResponseAuthentication yes/ChallengeResponseAuthentication no/g'  /etc/ssh/sshd_config

#修改成禁止密码登录
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g'  /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/g'  /etc/ssh/sshd_config
systemctl restart sshd

#检查源
if ! grep -q "http://mirrors.ustc.edu.cn/ubuntu" /etc/apt/sources.list; then
    echo "Adding new entry to /etc/apt/sources.list..."
    rm -f /etc/apt/sources.list
    #禁用系统版本升级
    sed -i 's/^Prompt=.*/Prompt=never/' /etc/update-manager/release-upgrades
    # 获取Ubuntu版本信息
    ubuntu_version=$(lsb_release -sr | cut -d'.' -f1,2 | tr -d '.')
    # 根据不同的版本执行不同的命令
    case $ubuntu_version in
    "2004")
        echo "执行针对 Ubuntu 20.04 的命令"
    sudo tee -a /etc/apt/sources.list << EOF
# See http://help.ubuntu.com/community/UpgradeNotes for how to upgrade to
# newer versions of the distribution.
deb http://mirrors.ustc.edu.cn/ubuntu focal main restricted
# deb-src http://mirrors.ustc.edu.cn/ubuntu focal main restricted

## Major bug fix updates produced after the final release of the
## distribution.
deb http://mirrors.ustc.edu.cn/ubuntu focal-updates main restricted
# deb-src http://mirrors.ustc.edu.cn/ubuntu focal-updates main restricted

## N.B. software from this repository is ENTIRELY UNSUPPORTED by the Ubuntu
## team. Also, please note that software in universe WILL NOT receive any
## review or updates from the Ubuntu security team.
deb http://mirrors.ustc.edu.cn/ubuntu focal universe
# deb-src http://mirrors.ustc.edu.cn/ubuntu focal universe
deb http://mirrors.ustc.edu.cn/ubuntu focal-updates universe
# deb-src http://mirrors.ustc.edu.cn/ubuntu focal-updates universe

## N.B. software from this repository is ENTIRELY UNSUPPORTED by the Ubuntu
## team, and may not be under a free licence. Please satisfy yourself as to
## your rights to use the software. Also, please note that software in
## multiverse WILL NOT receive any review or updates from the Ubuntu
## security team.
deb http://mirrors.ustc.edu.cn/ubuntu focal multiverse
# deb-src http://mirrors.ustc.edu.cn/ubuntu focal multiverse
deb http://mirrors.ustc.edu.cn/ubuntu focal-updates multiverse
# deb-src http://mirrors.ustc.edu.cn/ubuntu focal-updates multiverse

## N.B. software from this repository may not have been tested as
## extensively as that contained in the main release, although it includes
## newer versions of some applications which may provide useful features.
## Also, please note that software in backports WILL NOT receive any review
## or updates from the Ubuntu security team.
deb http://mirrors.ustc.edu.cn/ubuntu focal-backports main restricted universe multiverse
# deb-src http://mirrors.ustc.edu.cn/ubuntu focal-backports main restricted universe multiverse

## Uncomment the following two lines to add software from Canonical's
## 'partner' repository.
## This software is not part of Ubuntu, but is offered by Canonical and the
## respective vendors as a service to Ubuntu users.
# deb http://archive.canonical.com/ubuntu focal partner
# deb-src http://archive.canonical.com/ubuntu focal partner

deb http://mirrors.ustc.edu.cn/ubuntu focal-security main restricted
# deb-src http://mirrors.ustc.edu.cn/ubuntu focal-security main restricted
deb http://mirrors.ustc.edu.cn/ubuntu focal-security universe
# deb-src http://mirrors.ustc.edu.cn/ubuntu focal-security universe
deb http://mirrors.ustc.edu.cn/ubuntu focal-security multiverse
# deb-src http://mirrors.ustc.edu.cn/ubuntu focal-security multiverse
# by:hs-2004
EOF
        ;;
    "2204")
        echo "执行针对 Ubuntu 22.04 的命令"
    sudo tee -a /etc/apt/sources.list << EOF
# See http://help.ubuntu.com/community/UpgradeNotes for how to upgrade to
# newer versions of the distribution.
deb http://mirrors.ustc.edu.cn/ubuntu/ jammy main restricted
# deb-src http://mirrors.ustc.edu.cn/ubuntu/ jammy main restricted

## Major bug fix updates produced after the final release of the
## distribution.
deb http://mirrors.ustc.edu.cn/ubuntu/ jammy-updates main restricted
# deb-src http://mirrors.ustc.edu.cn/ubuntu/ jammy-updates main restricted

## N.B. software from this repository is ENTIRELY UNSUPPORTED by the Ubuntu
## team. Also, please note that software in universe WILL NOT receive any
## review or updates from the Ubuntu security team.
deb http://mirrors.ustc.edu.cn/ubuntu/ jammy universe
# deb-src http://mirrors.ustc.edu.cn/ubuntu/ jammy universe
deb http://mirrors.ustc.edu.cn/ubuntu/ jammy-updates universe
# deb-src http://mirrors.ustc.edu.cn/ubuntu/ jammy-updates universe

## N.B. software from this repository is ENTIRELY UNSUPPORTED by the Ubuntu
## team, and may not be under a free licence. Please satisfy yourself as to
## your rights to use the software. Also, please note that software in
## multiverse WILL NOT receive any review or updates from the Ubuntu
## security team.
deb http://mirrors.ustc.edu.cn/ubuntu/ jammy multiverse
# deb-src http://mirrors.ustc.edu.cn/ubuntu/ jammy multiverse
deb http://mirrors.ustc.edu.cn/ubuntu/ jammy-updates multiverse
# deb-src http://mirrors.ustc.edu.cn/ubuntu/ jammy-updates multiverse

## N.B. software from this repository may not have been tested as
## extensively as that contained in the main release, although it includes
## newer versions of some applications which may provide useful features.
## Also, please note that software in backports WILL NOT receive any review
## or updates from the Ubuntu security team.
deb http://mirrors.ustc.edu.cn/ubuntu/ jammy-backports main restricted universe multiverse
# deb-src http://mirrors.ustc.edu.cn/ubuntu/ jammy-backports main restricted universe multiverse

deb http://security.ubuntu.com/ubuntu/ jammy-security main restricted
# deb-src http://security.ubuntu.com/ubuntu/ jammy-security main restricted
deb http://security.ubuntu.com/ubuntu/ jammy-security universe
# deb-src http://security.ubuntu.com/ubuntu/ jammy-security universe
deb http://security.ubuntu.com/ubuntu/ jammy-security multiverse
# deb-src http://security.ubuntu.com/ubuntu/ jammy-security multiverse
# by:hs-2204
EOF

        # 禁止 Cloud-Init 修改网络配置 告诉 Cloud-Init 不再管理网络
        CONFIG_FILE="/etc/cloud/cloud.cfg.d/99-disable-network-config.cfg"
        CONFIG_LINE="network: {config: disabled}"

        # 如果文件不存在则创建，并写入内容
        if [ ! -f "$CONFIG_FILE" ]; then
            echo "$CONFIG_LINE" | sudo tee "$CONFIG_FILE" > /dev/null
            echo "已创建文件并写入配置。"
        # 如果文件存在但不包含该行，则追加
        elif ! grep -Fxq "$CONFIG_LINE" "$CONFIG_FILE"; then
            echo "$CONFIG_LINE" | sudo tee -a "$CONFIG_FILE" > /dev/null
            echo "配置已追加到文件。"
        else
            echo "配置已存在，无需修改。"
        fi

        ;;
    *)
        echo "❌ 不支持的 Ubuntu 版本: $ubuntu_version"
        rm -f /filecoin/auto-setup.sh
        exit
        ;;
    esac
    sudo sed -i "/^#\$nrconf{restart} = 'i';$/s/.*/\$nrconf{restart} = 'a';/" /etc/needrestart/needrestart.conf
    sudo sed -i 's/^\$nrconf{kernelhints} = .*/\$nrconf{kernelhints} = 0;/' /etc/needrestart/needrestart.conf
    #apt update && apt upgrade -y #系统更新
    sudo DEBIAN_FRONTEND=noninteractive apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y
fi

apt remove --purge nvidia* # 1、将驱动添加到黑名单blacklist.conf中
# 2、移除已安装的显卡
tee -a /etc/modprobe.d/blacklist.conf<< EOF
blacklist nouveau
options nouveau modeset=0
EOF
update-initramfs -u # 3、 更新挂载
#关闭虚拟内存 注释掉 swap.img
swapoff -a
sed -i '/\/swap.img/ s/^/#/' /etc/fstab
lsmod | grep nouveau # 4、查看显卡是否已禁用 如果有显示则重启一次 

#删除多余用户
users=$(awk -F: '/\/bin\/bash|\/bin\/sh|\/bin\/dash/ {print $1}' /etc/passwd)
# 检查sshd_config中的允许和拒绝用户设置
allow_users=$(grep '^AllowUsers' /etc/ssh/sshd_config | awk '{for(i=2;i<=NF;i++) print $i}')
deny_users=$(grep '^DenyUsers' /etc/ssh/sshd_config | awk '{for(i=2;i<=NF;i++) print $i}')

for user in $users; do
    if [[ -n "$allow_users" && ! " $allow_users " =~ " $user " ]]; then
        continue
    fi
    if [[ -n "$deny_users" && " $deny_users " =~ " $user " ]]; then
        continue
    fi
    if [[ "$user" != "root" ]]; then
        echo "Deleting user: $user"
        sudo userdel -r $user
    fi
done

# 设置 PS1 变量 来修改机器字体颜色
TARGET_PS1='\[\e[31;1m\]\u\[\e[33m\]@\[\e[35m\]\h \[\e[36m\]\t \[\e[32;1m\]\w\[\e[0m\]\$ '

# 检查 .bashrc 是否存在，不存在则创建
if [ ! -f ~/.bashrc ]; then
    touch ~/.bashrc
fi

# 检查是否已经存在 PS1 设置（匹配 export PS1= 或 PS1=）
if grep -q -E "^(export )?PS1='\\\[\\e\[31;1m\\\]" ~/.bashrc; then
    echo "✅ PS1 已设置，无需更改。"
else
    # 不存在 PS1 设置，追加新设置
    echo "export PS1='$TARGET_PS1'" >> ~/.bashrc
    echo "✅ PS1 设置已添加。"
fi
source ~/.bashrc

rm -f ~/i-gpu.sh
#wget --show-progress -q -O ~/i-gpu.sh http://$WEB_SERVER_IP/i-gpu.sh
echo "✅ i.sh  Done."
#echo "✅ bash i-gpu.sh"
#重启
reboot
exit
