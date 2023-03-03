# Prerequisites

- a kubernetes cluster, some software can be installed to create a local cluster such as [minikube](https://minikube.sigs.k8s.io/docs/start/), [kind](https://kind.sigs.k8s.io/docs/user/quick-start/) or [k3d](https://k3d.io/stable)
- bash
- helm
- terraform
- terraform-docs (optionnal)

# Setup

First get a kube config file and keep his location in mind for the next step.

```bash
#Let's assume we are using a k3d cluster
k3d kubeconfig write mycluster -o /somepath/filename.yaml
```

Feel free to set it's path as ``KUBECONFIG`` env variable so you can use kubectl. 

Then create the ``terraform.tfvars`` file and fill it with the variables you wish to change in ``./terraform/local/variables.tf`` 

> ‼️ The following tf variables are mandatory:
> - KUBECONFIG (path to config file you got earlier) 

> 💡 Otherwise you can generate said file with the command ``terraform-docs tfvars hcl ./terraform/local > ./terraform/local/terraform.tfvars``

# Deploy

```bash
cd terraform/local/
terraform init
terraform apply -auto-approve
```

## Access the app

AgroLD uses DNS redirection meaning that your request will be redirected by the ingress to the correct server according to the provided sub-domain name given.

![FQDN breakdown](https://kinsta.com/wp-content/uploads/2022/07/structure-of-url.png)

![K8S ingresses](https://miro.medium.com/max/1400/1*KIVa4hUVZxg-8Ncabo8pdg.png)

Here are the domain redirection provided by the ingress: 

* **\<basedomain\>**: AgroLD
* **rf.\<basedomain\>**: Relfinder Reformed's frontend
* **api.\<basedomain\>**: Relfinder Reformed's api (might be changed)
* **viz.\<basedomain\>**: Kubeview to view the kubernetes cluster

By default, the _127.0.0.1.sslip.io_ base domain is used. The DNS service [sslip.io](https://sslip.io) returns the ip adress you prepend to it, its useful to avoid having to configure a local dns server for development. 

# Undeploy

```bash
# in terraform/local/

cd terraform/local/
terraform init
terraform apply -auto-approve
```