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
  token = var.hcloud_token
}

resource "hcloud_ssh_key" "hcloud_ssh_public_key" {
  name       = "k8s-ssh-key"
  public_key = file("../keys/id_ed25519.pub")
}

resource "hcloud_server" "template" {
  count       = 1
  name        = "template"
  image       = "debian-12"
  server_type = "cpx21"
  ssh_keys    = [hcloud_ssh_key.hcloud_ssh_public_key.id]


  connection {
    type        = "ssh"
    user        = "root"
    private_key = file("../keys/id_ed25519")
    host        = self.ipv4_address
  }
  provisioner "file" {
    source      = "init.sh"
    destination = "/tmp/init.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/init.sh",
      "/tmp/init.sh"
    ]
  }

}