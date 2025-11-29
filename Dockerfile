FROM debian:stable-slim

RUN apt update && \
    DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends \
    openssh-client \
    autossh \
    openssh-server && \
    rm -rf /var/lib/apt/lists/*

RUN rm -f /etc/ssh/ssh_host_*_key /etc/ssh/ssh_host_*_key.pub

# --- SSHD Configの設定 (ビルド時に確定させる) ---
# Ubuntuでもsshd_configの場所は /etc/ssh/sshd_config です。
# "administratively prohibited" エラー回避のための設定をここで投入
RUN echo "Configuring sshd..." && \
    echo "HostKey /etc/ssh/ssh_host_ed25519_key" >> /etc/ssh/sshd_config && \
    echo "AllowTcpForwarding yes" >> /etc/ssh/sshd_config && \
    echo "GatewayPorts yes" >> /etc/ssh/sshd_config && \
    echo "PermitTunnel yes" >> /etc/ssh/sshd_config && \
    echo "AllowAgentForwarding yes" >> /etc/ssh/sshd_config && \
    # パスワード認証を無効化し、公開鍵認証のみにする(セキュリティ強化)
    echo "PasswordAuthentication no" >> /etc/ssh/sshd_config

# 起動スクリプトを配置
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# コンテナ内のSSHポート
EXPOSE 22

# コンテナ起動時にスクリプトを実行
ENTRYPOINT ["/entrypoint.sh"]

