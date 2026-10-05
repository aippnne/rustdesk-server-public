# RustDesk Server 公开版镜像

基于官方 `lejianwen/rustdesk-server-s6` 的定制 RustDesk 服务器镜像，开箱即用，无内置服务器地址与密钥，适合自建远程控制服务器。

![Docker Image Size](https://img.shields.io/docker/image-size/aippme/rustdesk-server-s6-public/latest)
![Docker Pulls](https://img.shields.io/docker/pulls/aippme/rustdesk-server-s6-public)

## 特性

- **定制 hbbs / hbbr**：官方 1.1.16 + lejianwen API 补丁，musl 静态编译，零依赖（详见[hbbs/hbbr 更新说明](#hbbshbbr-更新说明)）
- **定制管理后台**：ART Design Pro 风格前端，内置 **ip2region** 离线 IP 地理位置解析（详见[管理后台说明](#管理后台admin-dist优化与功能说明)）
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
  aippme/rustdesk-server-s6-public:latest
```

### 方式二：docker-compose（推荐）

复制仓库内的 [docker-compose.example.yml](docker-compose.example.yml) 或直接使用：

```yaml
services:
  rustdesk:
    network_mode: host
    image: aippme/rustdesk-server-s6-public:latest
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

> 首次部署后访问 `http://你的IP:21114/_admin/` 打开管理后台，默认管理员 `admin` / 密码 `admin123`（**请立即修改**）。

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

---

## hbbs/hbbr 更新说明

| 项 | 值 |
|---|---|
| 内核版本 | 官方 rustdesk-server **1.1.16** |
| 附加补丁 | **lejianwen fork 的 RustDesk API 补丁**（hbbs/hbbr 需配合 API 服务使用管理后台） |
| 编译方式 | musl 静态编译（zig 工具链），零动态依赖，容器内直接运行 |

### 官方 1.1.16 相对旧版本的变化

- 基于官方 1.1.16 发布版本，包含上游在 NAT 穿透（打洞）、中继连接、日志与稳定性方面的历次修复
- 与 lejianwen/rustdesk-server-s6 镜像同源，服务脚本（s6-overlay）与目录结构完全兼容

### 定制补丁（lejianwen API）

在官方 1.1.16 内核上合并了 lejianwen fork 的 API 补丁，约 500 行新增：

| 文件 | 变更 |
|---|---|
| `src/jwt.rs` | 新增：JWT 签发/校验（管理后台登录态） |
| `src/main.rs` / `src/lib.rs` | 接入 API 路由与配置项 |
| `src/rendezvous_server.rs` | 同步打洞/在线状态数据到 API 侧 |
| `Cargo.toml` / `Cargo.lock` | 新增依赖（jwt 等） |

补丁带来的能力：

- **管理后台**：用户 / 设备 / 地址簿 / Token / 登录日志 / 审计日志 / 系统信息
- **API 接口**：`/api/...` 供网页客户端与管理后台调用（21114 端口）
- **在线状态同步**：设备在线/离线状态与 API 侧实时同步

> 纯二进制替换：`hbbs`（ID 服务器）/ `hbbr`（中继服务器）直接覆盖镜像内 `/usr/bin/` 对应文件，不修改官方入口与数据目录结构。

---

## 管理后台（admin-dist）优化与功能说明

管理后台前端基于官方 `rustdesk-api-web`（Vue3 + Element Plus + Vite）深度定制，版本 **v76**。

### UI 优化（ART Design Pro 风格）

- **登录页**：ART 风格界面 + 记住密码 + 滑块验证
- **工作台**：
  - 顶部统计卡片组（用户/设备/在线/登录 4 卡，ART 配色）
  - **终端类型饼图**（按设备操作系统白名单分类统计，Windows 7/10/11、Android 9~15、Ubuntu、iOS 等，未命中归"其他"）
  - **登录日志折线图**（渐变背景，按天统计）
  - **近期登录 / 近期连接** 实时卡片（50 条上限，自动滚动 + 滚动条，展示设备 ID/主控被控端 ID/IP/地理位置/时间）
  - 系统信息：加密密钥、ID/中继/API 服务器地址支持小眼睛掩码切换（默认隐藏）
- **全局规范**：背景 `#fafbfc`、卡片边框 `1px rgba(219,223,233,0.6)`、圆角 `16px`、统一字体字号、菜单滑行动效、全局 ICON 补齐

### 功能增加

| 功能 | 说明 |
|---|---|
| **IP 地理位置解析** | 内置 **ip2region.xdb** 离线库（10.6MB），日志/设备/连接等页面按 IP 自动显示地理位置与运营商，无需外网接口 |
| **登录日志** | 修复筛选按钮；新增按日期范围筛选；IP 列右侧增加地理位置列 |
| **设备管理** | 隐藏"组"栏目；增加"位置信息"（按最后在线 IP 查询）；ID 栏前显示系统类型图标（Windows/Android/Linux/iOS 标准图标）；列宽自适应、内容不截断 |
| **地址簿** | ID 栏左对齐 + 复制按钮右对齐、列宽自适应、图标统一 |
| **近期实时** | 工作台近期登录/连接数据实时刷新（不刷新页面），最多 50 条 |
| **导航** | 工作台"在线设备"取自设备管理最后在线数据；移除顶部多余卡片 |

### 说明

- `ip2region.xdb` 为离线数据库，随镜像内置，**不依赖任何外网 IP 查询服务**
- 管理后台标题可通过 `RUSTDESK_API_ADMIN_TITLE` 自定义

---

## 更新记录（Changelog）

| 版本 | 日期 | 内容 |
|---|---|---|
| `latest`（v1.1.16-custom） | 2026-10-05 | 首次公开版：定制 hbbs/hbbr（1.1.16 + lejianwen API）+ 管理后台 v76（ART 风格 + ip2region） |

## 本地构建

```bash
docker build -t <your-id>/rustdesk-server-s6-public:latest .
docker push <your-id>/rustdesk-server-s6-public:latest
```

## GitHub Actions 自动构建

推送到 Docker Hub 的自动流程见 `.github/workflows/build.yml`（支持手动触发时额外打版本 tag）。

仓库 Settings → Secrets and variables → Actions 配置：

| Secret | 说明 |
|---|---|
| `DOCKERHUB_USERNAME` | Docker Hub 用户名 |
| `DOCKERHUB_TOKEN` | Docker Hub Access Token |
| `ALIYUN_REGISTRY` | 阿里云镜像仓库地址，如 `registry.cn-hangzhou.aliyuncs.com`（可选） |
| `ALIYUN_NAMESPACE` | 阿里云命名空间（可选） |
| `ALIYUN_USERNAME` | 阿里云账号（可选） |
| `ALIYUN_PASSWORD` | 阿里云密码或专用 Token（可选） |

## 常见问题（FAQ）

**Q1：客户端连接不上？**
- 检查防火墙放行 `21114/tcp 21116/tcp 21116/udp 21117/tcp`
- 确认客户端 ID/中继服务器地址填了端口（如 `IP:21116`）

**Q2：P2P 直连失败，走了中继？**
- 双方 UDP 21116 需可达；公网环境通常可直接打洞，内网对公网取决于 NAT 类型
- 服务器为 NAT 后时需在路由器映射 21116/udp + 21117/tcp

**Q3：强制加密怎么用？**
- `ENCRYPTED_ONLY=1` 时，客户端需先导入 `/data/id_ed25519.pub` 公钥
- 首次运行容器后 `cat /data/id_ed25519.pub` 查看公钥

**Q4：网页客户端（webclient2）打开慢？**
- 静态资源首次加载需要时间，可前置 Nginx 做 gzip + 静态缓存
- 参考 `docker-compose.example.yml` 中 Nginx 加速方案

**Q5：迁移服务器？**
- 停容器 → 打包两个数据目录（`/data`、`/app/data`）→ 新机器解压 → 改环境变量 IP → 重启

## 目录结构

```
├── Dockerfile              镜像构建文件
├── hbbs / hbbr             定制服务器二进制（1.1.16 + API 补丁，静态编译）
├── admin-dist/             定制管理后台前端（v76 + ip2region）
├── docker-compose.example.yml  完整部署示例（含 Nginx 加速可选）
├── .dockerignore
└── .github/workflows/      GitHub Actions 自动构建
```
