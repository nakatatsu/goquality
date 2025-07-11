このリポジトリは、ツール群をつめこんだDockerfileと利用方法を記したドキュメントならびに実験用のサンプルだけが入っているべきだ。

Go言語のクオリティの検査ワークフローを作ってもらおうと思っている。

以下のような「品質検査ワークフロー」に含めるタスクを Claude Codeへ依頼すると、Go コードの健全性をかなり網羅的にチェックできます。全部まとめて GitHub Actions（または他の CI）用の YAML として書いてもらうイメージです。

| ステージ           | 目的                | 代表的なコマンド・ツール                                           | 依頼時のポイント                             |
| -------------- | ----------------- | ------------------------------------------------------ | ------------------------------------ |
| **整形・インポート整理** | コードの体裁統一          | `gofumpt -l -w ./…`, `goimports -l -w ./…`             | フォーマットが乱れていたらジョブ失敗にする                |
| **静的解析（一般）**   | バグの芽を早期検知         | `go vet ./…`, `staticcheck ./…`                        | `golangci-lint` で複数 Linters を束ねる構成も可 |
| **モジュール健全性**   | 依存と tidy の乖離検知    | `go mod tidy -v`, `go mod verify`                      | 差分が出たら失敗・PR へ diff をコメント             |
| **ユニットテスト**    | 正常動作とカバレッジ確保      | `go test -race -coverprofile=cover.out ./…`            | 最低カバレッジ閾値（例: 80%）を設定                 |
| **ファズテスト**     | 入力多様性によるクラッシュ検知   | `go test -fuzz=Fuzz -fuzztime=30s ./…`                 | Go 1.18 以上が前提                        |
| **ベンチマーク**     | 性能回帰の検出           | `go test -bench=. -benchmem ./…`                       | 前回結果と比較し、閾値超えで警告                     |
| **脆弱性スキャン**    | 既知脆弱性の混入防止        | `govulncheck ./…`, `gosec ./…`                         | 重大度高ならビルド失敗                          |
| **ライセンスチェック**  | OSS ライセンス違反の抑止    | `license-eye` など                                       | 非互換ライセンス検知でエラー                       |
| **ビルドマトリクス**   | マルチ OS/Go バージョン検証 | `matrix: [1.22, 1.23, tip] × [linux, windows, darwin]` | macOS や Windows 固有バグの早期発見            |
| **成果物・バッジ**    | 可視化と配布            | カバレッジ HTML、バイナリ圧縮                                      | アーティファクトとしてアップロード                    |

### Claude Code への具体的な依頼例

1. **CI 定義ファイル**
   *「`go-quality.yml` という Workflow を作り、上記ステージを逐次またはジョブ分割で実装してほしい。失敗条件とキャッシュ戦略も盛り込むこと。」*

2. **`golangci-lint` 設定**
   *「`staticcheck`, `gosimple`, `unused` など主要 Linters を有効化し、タイムアウトは 5 分、除外パターンも追記してほしい。」*

3. **Makefile**
   *「ローカル実行用に `make lint`, `make test`, `make sec` など CI と同一コマンドをラップしたターゲットを用意してほしい。」*

4. **Pull Request コメント Bot**
   *「CI 成果物のカバレッジ値や govulncheck の結果サマリを PR に自動コメントするステップを追加してほしい。」*

5. **バッジ**
   *「README にビルドステータス、カバレッジ、Go Report Card のバッジを付けるスクリプトも欲しい。」*

これらをまとめて依頼すれば、クオリティ検査に必要な仕組み一式を自動生成してくれるはずです。頑張ってください。





コンテナ化の目的は **ツール一式を“焼き込み済み”にして再利用し、CI／ローカル双方で同じ実行環境を得る** ことです。以下の流れで導入すると運用コストを最小化できます。

---

## 1. ベースイメージ設計

