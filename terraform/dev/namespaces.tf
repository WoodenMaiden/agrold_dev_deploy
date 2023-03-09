resource "kubernetes_namespace" "metrics" {
  metadata {
    name = "metrics"
  }
}

resource "kubernetes_namespace" "namespace" {
  metadata {
    name = var.namespace
  }
}