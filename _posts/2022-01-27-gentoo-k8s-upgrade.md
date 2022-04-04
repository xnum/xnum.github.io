---
layout: post
title: kubernetes 升級 (1.20 -> 1.23) on gentoo
date: 2022-01-27 00:00 +0800
categories:
- k8s
- gentoo
---

升級需要手動修正的：

cert-manager 升級到 1.6.1，相關資源升級到 cert-manger.io/v1
Ingress升級到networking.k8s.io/v1，需要加上 `ingressClassName: nginx`
PodSecurityPolicy在1.25後deprecated，預防性先停用相關設定
ServiceTopology deprecated，移除相關設定

升級順序 (版本無法跳過，需逐個minor version升級)：

1. 挑一個master node `emerge --ask =sys-cluster/kubeadm-1.22.5`
2. `kubeadm upgrade plan` 看一下是否符合升級條件
3. `kubeadm upgrade apply v1.22.5`
4. 確定新的 etcd kue-api-server kube-controller-manager kube-scheduler kube-proxy 都已正常執行
5. 其他node執行 `kubeadm upgrade node`
6. as same as step4
7. 所有node執行 `emerge =sys-cluster/kubelet-1.22.5 =sys-cluster/kubectl-1.22.5`
8. 如果不是用docker CRI 修改 `/etc/systemd/system/multi-user.target.wants/kubelet.service` 把docker.service改成例如crio.service
9. (optional) cordon node && drain node 但是我懶得做也沒出甚麼問題
10. `systemctl daemon-reload && systemctl restart kubelet`
11. (optional) uncordon node

master node如果restart kubelet要稍微給一點時間間隔，讓etcd能夠重新連線，避免倒站

一直重複更新直到最新版
