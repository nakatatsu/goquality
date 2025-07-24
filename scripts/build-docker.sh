#!/usr/bin/env bash
set -euo pipefail

# ===== Config =====
OWNER=${OWNER:-nakatatsu}
REPO=${REPO:-goquality}
IMAGE="ghcr.io/${OWNER}/${REPO}"
DATE_TAG=$(date +%Y%m%d)
GH_USER=${GH_USER:-$OWNER}        # docker login 時のユーザー名
PLATFORM=${PLATFORM:-linux/amd64} # buildx を使うならここを変更

PUSH=false
LOGIN=false
TAG="$DATE_TAG"
LOCAL_TAG="${REPO}:latest"        # ローカル用（任意）

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Options:
  --push            生成したタグを ghcr.io に push します
  --login           実行前に ghcr.io へ docker login を行います（CR_PAT 必須）
  --tag <tag>       日付タグの代わりに指定タグを使用します（デフォルト: ${DATE_TAG}）
  --owner <name>    ghcr.io/<owner>/<repo> の owner（デフォルト: ${OWNER}）
  --repo <name>     ghcr.io/<owner>/<repo> の repo（デフォルト: ${REPO}）
  --platform <p>    docker buildx の --platform 値（デフォルト: ${PLATFORM}）
  --help            このヘルプを表示

Env:
  DOCKER            使う docker コマンド（例: "sudo docker"）
  CR_PAT            ghcr 用 PAT。--login 指定時に使用
  GH_USER           docker login のユーザー名（デフォルト: OWNER と同じ）
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --push) PUSH=true; shift ;;
    --login) LOGIN=true; shift ;;
    --tag) TAG="$2"; shift 2 ;;
    --owner) OWNER="$2"; IMAGE="ghcr.io/${OWNER}/${REPO}"; shift 2 ;;
    --repo) REPO="$2"; IMAGE="ghcr.io/${OWNER}/${REPO}"; shift 2 ;;
    --platform) PLATFORM="$2"; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

if $LOGIN; then
  if [[ -z "${CR_PAT:-}" ]]; then
    echo "ERROR: --login が指定されましたが CR_PAT がありません" >&2
    exit 1
  fi
  echo "$CR_PAT" | docker login ghcr.io -u "${GH_USER}" --password-stdin
fi

echo "==> Building image"
docker build \
  -t "${IMAGE}:latest" \
  -t "${IMAGE}:${TAG}" \
  -t "${LOCAL_TAG}" \
  .

echo "==> Verifying image"
docker image inspect "${IMAGE}:${TAG}" >/dev/null

if [ -n "${CR_PAT:-}" ]; then
    echo "$CR_PAT" | sudo docker login ghcr.io -u nakatatsu --password-stdin >/dev/null
fi
echo "==> Pushing images to ghcr.io"
docker push "${IMAGE}:${TAG}"
docker push "${IMAGE}:latest"
echo "==> Done"
