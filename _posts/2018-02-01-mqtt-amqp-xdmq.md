---
layout: post
title: MQTT與AMQP對比xdmq的差異
categories:
- 心得
---

前陣子開發[xdmq](https://github.com/xnum/xdmq)時，被問到跟MQTT和AMQP有什麼差異

## MQTT

MQ Telemetry Transport (MQTT) is a lightweight broker-based publish/subscribe messaging protocol

本質上MQTT是一項protocol，而且有幾項特色

- broker-based ([broker and brokerless](http://zeromq.org/whitepapers:brokerless))
- pub/sub model

設計來用於

- Where the network is expensive, has low bandwidth or is unreliable
- When run on an embedded device with limited processor or memory resources

https://public.dhe.ibm.com/software/dw/webservices/ws-mqtt/mqtt-v3r1.html

大多數是應用在IOT

## AMQP

Advanced Message Queuing Protocol

金融業發展出來用於交易所訊息交換的協定

適用於wire-level


這些都屬於一種協定，而另外有基於這些協定的[broker](https://en.wikipedia.org/wiki/Message_broker)實作，來符合這些協定

而xdmq實作了一個message broker，內部以raft作為核心，對於訊息的protocol則未有嚴謹規範
