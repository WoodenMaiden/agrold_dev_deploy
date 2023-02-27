# Using Terraform

## What is terraform (of 'tf 'for short)?

Terraform is a tool of 'infrastructure as code' created by Hashicorp. 
As it says, terraform will allow you to declare a whole IT achitecture using code in ``.tf`` files. This has many advantages:

- **Architecture versionning**: You can use versionning for your APIs and other apps, why not your architecture? 
- **Variables**:  Since you architecture is code, you can inject variables to adapt to whatever need you have without spending hours into your configuration files.
- ⚙️ **Automated Set up, updates and destroying**: Since tf's code is predictable one command is what you need to manipulate your architecture: a simple ``terraform apply`` gets you started.

## How does that work? 🤔

### Modules

In a nutshell, tf modules (your directory) contains ``.tf`` files that may contain different components of your architectures. 

- **Providers**: These are configurable plugins that allows you to use an API with tf, for example kubernetes and AWS have providers. These providers are community made and available with the [Terraform Registry](https://registry.terraform.io/)
- **Ressources**: Provided by a provider, ressources are objects that your architecure might use, such as a kubernetes pod for example. 
- **Variables**

### Set up a module

When you created your ``.tf`` files, you have to install providers from the registry (here installed providers are in the ``providers.tf`` file).

```bash
cd mymodule
terraform init
```

After the command is finished you shall see a **\.terraform.lock.hcl** file. From now You are free to go! 

```bash
terraform apply #to set up/update your infrastucture
terraform destroy #to put down your infrastucture
```

**HOWEVER**! Besides said file, you will see files you **SHALL NEVER** commit & push (put these in a .gitignore).

* ``*.tfstate*`` files contains **EVERYTHING**: ressources, variables used etc... This file is used by tf to manipulate the architecture and shall only be used by it.
* The ``.terraform`` directory contains binaries of your providers like a node_modules would do. commiting this is a waste of time (and disk space)
* When using variables you might be creating a ``terraform.tfvars`` to put variables and their values into (cf. the README in parent direxctory).  Passwords, SSH keys... There are many reasons you wouldn't like this to leak.

# Terraform in AgroLD

## Modules

Create a module for each environment you want to support (local, production etc..)

Here is the architecture of a module: 
```bash
myenv
|- charts.tf # Here goes Helm charts
|- namespaces.tf # Here goes whatever namespace you might be using (eg, kubernetes)
|- providers.tf # Providers configuration
|- terraform.tf # Terraform configuration
|- variables.tf # Variables declaration
```

## "Okay nice but what about variables?"
> I want to add something to the conf, where do I put it? Directly in helm charts? in `variables.tf` ? 

The rule is simple: 

>If this is something that is confidential (password), or something that might change (IP, hostname...), put it in `variables.tf` and use the [`set`](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release#set) argument of the helm provider to override chart's value.
>Else just write in in the chart directly

Of course if there is any problem feel free to contact me at yann.pomie@ird.fr