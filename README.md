# Goコードの品質検査をしたいリポジトリ

Go言語プロジェクトの品質を検査できるといいなという思いの元で作られたリポジトリです

## 概要

このリポジトリは、Go言語のコード品質を維持・向上させるための自動化ツール群をDockerイメージとして提供します。

- コードフォーマット（gofumpt, goimports）
- 静的解析（go vet, staticcheck, golangci-lint）
- テストとカバレッジ測定
- セキュリティスキャン（govulncheck, gosec, osv-scanner）
- 依存関係の健全性チェック

## 必要な環境

- Docker
- Make（オプション：便利なコマンドを使う場合）

**注意**: Go言語のインストールは不要です。全てのツールはDockerイメージに含まれています。

## クイックスタート

```bash
# 全品質チェックを一発実行
make
```

たったこれだけで、以下の全てが実行されます：
- コードフォーマット
- 静的解析  
- テスト実行
- カバレッジ測定
- セキュリティスキャン

## 詳細な使い方

### Dockerイメージは自動でpullされます

```bash
# 基本コマンド
make              # 全品質チェックを一発実行（推奨）
make check        # 同上

# 個別のチェックを実行したい場合
make docker-fmt        # コードフォーマットのみ
make docker-lint       # 静的解析のみ
make docker-test       # テストのみ
make docker-coverage   # カバレッジ測定のみ
make docker-sec        # セキュリティスキャンのみ
```

#### Dockerコマンドを直接使う場合

```bash
# 全ての品質チェックを実行
docker run --rm -v $(pwd):/work ghcr.io/nakatatsu/goquality:latest make quality

# 個別のチェックを実行
docker run --rm -v $(pwd):/work ghcr.io/nakatatsu/goquality:latest make fmt
docker run --rm -v $(pwd):/work ghcr.io/nakatatsu/goquality:latest make lint
docker run --rm -v $(pwd):/work ghcr.io/nakatatsu/goquality:latest make test
docker run --rm -v $(pwd):/work ghcr.io/nakatatsu/goquality:latest make coverage
docker run --rm -v $(pwd):/work ghcr.io/nakatatsu/goquality:latest make sec
```

### GitHub Actionsでの自動実行

リポジトリにpush/PRすると自動的に品質チェックが実行されます。GitHub ActionsもDockerイメージを使用するため、ローカルとCIで完全に同じ環境が保証されます。

## コマンド一覧

| Makeコマンド | 説明 |
|-------------|-----|
| `make` | 全品質チェックを一発実行（デフォルト） |
| `make check` | 同上 |
| `make docker-fmt` | コードフォーマットのみ |
| `make docker-lint` | 静的解析のみ |
| `make docker-test` | テストのみ |
| `make docker-coverage` | カバレッジ測定のみ |
| `make docker-sec` | セキュリティスキャンのみ |
| `make docker-build` | Dockerイメージをローカルビルド |
| `make docker-pull` | Dockerイメージを更新 |

### 任意のコマンドを実行

```bash
# 任意のコマンドをDockerコンテナ内で実行
make docker-run CMD='go mod tidy'

# または直接Dockerコマンドで
docker run --rm -v $(pwd):/work ghcr.io/nakatatsu/goquality:latest go mod tidy
```

## 設定のカスタマイズ

### golangci-lint設定

`.golangci.yml` ファイルを編集して、有効化するリンターや除外ルールをカスタマイズできます。変更後はDockerイメージの再ビルドは不要です。

### カバレッジ閾値の変更

デフォルトは80%です。変更する場合：

```bash
# 環境変数で一時的に変更
docker run --rm -v $(pwd):/work -e COVERAGE_THRESHOLD=90 ghcr.io/nakatatsu/goquality:latest make coverage
```

## Dockerイメージの詳細

### イメージ情報

- **レジストリ**: GitHub Container Registry (ghcr.io)
- **イメージ名**: `ghcr.io/nakatatsu/goquality`
- **利用可能タグ**:
  - `latest`: 最新安定版
  - `1.24-YYYYMMDD`: Goバージョンとビルド日付
  - `vX.Y.Z`: セマンティックバージョニング

### 含まれるツール

- **フォーマッター**: gofumpt v0.6.0, goimports v0.20.0
- **リンター**: staticcheck v0.5.5, golangci-lint v1.59.0
- **セキュリティ**: govulncheck v1.1.1, gosec v2.18.2, osv-scanner v1.7.0
- **ベース**: Go 1.24（Debian bookworm）

## トラブルシューティング

### Dockerイメージのpullが失敗する

```bash
# ネットワーク接続を確認して再試行
docker pull ghcr.io/nakatatsu/goquality:latest
```

### ローカルビルドが失敗する

```bash
# キャッシュをクリアして再ビルド
docker build --no-cache -t ghcr.io/nakatatsu/goquality:latest .
```

### 権限エラーが発生する

```bash
# ユーザーIDを指定して実行
docker run --rm -v $(pwd):/work --user $(id -u):$(id -g) ghcr.io/nakatatsu/goquality:latest make quality
```

### Windows環境での実行

PowerShellの場合：
```powershell
docker run --rm -v ${PWD}:/work ghcr.io/nakatatsu/goquality:latest make quality
```

## CI/CDパイプラインでの利用

GitHub Actionsを使用する場合、`.github/workflows/docker-build.yml` が自動的にDockerイメージをビルドしてGitHub Container Registryにプッシュします。

### 自動ビルドタイミング

- mainブランチへのpush時
- Pull Request作成時
- 毎日00:00 UTC（nightlyビルド）
- タグ付け時（v*）

## バッジの追加

READMEにステータスバッジを追加：

```bash
docker run --rm -v $(pwd):/work ghcr.io/nakatatsu/goquality:latest ./scripts/add-badges.sh [owner/repo]
```

## ライセンス

[LICENSE](LICENSE) ファイルを参照してください。