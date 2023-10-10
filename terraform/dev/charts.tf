# ============ #
#     RFR      #
# ============ #

resource "helm_release" "rf" {
  name      = "rf"
  namespace = kubernetes_namespace.namespace.metadata[0].name

  chart  = "../../charts/rf"
  values = [file("../../charts/rf/values.yaml")]

  set {
    name  = "image.repository" 
    value = "10.9.2.21:8080/rfr/relfinderreformedfront"
  }

  set {
    name  = "image.tag" 
    value = var.image_tags.rf
  }

  set {
    name  = "image.pullPolicy" 
    value = "Always"
  }

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
    name  = "image.repository" 
    value = "10.9.2.21:8080/rfr/relfinderreformedapi"
  }

  set {
    name  = "image.tag" 
    value = var.image_tags.rfapi
  }

  set {
    name  = "image.pullPolicy" 
    value = "Always"
  }

  set {
    name  = "autoscaling.enabled"
    value = false
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
    name  = "image.registry"
    value = "10.9.2.21:8080"
  }

  set {
    name  = "image.repository"
    value = "agrolddev"
  }

  set {
    name  = "image.tag"
    value = var.image_tags.agrold
  }

  set {
    name  = "image.pullPolicy"
    value = "Always"
  }

  set {
    name  = "tomcatPassword"
    value = var.tomcat_admin_password
  }

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
-Dagrold.db_connection_url='mysql.${kubernetes_namespace.namespace.metadata[0].name}.svc.cluster.local/agrolddb?useSSL=false' -Dagrold.db_username='${var.agrold_db_username}' -Dagrold.db_password='${var.agrold_db_password}' -Dagrold.name='${var.agrold_name}' -Dagrold.description='${var.agrold_description}' -Dagrold.baseurl='http://${var.base_domain}/' -Dagrold.sparql_endpoint='${var.sparql_endpoint}' -Dagrold.rf_link='http://${join(".", ["rf", var.base_domain])}'
EOL
  }

  depends_on = [
    kubernetes_namespace.namespace
  ]
}


# No sparql as we are hitting the production endpoint in dev env


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

# ================ #
#      Metrics     #
# ================ #

# 👇 We will complete this after prometheus endpoints are ready
resource "helm_release" "kube-prometheus-stack" {
  name      = "kube-prometheus-stack"
  namespace = kubernetes_namespace.metrics.metadata[0].name

  chart  = "../../charts/kube-prometheus-stack"
  values = [file("../../charts/kube-prometheus-stack/values.yaml")]


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
    value = join(".", ["grafana", var.base_domain])
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
  values = [file("../../charts/kubeview/values.yaml")]

  set {
    name  = "ingress.hosts[0].host"
    value = join(".", ["viz", var.base_domain])
  }

  depends_on = [
    kubernetes_namespace.namespace
  ]
}