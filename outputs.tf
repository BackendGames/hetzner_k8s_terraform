# OUTPUTS

output "master_ips" {
  value       = hcloud_server.master.*.ipv4_address
  description = "IP addresses of the master nodes"
}

output "worker_ips" {
  value       = hcloud_server.worker.*.ipv4_address
  description = "IP addresses of the worker nodes"
}

output "gameserver_ips" {
  value       = hcloud_server.gameserver.*.ipv4_address
  description = "IP addresses of the worker nodes"
}

output "database_ips" {
  value       = hcloud_server.database.*.ipv4_address
  description = "IP addresses of the worker nodes"
}

output "microservice_ips" {
  value       = hcloud_server.microservice.*.ipv4_address
  description = "IP addresses of the worker nodes"
}

output "kubeconfig" {
  value       = "ssh -i keys/id_ed25519 -o StrictHostKeyChecking=no root@${hcloud_server.master[0].ipv4_address} 'cat /etc/kubernetes/admin.conf' > config"
  description = "Get kubeconfig file by running this command"
}