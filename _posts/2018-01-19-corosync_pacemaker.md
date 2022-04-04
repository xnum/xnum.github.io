---
layout: post
title: Ubuntu架設corosync+pacemaker達成自訂服務切換
categories:
- sys_admin
---

# 目的

建置雙node Active/Passive HA叢集

- Ubuntu 17.10
- Corosync
- Pacemaker
- echo server

# 硬體配置

ms1    10.130.51.51
ms2    10.142.51.52

# 架設corosync + pacemaker

安裝軟體

`sudo apt-get install pacemaker`

產生金鑰用

`sudo apt-get install haveged`

ms1產生金鑰

`sudo corosync-keygen`

把`/etc/corosync/authkey`複製同份到ms2，權限400 root:root

## /etc/corosync/corosync.conf

設定有點多，我參考[C.2.1. Enabling Pacemaker For Corosync 2.x](http://clusterlabs.org/pacemaker/doc/en-US/Pacemaker/1.1/html/Pacemaker_Explained/_enabling_pacemaker.html#_enabling_pacemaker_for_corosync_2_emphasis_x_emphasis)

如下，採用udp單播連線

```
totem {
        version: 2

        cluster_name: debian

        token: 3000

        token_retransmits_before_loss_const: 10

        clear_node_high_bit: yes

        secauth: off

        crypto_cipher: none

        crypto_hash: none

        transport: udpu

        interface {
                ringnumber: 0
                bindnetaddr: 10.130.51.51
                broadcast: yes
                mcastport: 5405
                ttl: 1
        }
}

logging {
        fileline: off
        to_stderr: no
        to_logfile: no
        to_syslog: yes
        syslog_facility: daemon
        debug: off
        timestamp: on
        logger_subsys {
                subsys: QUORUM
                debug: off
        }
}

nodelist {
        node {
                ring0_addr: 10.130.51.51
                nodeid: 1
        }
        node {
                ring0_addr: 10.130.51.52
                nodeid: 2
        }
}

quorum {
        provider: corosync_votequorum
        two_node: 1
}

service {
  name: pacemaker
  ver: 1
}

```

`/etc/default/corosync`
START=yes

## corosync服務啟動

安裝好後corosync就被啟動了，要讓他重啟
`service corosync restart`

就能看到對方了

```
root@ms1:~# corosync-cmapctl | grep members
runtime.totem.pg.mrp.srp.members.1.config_version (u64) = 0
runtime.totem.pg.mrp.srp.members.1.ip (str) = r(0) ip(10.130.51.51)
runtime.totem.pg.mrp.srp.members.1.join_count (u32) = 1
runtime.totem.pg.mrp.srp.members.1.status (str) = joined
runtime.totem.pg.mrp.srp.members.2.config_version (u64) = 0
runtime.totem.pg.mrp.srp.members.2.ip (str) = r(0) ip(10.130.51.52)
runtime.totem.pg.mrp.srp.members.2.join_count (u32) = 1
runtime.totem.pg.mrp.srp.members.2.status (str) = joined
```

## pacemaker服務啟動

接著執行pacemaker相關設定

```
update-rc.d pacemaker defaults 20 01
service pacemaker start
```

就能在pacemaker看到node串起來

```
root@ms1:~# crm status
Stack: corosync
Current DC: ms1 (version 1.1.16-94ff4df) - partition with quorum
Last updated: Fri Jan 19 02:55:28 2018
Last change: Fri Jan 19 02:52:19 2018 by hacluster via crmd on ms1

2 nodes configured
0 resources configured

Online: [ ms1 ms2 ]

No resources

root@ms2:/etc/corosync# crm status
Stack: corosync
Current DC: ms1 (version 1.1.16-94ff4df) - partition with quorum
Last updated: Fri Jan 19 02:55:23 2018
Last change: Fri Jan 19 02:54:35 2018 by hacluster via crmd on ms1

2 nodes configured
0 resources configured

Online: [ ms1 ms2 ]

No resources
```

作2nodes特殊設定

```
root@ms2:/etc/corosync# crm configure property stonith-enabled=false
root@ms2:/etc/corosync# crm configure property no-quorum-policy=ignore
```

# 新增資源

## 實驗用的簡單service

https://github.com/xnum/echo_service

`sudo apt install libuv1-dev`
`make && sudo make install`

設定資源

` crm configure primitive ha-echod lsb:echod op monitor interval=10s`
`crm status`

設定

```
root@ms1:~/echo# crm config show
node 1: ms1
node 2: ms2
primitive ha-echod lsb:echod \
        op start interval=0s timeout=5s \
        op stop interval=0s timeout=5s \
        op monitor interval=10s on-fail=standby \
        meta target-role=Started migration-threshold=3 failure-timeout=15s
property cib-bootstrap-options: \
        have-watchdog=false \
        dc-version=1.1.16-94ff4df \
        cluster-infrastructure=corosync \
        cluster-name=debian \
        stonith-enabled=false \
        no-quorum-policy=ignore \
        last-lrm-refresh=1516341959
```

## 加上Virtual IP

`crm configure primitive VIP ocf:IPaddr2 params ip=10.130.51.1 nic=eth1 op monitor interval=10s`

嘗試`ping 10.130.51.1`

把兩個資源綁定在一起

`crm configure group ha-group VIP ha-echod`

```
Stack: corosync
Current DC: ms1 (version 1.1.16-94ff4df) - partition with quorum
Last updated: Fri Jan 19 07:11:21 2018
Last change: Fri Jan 19 07:11:18 2018 by root via cibadmin on ms1

2 nodes configured
2 resources configured

Online: [ ms1 ms2 ]

Active resources:

 Resource Group: ha-group
     VIP        (ocf::heartbeat:IPaddr2):       Started ms2
     ha-echod   (lsb:echod):    Started ms2
```

最後設定

```
ms1: ms
ms2: ms
primitive VIP IPaddr2 \
        params ip=10.130.51.1 nic=eth1 \
        op monitor interval=10s
primitive ha-echod lsb:echod \
        op start interval=0s timeout=5s \
        op stop interval=0s timeout=5s \
        op monitor interval=10s on-fail=standby \
        meta target-role=Started migration-threshold=3 failure-timeout=15s
group ha-group VIP ha-echod
property cib-bootstrap-options: \
        have-watchdog=false \
        dc-version=1.1.16-94ff4df \
        cluster-infrastructure=corosync \
        cluster-name=debian \
        stonith-enabled=false \
        no-quorum-policy=ignore

```

嘗試換node啟動

`crm node standby ms2`


http://linuxlasse.net/linux/howtos/Pacemaker_and_Corosync_HA_-_2_Node_setup

https://www.digitalocean.com/community/tutorials/how-to-create-a-high-availability-setup-with-corosync-pacemaker-and-floating-ips-on-ubuntu-14-04
