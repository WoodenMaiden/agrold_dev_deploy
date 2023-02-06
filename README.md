# Prerequisites

- a kubernetes cluster, some software can be installed to create a local cluster such as [minikube](https://minikube.sigs.k8s.io/docs/start/), [kind](https://kind.sigs.k8s.io/docs/user/quick-start/) or [k3d](https://k3d.io/stable)
- bash
- curl
- sudo
- helm
- terraform
- terraform-docs (optionnal)

# Setup

First get a kube config file and keep his location in mind for the next step.

```bash
#Let's assume we are using a k3d cluster
k3d kubeconfig write mycluster -o /somepath/filename.yaml
```

Then write the ``terraform.tfvars`` file and fill it with the variables you wish to change in ``./terraform/local/variables.tf`` 

> ‼️ The following variables are mandatory:
> - KUBECONFIG (path to config file you got earlier) 

> 💡 Otherwise you can generate said file with the command ``terraform-docs tfvars hcl ./terraform/local/variables.tf > ./terraform/local/terraform.tfvars``

# Deploy

```bash
cd terraform/local/
terraform init
terraform apply -auto-approve
```

# Undeploy

```bash
# in terraform/local/

cd terraform/local/
terraform init
terraform apply -auto-approve
```