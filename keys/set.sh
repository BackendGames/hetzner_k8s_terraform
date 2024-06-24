#!/bin/bash

ssh -i id_ed25519 -o StrictHostKeyChecking=no root@$1 'cat /etc/kubernetes/admin.conf' > ~/.kube/config
echo "~/kube/config configured."