#!/bin/bash

ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$1"
ssh -i id_ed25519 root@$1
