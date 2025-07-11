# Go Quality Tools - Docker Image

Go言語プロジェクトの品質検査ツール群をパッケージしたDockerイメージを提供するリポジトリです。

## 概要

このリポジトリは、Go言語のコード品質を維持・向上させるための自動化ツール群をDockerイメージとして提供します。CI/CDパイプラインやローカル開発環境で統一された品質検査環境を利用できます。

### 含まれるツール

- **フォーマッター**: gofumpt v0.6.0, goimports v0.20.0
- **リンター**: staticcheck, golangci-lint v1.59.0, go vet
- **セキュリティ**: govulncheck v1.1.1, gosec v2.18.2, osv-scanner v1.7.0
- **ベース**: Go 1.24（Debian bookworm）

## Dockerイメージの使い方

### イメージ情報

- **レジストリ**: GitHub Container Registry (ghcr.io)
- **イメージ名**: `ghcr.io/nakatatsu/goquality`
- **利用可能タグ**:
  - `latest`: mainブランチの最新版
  - `develop`: developブランチの最新版
  - `1.24-YYYYMMDD`: Goバージョンとビルド日付

### 基本的な使い方

Goプロジェクトのルートディレクトリで以下のコマンドを実行：

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

# カバレッジ測定
docker run --rm -v $(pwd):/work ghcr.io/nakatatsu/goquality:latest go test -race -coverprofile=coverage.out ./...

# セキュリティスキャン
docker run --rm -v $(pwd):/work ghcr.io/nakatatsu/goquality:latest govulncheck ./...
docker run --rm -v $(pwd):/work ghcr.io/nakatatsu/goquality:latest gosec ./...
docker run --rm -v $(pwd):/work ghcr.io/nakatatsu/goquality:latest osv-scanner .

# モジュール健全性チェック
docker run --rm -v $(pwd):/work ghcr.io/nakatatsu/goquality:latest go mod tidy -v
docker run --rm -v $(pwd):/work ghcr.io/nakatatsu/goquality:latest go mod verify
```

### ワンライナーでの使用例

```bash
# コードフォーマット修正
docker run --rm -v $(pwd):/work ghcr.io/nakatatsu/goquality:latest gofumpt -w .

# インポート整理
docker run --rm -v $(pwd):/work ghcr.io/nakatatsu/goquality:latest goimports -w .

# 任意のGoコマンド実行
docker run --rm -v $(pwd):/work ghcr.io/nakatatsu/goquality:latest go version
```

## GitHub Actionsでの利用

CI/CDパイプラインでの使用例：

```yaml
jobs:
  quality-check:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/nakatatsu/goquality:latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Format check
        run: |
          gofumpt -l -d .
          goimports -l -d .
      
      - name: Lint
        run: |
          go vet ./...
          staticcheck ./...
          golangci-lint run
      
      - name: Test
        run: go test -race -coverprofile=coverage.out ./...
      
      - name: Security scan
        run: |
          govulncheck ./...
          gosec ./...
```

実際の例は `.github/workflows/cicd-sample.yml` を参照してください。


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

### 環境変数の利用

```bash
# カバレッジ閾値の設定
docker run --rm -v $(pwd):/work -e COVERAGE_THRESHOLD=90 ghcr.io/nakatatsu/goquality:latest go test -coverprofile=coverage.out ./...
```

## CI/CDサンプル

このリポジトリには以下のサンプルファイルが含まれています：

- `.github/workflows/cicd-sample.yml`: GitHub Actionsでの品質チェックサンプル

