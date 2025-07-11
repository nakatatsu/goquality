# GitHub Actions設定

## docker-publish.yml

Dockerイメージをビルドしてレジストリにプッシュするワークフローです。

### 環境変数による設定

リポジトリの Settings > Secrets and variables > Actions > Variables で以下を設定できます：

| 変数名 | 説明 | デフォルト値 |
|-------|------|------------|
| `DOCKER_REGISTRY` | プッシュ先のレジストリ | `ghcr.io` |
| `DOCKER_IMAGE_NAME` | イメージ名 | リポジトリ名 |

### シークレットの設定

GitHub Container Registry（ghcr.io）以外のレジストリを使用する場合：

| シークレット名 | 説明 |
|---------------|------|
| `DOCKER_USERNAME` | レジストリのユーザー名 |
| `DOCKER_PASSWORD` | レジストリのパスワード/トークン |

### トリガー条件

- `main`または`develop`ブランチへのプッシュ
- バージョンタグ（`v*`）のプッシュ
- プルリクエスト（ビルドのみ、プッシュなし）
- 手動実行（workflow_dispatch）

### タグ付けルール

- ブランチ名（例：`main`、`develop`）
- セマンティックバージョン（例：`v1.2.3` → `1.2.3`、`1.2`、`1`）
- `latest`（mainブランチの場合）
- 短縮SHA付きブランチ名（例：`main-abc1234`）
- 日付とSHA（例：`20250711-abc1234`）

### 使用例

#### 1. GitHub Container Registry（デフォルト）

追加設定不要。自動的に`ghcr.io/owner/repo`にプッシュされます。

#### 2. Docker Hub

Variables:
```
DOCKER_REGISTRY=docker.io
DOCKER_IMAGE_NAME=myusername/go-quality
```

Secrets:
```
DOCKER_USERNAME=myusername
DOCKER_PASSWORD=mydockerhubtoken
```

#### 3. プライベートレジストリ

Variables:
```
DOCKER_REGISTRY=registry.example.com
DOCKER_IMAGE_NAME=team/go-quality
```

Secrets:
```
DOCKER_USERNAME=serviceaccount
DOCKER_PASSWORD=registrytoken
```

### マルチアーキテクチャ対応

AMD64とARM64の両方に対応したイメージをビルドします。

## go-quality.yml

品質チェックを実行するワークフローです。docker-publish.ymlでビルドされたイメージを使用します。