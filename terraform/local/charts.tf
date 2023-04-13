# ============ #
#     RFR      #
# ============ #

resource "helm_release" "rf" {
  name      = "rf"
  namespace = kubernetes_namespace.namespace.metadata[0].name

  chart  = "../../charts/rf"
  values = [file("../../charts/rf/values.yaml")]

  set {
    name  = "RFRApiUrl"
    value = "http://${join(".", ["rfapi", var.base_domain])}"
  }

  set {
    name  = "ingress.hosts[0].host"
    value = join(".", ["rf", var.base_domain])
  }

  depends_on = [
    kubernetes_namespace.namespace
  ]
}

resource "helm_release" "rfapi" {
  name      = "rfapi"
  namespace = kubernetes_namespace.namespace.metadata[0].name

  chart  = "../../charts/rfapi"
  values = [file("../../charts/rfapi/values.yaml")]

  set_sensitive {
    name  = "args"
    value = "{-p, 80, --loglevel, DEBUG}"
  }

  set {
    name  = "sparqlAddress"
    value = var.sparql_endpoint
  }

  set {
    name  = "ingress.hosts[0].host"
    value = join(".", ["rfapi", var.base_domain])
  }

  depends_on = [
    kubernetes_namespace.namespace
  ]
}



# =============== #
#      AgroLD     #
# =============== #

resource "helm_release" "tomcat" {
  name      = "tomcatagrold"
  namespace = kubernetes_namespace.namespace.metadata[0].name

  chart  = "../../charts/tomcat"
  values = [file("../../charts/tomcat/values.yaml")]

  set {
    name  = "ingress.hostname"
    value = var.base_domain
  }

  set {
    name  = "sparqlAddress"
    value = var.sparql_endpoint
  }

  set_sensitive {
    name  = "catalinaOpts"
    value = <<EOL
-Dagrold.db_connection_url='mysql.${kubernetes_namespace.namespace.metadata[0].name}.svc.cluster.local/agrolddb?useSSL=false' -Dagrold.db_username='${var.agrold_db_username}' -Dagrold.db_password='${var.agrold_db_password}' -Dagrold.name='${var.agrold_name}' -Dagrold.description='${var.agrold_description}' -Dagrold.baseurl='http://${var.base_domain}/' -Dagrold.sparql_endpoint='${var.sparql_endpoint}'
EOL
  }

  depends_on = [
    kubernetes_namespace.namespace
  ]
}

resource "kubernetes_config_map" "sparql-init" {
  metadata {
    name      = "sparql-init"
    namespace = kubernetes_namespace.namespace.metadata[0].name
  }

  data = {
    for f in fileset("${path.module}/../../volumes/sparql-initdb", "*"):
    f => file("${path.module}/../../volumes/sparql-initdb/${f}")
  }
}

resource "helm_release" "sparql" {
  name      = "sparql"
  namespace = kubernetes_namespace.namespace.metadata[0].name

  chart  = "../../charts/sparql"
  values = [file("../../charts/sparql/values.yaml")]

  depends_on = [
    kubernetes_namespace.namespace,
    kubernetes_config_map.sparql-init
  ]
}


resource "helm_release" "db" {

  name      = "databaseagrold"
  namespace = kubernetes_namespace.namespace.metadata[0].name

  chart  = "../../charts/agroldmysql"
  values = [file("../../charts/agroldmysql/values.yaml")]

  set_sensitive {
    name  = "auth.username"
    value = var.agrold_db_username
  }

  set_sensitive {
    name  = "auth.password"
    value = var.agrold_db_password
  }

  depends_on = [
    kubernetes_namespace.namespace
  ]
}

# ============= #
#      Misc     #
# ============= #

resource "helm_release" "kubeview" {
  name      = "kubeview"
  namespace = kubernetes_namespace.namespace.metadata[0].name

  chart  = "../../charts/kubeview"
  values = [file("../../charts/kubeview/values.yaml")]

  set {
    name  = "ingress.hosts[0].host"
    value = join(".", ["viz", var.base_domain])
  }

  depends_on = [
    kubernetes_namespace.namespace
  ]
}