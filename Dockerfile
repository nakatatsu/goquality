# Go Quality Tools Devcontainer
# Registry: ghcr.io/nakatatsu/goquality
#
FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

# Go 1.24をインストール
RUN curl -sSL https://go.dev/dl/go1.24.5.linux-amd64.tar.gz | tar -C /usr/local -xz

# Go環境変数設定
ENV PATH="/usr/local/go/bin:${PATH}" \
    GOPATH="/go" \
    GOMODCACHE="/go/pkg/mod" \
    GOCACHE="/go/.cache"

# 必要なシステムパッケージをインストール
RUN apt-get update && apt-get install -y \
    bc \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Goツールをインストール
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache \
    <<'EOS'
set -eu
go install mvdan.cc/gofumpt@v0.8.0
go install golang.org/x/tools/cmd/goimports@v0.35.0
go install honnef.co/go/tools/cmd/staticcheck@v0.6.1
go install github.com/golangci/golangci-lint/cmd/golangci-lint@v2.3.0
go install github.com/google/osv-scanner/cmd/osv-scanner@v2.1.0
go install golang.org/x/vuln/cmd/govulncheck@v1.1.4
go install github.com/securego/gosec/v2/cmd/gosec@v2.22.7
go install github.com/yahoojapan/lcom4go/cmd/lcom4@v0.0.3
EOS

# ツールをPATHに追加
ENV PATH="/go/bin:${PATH}"

# スクリプトをコピー
COPY scripts/go-quality-check.sh /usr/local/bin/go-quality-check
RUN chmod +x /usr/local/bin/go-quality-check

WORKDIR /workspaces

# Devcontainer用: コンテナを起動したままにする
# docker-compose.ymlのcommandで上書きされるが、デフォルトを設定
CMD ["sleep", "infinity"]