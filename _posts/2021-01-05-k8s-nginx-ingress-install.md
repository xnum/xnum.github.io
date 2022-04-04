---
layout: post
title: k8s nginx ingress install
date: 2021-01-05 18:54 +0800
categories: k8s
---

# 前言

WAN進來先用port forward走到虛擬IP的80,443

目前已經在cluster上架設keepalived + haproxy

haproxy listens on *:80 *:443 並開啟 proxy protocol

並自動將流量導向任意node的 :32080, :32443 使用 NodePort接收流量


# 設定目標

- namespace `cert-manager`
  - 使用nginx作為ingress controller
  - 使用cert-manager取得wildcard tls cert secret並自動renew
  - tls termination
  - 放tls secrets
- namespace `panel`
  - 架一個 `panel.foo.com` 前後端分離
- namespace `default`
  - 架一個k8s example guestbook 在 `guest.bar.io`

一般使用者無法讀取secrets，但可以在自己的namespaec裡自由建立ingress

由於有多張wildcard，不能用default certificate選項指定

# nginx-ingress

使用helm3進行安裝 Chart version 3.19, App version 0.42.0

```
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install my-release ingress-nginx/ingress-nginx
```

ref: https://kubernetes.github.io/ingress-nginx/deploy/#using-helm

自訂values.yaml部分

```
controller:
  config:
    use-proxy-protocol: "true"
  extraArgs:
    http-port: 9080
    https-port: 9443
  ports:
    http: 9080
    https: 9443
  targetPorts:
    http: 9080
    https: 9443
  type: NodePort
  nodePorts:
    http: 32080
    https:32443
```

# cert-manager

```
helm install \
  cert-manager jetstack/cert-manager \
  --namespace ingress \
  --version v1.1.0 \
  --set installCRDs=true
```

# cert-manager ACME provider

我從gandi上買個幾個domain 使用上面提供的DNS server設定DNS記錄

* 1800 IN A 62.226.87.21

接下來照著作

https://github.com/bwolf/cert-manager-webhook-gandi

---

# Fake ingress

首先確認 certificates 已經取得

```
kubectl get certificates
```

在namespace `cert-manager`使用這個ingress讓nginx解TLS流量

```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
  name: foo-com-entry
  namespace: cert-manager
spec:
  tls:
  - hosts:
    - "*.foo.com"
    secretName: wildcard-foo-com-tls
  rules:
  - host: "*.foo.com"
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
  name: bar-io-entry
  namespace: cert-manager
spec:
  tls:
  - hosts:
    - "*.bar.io"
    secretName: wildcard-bar-io-tls
  rules:
  - host: "*.bar.io"

```

# Real Ingress

個別使用者可以用以下設定方式將特定host導到service上

這邊tls section都省略

```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: guestbook
  namespace: default
  annotations: {}
spec:
  rules:
  - host: guest.bar.io
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend
            port:
              number: 80
```

nginx的rewrite功能我一直測試失敗，所以還是把prefix丟給service自己處理strip

```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: panel
  namespace: panel
  annotations: {}
spec:
  rules:
  - host: panel.foo.com
    http:
      paths:
      - backend:
          service:
            name: panel-api
            port:
              number: 80
        path: /api/
        pathType: Prefix
      - backend:
          service:
            name: panel-frontend
            port:
              number: 80
        path: /
        pathType: Prefix
```

# 缺點

走到default backend的時候由於沒有對應的cert

所以會回傳Kubernetes Fake Ingress Controller Certificates

# 附錄: 讓 nginx 看到 external IP

nginx helm values.yaml 加上

```
controller:
  config:                                                                       
    use-proxy-protocol: "true"        
```

haproxy.cfg 修改

```
global      
    log /dev/log local0
    log /dev/log local1 notice  
    daemon
                                                                                                                  
#---------------------------------------------------------------------
# common defaults that all the 'listen' and 'backend' sections will   
# use if not designated in their block
#---------------------------------------------------------------------
defaults            
    mode                    http
    log                     global                                                                                
    option                  httplog                                                                               
    option                  dontlognull                                                                           
    option http-server-close
    option forwardfor       except 127.0.0.0/8                                                                    
    option                  redispatch                                                                            
    retries                 1                                                                                     
    timeout connect         5s
    timeout client          7d
    timeout server          7d
                                                         
#---------------------------------------------------------------------
# apiserver frontend which proxys to the masters
#---------------------------------------------------------------------
frontend apiserver                     
    bind *:8443                                                                                                   
    mode tcp       
    option tcplog
    default_backend apiserver
                                                         
#---------------------------------------------------------------------
# round robin balancing for apiserver                                                                             
#---------------------------------------------------------------------
backend apiserver
    mode tcp             
    option tcp-check
    balance     roundrobin
        server k8s-node1 k8s-node1:6443 check
        server k8s-node2 k8s-node2:6443 check
        server k8s-node3 k8s-node3:6443 check

#---------------------------------------------------------------------
# ingress-http frontend which proxys to the k8s ingress controller
#---------------------------------------------------------------------
frontend ingress-http
    bind *:80                   
    mode tcp                                                                                                      
    option tcplog                                                                                                 
    default_backend ingress-http                                                                                  
                                                         
#---------------------------------------------------------------------                                            
# round robin balancing for ingress-http                                                                          
#---------------------------------------------------------------------                                            
backend ingress-http          
    mode tcp                  
    option tcp-check          
    balance     roundrobin                               
        server k8s-node1 k8s-node1:32080 check send-proxy             
        server k8s-node2 k8s-node2:32080 check send-proxy 
        server k8s-node3 k8s-node3:32080 check send-proxy             
                                                         
#---------------------------------------------------------------------                                            
# ingress-tls frontend which proxys to the k8s ingress controller
#---------------------------------------------------------------------
frontend ingress-tls         
    bind *:443                                           
    mode tcp                                                                                                      
    option tcplog                                                                                                 
    default_backend ingress-tls                                                                                   
                                                         
#---------------------------------------------------------------------
# round robin balancing for ingress-tls
#---------------------------------------------------------------------
backend ingress-tls                          
    mode tcp                                 
    option tcp-check                         
    balance     roundrobin
        server k8s-node1 k8s-node1:32443 check send-proxy             
        server k8s-node2 k8s-node2:32443 check send-proxy         
        server k8s-node3 k8s-node3:32443 check send-proxy             
                                                         
```
