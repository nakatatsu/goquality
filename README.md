# Go Quality Tools（作成中）

Go言語プロジェクトの品質検査

※ まだ作成中

## 概要

このリポジトリは、Go言語のコード品質を維持・向上させるための自動化ツール群をDockerイメージとして提供します。CI/CDパイプラインやローカル開発環境で統一された品質検査環境を利用できます。

### 含まれるツール

- **フォーマッター**: gofumpt v0.6.0, goimports v0.20.0
- **リンター**: staticcheck, golangci-lint v1.59.0, go vet
- **セキュリティ**: govulncheck v1.1.1, gosec v2.18.2, osv-scanner v1.7.0
- **ベース**: Go 1.24（Debian bookworm）

### 使い方

Goプロジェクトのルートディレクトリで以下のコマンドを実行：

```bash
# 全ての品質チェックを一括実行
docker run --rm -v $(pwd):/work ghcr.io/nakatatsu/goquality:latest go-quality-check
```

これで以下の全ての検査が実行されます：
- コードフォーマットチェック（gofumpt, goimports）
- 静的解析（go vet, staticcheck, golangci-lint）
- テスト実行とカバレッジ測定（80%閾値）
- セキュリティスキャン（govulncheck, gosec, osv-scanner）
- モジュール健全性チェック（go mod tidy, go mod verify）

### イメージ情報

- **レジストリ**: GitHub Container Registry (ghcr.io)
- **イメージ名**: `ghcr.io/nakatatsu/goquality`
- **利用可能タグ**:
  - `latest`: mainブランチの最新版
  - `develop`: developブランチの最新版
  - `1.24-YYYYMMDD`: Goバージョンとビルド日付

### カスタマイズオプション

```bash
# カバレッジ閾値を90%に設定
docker run --rm -v $(pwd):/work -e COVERAGE_THRESHOLD=90 ghcr.io/nakatatsu/goquality:latest go-quality-check

# セキュリティスキャンをスキップ
docker run --rm -v $(pwd):/work ghcr.io/nakatatsu/goquality:latest go-quality-check --skip-security

# テストをスキップしてフォーマットと静的解析のみ
docker run --rm -v $(pwd):/work ghcr.io/nakatatsu/goquality:latest go-quality-check --skip-test

# 詳細出力モード
docker run --rm -v $(pwd):/work ghcr.io/nakatatsu/goquality:latest go-quality-check --verbose
```

## 設定のカスタマイズ

### golangci-lint設定

プロジェクトルートに `.golangci.yml` を配置することで、リンターの設定をカスタマイズできます：

```yaml
linters-settings:
  gocyclo:
    min-complexity: 15
  
linters:
  enable:
    - gofmt
    - golint
    - govet
    - staticcheck
```


### 個別コマンド実行

必要に応じて個別のツールを実行することも可能です：

```bash
# コードフォーマットチェック
docker run --rm -v $(pwd):/work ghcr.io/nakatatsu/goquality:latest gofumpt -l -d .
docker run --rm -v $(pwd):/work ghcr.io/nakatatsu/goquality:latest goimports -l -d .

# 静的解析
docker run --rm -v $(pwd):/work ghcr.io/nakatatsu/goquality:latest go vet ./...
docker run --rm -v $(pwd):/work ghcr.io/nakatatsu/goquality:latest staticcheck ./...
docker run --rm -v $(pwd):/work ghcr.io/nakatatsu/goquality:latest golangci-lint run

# テスト実行
docker run --rm -v $(pwd):/work ghcr.io/nakatatsu/goquality:latest go test -race ./...

# セキュリティスキャン
docker run --rm -v $(pwd):/work ghcr.io/nakatatsu/goquality:latest govulncheck ./...
docker run --rm -v $(pwd):/work ghcr.io/nakatatsu/goquality:latest gosec ./...
```
