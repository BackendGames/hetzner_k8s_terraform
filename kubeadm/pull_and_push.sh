#!/bin/bash

# Define variables
ORG_NAME="frostline"
K8S_VERSION="v1.30.2"
ETCD_VERSION="3.5.12-0"
PAUSE_VERSION="3.9"
COREDNS_VERSION="v1.11.1"

# Kubernetes images from registry.k8s.io
images=(
  "kube-apiserver:${K8S_VERSION}"
  "kube-controller-manager:${K8S_VERSION}"
  "kube-scheduler:${K8S_VERSION}"
  "kube-proxy:${K8S_VERSION}"
  "etcd:${ETCD_VERSION}"
  "pause:${PAUSE_VERSION}"
  "coredns/coredns:${COREDNS_VERSION}"
)

# Function to pull, tag, and push images
function pull_tag_push {
  source_image=$1
  # Pull image
  docker pull registry.k8s.io/${source_image}

  # Tag image
  docker tag registry.k8s.io/${source_image} ${ORG_NAME}/${source_image}

  # Push image
  docker push ${ORG_NAME}/${source_image}

  # Clean up
#   docker rmi registry.k8s.io/${source_image}
#   docker rmi ${ORG_NAME}/${source_image}
}

# Loop through each image and call function
for image in "${images[@]}"
do
  pull_tag_push "${image}"
done

docker pull registry.k8s.io/coredns/coredns:${COREDNS_VERSION}
docker tag registry.k8s.io/coredns/coredns:${COREDNS_VERSION} ${ORG_NAME}/coredns:${COREDNS_VERSION}