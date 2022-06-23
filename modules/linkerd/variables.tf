variable "linkerd_version" {
  description = "Helm chart version for Linkerd (Linkerd version)"
  type        = string
  default     = "2.11.1"
}

variable "linkerd_identity_validity_period_hours" {
  description = "Updated certificate in advance of the expiration of the current certificate"
  type        = number
  default     = 7920
}

variable "enable_ha" {
  description = "Enable high availability for Linkerd control plane"
  type        = bool
  default     = false
}

variable "include_viz" {
  description = "Include Viz extension"
  type        = bool
  default     = true
}

variable "include_jaeger" {
  description = "Include Jaeger extension"
  type        = bool
  default     = true
}
