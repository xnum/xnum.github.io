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

---

cert-manager 和 nginx-ingress-controller 和 tls secret 放在同一個 namespace (e.g. ingress)

個別的 ingress 放在自己的 namespace (e.g. monitoring)

加上 tls 讓 http protocol 被 308 轉址

```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: grafana
spec:
  tls:
  - hosts:
    - grafana.example.com
    secretName: wildcard-xxx-tls
  rules:
  - host: grafana.examle.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: grafana
            port:
              number: 3000
```
