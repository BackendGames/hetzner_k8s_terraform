# install nfs provisioner

instal
```
$ helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
$ helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
    --set nfs.server=x.x.x.x \
    --set nfs.path=/exported/path
```

unintall 

```
helm uninstall nfs-subdir-external-provisioner
```

then you can deploy a pvc with the required storageclass name