variable "hcloud_token" {
  description = "Hetzner Cloud API Token"
  type        = string
  sensitive   = true
}

variable "hcloud_network_range" {
  description = "Hetzner Cloud Network IP Range"
  type        = string
}

variable "hcloud_subnet_range" {
  description = "Hetzner Cloud Subnet IP Range"
  type        = string
}

variable "master_count" {
  description = "Number of master nodes"
  type        = number
}

variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
}

variable "gameserver_count" {
  description = "Number of worker nodes"
  type        = number
}

variable "database_count" {
  description = "Number of worker nodes"
  type        = number
}

variable "microservice_count" {
  description = "Number of worker nodes"
  type        = number
}

variable "cni" {
  description = "CNI plugin (flannel or cilium)"
  type        = string
  default     = "flannel"
}

variable "cidr" {
  description = "Pod Network Cidr"
  type        = string
  default     = "10.244.0.0/16"
}

variable "master_type" {
  description = "Hetzner Cloud server type for master nodes"
  type        = string
  default     = "cx21"
}

variable "worker_type" {
  description = "Hetzner Cloud server type for worker nodes"
  type        = string
  default     = "cx11"
}

variable "gameserver_type" {
  description = "Hetzner Cloud server type for master nodes"
  type        = string
  default     = "cx21"
}

variable "database_type" {
  description = "Hetzner Cloud server type for worker nodes"
  type        = string
  default     = "cx11"
}

variable "microservice_type" {
  description = "Hetzner Cloud server type for worker nodes"
  type        = string
  default     = "cx11"
}

variable "hcloud_location" {
  description = "hcloud servers location"
  type        = string
  default     = "nbg1"
}


variable "image" {
  description = "Image type for the nodes"
  type        = string
  default     = "ubuntu-20.04"
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key file"
  sensitive   = true
}

variable "ssh_private_key_path" {
  description = "Path to the SSH public key file"
  sensitive   = true
}