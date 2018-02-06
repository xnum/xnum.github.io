---
layout: post
title: UDP multicast效能調校 - kernel參數
tags:
- network programming
---

以下為實驗用程式，測試在sender瘋狂灑封包下，recver可以成功收到多少封包 (一定會掉的)

## recv

```python
import socket
import time

def count(sock, buf_size=1024):
    pac_count = {}
    try:
        while True:
            data, sender_addr = sock.recvfrom(buf_size)
            l = len(data)
            if pac_count.has_key(l):
                pac_count[l] += 1
            else:
                pac_count.setdefault(l, 0)
    except:
        print
        byte=0
        for k, v in pac_count.iteritems():
            print k, v
            byte += k * v
        return byte


def recv(port=50000, addr="239.192.1.100"):
    """recv([port[, addr[,buf_size]]]) - waits for a datagram and returns the data."""

    # Create the socket
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

    # Set some options to make it multicast-friendly
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    try:
            s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEPORT, 1)
    except AttributeError:
            pass # Some systems don't support SO_REUSEPORT
    s.setsockopt(socket.SOL_IP, socket.IP_MULTICAST_TTL, 2)
    s.setsockopt(socket.SOL_IP, socket.IP_MULTICAST_LOOP, 1)

    # Bind to the port
    s.bind(('', port))

    # Set some more multicast options
    intf = socket.gethostbyname(socket.gethostname())
    s.setsockopt(socket.SOL_IP, socket.IP_MULTICAST_IF, socket.inet_aton(intf))
    s.setsockopt(socket.SOL_IP, socket.IP_ADD_MEMBERSHIP, socket.inet_aton(addr) + socket.inet_aton(intf))

    # Receive the data, then unregister multicast receive membership, then close the port
    start = time.time()
    byte = count(s)
    end = time.time()
    print(str((end - start)) + "s")
    print(str(byte/(end-start)/1024) + "Kbyte/s")

    s.setsockopt(socket.SOL_IP, socket.IP_DROP_MEMBERSHIP, socket.inet_aton(addr) + socket.inet_aton('0.0.0.0'))
    s.close()
    return

def main():
    recv()

if __name__ == "__main__":
    main()
```

## send

```python
import socket

UDP_IP = "239.192.1.100"
UDP_PORT = 50000
MESSAGE = "Hello, World!"*10

print "UDP target IP:", UDP_IP
print "UDP target port:", UDP_PORT
print "message:", MESSAGE

sock = socket.socket(socket.AF_INET, # Internet
                             socket.SOCK_DGRAM) # UDP
sock.setsockopt(socket.SOL_IP, socket.IP_MULTICAST_TTL, 2)
sock.setsockopt(socket.SOL_IP, socket.IP_MULTICAST_LOOP, 1)
while True:
    sock.sendto(MESSAGE, (UDP_IP, UDP_PORT))
```

## 執行方式

分別在不同機器上

```
python send.py
timeout -s INT 30 python recv.py 
```

## 原生Ubuntu 17.10 kernel參數

在完全不修改參數的情況下，執行結果(跑三次取平均)為

51856包/30s

## iptables bypass

`sudo iptables -t raw -I PREROUTING 1 -p udp --dport 50000 -j NOTRACK `

52861包/30s

## busy_read + busy_poll

在`/proc/sys/net/core`

數值原本為0，都設為50

52216包/30s

## wmem_default + wmem_max

在`/proc/sys/net/core`

原本為229376，增加到26214400

52122包/30s

## udp_mem + udp_wmem_min + udp_rmem_min

原本為22314   29755   44628 、 4096 、 4096
修改為65536 137012 500000、 65536 、 65536 (隨便給的)

52983包/30s

https://www.kernel.org/doc/Documentation/sysctl/net.txt

看來單process單純呼叫syscall極限在每秒1700包左右..待續
