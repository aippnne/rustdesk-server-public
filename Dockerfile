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

# ---- 1. 替换定制静态编译的 hbbs/hbbr ----
# 说明：官方 s6 镜像中 hbbs/hbbr 位于 /usr/bin/（s6 服务脚本调用）
#       若基础镜像版本路径有变化，可先 docker run 进容器确认
COPY hbbs /usr/bin/hbbs
COPY hbbr /usr/bin/hbbr
RUN chmod +x /usr/bin/hbbs /usr/bin/hbbr \
    && hbbs --version 2>/dev/null || true

# ---- 2. 定制管理后台 / 网页客户端前端（v76） ----
# 覆盖默认 resources/admin（含 static/、index.html、ip2region.xdb）
COPY admin-dist/ /app/resources/admin/

# ---- 端口（host 模式部署时由环境决定） ----
# 21114 API/后台/网页客户端   21116 ID 服务器   21117 中继服务器
EXPOSE 21114 21116 21117

# ---- 入口保持官方 s6-overlay 机制，不修改 ----
