variable "host_project_id" {
  description = "vpc01-335820"
}

variable "service_project_id1" {
  description = "serviceproject01-336818"
}

variable "service_project_id2" {
  description = "serviceproject02-336818"
}

variable "service_project_number" {
  description = "659171180603"
}

variable "service_project_owners" {
  description = "Service project owners, in IAM format."
  default     = ["siddharth.mehra@badal.io"]
}

variable "network_name" {
  description = "Name of the shared VPC."
  default     = "host-svpc"
}