```Dockerfile
# -------------------- stage: build-tools --------------------
FROM golang:1.23.11-bookworm AS build-tools  # 最新セキュリティパッチ適用版 :contentReference[oaicite:0]{index=0}
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache \
    <<'EOS'
set -eu
# 実行時に必要なツールを固定バージョンで取得
go install mvdan.cc/gofumpt@v0.6.0
go install golang.org/x/tools/cmd/goimports@v0.20.0
go install honnef.co/go/tools/cmd/staticcheck@v0.5.5
go install github.com/golangci/golangci-lint/cmd/golangci-lint@v1.59.0
go install github.com/google/osv-scanner/cmd/osv-scanner@v1.7.0
go install golang.org/x/vuln/cmd/govulncheck@v1.1.1
go install github.com/securego/gosec/v2/cmd/gosec@v2.18.2
EOS

# -------------------- stage: runtime --------------------
FROM golang:1.23.11-bookworm AS runtime
# ツールバイナリだけコピーして極小化
COPY --from=build-tools /go/bin /usr/local/bin

# 共有キャッシュディレクトリを作り I/O を削減
ENV GOMODCACHE=/go/pkg/mod \
    GOCACHE=/go/.cache

WORKDIR /work
ENTRYPOINT ["bash","-c"]
CMD ["go version && echo 'Run make quality or go test …'"]
```

**ポイント**

| 項目                    | 説明                                        |
| --------------------- | ----------------------------------------- |
| **multi-stage**       | ツールのビルド層と実行層を分離し、ランタイム側を小さく保つ             |
| **バージョン固定**           | `go install pkg@ver` で将来の破壊的変更を防止         |
| **build cache mount** | `--mount=type=cache` により CI ランでの再ビルド時間を短縮 |
| **ENTRYPOINT**        | シェル経由にして Makefile 等で柔軟に呼び出せる              |

---

## 2. レジストリ公開とタグ戦略

1. **CI（GitHub Actions）で nightly ビルド → GHCR に push**
   `ghcr.io/yourorg/go-quality:1.23.11-20250711` のように *Go 版数 + ビルド日* でタグ。
2. **安定版** は `:latest` にリタグしておくとローカル開発者が常に同じ環境を pull 可能。
3. Go のマイナーアップデートが出たらイメージだけ更新し、CI ジョブは *書き換え無し* で即追従。

Docker Hub の公式 `golang:1.24-bookworm` は数週間ごとにマイナーリビルドされ、パッチ番号も追従しています（例: `1.24` は最新版） ([Docker Hub][1], [Go][2])。

---

## 3. CI での利用例（GitHub Actions）

```yaml
jobs:
  quality:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/yourorg/go-quality:1.23.11-20250711
      options: --user 1001  # ホスト UID に合わせる
    steps:
      - uses: actions/checkout@v4
      - name: Cache Go modules
        uses: actions/cache@v4
        with:
          path: |
            ~/.cache
            ${{ github.workspace }}/pkg/mod
          key: ${{ runner.os }}-go-${{ hashFiles('**/go.sum') }}
      - name: Run quality pipeline
        run: |
          make lint
          make test
          make sec
```

*`container:` キーを使えばホストのセットアップを一切触らずに済む* ため、Ansible や apt/yum の管理対象が丸ごと消えます。

---

## 4. ローカル開発者向け“dev container”

* **VS Code Dev Containers** や **GitHub Codespaces** を使う場合は `.devcontainer/devcontainer.json` で同じイメージを指定。
* これにより *CI と完全一致* の環境でコードを書けるので、「ローカルでは通るが CI で落ちる」問題が激減します。

---

## 5. 具体的な運用フロー

1. **`docker pull ghcr.io/yourorg/go-quality:latest`**
2. **`docker run --rm -v $(pwd):/work ghcr.io/yourorg/go-quality make lint`**
3. CI ジョブも上記イメージで実行（ジョブごとに `make` ターゲットを分割）
4. 定期（週次）でベースイメージを再ビルドし、脆弱性レポートを Slack／Teams へ自動通知

---

### まとめ

* **“ツール群を永続化したコンテナ”** を 1 つ用意し、CI とローカルで共通利用するのが最小コスト。
* multi-stage＋キャッシュでビルド時間・イメージサイズを抑制。
* バージョンは *Go 本体とツールをピン留め* し、イメージの更新だけで品質ワークフロー全体を保守可能。

これで毎回の Ansible インストール地獄から解放され、開発者も CI も “同一バイナリ” で品質検査を回せます。

[1]: https://hub.docker.com/_/golang?utm_source=chatgpt.com "golang - Official Image | Docker Hub"
[2]: https://go.dev/doc/devel/release?utm_source=chatgpt.com "Release History - The Go Programming Language"
