---
layout: post
title: 使用DNS紀錄來自動更新IP白名單
categories: [sys_admin]
description: 被中華電信換IP影響，研究出來的作法
---

為了獲得比較嚴謹的安全性，我們通常可以在防火牆上面設定，只有固定的IP允許存取。

但要更換IP時，就需要去所有機器上更新名單。如果我們可以利用DNS紀錄，來尋找某個網域指向的IP，就可以藉此讓生活更加便利。

我們可以為某個domain新增多個A record，這原本是用來作為round-robin使用，讓用戶端自行隨機挑選IP，因此他會回傳一個IP列表。

例如我們用指令查詢ptt.cc會發現以下結果：

```
$ dig +short ptt.cc
140.112.172.3
140.112.172.5
140.112.172.11
140.112.172.1
140.112.172.4
140.112.172.2
```

## pfsense

pfsense本身就有支援利用FQDN當作IP清單來源，在防火牆的aliases頁面底下，新增對應的IP alias就可以。

Type選擇Hosts，IP or FQDN欄位直接填寫domain name。

如果想要確認結果可以在Diagnostics > Table，找到該alias解出來的IP清單。

## iptables

iptables操作的nftables是一個kernel module，本身不支援透過FQDN解出IP，但我們可以自己寫一個script達成這樣功能。

```
#!/usr/bin/env bash

DYNHOST=ptt.cc
DYNHOST=${DYNHOST:0:28}
DYNIPS=$(host $DYNHOST |cut -f4 -d' ')

for DYNIP in $DYNIPS
do
	echo "Checking..." $DYNIP
	# Exit if invalid IP address is returned
	case $DYNIP in
	0.0.0.0 )
	exit 1 ;;
	255.255.255.255 )
	exit 1 ;;
	esac

	# Exit if IP address not in proper format
	if ! [[ $DYNIP =~ (([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5]) ]]; then
	exit 1
	fi
	echo "OK"
done

# If chain for remote doesn't exist, create it
if ! /sbin/iptables -L $DYNHOST -n >/dev/null 2>&1 ; then
/sbin/iptables -N $DYNHOST >/dev/null 2>&1
fi

# Flush old rules
/sbin/iptables -F $DYNHOST >/dev/null 2>&1

for DYNIP in $DYNIPS
do
	echo "Adding new IP..." $DYNIP
	# Add new IPs
	/sbin/iptables -I $DYNHOST -s $DYNIP -j ACCEPT
done

# Add chain to INPUT filter if it doesn't exist
if ! /sbin/iptables -C INPUT -t filter -j $DYNHOST >/dev/null 2>&1 ; then
/sbin/iptables -t filter -I INPUT -j $DYNHOST
fi
```

之後在crontab加上排程自動更新

```
* * * * * root /root/update_iptables.sh > /var/log/abc.log 2>&1
```

順便也附上我的iptables設定 (未知IP除了80和443一律拒絕存取)

```
iptables -F

# 先確保你的IP已經在允許清單裡面

iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -P INPUT DROP
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
```

一些可能的需求和做法：

- 如果想要連80和443都不開的話，也可以用cloudflare tunnel來提供服務。
- 如果有從陌生IP連線的需求，但都是從自己的裝置連線，可以設定WireGuard或[wg-wasy](https://github.com/wg-easy/wg-easy)來加密和建立連線，安全性會比暴露ssh更高。