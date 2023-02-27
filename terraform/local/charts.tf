# ============ #
#     RFR      #
# ============ #

resource "helm_release" "rfrfrontend" {
  name      = "rfrfrontend"
  namespace = kubernetes_namespace.namespace.metadata[0].name

  chart  = "../../front"
  values = ["${file("../../front/values.yaml")}"]

  set {
    name  = "apiUrl"
    value = var.sparql_endpoint
  }

  set {
    name  = "ingress.hosts[0].domain"
    value = var.basedomain
  }

  depends_on = [
    kubernetes_namespace.namespace
  ]
}

resource "helm_release" "rfrapi" {
  name      = "rfrapi"
  namespace = kubernetes_namespace.namespace.metadata[0].name

  chart  = "../../api"
  values = ["${file("../../api/values.yaml")}"]

  set {
    name  = "args"
    value = "{-p, 80, --loglevel, DEBUG}"
  }

  set {
    name  = "ingress.hosts[0].domain"
    value = var.basedomain
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

  chart  = "../../tomcat"
  values = ["${file("../../tomcat/values.yaml")}"]

  set {
    name  = "ingress.hostname"
    value = var.basedomain
  }

  set {
    name  = "sparqlAddress"
    value = var.AGROLD_SPARQL_ENDPOINT
  }

  set {
    name  = "catalinaOpts"
    value = <<EOL
-Dagrold.db_connection_url='mysql.${kubernetes_namespace.namespace.metadata[0].name}.svc.cluster.local/agrolddb?useSSL=false' -Dagrold.db_username='${var.AGROLD_DB_USERNAME}' -Dagrold.db_password='${var.AGROLD_DB_PASSWORD}' -Dagrold.name='${var.AGROLD_NAME}' -Dagrold.description='${var.AGROLD_DESCRIPTION}' -Dagrold.baseurl='${var.AGROLD_BASEURL}' -Dagrold.sparql_endpoint='${var.AGROLD_SPARQL_ENDPOINT}'
EOL
  }

  depends_on = [
    kubernetes_namespace.namespace
  ]
}


# resource "helm_release" "sparql" {

# }


resource "helm_release" "db" {

  name      = "databaseagrold"
  namespace = kubernetes_namespace.namespace.metadata[0].name

  chart  = "../../mysql"
  values = ["${file("../../mysql/values.yaml")}"]

  set {
    name  = "auth.username"
    value = var.AGROLD_DB_USERNAME
  }

  set {
    name  = "auth.password"
    value = var.AGROLD_DB_PASSWORD
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

  chart  = "../../kubeview"
  values = ["${file("../../kubeview/values.yaml")}"]

  set {
    name  = "ingress.hosts[0].domain"
    value = var.basedomain
  }

  depends_on = [
    kubernetes_namespace.namespace
  ]
}