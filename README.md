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
    │   ├── .ci               # CI 用ホスト変数 (全ロールを有効化するダミー値)
    │   └── .example          # 変数定義のサンプル
    └── roles/
        ├── system/           # 基本システム設定
        ├── unique-oci/       # OCI固有設定 (iptables)
        ├── common-apps/      # 共通アプリケーション
        ├── o11y/             # 可観測性 (Prometheus / Alertmanager)
        ├── uptime-kuma/      # 死活監視 (Uptime Kuma)
        ├── nginx/            # リバースプロキシ (nginx)
        ├── minecraft/        # Minecraft サーバー
        ├── palworld/         # Palworld サーバー
        └── ops/              # 運用設定 (logrotate等)
```

## Ansible ロール

ロールは `System / Common` → `Apps` → `Ops` の順に実行されます。  
`ops` は各アプリのログ出力先などを前提とするため、必ず最後に適用されます。

| 区分 | ロール | 内容 | 適用条件 |
|---|---|---|---|
| System / Common | `system` | hostname / timezone / sshd / sudo / users / apt | 常時 |
| System / Common | `unique-oci` | OCI向けiptablesルール | `platform_name == "oci"` |
| System / Common | `common-apps` | cloudflared / cockpit / docker / prom-node-exporter | 常時 |
| Apps | `o11y` | Prometheus + Alertmanager + Cloudflare Exporter | 各種トークン定義時 |
| Apps | `uptime-kuma` | Uptime Kuma (死活監視) | `kuma_cloudflared_token` 定義時 |
| Apps | `nginx` | nginx リバースプロキシ | `rpx_cloudflared_token` 定義時 |
| Apps | `minecraft` | Minecraft サーバー (Paper + 各種プラグイン) | `mc_version` 定義時 |
| Apps | `palworld` | Palworld サーバー | `pal_join_fqdn` 等定義時 |
| Ops | `ops` | docker設定 / logrotate | 常時 |

> `palworld` ロールのデフォルト値 (`defaults/main.yml`) は廃止されました。  
> `pal_join_fqdn` / `pal_discord_webhook_url` / `pal_server_password` / `pal_admin_password` は host_vars で明示的に定義する必要があります。

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

| イベント | ワークフロー / ジョブ | 内容 |
|---|---|---|
| `pull_request` → develop / main | `Ansible CI (Check)` / `check-lint` | `ansible-lint` による静的解析 |
| `pull_request` → develop / main | `Ansible CI (Check)` / `check-syntax` | `ansible-playbook --syntax-check` による構文チェック |
| `pull_request` → develop / main | `Ansible CI (Check)` / `check-plan` | ベースブランチ適用後に PR ブランチを `--diff` 実行し、変更内容をプランとして出力 |
| `push` → develop / main | `Ansible CI (Test)` / `deploy` | devcontainer 内で Playbook を実行し、イメージを GHCR へプッシュ |

各チェックの実行結果は共通ワークフロー `_ansible-run-output.yml` を経由して PR コメントに投稿されます。

### CI 用ホスト変数

CI では [ansible/host_vars/.ci](ansible/host_vars/.ci) を `ansible/host_vars/localhost` にコピーして Playbook を実行します。  
このファイルには全ロールの適用条件を満たすためのダミー値がまとめられているため、**新しい変数をロールの適用条件に追加した場合は `.ci` にも追記してください**。追記を忘れると、そのロールが CI でスキップされ検証されません。

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
