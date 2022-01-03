variable "host_project_id" {
  type        = string
  description = "vpc01-335820"
}

# passed-in values can be dynamic, so variables used in count need to be separate

variable "service_project_num" {
  type        = number
  description = "Number of service projects that will be attached to the Shared VPC."
  default     = 2
}

variable "service_project_ids" {
  type        = list(string)
  description = "Ids of the service projects that will be attached to the Shared VPC."
  default = ["serviceproject01-336818", "serviceproject02-336818"]
}

variable "host_subnets" {
  type        = list(string)
  description = "List of subnet names on which to grant network user role."
  default     = ["testa", "testb"]
}

variable "host_subnet_regions" {
  type        = list(string)
  description = "List of subnet regions, one per subnet."
  default     = ["us-central1", "us-central1"]
}

variable "host_subnet_users" {
  type        = map(any)
  description = "Map of comma-delimited IAM-style members to which network user roles for subnets will be assigned."
  default     = {}
}

variable "host_service_agent_role" {
  type        = bool
  description = "Assign host service agent role to users in host_service_agent_users variable."
  default     = false
}

variable "host_service_agent_users" {
  type        = list(string)
  description = "List of IAM-style users that will be granted the host service agent role on the host project."
  default     = ["serviceAccount:siddharth.mehra@badal.io"]
}