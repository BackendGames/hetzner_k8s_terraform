# master nodes
resource "hcloud_server" "master" {
  count       = var.master_count
  name        = "k8s-master-${count.index + 1}"
  image       = var.image
  server_type = var.master_type
  location    = var.hcloud_location
  ssh_keys    = [hcloud_ssh_key.hcloud_ssh_public_key.id]
  network {
    network_id = hcloud_network_subnet.k8s_subnet.network_id
  }
  public_net {
    ipv4_enabled = true
    ipv6_enabled = false
  }

}

# init first master (kubeadm init)
resource "null_resource" "init_first_master" {
  count      = var.master_count > 0 ? 1 : 0
  depends_on = [hcloud_server.master]
  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(var.ssh_private_key_path)
    host        = hcloud_server.master[0].ipv4_address
  }

  provisioner "remote-exec" {
    # --ignore-preflight-errors=NumCPU in order to use smaller type than CX21 current type is CX11; 2VCpus is required for k8s
    inline = [
      "kubeadm init --control-plane-endpoint=${hcloud_load_balancer.lb.ipv4}:6443 --apiserver-advertise-address ${hcloud_server.master[0].network.*.ip[0]} --pod-network-cidr=${var.cidr} --cri-socket=/run/containerd/containerd.sock --ignore-preflight-errors=NumCPU",
      "mkdir -p /root/.kube",
      "cp -i /etc/kubernetes/admin.conf /root/.kube/config",
      "chown $(id -u):$(id -g) /root/.kube/config"
    ]
  }
  # add public key
  provisioner "remote-exec" {
    inline = [
      <<-EOF
        cat >>~/.ssh/authorized_keys<<EOKEY
        ${file(var.ssh_public_key_path)}
        EOKEY
      EOF
    ]
  }

}

# add secondary masters
resource "null_resource" "join_other_masters" {
  count      = var.master_count > 1 ? var.master_count - 1 : 0
  depends_on = [null_resource.init_first_master]
  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(var.ssh_private_key_path)
    host        = hcloud_server.master[count.index + 1].ipv4_address
  }

  provisioner "file" {
    source      = "keys/id_ed25519"
    destination = "/tmp/id_ed25519"
  }

  # add private key
  provisioner "remote-exec" {
    inline = [
      "cp /tmp/id_ed25519 ~/.ssh/",
      "chmod 400 ~/.ssh/id_ed25519",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "ssh -o StrictHostKeyChecking=no root@${hcloud_server.master[0].ipv4_address} 'kubeadm init phase upload-certs --upload-certs > /tmp/JOIN_CERT'",
      "scp root@${hcloud_server.master[0].ipv4_address}:/tmp/JOIN_CERT /tmp/JOIN_CERT",
      "JOIN_CERT=$(ssh -o StrictHostKeyChecking=no root@${hcloud_server.master[0].ipv4_address} 'grep -oE '[0-9a-f]{64}' /tmp/JOIN_CERT')",
      "JOIN_CMD=$(ssh -o StrictHostKeyChecking=no root@${hcloud_server.master[0].ipv4_address} 'kubeadm --kubeconfig=/etc/kubernetes/admin.conf token create --print-join-command')",
      "$JOIN_CMD --control-plane --certificate-key $JOIN_CERT --apiserver-advertise-address ${hcloud_server.master[count.index + 1].ipv4_address}"
    ]
  }

}