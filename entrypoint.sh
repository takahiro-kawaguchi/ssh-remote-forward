#!/bin/sh

# 環境変数 JUMP_USER が設定されていない場合はデフォルト値 'jumpuser' を使用
USER_NAME=${JUMP_USER:-jumpuser}

echo "Setting up jump host with user: ${USER_NAME}"

# 1. ユーザーの作成
if ! id "${USER_NAME}" >/dev/null 2>&1; then
    echo "Creating user ${USER_NAME}..."
    useradd -m -s /bin/sh "${USER_NAME}"
fi

# 2. 利用者の公開鍵を配置
KEY_DIR="/home/${USER_NAME}/.ssh"
AUTHORIZED_KEYS_FILE="${KEY_DIR}/authorized_keys"

if [ -f /root/mounted_keys/authorized_keys ]; then
    echo "Setting up authorized_keys for ${USER_NAME}..."
    mkdir -p "${KEY_DIR}"
    cp /root/mounted_keys/authorized_keys "${AUTHORIZED_KEYS_FILE}"
    chown -R "${USER_NAME}:${USER_NAME}" "${KEY_DIR}"
    chmod 700 "${KEY_DIR}"
    chmod 600 "${AUTHORIZED_KEYS_FILE}"
else
    echo "WARNING: No authorized_keys found at /root/mounted_keys/authorized_keys"
fi

# 3. SSHサーバー (sshd) をバックグラウンドで起動
echo "Starting sshd..."
mkdir -p /run/sshd
/usr/sbin/sshd


# 共通オプション
AUTOSSH_COMMON_OPTS="\
     -M 0 \
     -N \
     -o ServerAliveInterval=30 \
     -o ServerAliveCountMax=3 \
     -o ExitOnForwardFailure=no \
     -o StrictHostKeyChecking=yes \
     -o UserKnownHostsFile=/root/.ssh/known_hosts \
     -p ${SSH_PORT} \
     -i ${SSH_KEY_PATH} \
     ${SSH_USER}@${SSH_HOST}"

# TUNNELS変数をパースして -R フラグを生成
# 形式: リモートポート:転送先ホスト:転送先ポート (カンマ区切りで複数指定可)
TUNNEL_ARGS=""
for tunnel in $(echo "${TUNNELS}" | tr ',' ' '); do
    echo "Adding tunnel: ${SSH_HOST}:${tunnel}"
    TUNNEL_ARGS="${TUNNEL_ARGS} -R ${tunnel}"
done

exec autossh \
     ${TUNNEL_ARGS} \
     ${AUTOSSH_COMMON_OPTS}