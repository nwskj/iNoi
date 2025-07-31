# 第一阶段：构建阶段
FROM --platform=$BUILDPLATFORM alpine:edge as builder
LABEL stage=go-builder
WORKDIR /app/

# 安装构建依赖
RUN apk add --no-cache bash curl gcc git go musl-dev make

# 复制并构建
COPY . .
RUN ./build.sh release docker-multiplatform

# 第二阶段：运行时镜像
ARG BASE_IMAGE_TAG=base
FROM openlistteam/openlist-base-image:${BASE_IMAGE_TAG}

# 参数定义
ARG INSTALL_FFMPEG=false
ARG INSTALL_ARIA2=false
ARG TARGETARCH
ARG TARGETVARIANT
LABEL MAINTAINER="iNoi"

# 安装运行时依赖
WORKDIR /opt/inoi/
RUN apk update && \
    apk upgrade --no-cache && \
    apk add --no-cache bash jq ca-certificates su-exec tzdata runit && \
    rm -rf /var/cache/apk/*

# 条件安装FFmpeg和Aria2
RUN if [ "$INSTALL_FFMPEG" = "true" ]; then \
        apk add --no-cache ffmpeg; \
    fi

RUN if [ "$INSTALL_ARIA2" = "true" ]; then \
        apk add --no-cache curl aria2 && \
        mkdir -p /opt/aria2/.aria2 && \
        wget https://github.com/P3TERX/aria2.conf/archive/refs/heads/master.tar.gz -O /tmp/aria-conf.tar.gz && \
        tar -zxvf /tmp/aria-conf.tar.gz -C /opt/aria2/.aria2 --strip-components=1 && \
        rm -f /tmp/aria-conf.tar.gz && \
        sed -i 's|rpc-secret|#rpc-secret|g' /opt/aria2/.aria2/aria2.conf && \
        sed -i 's|/root/.aria2|/opt/aria2/.aria2|g' /opt/aria2/.aria2/aria2.conf && \
        sed -i 's|/root/.aria2|/opt/aria2/.aria2|g' /opt/aria2/.aria2/script.conf && \
        sed -i 's|/root|/opt/aria2|g' /opt/aria2/.aria2/aria2.conf && \
        sed -i 's|/root|/opt/aria2|g' /opt/aria2/.aria2/script.conf && \
        mkdir -p /opt/service/stop/aria2/log && \
        echo '#!/bin/sh' > /opt/service/stop/aria2/run && \
        echo 'exec 2>&1' >> /opt/service/stop/aria2/run && \
        echo 'exec aria2c --enable-rpc --rpc-allow-origin-all --conf-path=/opt/aria2/.aria2/aria2.conf' >> /opt/service/stop/aria2/run && \
        echo '#!/bin/sh' > /opt/service/stop/aria2/log/run && \
        echo 'mkdir -p /opt/openlist/data/log/aria2 2>/dev/null' >> /opt/service/stop/aria2/log/run && \
        echo 'exec svlogd /opt/openlist/data/log/aria2' >> /opt/service/stop/aria2/log/run && \
        chmod +x /opt/service/stop/aria2/run /opt/service/stop/aria2/log/run && \
        touch /opt/aria2/.aria2/aria2.session && \
        /opt/aria2/.aria2/tracker.sh; \
    fi

# 复制构建产物（根据目标平台自动选择正确架构）
COPY --from=builder /app/build/linux/${TARGETARCH}${TARGETVARIANT:+/$TARGETVARIANT}/iNoi /opt/inoi/iNoi
COPY --chmod=755 entrypoint.sh /entrypoint.sh

# 验证版本
RUN /entrypoint.sh version

# 环境变量和配置
ENV PUID=0 PGID=0 UMASK=022 RUN_ARIA2=${INSTALL_ARIA2}
VOLUME /opt/inoi/data/
EXPOSE 5244 5245
CMD [ "/entrypoint.sh" ]