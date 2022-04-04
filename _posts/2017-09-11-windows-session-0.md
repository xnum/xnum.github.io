---
layout: post
title: windows服務與 session 0
categories: 
- windows programming
---

Windows的服務程式在Vista開始

與使用者程式分開，獨立在session 0執行

如此一來服務就無法直接與使用者桌面的sessions互動

即無法使用PostMessage和SendMessage傳遞訊息

ref: [Service Changes for Windows Vista](https://msdn.microsoft.com/en-us/library/windows/desktop/bb203962(v=vs.85).aspx)

---

但服務仍然有程式間通訊的需求

必須透過特定寫法實作，如：
 
- WTSSendMessage (用途即MessageBox)
- RunProcessAsUser (在該使用者session執行一個child process)
- IPCs
  - Events
  - Named Pipes
  - Mailslots
  - Memory-Mapped files
  - Sockets

根據不同需求來選用不同寫法

ref: [Application Compatibility – Session 0 Isolation](https://blogs.technet.microsoft.com/askperf/2007/04/27/application-compatibility-session-0-isolation/)

---

IPC通常會創建一個kernel object來進行操作，其中需要一個security attributes的參數

無獨有偶在使用RunProcessAsUser也需要這樣一個參數

ref: [穿透Session 0 隔离（二）(WTSSendMessage/RunProcessAsUser)](http://www.cnblogs.com/gnielee/archive/2010/04/08/session0-isolation-part2.html)

在Session 0執行的程式為SYSTEM帳號權限，而security attributes使用預設設定(傳NULL)時

> The ACLs in the default security descriptor for a named pipe grant full control to the LocalSystem account, administrators, and the creator owner. They also grant read access to members of the Everyone group and the anonymous account.

則只有同樣擁有admin才能完整存取，否則只能讀

ref: [CreateNamedPipe function](https://msdn.microsoft.com/zh-tw/library/windows/desktop/aa365150(v=vs.85).aspx)

但是反過來由其他session當write end，服務程式當read end就可行

回到正題，對於security attributes較好的設定是利用[well-known SIDs](https://msdn.microsoft.com/zh-tw/library/windows/desktop/aa379649(v=vs.85).aspx)指定允許full access的對象

使用的方式[在此](https://www.experts-exchange.com/questions/23117867/Add-write-access-for-'everyone'-to-named-pipe-ACL.html)

而我的選擇是直接將DACL設為NULL

在security attributes的屬性中，DACL代表可存取控制列表，每個節點代表一個允許的對象和權限

但DACL為NULL時，則Everyone都可以得到full access control

[The SECURITY_ATTRIBUTES struct and CreateNamedPipe()](https://stackoverflow.com/questions/38412919/the-security-attributes-struct-and-createnamedpipe)

---

Events也需要相同的權限設定方式

[VS与Win7共舞：系统服务的Session 0隔离](http://tech.it168.com/a2009/0923/736/000000736809_all.shtml)

[Memory mapped file](http://blog.darkthread.net/post-2017-07-05-about-shared-memory.aspx)就不一樣了

這部分我並未做嘗試
