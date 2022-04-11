---
layout: post
title: nginx ingress 的 root domain 設定
categories: [k8s, sys_admin]
description: 
keywords: k8s, nginx, ingress, tls
---

先前使用 wildcard tls cert 作為整個 domain 的憑證共用

今天發現如果沒有帶 subdomain 的話無法直接使用這個憑證

連線到 www.example.com 的時候可以正常運作，但是 example.com 就無法運作了

在 firefox 上會很雞婆的幫你補上 www. ，看起來一切正常。但如果換到 curl 或 chrome 就會噴 tls 憑證警告

這個原因是：該憑證上只有 `*.example.com` 而沒有 `example.com`

這邊我懶惰所以直接用 http01 另外簽一個專門給 `example.com` 用的 tls secret

而沒有動本來簽好的憑證設定

如果有參考了我以前做的 [k8s-nginx-ingress](2021/01/k8s-nginx-ingress-install/) 設定方式

那麼 ingress config 需要拆開寫，再把 service 指到同一個

```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: www-example-homepage
  namespace: default
spec:
  ingressClassName: nginx
  rules:
  - host: www.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: example-homepage
            port:
              number: 80
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example-homepage
  namespace: default
spec:
  ingressClassName: nginx
  rules:
  - host: example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: example-homepage
            port:
              number: 80
  tls:
  - hosts:
    - example.com
    secretName: example-com-tls
```


