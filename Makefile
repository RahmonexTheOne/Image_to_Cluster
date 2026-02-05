# Variables
CLUSTER_NAME=lab
IMAGE_NAME=my-custom-nginx
TAG=latest

.PHONY: setup build deploy clean all help

all: setup build deploy

setup:
	@echo "--------------------------------------------------"
	@echo "PREPARATION : Installation des outils et cluster"
	@echo "--------------------------------------------------"
	@sudo rm -f /etc/apt/sources.list.d/yarn.list
	@sudo apt-get update -qq && sudo apt-get install packer ansible -y -qq
	@sudo /usr/bin/python3 -m pip install kubernetes --break-system-packages --quiet
	@k3d cluster get $(CLUSTER_NAME) >/dev/null 2>&1 || k3d cluster create $(CLUSTER_NAME) --servers 1 --agents 2

build:
	@echo "--------------------------------------------------"
	@echo "BUILD : Creation de l'image avec Packer"
	@echo "--------------------------------------------------"
	@packer init image.pkr.hcl
	@packer build -force image.pkr.hcl
	@k3d image import $(IMAGE_NAME):$(TAG) -c $(CLUSTER_NAME)

deploy:
	@echo "--------------------------------------------------"
	@echo "DEPLOY : Orchestration Ansible et Exposition"
	@echo "--------------------------------------------------"
	@ansible-playbook deploy.yml
	@kubectl rollout restart deployment custom-nginx
	@echo "Attente du redemarrage des pods..."
	@kubectl rollout status deployment custom-nginx
	@killall kubectl 2>/dev/null || true
	@kubectl port-forward svc/custom-nginx-service 8081:80 >/dev/null 2>&1 &
	@echo "--------------------------------------------------"
	@echo "TERMINE : Application disponible sur le port 8081"
	@echo "--------------------------------------------------"

clean:
	@echo "--------------------------------------------------"
	@echo "CLEAN : Suppression du cluster"
	@echo "--------------------------------------------------"
	@k3d cluster delete $(CLUSTER_NAME)