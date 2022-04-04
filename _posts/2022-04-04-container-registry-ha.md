---
layout: post
title: container registry 異地備援設計
categories: [sys_admin]
description: 用 harbor + gcr 混合架構架設高可用的 registry
keywords: k8s
---

## 前情提要

由於 kubernetes 依賴於一個穩健的 registry ，一旦失效就會噴發一堆 ImagePullBackOffError，

一般使用的 docker.io 在大量 deploy 的時候會很快打到 free plan rate limit，

所以我們先前就已經在每個 region 架設 registry mirror 來減緩。

mirror 雖然可以延緩 registry offline 時馬上爆炸，

但是 mirror 模式並不允許直接對其進行 container image push，

這造成我們執行 build and deploy 時仍要等到 registry 修復後才能執行。

我們現有的 private registry 架設在一台 synology 的 NAS 上，今年陸續發生了NAS當機、reverse proxy爛線等等奇怪的毛病

因此決定在架構上面進行加強來彌補 registry 掛點時系統搖搖欲墜的問題

## 架構修改

使用雲端服務需要費用，機房網路流量也需要費用，所以在設計上沒有直接讓 gcr.io 作為主要站點

另外也是從 gcr.io 要同步新 push 的 image 沒有 event trigger 的方法，只能用 polling and sync 的方式做

我們最後的方案是一個使用 harbor 搭建的地端 registry，搭配 gcr.io 作為備用地址

![](/images/posts/2022-04-04/1.png)

harbor 可以新增 webhook ，在有 image push 上來的時候進行通知

只要再另外寫個小程式 rewrite url 之後 push 到 gcr 就可以完成兩個 registry 的同步

### mirror

在每個 region 我們都需要架設兩個 mirror ，一個從 harbor pull，另一個從 gcr pull

因為 image 我們都沒有開放 public access，所以兩個 mirror 需要使用各自的 credential 登入

這邊直接用 static pod 架設在 kubernetes worker node 上

下面是 gcr.io 的範例

pod.yaml

```
apiVersion: v1
kind: Pod
metadata:
  name: mirror-registry-asia-gcr-io
  namespace: registry
  labels:
    app: registry
spec:
  containers:
  - command:
    - /bin/registry
    - serve
    - /config.yml
    image: docker.io/library/registry:2.7.1
    imagePullPolicy: IfNotPresent
    livenessProbe:
      failureThreshold: 3
      httpGet:
        path: /
        port: 35007
        scheme: HTTP
      periodSeconds: 10
      successThreshold: 1
      timeoutSeconds: 1
    name: registry-asia-gcr-io-mirror
    ports:
    - containerPort: 35007
      protocol: TCP
    readinessProbe:
      failureThreshold: 3
      httpGet:
        path: /
        port: 35007
        scheme: HTTP
      periodSeconds: 10
      successThreshold: 1
      timeoutSeconds: 1
    volumeMounts:
    - mountPath: /var/lib/registry
      name: data
    - mountPath: /config.yml
      name: config
  hostNetwork: true
  volumes:
  - hostPath:
      path: /hdd_raid10/asia-gcr-io-registry
      type: DirectoryOrCreate
    name: data
  - hostPath:
      path: /hdd_raid10/config.yaml
      type: FileOrCreate
    name: config
```

config.yaml

```
version: 0.1
log:
  fields:
    service: registry
storage:
  cache:
    blobdescriptor: inmemory
  filesystem:
    rootdirectory: /var/lib/registry
http:
  addr: :35007
  headers:
    X-Content-Type-Options: [nosniff]
health:
  storagedriver:
    enabled: true
    interval: 10s
    threshold: 3
proxy:
  remoteurl: https://asia.gcr.io
  username: _json_key
  password: |-
    <content of service account json key>
```

### client

由於 mirror 已經設定了登入用的密碼，client side 就不需要再設定

但是 client side 需要對 url 進行 rewrite，以便從 mirror pull image

cri-o 的設定方式如下

```
cat << EOF > /etc/containers/registries.conf.d/001-mirror.conf
[[registry]]
  prefix = "cr.example.io/library"
  location = "cr.example.io/library"

  # mirror of cr.example.io self-hosting
  [[registry.mirror]]
    insecure = true
    location = "10.10.100.1:35007/library"

  # mirror of asia.gcr.io cloud hosting
  [[registry.mirror]]
    insecure = true
    location = "10.10.100.2:35007/example-project"
EOF
```

也可以再新增直接指向 gcr.io 不經過 mirror 的欄位，但是就需要設定 imagePullSecret 才能作用了
