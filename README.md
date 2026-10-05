# RustDesk Server 公开版镜像

基于官方 `lejianwen/rustdesk-server-s6` 的定制 RustDesk 服务器镜像，开箱即用，无内置服务器地址与密钥，适合自建远程控制服务器。

## 特性

- **定制 hbbs / hbbr**：官方 1.1.16 + lejianwen API 补丁，musl 静态编译，零依赖
- **定制管理后台**：ART Design Pro 风格前端（登录页/工作台/设备管理等全面美化），内置 **ip2region** 离线 IP 地理位置解析
- **网页客户端** `webclient2`：浏览器直接远程控制
- **API 后台**：用户/设备/地址簿/登录日志/审计等管理功能

## 快速开始

### 方式一：Docker 直接运行（host 网络）

```bash
docker run -d --name rustdesk-server --network host --restart unless-stopped \
  -e RELAY=你的公网IP:21117 \
  -e RUSTDESK_API_RUSTDESK_ID_SERVER=你的公网IP:21116 \
  -e RUSTDESK_API_RUSTDESK_RELAY_SERVER=你的公网IP:21117 \
  -e RUSTDESK_API_RUSTDESK_API_SERVER=http://你的公网IP:21114 \
  -e ENCRYPTED_ONLY=1 \
  -e RUSTDESK_API_KEY_FILE=/data/id_ed25519.pub \
  -e RUSTDESK_API_ADMIN_TITLE=RS SERVER \
  -e TZ=Asia/Shanghai \
  -v /root/rustdesk/server:/data \
  -v /root/rustdesk/api:/app/data \
  <你的仓库>/rustdesk-server-s6-public:latest
```

### 方式二：docker-compose

```yaml
services:
  rustdesk:
    network_mode: host
    image: <你的仓库>/rustdesk-server-s6-public:latest
    environment:
      - RELAY=你的公网IP:21117
      - RUSTDESK_API_RUSTDESK_ID_SERVER=你的公网IP:21116
      - RUSTDESK_API_RUSTDESK_RELAY_SERVER=你的公网IP:21117
      - RUSTDESK_API_RUSTDESK_API_SERVER=http://你的公网IP:21114
      - ENCRYPTED_ONLY=1
      - MUST_LOGIN=N
      - RUSTDESK_API_KEY_FILE=/data/id_ed25519.pub
      - LIMIT_SPEED=100
      - RUSTDESK_API_APP_BAN_THRESHOLD=3
      - RUSTDESK_API_ADMIN_TITLE=RS SERVER
      - TZ=Asia/Shanghai
      - RUSTDESK_API_JWT_KEY=$(openssl rand -hex 32)
    volumes:
      - /root/rustdesk/server:/data
      - /root/rustdesk/api:/app/data
    restart: unless-stopped
    cap_add:
      - NET_ADMIN
```

## 环境变量

| 变量 | 说明 | 示例 |
|---|---|---|
| `RELAY` | 中继服务器地址 | `1.2.3.4:21117` |
| `RUSTDESK_API_RUSTDESK_ID_SERVER` | ID 服务器地址 | `1.2.3.4:21116` |
| `RUSTDESK_API_RUSTDESK_RELAY_SERVER` | 中继地址（API 侧） | `1.2.3.4:21117` |
| `RUSTDESK_API_RUSTDESK_API_SERVER` | API 地址 | `http://1.2.3.4:21114` |
| `ENCRYPTED_ONLY` | 强制加密（1 开 / 0 关） | `1` |
| `MUST_LOGIN` | 强制登录（Y/N） | `N` |
| `RUSTDESK_API_KEY_FILE` | 服务器公钥文件路径 | `/data/id_ed25519.pub` |
| `RUSTDESK_API_ADMIN_TITLE` | 管理后台标题 | `RS SERVER` |
| `RUSTDESK_API_JWT_KEY` | API JWT 密钥（建议随机 64 位 hex） | `openssl rand -hex 32` |
| `TZ` | 时区 | `Asia/Shanghai` |

## 数据持久化

| 挂载 | 内容 |
|---|---|
| `/data` | hbbs 数据 + 服务器密钥 `id_ed25519(.pub)` |
| `/app/data` | API 数据库（用户/设备/日志等） |

> 换服务器时迁移这两个目录即可；加密模式需把 `/data/id_ed25519.pub` 公钥分发给客户端。

## 端口

| 端口 | 用途 |
|---|---|
| 21114 | API / 管理后台 `/_admin/` / 网页客户端 `/webclient2/` |
| 21116 | ID 服务器（TCP+UDP，打洞） |
| 21117 | 中继服务器 |

防火墙放行：`21114/tcp 21116/tcp 21116/udp 21117/tcp`。

## 客户端连接配置

RustDesk 客户端 → 设置 ID/中继服务器：

```
ID 服务器:  你的IP:21116
中继服务器: 你的IP:21117
API 服务器: http://你的IP:21114（自编译客户端内置；官方客户端在"网络"页填写）
```

加密模式（ENCRYPTED_ONLY=1）需先在客户端导入服务器公钥。

## 本地构建

```bash
docker build -t <your-id>/rustdesk-server-s6-public:latest .
docker push <your-id>/rustdesk-server-s6-public:latest
```

## GitHub Actions 自动构建

推送到 Docker Hub + 阿里云 ACR 的自动流程见 `.github/workflows/build.yml`。

仓库 Settings → Secrets and variables → Actions 配置：

| Secret | 说明 |
|---|---|
| `DOCKERHUB_USERNAME` | Docker Hub 用户名 |
| `DOCKERHUB_TOKEN` | Docker Hub Access Token |
| `ALIYUN_REGISTRY` | 阿里云镜像仓库地址，如 `registry.cn-hangzhou.aliyuncs.com` |
| `ALIYUN_NAMESPACE` | 阿里云命名空间 |
| `ALIYUN_USERNAME` | 阿里云账号 |
| `ALIYUN_PASSWORD` | 阿里云密码或专用 Token |

## 目录结构

```
├── Dockerfile            镜像构建文件
├── hbbs / hbbr           定制服务器二进制（静态编译）
├── admin-dist/           定制管理后台前端（v76）
└── .github/workflows/    GitHub Actions 自动构建
```
