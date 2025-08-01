# Check to see if we can use ash, in Alpine images, or default to BASH.
SHELL_PATH = /bin/ash
SHELL = $(if $(wildcard $(SHELL_PATH)),/bin/ash,/bin/bash)


# ==============================================================================
# Define dependencies

GOLANG          := golang:1.24
ALPINE          := alpine:3.22
KIND            := kindest/node:v1.33.1
POSTGRES        := postgres:17.5
GRAFANA         := grafana/grafana:11.6.0
PROMETHEUS      := prom/prometheus:v3.4.0
TEMPO           := grafana/tempo:2.7.0
LOKI            := grafana/loki:3.5.0
PROMTAIL        := grafana/promtail:3.5.0

KIND_CLUSTER    := ardan-starter-cluster
NAMESPACE       := sales-system
SALES_APP       := sales
AUTH_APP        := auth
BASE_IMAGE_NAME := localhost/ardanlabs
VERSION         := 0.0.1
SALES_IMAGE     := $(BASE_IMAGE_NAME)/$(SALES_APP):$(VERSION)
METRICS_IMAGE   := $(BASE_IMAGE_NAME)/metrics:$(VERSION)
AUTH_IMAGE      := $(BASE_IMAGE_NAME)/$(AUTH_APP):$(VERSION)


# ==============================================================================
# Install dependencies

dev-gotooling:
	go install github.com/divan/expvarmon@latest
	go install github.com/rakyll/hey@latest
	go install honnef.co/go/tools/cmd/staticcheck@latest
	go install golang.org/x/vuln/cmd/govulncheck@latest
	go install golang.org/x/tools/cmd/goimports@latest

dev-brew:
	brew update
	brew list kind || brew install kind
	brew list kubectl || brew install kubectl
	brew list kustomize || brew install kustomize
	brew list pgcli || brew install pgcli
	brew list watch || brew install watch

# dev-docker:
# 	docker pull $(GOLANG) & \
# 	docker pull $(ALPINE) & \
# 	docker pull $(KIND) & \
# 	docker pull $(POSTGRES) & \
# 	docker pull $(GRAFANA) & \
# 	docker pull $(PROMETHEUS) & \
# 	docker pull $(TEMPO) & \
# 	docker pull $(LOKI) & \
# 	docker pull $(PROMTAIL) & \
# 	wait;

dev-docker:
	docker pull --platform=linux/amd64 $(POSTGRES) & \
	docker pull --platform=linux/amd64 $(GRAFANA) & \
	docker pull --platform=linux/amd64 $(PROMETHEUS) & \
	docker pull --platform=linux/amd64 $(TEMPO) & \
	docker pull --platform=linux/amd64 $(LOKI) & \
	docker pull --platform=linux/amd64 $(PROMTAIL) & \
	wait;


run:
	go run apis/services/sales/main.go | go run apis/tooling/logfmt/main.go

help:
	go run apis/services/sales/main.go --help

version:
	go run apis/services/sales/main.go --version

tidy:
	go mod tidy
	go mod vendor

# ==============================================================================
# Running from within k8s/kind

# dev-up:
# 	kind create cluster \
# 		--image $(KIND) \
# 		--name $(KIND_CLUSTER) \
# 		--config zarf/k8s/dev/kind-config.yaml

# 	kubectl wait --timeout=120s --namespace=local-path-storage --for=condition=Available deployment/local-path-provisioner

# 	kind load docker-image $(POSTGRES) --name $(KIND_CLUSTER) & \
# 	kind load docker-image $(GRAFANA) --name $(KIND_CLUSTER) & \
# 	kind load docker-image $(PROMETHEUS) --name $(KIND_CLUSTER) & \
# 	kind load docker-image $(TEMPO) --name $(KIND_CLUSTER) & \
# 	kind load docker-image $(LOKI) --name $(KIND_CLUSTER) & \
# 	kind load docker-image $(PROMTAIL) --name $(KIND_CLUSTER) & \
# 	wait;

dev-up:
	kind create cluster \
		--image $(KIND) \
		--name $(KIND_CLUSTER) \
		--config zarf/k8s/dev/kind-config.yaml

	kubectl wait --timeout=120s --namespace=local-path-storage --for=condition=Available deployment/local-path-provisioner

	@for img in $(EXTERNAL_IMAGES); do \
		echo "Loading $$img into KIND cluster..."; \
		kind load docker-image $$img --name $(KIND_CLUSTER) || exit 1; \
	done


dev-down:
	kind delete cluster --name $(KIND_CLUSTER)

dev-status-all:
	kubectl get nodes -o wide
	kubectl get svc -o wide
	kubectl get pods -o wide --watch --all-namespaces

dev-status:
	watch -n 2 kubectl get pods -o wide --all-namespaces

# Building containers

build: sales

sales:
	docker build \
		-f zarf/docker/dockerfile.sales \
		-t $(SALES_IMAGE) \
		--build-arg BUILD_REF=$(VERSION) \
		--build-arg BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
		.

metrics:
	docker build \
		-f zarf/docker/dockerfile.metrics \
		-t $(METRICS_IMAGE) \
		--build-arg BUILD_REF=$(VERSION) \
		--build-arg BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
	

# ------------------------------------------------------------------------------

dev-load:
	kind load docker-image $(SALES_IMAGE) --name $(KIND_CLUSTER)

dev-apply:
	kustomize build zarf/k8s/dev/sales | kubectl apply -f -
	kubectl wait pods --namespace=$(NAMESPACE) --selector app=$(SALES_APP) --timeout=120s --for=condition=Ready

dev-restart:
	kubectl rollout restart deployment $(SALES_APP) --namespace=$(NAMESPACE)

dev-run: build dev-up dev-load dev-apply

dev-update: build dev-load dev-restart

dev-update-apply: build dev-load dev-apply

dev-logs:
	kubectl logs --namespace=$(NAMESPACE) -l app=$(SALES_APP) --all-containers=true -f --tail=100 --max-log-requests=6 | go run apis/tooling/logfmt/main.go -service=$(SALES_APP)

dev-logs-auth:
	kubectl logs --namespace=$(NAMESPACE) -l app=$(AUTH_APP) --all-containers=true -f --tail=100 | go run api/tooling/logfmt/main.go

dev-describe-deployment:
	kubectl describe deployment --namespace=$(NAMESPACE) $(SALES_APP)

dev-describe-sales:
	kubectl describe pod --namespace=$(NAMESPACE) -l app=$(SALES_APP)


# ==============================================================================
# Metrics and Tracing

metrics:
	expvarmon -ports="localhost:3010" -vars="build,requests,goroutines,errors,panics,mem:memstats.HeapAlloc,mem:memstats.HeapSys,mem:memstats.Sys"

metrics-view:
	expvarmon -ports="localhost:4020" -endpoint="/metrics" -vars="build,requests,goroutines,errors,panics,mem:memstats.HeapAlloc,mem:memstats.HeapSys,mem:memstats.Sys"

grafana:
	open http://localhost:3100/

statsviz:
	open http://localhost:3010/debug/statsviz
