# ssh-remote-forward

NAT/ファイアウォールの内側にあるマシンに、外部の踏み台(リレー)サーバー経由でSSHアクセスできるようにする、autossh + SSHリバースフォワード用のDockerコンテナです。

## 仕組み

```
[あなたのPC] --ssh--> [SSH_HOST:REMOTE_PORT] --tunnel--> [このコンテナのsshd:22] --> ローカルネットワーク内
```

このコンテナは以下の2つの役割を同時に持ちます。

1. **踏み台への接続元(クライアント)**
   `autossh`で外部の踏み台サーバー(`SSH_HOST`)へ接続し続け、`-R ${REMOTE_PORT}:localhost:22` でリバースフォワードを張ります。切断されても自動再接続します。
2. **踏み台自体(サーバー)**
   コンテナ内でも独自の`sshd`が動作しており、`JUMP_USER`というユーザーでログインを受け付けます。

結果として、踏み台サーバー(`SSH_HOST`)の`${REMOTE_PORT}`にSSH接続すると、トンネルを通ってこのコンテナのsshdに繋がり、外からNAT内部のマシンへSSHできるようになります。

## セットアップ

### 1. `.env` を作成

`.env.example` をコピーして `.env` を作成し、値を埋めます。

```bash
cp .env.example .env
```

| 変数名 | 説明 |
|---|---|
| `JUMP_USER` | コンテナ内に作成するユーザー名(踏み台ユーザー) |
| `SSH_USER` | 接続先の踏み台サーバーのユーザー名 |
| `SSH_HOST` | 接続先の踏み台サーバーのホスト名/IP |
| `SSH_PORT` | 接続先の踏み台サーバーのSSHポート |
| `IDENTITY_FILE` | 踏み台サーバーへ**出ていく**接続に使う秘密鍵のファイル名(`ssh_key/`内に配置) |
| `REMOTE_PORT` | 踏み台サーバー側でリバースフォワードに使うポート番号 |

### 2. `ssh_key/` フォルダを用意

```
ssh_key/
├── ${IDENTITY_FILE}      # 踏み台サーバーへ接続するための秘密鍵
├── known_hosts           # 踏み台サーバーのホストキー
└── authorized_keys       # このコンテナへ入ってくる利用者の公開鍵
```

- `${IDENTITY_FILE}`: `SSH_USER@SSH_HOST` への接続に使う秘密鍵。対応する公開鍵は踏み台サーバー側の`authorized_keys`に登録しておく必要があります。
- `known_hosts`: `StrictHostKeyChecking=yes` で接続するため、あらかじめ踏み台サーバーのホストキーを登録しておく必要があります。取得例:
  ```bash
  ssh-keyscan -p ${SSH_PORT} ${SSH_HOST} > ssh_key/known_hosts
  ```
- `authorized_keys`: このコンテナ(踏み台)に**入ってくる**利用者の公開鍵を列挙します。

### 3. `ssh_host_keys/` フォルダを用意

コンテナ自身のsshdホストキーを永続化するためのフォルダです。再起動のたびにホストキーが変わらないよう、あらかじめ生成しておきます。

```bash
mkdir -p ssh_host_keys
ssh-keygen -t ed25519 -f ssh_host_keys/ssh_host_ed25519_key -N ""
```

### 4. 起動

```bash
docker compose up -d --build
```

## 使い方

踏み台サーバー経由でコンテナに接続します。

```bash
ssh -p ${REMOTE_PORT} ${JUMP_USER}@${SSH_HOST} -i <authorized_keysに対応する秘密鍵>
```

ここからさらにローカルネットワーク内の他マシンへ接続する、あるいは`-J`(ProxyJump)や追加のポートフォワードを組み合わせて使うことを想定しています。

## 注意事項

- 踏み台サーバー(`SSH_HOST`)側の`sshd_config`で`GatewayPorts yes`相当の設定が有効になっていないと、`localhost`以外(外部)から`${REMOTE_PORT}`へアクセスできません。踏み台サーバー側の設定も合わせて確認してください。
- `PasswordAuthentication no`のため、コンテナへのログインは公開鍵認証のみです。
