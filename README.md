# Provisioning Kubernetes on Hetzner Cloud

This project automates the provisioning of a Kubernetes cluster on Hetzner Cloud using Terraform


1. add terraform credentials under '~/.terraform.rc'

```bash
credentials app.terraform.io" {
      "token": "YOUR_TOKEN"
}
```
**If you don't want to use remote backend, delete the remote.tf file**

2. navigate to keys/ and run the following to generate ssh keys

```bash
ssh-keygen -t ed25519
```
set the path as .


3. set the values of variables on terraform.tfvars.example

```bash
hcloud_token         = "HCLOUD_TOKEN"
ssh_public_key_path  = "./keys/id_ed25519.pub"
ssh_private_key_path = "./keys/id_ed25519"
masters_count        = 1 # add more masters if you've set a loadbalancer
workers_count        = 1
cni                  = "cilium"
master_type          = "cpx21"
worker_type          = "cpx11"
image                = "ubuntu-20.04"
```
you can change them according to your need
```bash
mv terraform.tfvars.example terraform.tfvars
```

4. review your configuration then apply 

```bash
terraform plan
terraform apply
```
