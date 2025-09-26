# OPK Hub 静态网站部署指南

本指南将帮助您在服务器上部署OPK Hub静态网站。

## 目录结构

```
aipowerpay.com/
├── index.html           # 网站主页
├── style.css            # 主样式文件
├── static/              # 静态资源目录
│   ├── css/             # CSS文件
│   ├── js/              # JavaScript文件
│   ├── picture/         # 图片资源
│   └── image/           # 其他图像资源
├── deploy.sh            # 部署脚本
├── nginx.conf           # Nginx配置文件
└── README.md            # 部署指南（本文件）
```

## 前置要求

在开始部署之前，确保您已经：

1. 拥有一台运行Linux的服务器（推荐Ubuntu或Debian）
2. 在服务器上安装了Nginx
3. 配置了域名（aipowerpay.com或其他您选择的域名）指向服务器IP
4. 服务器上已设置SSH访问

## 部署步骤

### 1. 准备部署脚本

首先，编辑`deploy.sh`文件，配置您的服务器信息：

```bash
# 使用您喜欢的编辑器打开文件
nano deploy.sh

# 修改以下配置参数
SERVER_USER="your_user"             # 服务器用户名
SERVER_IP="your_server_ip"           # 服务器IP地址
SERVER_DIR="/var/www/aipowerpay.com"  # 服务器上的网站目录
```

### 2. 设置脚本可执行权限

```bash
chmod +x deploy.sh
```

### 3. 初始化服务器环境

运行以下命令在服务器上设置网站目录：

```bash
./deploy.sh --setup
```

此命令将：
- 在服务器上创建网站目录
- 创建备份目录
- 设置适当的文件权限

### 4. 部署网站

运行以下命令部署最新的网站文件到服务器：

```bash
./deploy.sh --deploy
```

此命令将：
- 备份当前网站（如果存在）
- 上传所有网站文件到服务器
- 设置新的网站文件为当前版本

### 5. 配置Nginx

将`nginx.conf`文件复制到服务器并应用配置：

```bash
# 将配置文件复制到服务器
scp nginx.conf $SERVER_USER@$SERVER_IP:~

# 登录到服务器
ssh $SERVER_USER@$SERVER_IP

# （在服务器上）将配置文件移动到Nginx配置目录
 sudo cp nginx.conf /etc/nginx/sites-available/aipowerpay.com

# 创建符号链接到启用的站点目录
sudo ln -s /etc/nginx/sites-available/aipowerpay.com /etc/nginx/sites-enabled/

# 测试Nginx配置是否正确
sudo nginx -t

# 重新加载Nginx以应用新配置
sudo systemctl reload nginx
```

### 6. 启用HTTPS（可选）

如果您想启用HTTPS，推荐使用Let's Encrypt获取免费的SSL证书：

```bash
# 在服务器上安装Certbot
sudo apt update
sudo apt install certbot python3-certbot-nginx

# 获取并安装SSL证书
 sudo certbot --nginx -d aipowerpay.com -d www.aipowerpay.com
```

Certbot将自动更新您的Nginx配置以启用HTTPS。

## 管理网站

### 回滚到上一个版本

如果您需要回滚到上一个版本的网站，可以使用以下命令：

```bash
./deploy.sh --rollback
```

### 查看帮助信息

要查看脚本的帮助信息：

```bash
./deploy.sh --help
```

## 常见问题解决

### Nginx无法启动

检查Nginx配置是否有错误：

```bash
sudo nginx -t
```

查看Nginx错误日志：

```bash
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/aipowerpay_error.log
```

### 文件权限问题

如果您遇到文件权限问题，可以在服务器上运行：

```bash
sudo chown -R $SERVER_USER:$SERVER_USER $SERVER_DIR
sudo chmod -R 755 $SERVER_DIR/current
```

### 防火墙配置

确保您的服务器防火墙允许HTTP（80端口）和HTTPS（443端口）流量：

```bash
sudo ufw allow 'Nginx Full'
sudo ufw reload
```

## 定期备份

为了确保网站数据安全，建议定期备份网站文件和配置。`deploy.sh`脚本在每次部署时都会自动创建备份，但您也可以设置定期备份任务。

```bash
# 添加到crontab（每天凌晨2点备份）
0 2 * * * /path/to/deploy.sh --backup
```

## 联系方式

如果您在部署过程中遇到任何问题，请联系技术支持获取帮助。