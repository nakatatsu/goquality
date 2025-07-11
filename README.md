# Go言語品質検査ワークフロー

Go言語プロジェクトの品質を自動的に検査するためのDocker完全対応ワークフローです。

## 概要

このリポジトリは、Go言語のコード品質を維持・向上させるための自動化ツール群をDockerイメージとして提供します。ローカル環境への依存ゼロで、以下の検査を実行できます：

- コードフォーマット（gofumpt, goimports）
- 静的解析（go vet, staticcheck, golangci-lint）
- テストとカバレッジ測定
- セキュリティスキャン（govulncheck, gosec, osv-scanner）
- 依存関係の健全性チェック

## 必要な環境

- Docker
- Make（オプション：便利なコマンドを使う場合）

**注意**: Go言語のインストールは不要です。全てのツールはDockerイメージに含まれています。

## 使い方

### 1. Dockerイメージのビルド

```bash
# Dockerイメージをビルド
docker build -t go-quality .
```

### 2. 品質チェックの実行

#### Makefileを使う場合（推奨）

```bash
# 全ての品質チェックを実行
make docker-quality

# 個別のチェックを実行
make docker-fmt        # コードフォーマット
make docker-lint       # 静的解析
make docker-test       # テスト実行
make docker-coverage   # カバレッジ測定
make docker-sec        # セキュリティスキャン
```

#### Dockerコマンドを直接使う場合

```bash
# 全ての品質チェックを実行
docker run --rm -v $(pwd):/work go-quality make quality

# 個別のチェックを実行
docker run --rm -v $(pwd):/work go-quality make fmt
docker run --rm -v $(pwd):/work go-quality make lint
docker run --rm -v $(pwd):/work go-quality make test
docker run --rm -v $(pwd):/work go-quality make coverage
docker run --rm -v $(pwd):/work go-quality make sec
```

### 3. GitHub Actionsでの自動実行

リポジトリにpush/PRすると自動的に品質チェックが実行されます。GitHub ActionsもDockerイメージを使用するため、ローカルとCIで完全に同じ環境が保証されます。

## コマンド一覧

| Makeコマンド | 説明 | Dockerコマンド |
|-------------|------|---------------|
| `make docker-quality` | 全ての品質チェックを実行 | `docker run --rm -v $(pwd):/work go-quality make quality` |
| `make docker-fmt` | コードを整形 | `docker run --rm -v $(pwd):/work go-quality make fmt` |
| `make docker-lint` | リンターを実行 | `docker run --rm -v $(pwd):/work go-quality make lint` |
| `make docker-test` | テストを実行 | `docker run --rm -v $(pwd):/work go-quality make test` |
| `make docker-coverage` | カバレッジを測定 | `docker run --rm -v $(pwd):/work go-quality make coverage` |
| `make docker-sec` | セキュリティスキャン | `docker run --rm -v $(pwd):/work go-quality make sec` |

### 任意のコマンドを実行

```bash
# 任意のコマンドをDockerコンテナ内で実行
make docker-run CMD='go mod tidy'

# または直接Dockerコマンドで
docker run --rm -v $(pwd):/work go-quality go mod tidy
```

## 設定のカスタマイズ

### golangci-lint設定

`.golangci.yml` ファイルを編集して、有効化するリンターや除外ルールをカスタマイズできます。変更後はDockerイメージの再ビルドは不要です。

### カバレッジ閾値の変更

デフォルトは80%です。変更する場合：

```bash
# 環境変数で一時的に変更
docker run --rm -v $(pwd):/work -e COVERAGE_THRESHOLD=90 go-quality make coverage
```

## Dockerイメージの詳細

イメージには以下のツールが含まれています：

- **フォーマッター**: gofumpt v0.6.0, goimports v0.20.0
- **リンター**: staticcheck v0.5.5, golangci-lint v1.59.0
- **セキュリティ**: govulncheck v1.1.1, gosec v2.18.2, osv-scanner v1.7.0
- **ベース**: Go 1.24（Debian bookworm）

## トラブルシューティング

### Dockerイメージのビルドが失敗する

```bash
# キャッシュをクリアして再ビルド
docker build --no-cache -t go-quality .
```

### 権限エラーが発生する

```bash
# ユーザーIDを指定して実行
docker run --rm -v $(pwd):/work --user $(id -u):$(id -g) go-quality make quality
```

### Windows環境での実行

PowerShellの場合：
```powershell
docker run --rm -v ${PWD}:/work go-quality make quality
```

## CI/CDパイプラインでの利用

GitHub Actionsを使用する場合、`.github/workflows/go-quality.yml` が自動的にDockerイメージをビルドして使用します。プロジェクトごとの設定は不要です。

## バッジの追加

READMEにステータスバッジを追加：

```bash
docker run --rm -v $(pwd):/work go-quality ./scripts/add-badges.sh [owner/repo]
```

## ライセンス

[LICENSE](LICENSE) ファイルを参照してください。