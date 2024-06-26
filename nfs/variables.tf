variable "hcloud_token" {
  description = "Hetzner Cloud API Token"
  type        = string
  sensitive   = true
}

variable "hcloud_network_id" {
  description = "Hetzner Cloud Network IP Range"
  type        = string
}

variable "server_type" {
  description = "Hetzner Cloud server type for master nodes"
  type        = string
  default     = "cx21"
}


variable "hcloud_location" {
  description = "hcloud servers location"
  type        = string
  default     = "nbg1"
}


variable "image" {
  description = "Image type for the nodes"
  type        = string
  default     = "debian-12"
}

variable "hcloud_subnet_range" {
  description = "Hetzner Cloud Subnet IP Range"
  type        = string
}

variable "hcloud_ssh_public_key_id" {
  description = "ssh public key id"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Path to the SSH public key file"
  sensitive   = true
}