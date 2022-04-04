---
layout: post
title: Gentoo k8s calico 安裝
date: 2021-01-05 18:31 +0800
categories: k8s
---

舊版的 calico 沒有用到 `/sys/fs/bpf` 可以直接 apply yaml

`curl wget https://docs.projectcalico.org/v3.10/manifests/calico.yaml -O`

找到 `CALICO_IPV4POOL_CIDR` 進行修改

加上這組設定 (這是gateway IP)

```
- name: IP_AUTODETECTION_METHOD
  value: can-reach=10.168.100.253
```

新版可能會出現錯誤

`path /sys/fs is mounted on /sys but it is not a shared mount`

因為 OpenRC 沒有把 mount 轉換成 shared mount

`findmnt -o TARGET,PROPAGATION /` 進行確認

可以手動 `mount --make-rshared /` 或加在開機 script

使用 `kubectl -n kube-system get pods -w` 檢查 calico 已正常運作

如下

```
NAME                                       READY   STATUS    RESTARTS   AGE
calico-kube-controllers-744cfdf676-5l8d6   1/1     Running   0          35s
calico-node-4mxc7                          1/1     Running   0          35s
calico-node-77wxr                          1/1     Running   0          35s
calico-node-8rw75                          1/1     Running   0          35s
calico-node-nnc25                          1/1     Running   0          35s
calico-node-p27l4                          1/1     Running   0          35s
calico-node-tlkrh                          1/1     Running   0          35s
coredns-74ff55c5b-spddd                    1/1     Running   0          24m
coredns-74ff55c5b-trzpg                    1/1     Running   0          24m
kube-apiserver-k8s-node1                   1/1     Running   0          24m
kube-apiserver-k8s-node2                   1/1     Running   0          22m
kube-apiserver-k8s-node3                   1/1     Running   0          21m
kube-controller-manager-k8s-node1          1/1     Running   0          24m
kube-controller-manager-k8s-node2          1/1     Running   0          22m
kube-controller-manager-k8s-node3          1/1     Running   0          21m
kube-proxy-4v5rd                           1/1     Running   0          19m
kube-proxy-8wjkc                           1/1     Running   0          20m
kube-proxy-brq2p                           1/1     Running   0          24m
kube-proxy-jjh5q                           1/1     Running   0          21m
kube-proxy-mdph2                           1/1     Running   0          18m
kube-proxy-shvh7                           1/1     Running   0          22m
kube-scheduler-k8s-node1                   1/1     Running   0          24m
kube-scheduler-k8s-node2                   1/1     Running   0          22m
kube-scheduler-k8s-node3                   1/1     Running   0          21m
```

ref: https://success.mirantis.com/article/not-a-shared-mount-error
