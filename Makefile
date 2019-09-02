SHELL := bash
SRC_DIR=$(shell pwd)
BUILD_DIR=$(SRC_DIR)/build

GO_DIR=$(BUILD_DIR)/go
GOPATH_DIR=$(BUILD_DIR)/gopath
K8SIO_DIR=$(GOPATH_DIR)/src/k8s.io
KUBERNETES_DIR=$(K8SIO_DIR)/kubernetes
GO_VERSION ?= 1.11.5
K8S_VERSION ?= 1.13
REPO_URL := https://github.com/kubernetes/kubernetes
PROXY_EXE := $(KUBERNETES_DIR)/_output/local/go/bin/kube-proxy
CONTAINER_DIR=$(BUILD_DIR)/container
IMAGE_MARKER=$(CONTAINER_DIR)/image-built
IMAGE_TAG ?= platform9/kube-proxy:$(K8S_VERSION)

$(BUILD_DIR):
	mkdir -p $@
	 
$(GOPATH_DIR):
	mkdir -p $@

$(CONTAINER_DIR):
	mkdir -p $@

$(GO_DIR): | $(BUILD_DIR)
	cd $(BUILD_DIR) && \
	wget -q https://dl.google.com/go/go$(GO_VERSION).linux-amd64.tar.gz && \
	tar xf go$(GO_VERSION).linux-amd64.tar.gz

$(K8SIO_DIR):
	mkdir -p $@

$(KUBERNETES_DIR): | $(K8SIO_DIR)
	cd $(K8SIO_DIR) && git clone --branch release-$(K8S_VERSION) --depth=1 $(REPO_URL)

k8s: | $(KUBERNETES_DIR)

go: | $(GO_DIR)

$(PROXY_EXE): | $(GOPATH_DIR) $(GO_DIR) $(KUBERNETES_DIR)
	cd $(KUBERNETES_DIR) && \
	find pkg/proxy -name *.go|xargs sed -i s/KUBE-/P9K8-/g && \
	GOPATH=$(GOPATH_DIR) PATH=$(GO_DIR)/bin:$(PATH) make WHAT=cmd/kube-proxy

exe: $(PROXY_EXE)

clean:
	rm -rf $(BUILD_DIR)


$(IMAGE_MARKER): $(PROXY_EXE) | $(CONTAINER_DIR)
	cp Dockerfile $(CONTAINER_DIR)
	cp $(PROXY_EXE) $(CONTAINER_DIR)
	docker build --tag $(IMAGE_TAG) $(CONTAINER_DIR)
	touch $@

image: $(IMAGE_MARKER)

image-clean:
	docker images|tail -n +2|grep platform9/kube-proxy|awk '{print $3}' | xargs docker rmi -f || true
	rm -f $(IMAGE_MARKER)
