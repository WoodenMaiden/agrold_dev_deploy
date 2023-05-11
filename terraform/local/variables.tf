variable "KUBECONFIG" {
  description = "KUBECONFIG env variable"
  type        = string
}

variable "base_domain" {
  description = "Domain used for FQDN (https://kinsta.com/wp-content/uploads/2022/07/structure-of-url.png)"
  type        = string
  default     = "127.0.0.1.sslip.io"
}


variable "namespace" {
  description = "namespace used"
  type        = string
  default     = "agrold"
}

variable "sparql_endpoint" {
  description = "SPARQL endpoint used by rfr api"
  type        = string
  default     = "http://sparql.agrold.svc.cluster.local/sparql"
}

variable "tomcat_admin_password" {
  description = "Admin password used for tomcat"
  type        = string
  default     = "password"
}

variable "agrold_name" {
  description = "Prefix of agrold main app: http://[base_domain]/[agrold_name]"
  type        = string
  default     = "aldp"
}

variable "agrold_description" {
  description = "Description of agrold prompted in tomcat's admin pannel"
  type        = string
  default     = ""
}

variable "agrold_db_username" {
  description = "Agrold database username"
  type        = string
  default     = "app"
}

variable "agrold_db_password" {
  description = "Agrold database password"
  type        = string
  default     = "password"
}
