terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
  }
  # new version is required
  required_version = ">= 0.13"
}

provider "hcloud" {
  token = "nbaxW3pD9ljfOncMssBP7M3AaRddFFDztFrAK7LoRp8XKdYv06yX8spMhkt0MMbf"
}

resource "hcloud_ssh_key" "hcloud_ssh_public_key" {
  name       = "k8s-ssh-key"
  public_key = file("../keys/id_ed25519.pub")
}

resource "hcloud_server" "workers" {
  count       = 1
  name        = "ubuntu-22"
  image       = "ubuntu-22.04"
  server_type = "cpx21"
  ssh_keys    = [hcloud_ssh_key.hcloud_ssh_public_key.id]
}