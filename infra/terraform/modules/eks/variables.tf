variable "cluster_name" {
  type = string
}

variable "kubernetes_version" {
  type    = string
  default = null
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "node_instance_types" {
  type    = list(string)
  default = ["t3.large", "m5.large"]
}

variable "capacity_type" {
  type    = string
  default = "SPOT"
}

variable "node_count" {
  type    = number
  default = 2
}
