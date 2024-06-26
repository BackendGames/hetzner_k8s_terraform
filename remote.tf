terraform {
  backend "remote" {
    organization = "Frostline"
    workspaces {
      name = "Hetzner-K8s"
    }
  }
}