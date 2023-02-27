provider "helm" {
  kubernetes {
    config_path = var.KUBECONFIG
  }
}

provider "kubernetes" {
  config_path = var.KUBECONFIG
}