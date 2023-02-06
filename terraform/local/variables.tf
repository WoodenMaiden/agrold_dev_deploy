variable "KUBECONFIG" {
  description = "KUBECONFIG env variable"
  type        = string
}

variable "basedomain" {
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
  description = "SPARQL endpoint used by rfr"
  type        = string
  default     = "http://127.0.0.1.sslip.io"
}

variable "tomcat_admin_password" {
  description = "Admin password used for tomcat"
  type        = string
  default     = "password"
}


# variable "war_path" {
#     type
# }

variable "AGROLD_NAME" {
  description = "Prefix of agrold main app: http://[basedomain]/[AGROLD_NAME]"
  type        = string
  default     = "aldp"
}

variable "AGROLD_DESCRIPTION" {
  description = "Description of agrold prompted in tomcat's admin pannel"
  type        = string
  default     = ""
}


variable "AGROLD_BASEURL" {
  description = "App's base URL"
  type        = string
  default     = "http://127.0.0.1.sslip.io/"
}

variable "AGROLD_SPARQL_ENDPOINT" {
  description = "SPARQL endpoint used by AgroLD"
  type        = string
  default     = "http://sparql.southgreen.fr"
}

variable "AGROLD_DB_USERNAME" {
  description = "Agrold database username"
  type        = string
  default     = "app"
}

variable "AGROLD_DB_PASSWORD" {
  description = "Agrold database password"
  type        = string
  default     = "password"
}
