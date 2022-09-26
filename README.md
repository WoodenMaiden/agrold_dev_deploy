# Prerequisites

- A kubernetes cluster, some softwar can be installed to create lical lsuter such as [minikube](https://minikube.sigs.k8s.io/docs/start/) or [k3d](https://k3d.io/stable)
- bash
- curl
- sudo

# Setup Kube, Helm and this directory

First get a kube config file, and put it in a folder named kubeconfig.

```bash
#Let's assume we are using a k3d cluster
k3d kubeconfig write mycluster
mkdir kubeconfig
mv kubeconfig-mycluster.yaml kubeconfig/
```

Then run the script ``setup_kube.sh``, it is important to run this file in the context of your shell so you can have the variable ``KUBECONFIG`` available for your shell.

This script also installs kubectl and helm if you don't have them
```bash
. ./setup_kube.sh
#or
source ./setup_kube.sh
```

# Deploy

Execute the deploying script in the same terminal
```bash
./deploy_dev.sh
```