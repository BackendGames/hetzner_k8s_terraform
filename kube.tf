provider "hcloud" {
  token = var.hcloud_token
}

resource "hcloud_ssh_key" "hcloud_ssh_public_key" {
  name       = "k8s-ssh-key"
  public_key = file(var.ssh_public_key_path)
}

# define hcloud network & subnet
resource "hcloud_network" "k8s_network" {
  name     = "example-network"
  ip_range = "10.0.0.0/16"
}
resource "hcloud_network_subnet" "k8s_subnet" {
  network_id   = hcloud_network.k8s_network.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.0.0.0/16"
}


# CNI installation flannel/cilium
resource "null_resource" "install_cni" {
  count = var.master_count > 0 ? 1 : 0

  # add CNI file
  provisioner "file" {
    source      = "cni/${var.cni}.sh"
    destination = "/tmp/${var.cni}.sh"
  }

  # install helm
  provisioner "remote-exec" {
    inline = [
      "curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3",
      "chmod 700 get_helm.sh",
      "./get_helm.sh"
    ]
  }

  # install CNI
  # helm must be installed before this step
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/${var.cni}.sh",
      "/tmp/${var.cni}.sh"
    ]
  }

  depends_on = [null_resource.init_first_master]
  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(var.ssh_private_key_path)
    host        = hcloud_server.master[0].ipv4_address
  }
}

# update hosts with workers & masters IP Addresses
resource "null_resource" "update_hosts" {
  count = var.master_count + var.worker_count

  provisioner "remote-exec" {
    inline = [
      "cat <<EOF | sudo tee -a /etc/hosts",
      "${join("\n", [
        for i, master in hcloud_server.master : "${master.ipv4_address} k8s-master-${i + 1}"
      ])}",
      "${join("\n", [
        for i, worker in hcloud_server.worker : "${worker.ipv4_address} k8s-worker-${i + 1}"
      ])}",
      "EOF"
    ]
  }

  depends_on = [hcloud_server.master, hcloud_server.worker]

  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(var.ssh_private_key_path)
    host        = element(concat(hcloud_server.master[*].ipv4_address, hcloud_server.worker[*].ipv4_address), count.index)
  }
}
