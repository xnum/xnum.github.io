---
layout: post
title: 2023年維護雜記
categories: [sys_admin]
---

### dracut 沒 include 到 LVM module 開機失敗

gentoo要USE FLAG在LVM2 +lvm才會build出/sbin/lvm

繼而讓dracut偵測到的樣子

要仔細檢查dracut的output才行

`lsinitrd` 也可以檢查是否有include到module

---

### haproxy 2.7.2 啟動失敗

http-use-htx 選項被移除 直接把這行從config裡面刪除

---

### mssql crash after kernel upgrade to 6.1

死亡訊息：

```
This program has encountered a fatal error and cannot continue running.
The following diagnostic information is available:

       Reason: 0x00000003
      Message: mappedBase == address
   Stacktrace: 0000556cd10abd55 0000556cd10c6f5c 0000556cd10c6c76
               0000556cd10bbd84 0000556cd10bbc91 0000556cd10628d3
      Process: 8 - sqlservr
       Thread: 110 (application thread 0x1188)
  Instance Id: 7d7c20ed-7e44-45ef-a612-8bb47aea79e3
     Crash Id: 8eabb17b-0eb6-477a-bdf6-a25cf2d0771a
  Build stamp: 7d599fe53e35b5a1b0c8a5e4185d8b7334e01a8c5fa77540415502a85f37ef27

Capturing core dump and information...
No journal files were found.
No journal files were found.
Attempting to capture a dump with paldumper
Core dump and information are being compressed in the background. When
complete, they can be found in the following location:
  /var/opt/mssql/log/core.sqlservr.01_25_2023_13_58_43.8.tbz2
```

不確定成因，猜測會造成影響的只有kernel，
[官方給的指引](https://learn.microsoft.com/en-us/troubleshoot/sql/linux/core-dump-rhel-7-4-run-mssql-conf)也像是kernel，雖然試過完全沒用

升級到2022版就解決了，幸好不用退kernel版本

直接從2017升上2022會觸發assertion failed崩潰，但先退回2019跑一次以後再改成2022就可以順利執行，謎一般的升級機制...

---

### pfsense slave 的 TLS 憑證過期了 HTST 導致連不進去 web ui

老問題了，重啟web ui解決

雖然master的ACME會去更新憑證，也會sync到slave上面，但必須重新啟動才會換掉

crontab加一個 `/etc/rc.restart_webgui`

---

### ubuntu PUBKEY issue

默默地又過期了，22.04上的key管理有點改變，只好修了

親測kubeadm kubelet kubectl這三板斧的apt source就用下面這個

```
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
```

ref.
https://blog.zeroplex.tw/2022/10/15/build-kuberenetes-cluster-on-ubuntu-22-04/
https://zhuanlan.zhihu.com/p/507673339

---

### ubuntu upgrade to 22.04

也不算甚麼大問題

kubeadm kubelet hold版本以後因為沒有全部更新到最新版 被擋住不能更新

也可以把apt source刪掉

不過20.04還可以用到2025年 乾脆等k8s 1.26多幾個版本號再一次更新上去吧

---

### gentoo upgrade world

從2022年初升過來

確定portage超過3.0.20，個別套件升到下面這個版本，就可以跳到最新進度一次編world了


```
equery list perl python portage glibc gcc libxcrypt libcrypt

 * Searching for perl ...
[IP-] [  ] dev-lang/perl-5.36.0-r2:0/5.36

 * Searching for python ...
[I--] [??] dev-lang/python-3.9.10-r1:3.9
[IP-] [  ] dev-lang/python-3.10.9:3.10

 * Searching for portage ...
[I--] [??] sys-apps/portage-3.0.30-r1:0

 * Searching for glibc ...
[IP-] [  ] sys-libs/glibc-2.36-r7:2.2

 * Searching for gcc ...
[I--] [??] sys-devel/gcc-11.2.1_p20220115:11

 * Searching for libxcrypt ...
[I--] [??] sys-libs/libxcrypt-4.4.27:0/1

 * Searching for libcrypt ...
[IP-] [  ] virtual/libcrypt-2:0/2
```

---

### RAID1 grub-install failed

說要指定disk甚麼的，還是加個--removable省事

```
grub-mkconfig -o /boot/grub/grub.cfg
mount /boot/efi
grub-install --target=x86_64-efi --efi-directory=/boot/efi --removable
```

---

### systemctl restart kubelet failed, require docker.service

每次重裝完kubelet，就要改一次...

```
sed -i 's/docker/crio/g' /usr/lib/systemd/system/kubelet.service &amp;&amp; \
systemctl daemon-reload &amp;&amp; \
systemctl restart kubelet
```

---

### 指定版本安裝的cheatsheet

ubuntu

```
apt-cache madison kubelet

apt-mark unhold kubelet kubectl kubeadm &amp;&amp; \
apt-get update &amp;&amp; apt-get install -y kubelet=1.25.6-00 kubectl=1.25.6-00 kubeadm=1.25.6-00 &amp;&amp; \
apt-mark hold kubelet kubectl kubeadm
```

gentoo

```
equery y kubelet

emerge --ask =kubeadm-1.24.10 =kubelet-1.24.10
```

---

### ASUS BMC 登入後顯示 Session Expired

莫名的問題，猜測是他的NTP不知道歪去哪裡

安裝ipmitool以後從作業系統重開他

```
ipmitool mc reset cold
ipmitool lan print
```

