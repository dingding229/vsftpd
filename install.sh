#!/bin/bash

green(){ echo -e "\e[32m$1\e[0m"; }
red(){ echo -e "\e[31m$1\e[0m"; }

# 安装 vsftpd
green "[1/5] 安装 vsftpd..."
apt update && apt install -y vsftpd || { red "安装失败"; exit 1; }

# 备份配置
cp /etc/vsftpd.conf /etc/vsftpd.conf.bak.$(date +%s)

# 写入配置文件
cat > /etc/vsftpd.conf <<EOF
listen=YES
listen_ipv6=NO
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
use_localtime=YES
xferlog_enable=YES
connect_from_port_20=YES
chroot_local_user=YES
allow_writeable_chroot=YES
local_root=/
secure_chroot_dir=/var/run/vsftpd/empty
pam_service_name=vsftpd
rsa_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem
rsa_private_key_file=/etc/ssl/private/ssl-cert-snakeoil.key
pasv_enable=YES
pasv_min_port=30000
pasv_max_port=31000
EOF

# 启动 vsftpd
green "[2/5] 启动 vsftpd..."
systemctl restart vsftpd
systemctl enable vsftpd

# 配置防火墙（如启用 ufw）
if command -v ufw >/dev/null 2>&1; then
    green "[3/5] 配置 UFW 防火墙..."
    ufw allow 21
    ufw allow 30000:31000/tcp
fi

# 创建 FTP 用户
read -p "是否创建 FTP 用户？(y/n): " create_user
if [[ "$create_user" =~ ^[Yy]$ ]]; then
    read -p "请输入用户名: " ftpuser
    read -p "请输入密码: " ftppass

    # 创建用户，home 设置为根目录
    useradd -d / "$ftpuser" -s /sbin/nologin
    echo "${ftpuser}:${ftppass}" | chpasswd

    green "[4/5] 已创建用户 $ftpuser，FTP 登录目录为 /"
fi

# 输出登录信息
IP=$(hostname -I | awk '{print $1}')
green "[5/5] 安装完成，登录信息如下："
echo "---------------------------------------------"
echo "  地址:   ftp://$IP:21"
if [[ "$ftpuser" != "" ]]; then
    echo "  用户名: $ftpuser"
    echo "  密码:   $ftppass"
fi
echo "  登录目录: /"
echo "  被动端口范围: 30000-31000"
echo "---------------------------------------------"
