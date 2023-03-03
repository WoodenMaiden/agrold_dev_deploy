# ============ #
#     RFR      #
# ============ #

resource "helm_release" "rfrfrontend" {
  name      = "rfrfrontend"
  namespace = kubernetes_namespace.namespace.metadata[0].name

  chart  = "../../charts/rf"
  values = ["${file("../../charts/rf/values.yaml")}"]

  set {
    name  = "apiUrl"
    value = var.sparql_endpoint
  }

  set {
    name  = "ingress.hosts[0].host"
    value = "${join(".", ["rf", var.basedomain])}"
  }

  depends_on = [
    kubernetes_namespace.namespace
  ]
}

resource "helm_release" "rfrapi" {
  name      = "rfrapi"
  namespace = kubernetes_namespace.namespace.metadata[0].name

  chart  = "../../charts/rfapi"
  values = ["${file("../../charts/rfapi/values.yaml")}"]

  set_sensitive {
    name  = "args"
    value = "{-p, 80, --loglevel, DEBUG}"
  }

  set {
    name  = "ingress.hosts[0].host"
    value = "${join(".", ["api", var.basedomain])}"
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
  values = ["${file("../../charts/tomcat/values.yaml")}"]

  set {
    name  = "ingress.hostname"
    value = var.basedomain
  }

  set {
    name  = "sparqlAddress"
    value = var.AGROLD_SPARQL_ENDPOINT
  }

  set_sensitive {
    name  = "catalinaOpts"
    value = <<EOL
-Dagrold.db_connection_url='mysql.${kubernetes_namespace.namespace.metadata[0].name}.svc.cluster.local/agrolddb?useSSL=false' -Dagrold.db_username='${var.AGROLD_DB_USERNAME}' -Dagrold.db_password='${var.AGROLD_DB_PASSWORD}' -Dagrold.name='${var.AGROLD_NAME}' -Dagrold.description='${var.AGROLD_DESCRIPTION}' -Dagrold.baseurl='${var.AGROLD_BASEURL}' -Dagrold.sparql_endpoint='${var.AGROLD_SPARQL_ENDPOINT}'
EOL
  }

  depends_on = [
    kubernetes_namespace.namespace
  ]
}


resource "helm_release" "sparql" {
  name      = "sparql"
  namespace = kubernetes_namespace.namespace.metadata[0].name

  chart  = "../../charts/sparql"
  values = ["${file("../../charts/sparql/values.yaml")}"]

  depends_on = [
    kubernetes_namespace.namespace
  ]
}


resource "helm_release" "db" {

  name      = "databaseagrold"
  namespace = kubernetes_namespace.namespace.metadata[0].name

  chart  = "../../charts/agroldmysql"
  values = ["${file("../../charts/agroldmysql/values.yaml")}"]

  set_sensitive {
    name  = "auth.username"
    value = var.AGROLD_DB_USERNAME
  }

  set_sensitive {
    name  = "auth.password"
    value = var.AGROLD_DB_PASSWORD
  }

  depends_on = [
    kubernetes_namespace.namespace
  ]
}

# ================ #
#      Metrics     #
# ================ #

resource "helm_release" "kube-prometheus-stack" {
  name      = "kube-prometheus-stack"
  namespace = kubernetes_namespace.metrics.metadata[0].name

  chart  = "../../charts/kube-prometheus-stack"
  values = ["${file("../../charts/kube-prometheus-stack/values.yaml")}"]


  set_sensitive {
    name  = "grafana.adminPassword"
    value = var.grafana_admin_password
  }

  set {
    name  = "grafana.ingress.enabled"
    value = true
  }

  set {
    name  = "grafana.ingress.hosts[0]"
    value = "${join(".", ["grafana", var.basedomain])}"
  }


  depends_on = [
    kubernetes_namespace.metrics
  ]
}

# ============= #
#      Misc     #
# ============= #

resource "helm_release" "kubeview" {
  name      = "kubeview"
  namespace = kubernetes_namespace.namespace.metadata[0].name

  chart  = "../../charts/kubeview"
  values = ["${file("../../charts/kubeview/values.yaml")}"]

  set {
    name  = "ingress.hosts[0].host"
    value = "${join(".", ["viz", var.basedomain])}"
  }

  depends_on = [
    kubernetes_namespace.namespace
  ]
}