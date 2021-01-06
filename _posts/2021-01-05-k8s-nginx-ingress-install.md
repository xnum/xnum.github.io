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

# 讓 nginx 看到 external IP

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
