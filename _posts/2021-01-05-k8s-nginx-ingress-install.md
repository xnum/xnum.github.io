---
layout: post
title: k8s nginx ingress install
date: 2021-01-05 18:54 +0800
---

# nginx-ingress

using helm, 3.19

使用NodePort 內部 listen 改成 9080 和 9443

範例:

```
<   extraArgs:
<     http-port: 9080
<     https-port: 9443
<     default-ssl-certificate: "default/wildcard-xxx-tls"
```

# cert-manager

```
helm install \
  cert-manager jetstack/cert-manager \
  --namespace ingress \
  --version v1.1.0 \
  --set installCRDs=true
```

照著作

https://github.com/bwolf/cert-manager-webhook-gandi

看cert-manager pod可以看到狀態
