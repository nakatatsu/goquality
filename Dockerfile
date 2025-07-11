# Go Quality Tools Docker Image
# Registry: ghcr.io/nakatatsu/goquality
#
# -------------------- stage: build-tools --------------------
FROM golang:1.24-bookworm AS build-tools
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache \
    <<'EOS'
set -eu
# 実行時に必要なツールを固定バージョンで取得
go install mvdan.cc/gofumpt@v0.6.0
go install golang.org/x/tools/cmd/goimports@v0.20.0
go install honnef.co/go/tools/cmd/staticcheck@latest
go install github.com/golangci/golangci-lint/cmd/golangci-lint@v1.64.3
go install github.com/google/osv-scanner/cmd/osv-scanner@v1.7.0
go install golang.org/x/vuln/cmd/govulncheck@v1.1.1
go install github.com/securego/gosec/v2/cmd/gosec@v2.22.5
EOS

# -------------------- stage: runtime --------------------
FROM golang:1.24-bookworm AS runtime
# 必要なシステムパッケージをインストール
RUN apt-get update && apt-get install -y bc && rm -rf /var/lib/apt/lists/*
# ツールバイナリだけコピーして極小化
COPY --from=build-tools /go/bin /usr/local/bin

# スクリプトをコピー
COPY scripts/go-quality-check.sh /usr/local/bin/go-quality-check
RUN chmod +x /usr/local/bin/go-quality-check

# 共有キャッシュディレクトリを作り I/O を削減
ENV GOMODCACHE=/go/pkg/mod \
    GOCACHE=/go/.cache

WORKDIR /work
ENTRYPOINT ["bash","-c"]
CMD ["go version && echo 'Go Quality Tools - Run go-quality-check for full quality check'"]
