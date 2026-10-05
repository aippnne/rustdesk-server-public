# ============================================================
# RustDesk Server 公开版镜像（1.1.16 定制）
# 基于官方 lejianwen/rustdesk-server-s6 镜像，替换：
#   1) 定制静态编译 hbbs/hbbr（1.1.16 + lejianwen API 补丁）
#   2) 定制管理后台 / 网页客户端前端（v76，ART 风格 + ip2region）
# 无内置服务器地址/密钥，部署时通过环境变量配置自己的服务器
#
# 本地构建：
#   docker build -t <your-id>/rustdesk-server-s6-public:latest .
# GitHub Actions 自动构建：见 .github/workflows/build.yml
# ============================================================

FROM lejianwen/rustdesk-server-s6:latest

# ---- OCI 元数据标签（docker inspect 可查） ----
LABEL org.opencontainers.image.title="RustDesk Server Public"
LABEL org.opencontainers.image.description="RustDesk server with custom hbbs/hbbr 1.1.16 + ART-style admin web v76, no embedded server config"
LABEL org.opencontainers.image.version="1.1.16"
LABEL org.opencontainers.image.source="https://github.com/aippnne/rustdesk-server-public"

# ---- 1. 替换定制静态编译的 hbbs/hbbr ----
# 说明：官方 s6 镜像中 hbbs/hbbr 位于 /usr/bin/（s6 服务脚本调用）
#       若基础镜像版本路径有变化，可先 docker run 进容器确认
COPY --chmod=755 hbbs /usr/bin/hbbs
COPY --chmod=755 hbbr /usr/bin/hbbr
RUN hbbs --version 2>/dev/null || true

# ---- 2. 定制管理后台 / 网页客户端前端（v76） ----
# 覆盖默认 resources/admin（含 static/、index.html、ip2region.xdb）
COPY admin-dist/ /app/resources/admin/

# ---- 3. 内置脱敏后的生产配置（开箱即用）----
# config.yaml：内置 Nginx 加速模式（gin.api-addr=21140，21114 让给 Nginx）
#              IP/密钥均为占位符，部署时由环境变量（RUSTDESK_API_*）注入
#              如需自定义，挂载 /app/conf/config.yaml 覆盖即可
COPY config.yaml.example /app/conf/config.yaml

# nginx.conf 模板：内置供部署时提取/参考（gzip + 30天静态缓存 + 反代 21140）
#   提取到宿主机：docker cp <容器名>:/app/resources/nginx.conf /root/rustdesk/nginx.conf
COPY nginx.conf.example /app/resources/nginx.conf

# ---- 端口（host 模式部署时由环境决定） ----
# 21114 API/后台/网页客户端   21116 ID 服务器   21117 中继服务器
EXPOSE 21114 21116 21117

# ---- 入口保持官方 s6-overlay 机制，不修改 ----
