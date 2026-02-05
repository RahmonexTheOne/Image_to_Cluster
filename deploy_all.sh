#!/bin/bash

echo "----------------------------------------"
echo "Démarrage du déploiement automatique..."
echo "----------------------------------------"

# 1. Nettoyage et installation des dépendances
echo "----------------------------------------"
echo "Installation des outils..."
echo "----------------------------------------"

sudo rm -f /etc/apt/sources.list.d/yarn.list
sudo apt-get update && sudo apt-get install packer ansible -y
sudo /usr/bin/python3 -m pip install kubernetes --break-system-packages --quiet

# 2. Vérification du cluster
if ! k3d cluster get lab >/dev/null 2>&1; then
    echo "----------------------------------------"
    echo "Création du cluster K3d..."
    echo "----------------------------------------"
    k3d cluster create lab --servers 1 --agents 2
fi

# 3. Build et Import
echo "----------------------------------------"
echo "Build de l'image avec Packer..."
echo "----------------------------------------"

packer init image.pkr.hcl
packer build -force image.pkr.hcl
k3d image import my-custom-nginx:latest -c lab

# 4. Déploiement Ansible
echo "----------------------------------------"
echo "Déploiement sur Kubernetes via Ansible..."
echo "----------------------------------------"
ansible-playbook deploy.yml

# 5. Refresh
echo "----------------------------------------"
echo "Refresh des pods..."
echo "----------------------------------------"

kubectl rollout restart deployment custom-nginx

# Tuer tout ancien tunnel
killall kubectl 2>/dev/null || true

echo "----------------------------------------"
echo "Activation du tunnel d'accès (Port 8081)..."
echo "----------------------------------------"
# On lance le forward et on attend 5 secondes qu'il s'initialise
kubectl port-forward svc/custom-nginx-service 8081:80 >/tmp/k8s_port_forward.log 2>&1 &
sleep 5 

# Tentative d'exposition automatique
CODESPACE_NAME=$(hostname)
gh codespace ports visibility 8081:public -c $CODESPACE_NAME 2>/dev/null || echo "⚠️ Note : Visibilité à régler manuellement dans l'onglet PORTS."

PREVIEW_URL="https://${CODESPACE_NAME}-8081.app.github.dev"

echo "--------------------------------------------------"
echo "✅ DEPLOYMENT SUCCESSFUL !"
echo "📍 Votre application est disponible ici :"
echo -e "\033[1;34m${PREVIEW_URL}\033[0m"
echo "--------------------------------------------------"