# GitHub Actions設定

## docker-build.yml

Dockerイメージをビルドして複数のレジストリにプッシュするワークフローです。

### レジストリ設定

このワークフローは以下の2つのレジストリに対応しています：

1. **GitHub Container Registry (GHCR)** - メインレジストリ（常に有効）
   - イメージ: `ghcr.io/nakatatsu/goquality`
   - 認証: 自動（GITHUB_TOKEN使用）

2. **Docker Hub** - オプション（設定時のみ有効）
   - イメージ: `tnakamura2025/goquality`
   - 認証: Variables/Secretsの設定が必要

### Variables/Secretsの設定

Docker Hubを使用する場合、リポジトリの Settings > Secrets and variables > Actions で以下を設定：

#### Variables（公開情報）
| 変数名 | 説明 | 必須 |
|-------|------|-----|
| `DOCKERHUB_USERNAME` | Docker Hubのユーザー名 | Docker Hub使用時のみ |

#### Secrets（機密情報）
| シークレット名 | 説明 | 必須 |
|--------------|------|-----|
| `DOCKERHUB_TOKEN` | Docker Hubのアクセストークン | Docker Hub使用時のみ |

### トリガー条件

- `main`または`develop`ブランチへのプッシュ
- バージョンタグ（`v*`）のプッシュ
- プルリクエスト（ビルドのみ、プッシュなし）
- 毎日00:00 UTC（nightlyビルド）
- 手動実行（workflow_dispatch）
  - `push`パラメータでPR時のプッシュを制御可能

### タグ付けルール

#### 共通タグ
- ブランチ名（例：`main`、`develop`）
- プルリクエスト番号（例：`pr-123`）
- セマンティックバージョン（例：`v1.2.3` → `1.2.3`、`1.2`）
- `latest`（mainブランチの場合）

#### GHCR専用タグ
- Goバージョン+日付（例：`1.24-20250711`）

#### Docker Hub専用タグ
- 日付のみ（例：`20250711`）
- Goバージョン+日付（例：`1.24-20250711`）

### 使用例

#### イメージのpull

```bash
# GitHub Container Registry（推奨）
docker pull ghcr.io/nakatatsu/goquality:latest

# Docker Hub（利用可能な場合）
docker pull tnakamura2025/goquality:latest
```

#### 手動実行でプッシュを制御

1. Actions タブから "Build and Push Docker Image" を選択
2. "Run workflow" をクリック
3. `push` オプションで `true` を選択するとPR時でもプッシュ

### マルチアーキテクチャ対応

AMD64とARM64の両方に対応したイメージをビルドします。

### ビルド後の処理

1. **イメージレポート**: ビルド成功時にサマリーを生成
2. **脆弱性スキャン**: nightlyビルドと手動実行時にTrivyでスキャン

### キャッシュ戦略

GitHub Actions Cache（gha）を使用してビルド時間を短縮します。