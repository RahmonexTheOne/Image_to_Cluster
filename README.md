# Atelier : Industrialisation du cycle de vie applicatif

[![Packer](https://img.shields.io/badge/Packer-1.15.0-blue?logo=packer&logoColor=white)](https://www.packer.io/)
[![Ansible](https://img.shields.io/badge/Ansible-9.2.0-red?logo=ansible&logoColor=white)](https://www.ansible.com/)
[![Kubernetes](https://img.shields.io/badge/K3d-v5.6.3-blue?logo=kubernetes&logoColor=white)](https://k3d.io/)
[![Status](https://img.shields.io/badge/Build-Success-green)](#)

## Description du projet
Ce projet a pour objectif de mettre en place une chaîne de déploiement automatisée permettant de passer d'un artefact applicatif brut à un service orchestré en haute disponibilité. L'approche repose sur le concept d'infrastructure immuable : chaque modification de l'application (ici une page Nginx personnalisée) entraîne la reconstruction complète d'une image Docker via Packer, son importation dans un cluster Kubernetes léger (K3d) et son déploiement final par Ansible.

---

## Architecture technique

Le workflow est divisé en trois segments logiques intégrés dans un environnement reproductible GitHub Codespaces :

1.  **Build (Packer)** : Construction d'une image Docker basée sur l'image officielle Nginx. Le provisionnement consiste à injecter de manière statique le fichier `index.html` dans les répertoires du serveur web au sein de l'image pour créer un artefact prêt à l'emploi.
2.  **Orchestration (Ansible)** : Utilisation de playbooks pour déclarer l'état souhaité de l'infrastructure Kubernetes. Ansible pilote la création du Deployment (stratégie de réplication à 2 pods) et du Service (exposition réseau via NodePort).
3.  **Runtime (K3d/K8s)** : Plateforme d'exécution utilisant K3s pour simuler un environnement de production multi-nœuds comprenant un nœud maître (server) et deux nœuds esclaves (agents).

---

## Dépendances et prérequis

Le projet est conçu pour s'exécuter sur un environnement Linux (Ubuntu 24.04). Les composants suivants sont installés et configurés automatiquement :

* **Packer** : Moteur de création d'images de conteneurs.
* **Ansible** : Outil d'automatisation des configurations et déploiements.
* **K3d** : Wrapper Docker pour la gestion de clusters K3s.
* **Python 3 & SDK Kubernetes** : Nécessaire pour l'interaction entre Ansible et l'API Kubernetes.

*Note : Une gestion spécifique des environnements Python (PEP 668) est incluse pour permettre l'installation des dépendances sur l'interpréteur système via le flag `--break-system-packages`.*

---

## Automatisation via Makefile

Pour garantir la reproductibilité, un `Makefile` centralise l'ensemble des commandes. Ce choix permet d'abstraire la complexité des scripts sous-jacents.

### Installation complète
Pour exécuter l'intégralité du cycle (provisionnement, construction, déploiement), utilisez la commande suivante :

```bash
make all
```

### Détail des cibles disponibles
* **make setup** : Nettoie les dépôts APT, installe les binaires Packer/Ansible et initialise le cluster K3d.
* **make build** : Initialise Packer, construit l'image personnalisée et l'importe dans les nœuds du cluster.
* **make deploy** : Exécute le playbook Ansible, déclenche un Rollout des pods et active le tunnel Port-forwarding.
* **make clean** : Supprime le cluster Kubernetes et nettoie les ressources temporaires.

---

## Accès à l'application

Une fois le déploiement terminé, l'application est accessible via un tunnel sur le port **8081**.

1.  Vérifiez l'activation du tunnel dans l'onglet **PORTS** de GitHub Codespaces.
2.  Si le port n'est pas détecté, ajoutez manuellement le transfert du port 8081.
3.  L'application est servie via l'URL de preview générée par l'environnement de développement.

---

## Choix de conception

* **Immuabilité** : L'utilisation de Packer garantit que l'image est scellée après construction, éliminant les dérives de configuration entre les environnements.
* **Idempotence** : Les scripts et playbooks sont conçus pour être relancés plusieurs fois sans provoquer d'erreurs, vérifiant l'état existant avant toute action.
* **Isolation** : L'importation manuelle de l'image dans K3d permet de travailler sans registre Docker externe, optimisant les temps de déploiement en environnement de développement.

---
*Projet réalisé dans le cadre de l'atelier Image to Cluster - 2026*