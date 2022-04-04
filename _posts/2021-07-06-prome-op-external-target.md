---
layout: post
title: prometheus operator scrape external target for HAProxy
date: 2021-07-06 12:00 +0800
categories: k8s
---

haproxy編譯時加入prometheus-exporter

haproxy.cfg加入

```
frontend stats
 mode http
 timeout client 30s
 bind *:8404
 option http-use-htx
 http-request use-service prometheus-exporter if { path /metrics }
 stats enable
 stats uri /stats
 stats refresh 10s
```

確認正常作用

`curl http://localhost:8404/metrics`

新增一個沒有PodSelector的Service，用來讓我們手動指定IP

Service和Endpoints的metadata保持相同，並在Endpoints的addresses裡面加入一至多個IP

```
kind: Service
apiVersion: v1
metadata:
  name: external-haproxy-exporter
  labels:
    app: external-haproxy-exporter
spec:
  type: ClusterIP
  ports:
  - name: metrics
    port: 8404
    protocol: TCP
    targetPort: 8404
---
apiVersion: v1
kind: Endpoints
metadata:
  name: external-haproxy-exporter
  labels:
    app: external-haproxy-exporter
subsets:
  - addresses:
    - ip: 10.168.101.201
      nodeName: k8s-master1
    - ip: 10.168.101.202
      nodeName: k8s-master2
    - ip: 10.168.101.203
      nodeName: k8s-master3
    ports:
      - name: metrics
        port: 8404
        protocol: TCP
```

讓ServiceMonitor的selector能match Service

並relabel方便之後寫alert

```
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  labels:
    app: external-haproxy-exporter
  name: external-haproxy-exporter
  namespace: monitoring
spec:
  endpoints:
  - port: metrics
    relabelings:
    - action: replace
      sourceLabels:
      - __meta_kubernetes_endpoint_node_name
      regex: (.*)
      targetLabel: kubernetes_node
      replacement: $1
  namespaceSelector:
    matchNames:
    - monitoring
  selector:
    matchLabels:
      app: external-haproxy-exporter
```

ref

https://kubernetes.io/docs/reference/kubernetes-api/service-resources/endpoints-v1/
https://docs.openshift.com/container-platform/4.4/rest_api/monitoring_apis/servicemonitor-monitoring-coreos-com-v1.html
https://prometheus.io/docs/prometheus/latest/configuration/configuration/#endpoints
https://devops.college/prometheus-operator-how-to-monitor-an-external-service-3cb6ac8d5acb
https://jpweber.io/blog/monitor-external-services-with-the-prometheus-operator/
https://prometheus.io/docs/prometheus/latest/configuration/configuration/#relabel_config
