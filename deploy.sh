#!/bin/bash

# 服务器部署脚本 - OPK Hub静态网站

# 配置参数
SERVER_USER="your_user"             # 服务器用户名
SERVER_IP="your_server_ip"           # 服务器IP地址
SERVER_DIR="/var/www/aipowerpay.com"  # 服务器上的网站目录

# 颜色定义
green="\033[0;32m"
red="\033[0;31m"
reset="\033[0m"

# 显示帮助信息
show_help() {
    echo -e "${green}OPK Hub静态网站部署脚本${reset}"
    echo "使用方法: ./deploy.sh [选项]"
    echo "选项:"
    echo "  --setup          在服务器上设置网站目录"
    echo "  --deploy         部署最新的网站文件"
    echo "  --rollback       回滚到上一个版本"
    echo "  --help           显示此帮助信息"
}

# 初始化服务器环境
setup_server() {
    echo -e "${green}正在设置服务器环境...${reset}"
    
    # 连接服务器并创建网站目录
    ssh $SERVER_USER@$SERVER_IP "sudo mkdir -p $SERVER_DIR && sudo chown -R $SERVER_USER:$SERVER_USER $SERVER_DIR"
    
    # 创建备份目录
    ssh $SERVER_USER@$SERVER_IP "mkdir -p $SERVER_DIR/backups"
    
    echo -e "${green}服务器环境设置完成！${reset}"
}

# 部署网站
deploy_site() {
    echo -e "${green}正在部署网站...${reset}"
    
    # 创建备份文件名（使用时间戳）
    BACKUP_FILE="$SERVER_DIR/backups/site-backup-$(date +%Y%m%d%H%M%S).tar.gz"
    
    # 备份现有网站（如果存在）
    ssh $SERVER_USER@$SERVER_IP "if [ -d $SERVER_DIR/current ]; then tar -czf $BACKUP_FILE -C $SERVER_DIR current/; fi"
    
    # 创建临时目录
    TEMP_DIR="$(ssh $SERVER_USER@$SERVER_IP "mktemp -d")"
    
    # 复制网站文件到服务器临时目录
    echo -e "${green}正在上传文件...${reset}"
    rsync -avz --exclude='*.git*' --exclude='deploy.sh' --exclude='README.md' --exclude='nginx.conf' . $SERVER_USER@$SERVER_IP:$TEMP_DIR
    
    # 替换当前网站
    ssh $SERVER_USER@$SERVER_IP "rm -rf $SERVER_DIR/current && mv $TEMP_DIR $SERVER_DIR/current"
    
    echo -e "${green}网站部署完成！${reset}"
}

# 回滚到上一个版本
rollback_site() {
    echo -e "${green}正在回滚网站...${reset}"
    
    # 获取最新的备份文件
    LATEST_BACKUP=$(ssh $SERVER_USER@$SERVER_IP "ls -t $SERVER_DIR/backups/site-backup-*.tar.gz 2>/dev/null | head -1")
    
    if [ -z "$LATEST_BACKUP" ]; then
        echo -e "${red}没有找到备份文件，无法回滚！${reset}"
        exit 1
    fi
    
    echo -e "${green}使用备份文件: $LATEST_BACKUP${reset}"
    
    # 备份当前网站（以防万一）
    ssh $SERVER_USER@$SERVER_IP "if [ -d $SERVER_DIR/current ]; then tar -czf $SERVER_DIR/backups/pre-rollback-$(date +%Y%m%d%H%M%S).tar.gz -C $SERVER_DIR current/; fi"
    
    # 删除当前网站并从备份恢复
    ssh $SERVER_USER@$SERVER_IP "rm -rf $SERVER_DIR/current && mkdir -p $SERVER_DIR/current && tar -xzf $LATEST_BACKUP -C $SERVER_DIR/current --strip-components=1"
    
    echo -e "${green}网站回滚完成！${reset}"
}

# 创建网站备份
backup_site() {
    echo -e "${green}正在创建网站备份...${reset}"
    
    # 检查当前网站是否存在
    if ssh $SERVER_USER@$SERVER_IP "[ ! -d $SERVER_DIR/current ]"; then
        echo -e "${red}网站目录不存在，无法创建备份！${reset}"
        exit 1
    fi
    
    # 创建备份文件名（使用时间戳）
    BACKUP_FILE="$SERVER_DIR/backups/site-backup-$(date +%Y%m%d%H%M%S).tar.gz"
    
    # 创建备份
    ssh $SERVER_USER@$SERVER_IP "tar -czf $BACKUP_FILE -C $SERVER_DIR current/"
    
    # 显示备份完成信息
    echo -e "${green}网站备份完成！${reset}"
    echo -e "${green}备份文件: $BACKUP_FILE${reset}"
    
    # 可选：清理旧备份（保留最近10个）
    ssh $SERVER_USER@$SERVER_IP "ls -t $SERVER_DIR/backups/site-backup-*.tar.gz | tail -n +11 | xargs -r rm -f"
    echo -e "${green}已清理超过10个的旧备份文件。${reset}"
}

# 主程序逻辑
if [ $# -eq 0 ]; then
    show_help
    exit 1
fi

case "$1" in
    --setup)
        setup_server
        ;;
    --deploy)
        deploy_site
        ;;
    --rollback)
        rollback_site
        ;;
    --backup)
        backup_site
        ;;
    --help)
        show_help
        ;;
    *)
        echo -e "${red}无效的选项: $1${reset}"
        show_help
        exit 1
        ;;
esac

# 设置脚本可执行权限（第一次运行后）
if [ ! -x "$0" ]; then
    echo -e "${green}请先设置脚本可执行权限: chmod +x $0${reset}"
fi