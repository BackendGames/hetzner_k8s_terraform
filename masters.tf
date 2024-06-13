# master nodes
resource "hcloud_server" "masters" {
  count       = var.masters_count
  name        = "k8s-master-${count.index + 1}"
  image       = var.image
  server_type = var.master_type
  ssh_keys    = [hcloud_ssh_key.hcloud_ssh_public_key.id]
  network {
    network_id = hcloud_network_subnet.k8s_subnet.network_id
  }

}

# init first master (kubeadm init)
resource "null_resource" "init_first_master" {
  count      = var.masters_count > 0 ? 1 : 0
  depends_on = [hcloud_server.masters]
  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(var.ssh_private_key_path)
    host        = hcloud_server.masters[0].ipv4_address
  }
  provisioner "remote-exec" {
    # --ignore-preflight-errors=NumCPU in order to use smaller type than CX21 current type is CX11; 2VCpus is required for k8s
    # --pod-network-cidr must match CNI's cidr
    # for production
    # "sudo kubeadm init ${var.kubernetes_api_dns != "" ? "--control-plane-endpoint=${var.kubernetes_api_dns}" : ""} ${var.kubernetes_api_dns} --apiserver-advertise-address ${hcloud_server.masters[0].ipv4_address} --pod-network-cidr=10.244.0.0/16 --cri-socket=/run/containerd/containerd.sock --ignore-preflight-errors=NumCPU"
    inline = [
      "sudo kubeadm init --control-plane-endpoint=${hcloud_server.masters[0].ipv4_address}:6443 --apiserver-advertise-address ${hcloud_server.masters[0].ipv4_address} --pod-network-cidr=10.244.0.0/16 --cri-socket=/run/containerd/containerd.sock --ignore-preflight-errors=NumCPU",
      "mkdir -p /root/.kube",
      "sudo cp -i /etc/kubernetes/admin.conf /root/.kube/config",
      "sudo chown $(id -u):$(id -g) /root/.kube/config"
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
  count      = var.masters_count > 1 ? var.masters_count - 1 : 0
  depends_on = [null_resource.init_first_master]
  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(var.ssh_private_key_path)
    host        = hcloud_server.masters[count.index + 1].ipv4_address
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
      "ssh -o StrictHostKeyChecking=no root@${hcloud_server.masters[0].ipv4_address} 'kubeadm init phase upload-certs --upload-certs > /tmp/JOIN_CERT'",
      "scp root@${hcloud_server.masters[0].ipv4_address}:/tmp/JOIN_CERT /tmp/JOIN_CERT",
      "JOIN_CERT=$(ssh -o StrictHostKeyChecking=no root@${hcloud_server.masters[0].ipv4_address} 'grep -oE '[0-9a-f]{64}' /tmp/JOIN_CERT')",
      "JOIN_CMD=$(ssh -o StrictHostKeyChecking=no root@${hcloud_server.masters[0].ipv4_address} 'kubeadm --kubeconfig=/etc/kubernetes/admin.conf token create --print-join-command')",
      "$JOIN_CMD --control-plane --certificate-key $JOIN_CERT --apiserver-advertise-address ${hcloud_server.masters[count.index + 1].ipv4_address}"
    ]
  }

}