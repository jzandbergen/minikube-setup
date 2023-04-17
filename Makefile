MINIKUBE_DRIVER := kvm
MINIKUBE_K8S_VERSION := latest
MINIKUBE_STATIC_IP := 192.168.13.37


KUBECTL := minikube kubectl --

TEMP_DIR := $(shell mktemp -d)
PLATFORM := $(shell uname -s | tr "A-Z" "a-z")
ARCH := amd64

.PHONY: all
.PHONY: cluster-up
.PHONY: cluster-destroy
.PHONY: install-minikube
.PHONY: help

help:
	@echo "make all"
	@echo "========"
	@echo "- install minikube"
	@echo "- create minikube cluster"
	@echo ""	
	@echo "make install-minikube"
	@echo "====================="
	@echo "- install minikube"
	@echo ""	
	@echo "make cluster-up"
	@echo "===================="
	@echo "- Create minikube cluster"
	@echo ""	
	@echo "make cluster-destroy"
	@echo "===================="
	@echo "- destroy cluster instance"
	@echo ""	

all: install-minikube cluster-up argocd-bootstrap argocd-up
all-no-download: cluster-up argocd-bootstrap argocd-up

cluster-up:
	### Create Minikube Cluster
	minikube start \
		--cpus 4 \
		--memory 4g \
		--driver "$(MINIKUBE_DRIVER)" \
		--kubernetes-version "$(MINIKUBE_K8S_VERSION)" \
		--static-ip "$(MINIKUBE_STATIC_IP)"
	
	### Make sure we are in the proper context.
	$(KUBECTL) config use-context minikube

argocd-bootstrap:
	### Make sure we are in the proper context.
	$(KUBECTL) config use-context minikube

	### Deploy ArgoCD - (CRD's)
	-$(KUBECTL) create namespace argocd
	# ArgoCD is done twice, this first run is to first deploy the CRD's.
	-$(KUBECTL) -n argocd apply -k ./bootstrap/argocd

	### Required for kubernetes to settle when deploying the CRD's.
	#   if this is omitted argocd will fail to deploy because the appset
	#   CRD's will not be found.
	sleep 1

argocd-up:
	### Make sure we are in the proper context.
	$(KUBECTL) config use-context minikube

	### Deploy our actual ArgoCD
	$(KUBECTL) -n argocd apply -k ./appsets/baseline/argocd
	

	@echo ""	
	@echo -------------------------------
	@echo "Wait a few moments for ArgoCD to come up and retrieve the"
	@echo "admin credentials with:"
	@echo ""
	@echo "kubectl get secret argocd-initial-admin-secret -n argocd -o json | jq '.data.password | @base64d'"
	@echo ""
	@echo "When you have obtained the admin password, open a port-forward to"
	@echo "the ArgoCD server. with:"
	@echo ""
	@echo "kubectl -n argocd port-forward argocd-server-<id> 28080:8080"
	@echo -------------------------------
	@echo ""	

cluster-destroy:
	minikube delete --all --purge
	
install-minikube:
	curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
	sudo install minikube-linux-amd64 /usr/local/bin/minikube
	rm -fv minikube-linux-amd64
