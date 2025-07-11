.PHONY: all help docker-build docker-quality docker-fmt docker-lint docker-test docker-coverage docker-sec docker-run

# Variables
DOCKER_IMAGE ?= go-quality
DOCKER_RUN := docker run --rm -v $(PWD):/work $(DOCKER_IMAGE)

# Default target
all: docker-quality

# Help target
help:
	@echo "Go Quality Check - Docker専用Makefile"
	@echo ""
	@echo "使い方:"
	@echo "  make <target>"
	@echo ""
	@echo "ターゲット:"
	@echo "  all              - docker-qualityを実行（デフォルト）"
	@echo "  help             - このヘルプメッセージを表示"
	@echo "  docker-build     - Dockerイメージをビルド"
	@echo "  docker-quality   - 全ての品質チェックを実行"
	@echo "  docker-fmt       - コードフォーマット"
	@echo "  docker-lint      - リンターを実行"
	@echo "  docker-test      - テストを実行"
	@echo "  docker-coverage  - カバレッジレポートを生成"
	@echo "  docker-sec       - セキュリティスキャンを実行"
	@echo "  docker-run       - 任意のコマンドをDocker内で実行"
	@echo ""
	@echo "例:"
	@echo "  make docker-build    # イメージをビルド"
	@echo "  make docker-quality  # 全チェックを実行"
	@echo "  make docker-run CMD='go mod tidy'  # 任意のコマンド実行"

# Build Docker image
docker-build:
	@echo "==> Dockerイメージをビルド中..."
	@docker build -t $(DOCKER_IMAGE) .
	@echo "✓ Dockerイメージのビルドが完了: $(DOCKER_IMAGE)"

# Run all quality checks
docker-quality: docker-build
	@echo "==> Docker内で全品質チェックを実行..."
	@$(DOCKER_RUN) make quality

# Format code
docker-fmt: docker-build
	@echo "==> Docker内でコードフォーマットを実行..."
	@$(DOCKER_RUN) make fmt

# Run linters
docker-lint: docker-build
	@echo "==> Docker内でリンターを実行..."
	@$(DOCKER_RUN) make lint

# Run tests
docker-test: docker-build
	@echo "==> Docker内でテストを実行..."
	@$(DOCKER_RUN) make test

# Run coverage
docker-coverage: docker-build
	@echo "==> Docker内でカバレッジ測定を実行..."
	@$(DOCKER_RUN) make coverage

# Run security scans
docker-sec: docker-build
	@echo "==> Docker内でセキュリティスキャンを実行..."
	@$(DOCKER_RUN) make sec

# Run arbitrary command in Docker
docker-run: docker-build
	@if [ -z "$(CMD)" ]; then \
		echo "使い方: make docker-run CMD='<コマンド>'"; \
		echo "例: make docker-run CMD='go mod tidy'"; \
		exit 1; \
	fi
	@echo "==> Docker内で実行: $(CMD)"
	@$(DOCKER_RUN) $(CMD)

# 以下はDocker内部で使用されるターゲット（直接実行不可）
# =====================================================

.PHONY: fmt lint vet test coverage bench sec quality clean

# Variables for internal use
GO_FILES := $(shell find . -type f -name '*.go' -not -path "./vendor/*")
COVERAGE_THRESHOLD := 80

# Format code
fmt:
	@echo "==> コードフォーマット中..."
	@gofumpt -l -w $(GO_FILES)
	@goimports -l -w $(GO_FILES)
	@echo "✓ コードフォーマット完了"

# Run linters
lint: vet
	@echo "==> staticcheck実行中..."
	@staticcheck ./...
	@echo "==> golangci-lint実行中..."
	@golangci-lint run --timeout=5m
	@echo "✓ リンターチェック完了"

# Run go vet
vet:
	@echo "==> go vet実行中..."
	@go vet ./...
	@echo "✓ go vet完了"

# Run tests
test:
	@echo "==> テスト実行中..."
	@go test -race -short ./...
	@echo "✓ テスト完了"

# Run tests with coverage
coverage:
	@echo "==> カバレッジ測定中..."
	@go test -race -coverprofile=coverage.out -covermode=atomic ./...
	@go tool cover -html=coverage.out -o coverage.html
	@echo "==> カバレッジレポート:"
	@go tool cover -func=coverage.out
	@echo ""
	@COVERAGE=$$(go tool cover -func=coverage.out | grep total | awk '{print $$3}' | sed 's/%//'); \
	echo "総カバレッジ: $$COVERAGE%"; \
	if [ $$(echo "$$COVERAGE < $(COVERAGE_THRESHOLD)" | bc) -eq 1 ]; then \
		echo "✗ カバレッジが$(COVERAGE_THRESHOLD)%未満です"; \
		exit 1; \
	else \
		echo "✓ カバレッジ基準を満たしています"; \
	fi

# Run benchmarks
bench:
	@echo "==> ベンチマーク実行中..."
	@go test -bench=. -benchmem -benchtime=10x ./... | tee benchmark.txt
	@echo "✓ ベンチマーク完了"

# Run security scans
sec:
	@echo "==> セキュリティスキャン実行中..."
	@echo "==> govulncheck実行中..."
	@govulncheck ./... || true
	@echo "==> gosec実行中..."
	@gosec -fmt=text ./... || true
	@echo "==> OSV Scanner実行中..."
	@osv-scanner --format table . || true
	@echo "✓ セキュリティスキャン完了"

# Run all quality checks
quality: fmt lint test coverage sec
	@echo ""
	@echo "✓ 全ての品質チェックが完了しました！"

# Clean build artifacts
clean:
	@echo "==> クリーンアップ中..."
	@rm -f coverage.out coverage.html benchmark.txt
	@rm -f gosec-results.sarif osv-results.sarif
	@go clean -cache -testcache
	@echo "✓ クリーンアップ完了"