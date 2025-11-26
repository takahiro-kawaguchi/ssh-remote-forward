#!/bin/sh
# リモートフォワード専用ロジック

# 共通オプション
AUTOSSH_COMMON_OPTS="\
     -M 0 \
     -N \
     -o ServerAliveInterval=30 \
     -o ServerAliveCountMax=3 \
     -o ExitOnForwardFailure=yes \
     -o StrictHostKeyChecking=yes \
     -o UserKnownHostsFile=/root/.ssh/known_hosts \
     -p ${SSH_PORT} \
     -i ${SSH_KEY_PATH} \
     ${SSH_USER}@${SSH_HOST}"

echo "Starting autossh remote tunnel: ${SSH_HOST}:${REMOTE_PORT} -> localhost:22"

# リモートフォワードオプションのみを実行
exec autossh \
     -R "${REMOTE_PORT}:localhost:22" \
     ${AUTOSSH_COMMON_OPTS}