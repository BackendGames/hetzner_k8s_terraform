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

resource "hcloud_server" "nfs" {
  name        = "k8s-nfs"
  image       = var.image
  server_type = var.server_type
  location    = var.hcloud_location
  ssh_keys    = [var.hcloud_ssh_public_key_id]
  network {
    network_id = var.hcloud_network_id # after cluster creation get the id
  }
  public_net {
    ipv4_enabled = true
    ipv6_enabled = false
  }

  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(var.ssh_private_key_path)
    host        = self.ipv4_address
  }

  # install nfs
  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install nfs-kernel-server ufw -y",
      "sudo mkdir -p /mnt/nfs",
      "sudo chown nobody:nogroup /mnt/nfs",
      "sudo bash -c 'echo \"/mnt/nfs ${var.hcloud_subnet_range}(rw,sync,no_subtree_check)\" >> /etc/exports'",
      "sudo exportfs -a",
      "sudo systemctl restart nfs-kernel-server",
      "sudo ufw allow ssh",
      "sudo ufw allow from ${var.hcloud_subnet_range} to any port nfs",
      "sudo ufw --force enable"
    ]
  }


}