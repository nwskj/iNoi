#!/bin/sh
set -euo pipefail

# 设置默认umask（带后备值）
UMASK=${UMASK:-022}
umask "$UMASK"

# 版本检查命令
if [ "$1" = "version" ]; then
    if [ -x "./iNoi" ]; then
        ./iNoi version
    else
        echo "Error: iNoi binary not found or not executable" >&2
        exit 1
    fi
    exit 0
fi

# 主运行逻辑
main() {
    # 条件启动Aria2
    if [ "${RUN_ARIA2:-false}" = "true" ]; then
        if [ -d "/opt/service/stop/aria2" ]; then
            if ! cp -a /opt/service/stop/aria2 /opt/service/start/ 2>/dev/null; then
                echo "Warning: Failed to setup Aria2 service" >&2
            fi
        else
            echo "Warning: Aria2 service directory not found" >&2
        fi
    fi

    # 权限处理（带后备值）
    PUID=${PUID:-0}
    PGID=${PGID:-0}
    
    if [ "$PUID" -ne 0 ] || [ "$PGID" -ne 0 ]; then
        if ! chown -R "${PUID}:${PGID}" /opt/inoi/ 2>/dev/null; then
            echo "Warning: Failed to change ownership of /opt/inoi/" >&2
        fi
    fi

    # 主程序执行
    exec su-exec "${PUID}:${PGID}" ./iNoi server --no-prefix
}

# 捕获中断信号
trap 'exit 0' INT TERM

main "$@"