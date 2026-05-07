# am-helper

サーバーの構成管理を自動化するツールです。  
systemd タイマーで定期的に GitHub リポジトリの更新を検知し、変更があれば Ansible Playbook を実行してサーバーをセルフアップデートします。

## 仕組み

```
am-helper.timer (1分間隔)
  └─ am-helper.service
       └─ am-helper.sh
            ├─ git fetch origin main
            ├─ 差分あり → git pull
            └─ ansible-playbook ansible/main.yml
```

## ディレクトリ構成

```
.
├── am-helper.sh              # メインスクリプト
├── systemd/
│   ├── am-helper.service     # systemd サービスユニット
│   └── am-helper.timer       # systemd タイマーユニット (1分間隔)
└── ansible/
    ├── main.yml              # Ansible メインPlaybook
    ├── host_vars/
    │   ├── localhost         # ホスト変数 (実機用・gitignore対象)
    │   └── .example          # 変数定義のサンプル
    └── roles/
        ├── system/           # 基本システム設定
        ├── unique-oci/       # OCI固有設定 (iptables)
        ├── common-apps/      # 共通アプリケーション
        ├── ops/              # 運用設定 (logrotate等)
        ├── o11y/             # 可観測性 (Prometheus / Alertmanager)
        ├── uptime-kuma/      # 死活監視 (Uptime Kuma)
        ├── nginx/            # リバースプロキシ (nginx)
        ├── minecraft/        # Minecraft サーバー
        └── palworld/         # Palworld サーバー
```

## Ansible ロール

| ロール | 内容 | 適用条件 |
|---|---|---|
| `system` | hostname / timezone / sshd / sudo / users / apt | 常時 |
| `unique-oci` | OCI向けiptablesルール | `platform_name == "oci"` |
| `common-apps` | cloudflared / cockpit / docker / prom-node-exporter | 常時 |
| `ops` | docker設定 / logrotate | 常時 |
| `o11y` | Prometheus + Alertmanager + Cloudflare Exporter | 各種トークン定義時 |
| `uptime-kuma` | Uptime Kuma (死活監視) | `kuma_cloudflared_token` 定義時 |
| `nginx` | nginx リバースプロキシ | `rpx_cloudflared_token` 定義時 |
| `minecraft` | Minecraft サーバー (Paper + 各種プラグイン) | `mc_version` 定義時 |
| `palworld` | Palworld サーバー | `pal_join_fqdn` 等定義時 |

## セットアップ

### 1. リポジトリの配置

```bash
git clone https://github.com/AhiruMarsh/am-helper
```

### 2. ホスト変数の設定

`ansible/host_vars/localhost` を作成し、サーバーに応じた変数を設定します。  
定義可能な変数は [ansible/host_vars/.example](ansible/host_vars/.example) を参照してください。

```yaml
# 必須
hostname: your-hostname
platform_name: oci  # or other

# オプション (有効にしたいロールに応じて追加)
mc_version: "1.21.4"
# ...
```

### 3. am-helper 実行

```bash
ansible-playbook ./am-helper/ansible/main.yml
```

## CI / CD

GitHub Actions による自動化が設定されています。

| イベント | ジョブ | 内容 |
|---|---|---|
| `pull_request` → develop / main | `static-check` | `ansible-playbook --syntax-check` による構文チェック |
| `push` → develop | `deploy` | devcontainer イメージのビルドと GHCR へのプッシュ |

## 開発環境

Dev Container が設定されています。VS Code または GitHub Codespaces で開くと、Ansible 開発環境が自動的に構築されます。

推奨拡張機能: [Red Hat Ansible](https://marketplace.visualstudio.com/items?itemName=redhat.ansible)

```bash
# Dev Container 内での構文チェック
ansible-playbook ansible/main.yml --syntax-check
```

## 依存関係の自動更新

Dependabot により以下のパッケージが週次で自動更新されます。

- GitHub Actions
- Docker Compose (各ロールのコンテナイメージ)
