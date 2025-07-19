# Go Quality Tools(α)

Go言語プロジェクトの包括的品質検査ツール(α版)

## 概要

このリポジトリは、Go言語のコード品質を維持・向上させるための自動化ツール群をDockerイメージとして提供します。CI/CDパイプラインやローカル開発環境で統一された品質検査環境を利用できます。

### 含まれるツール

- **フォーマッター**: gofumpt v0.6.0, goimports v0.20.0
- **リンター**: staticcheck, golangci-lint v1.64.3, go vet
- **セキュリティ**: govulncheck v1.1.1, gosec v2.22.5, osv-scanner v1.7.0
- **凝集度測定**: lcom4go (LCOM4メトリクス)
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
- 凝集度分析（LCOM4メトリクス）
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

# セキュリティスキャン
docker run --rm -v $(pwd):/work ghcr.io/nakatatsu/goquality:latest govulncheck ./...
docker run --rm -v $(pwd):/work ghcr.io/nakatatsu/goquality:latest gosec ./...

# 凝集度分析
docker run --rm -v $(pwd):/work ghcr.io/nakatatsu/goquality:latest lcom4 ./...
```

## 品質検査の効果

### 🚀 実際の改善効果

このツールセットにより以下の問題を早期発見・修正できます：

#### **バグの早期発見**
- **go vet**: データ競合、nil参照、型エラーを検出
- **staticcheck**: 無限ループ、未使用変数、論理エラーを発見  
- **golangci-lint**: 100種類以上のバグパターンを自動検出

#### **セキュリティリスクの排除**
- **gosec**: SQLインジェクション、パストラバーサル、暗号化の脆弱性
- **govulncheck**: 既知の脆弱性のある依存関係を検出
- **osv-scanner**: サプライチェーン攻撃の防止

#### **設計品質の向上**
- **LCOM4**: 構造体の凝集度測定（値が低いほど良い設計）
- **複雑度チェック**: 理解しにくいコードを発見
- **テストカバレッジ**: 未テスト部分の可視化

#### **保守性の確保**
- **gofumpt/goimports**: チーム全体でコードスタイル統一
- **非推奨API検出**: 将来のGo版での互換性問題を防止
- **依存関係の健全性**: セキュリティパッチの適用状況確認
