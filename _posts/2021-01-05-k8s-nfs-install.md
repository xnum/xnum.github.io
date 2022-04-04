---
layout: post
title: k8s nfs install
date: 2021-01-05 20:36 +0800
categories: k8s
---

```
emerge nfs-utils rpcbind
rc-service nfsmount start
showmount -e 10.x.x.x
```

patch (for k8s v1.20+)

```
9,10c9,11
<   repository: quay.io/external_storage/nfs-client-provisioner
<   tag: v3.1.0-k8s1.11
---
>   #repository: quay.io/external_storage/nfs-client-provisioner
>   repository: groundhog2k/nfs-subdir-external-provisioner
>   tag: v3.2.0
14,15c15,16
<   server:
<   path: /ifs/kubernetes
---
>   server: 10.168.100.21
>   path: /volume1/[pathToDir]
```
