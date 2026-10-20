FROM nattertool/natter:debian

# 安装 requests 等 Hook 脚本常用依赖
RUN apt-get update \
    && apt-get install -y --no-install-recommends python3-requests \
    && rm -rf /var/lib/apt/lists/*

COPY natter-entrypoint.sh /usr/local/bin/natter-entrypoint.sh
RUN chmod 755 /usr/local/bin/natter-entrypoint.sh
ENTRYPOINT ["/usr/local/bin/natter-entrypoint.sh"]
