provider "hcloud" {
  token = var.hcloud_token
}

resource "hcloud_ssh_key" "hcloud_ssh_public_key" {
  name       = "k8s-ssh-key"
  public_key = file(var.ssh_public_key_path)
}

# HA loadbalancer
resource "hcloud_load_balancer" "lb" {
  name               = "cluster-endpoint"
  load_balancer_type = "lb11"
  location           = "nbg1"
}

resource "hcloud_load_balancer_target" "load_balancer_target" {
  count            = var.master_count
  type             = "server"
  load_balancer_id = hcloud_load_balancer.lb.id
  server_id        = hcloud_server.master[count.index].id
}

resource "hcloud_load_balancer_service" "k8s_api_service" {
  load_balancer_id = hcloud_load_balancer.lb.id
  protocol         = "tcp"
  listen_port      = 6443
  destination_port = 6443

  health_check {
    protocol = "tcp"
    port     = 6443
    interval = 10
    timeout  = 5
    retries  = 3
  }
}

resource "hcloud_load_balancer_network" "srvnetwork" {
  load_balancer_id = hcloud_load_balancer.lb.id
  network_id       = hcloud_network.k8s_network.id
  # **Note**: the depends_on is important when directly attaching the
  # server to a network. Otherwise Terraform will attempt to create
  # server and sub-network in parallel. This may result in the server
  # creation failing randomly.
  depends_on = [
    hcloud_network_subnet.k8s_subnet
  ]
}

# define hcloud network & subnet
resource "hcloud_network" "k8s_network" {
  name     = "k8s-network"
  ip_range = var.hcloud_network_range
}
resource "hcloud_network_subnet" "k8s_subnet" {
  network_id   = hcloud_network.k8s_network.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = var.hcloud_subnet_range
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

  # configure ccm & csi
  provisioner "remote-exec" {
    inline = [
      "kubectl -n kube-system create secret generic hcloud --from-literal=token=${var.hcloud_token}",
      "helm repo add hcloud https://charts.hetzner.cloud",
      "helm repo update hcloud",
      "helm install hccm hcloud/hcloud-cloud-controller-manager -n kube-system",
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
  count = var.master_count + var.worker_count + var.gameserver_count + var.database_count + var.microservice_count

  provisioner "remote-exec" {
    inline = [
      "cat <<EOF | sudo tee -a /etc/hosts",
      "${join("\n", [
        for i, master in hcloud_server.master : "${master.network.*.ip[0]} k8s-master-${i + 1}"
      ])}",
      "${join("\n", [
        for i, worker in hcloud_server.worker : "${worker.network.*.ip[0]} k8s-worker-${i + 1}"
      ])}",
      "${join("\n", [
        for i, gameserver in hcloud_server.gameserver : "${gameserver.network.*.ip[0]} k8s-worker-${i + 1}"
      ])}",
      "${join("\n", [
        for i, database in hcloud_server.database : "${database.network.*.ip[0]} k8s-worker-${i + 1}"
      ])}",
      "${join("\n", [
        for i, microservice in hcloud_server.microservice : "${microservice.network.*.ip[0]} k8s-worker-${i + 1}"
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
