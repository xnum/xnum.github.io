---
layout: post
title: libuv的uv_fs_poll和uv_fs_event比較
categories:
- network programming
---

fs-poll是不相依平台、基於polling機制的實作，只能監測單一檔案

內部使用uv_timer_t來完成[uv_fs_poll_start原始碼](https://github.com/libuv/libuv/blob/v1.x/src/fs-poll.c#L56)

呼叫使用者程式碼的[關鍵function](https://github.com/libuv/libuv/blob/v1.x/src/fs-poll.c#L172)

fs-event則是平台相依的，一般可用來監控某個資料架下的所有檔案，部分OS支援遞迴性監控

相關定義可在[Makefile.am](https://github.com/libuv/libuv/blob/v1.x/Makefile.am#L392)找到

- 在Linux使用[inotify](http://man7.org/linux/man-pages/man7/inotify.7.html)
- 在OSX使用[fsevent](https://developer.apple.com/library/content/documentation/Darwin/Conceptual/FSEvents_ProgGuide/UsingtheFSEventsFramework/UsingtheFSEventsFramework.html)
- WINNT使用[ReadDirectoryChangesW](https://msdn.microsoft.com/zh-tw/library/windows/desktop/aa365465(v=vs.85).aspx)
- 在BSD使用[kqueue](https://developer.apple.com/library/content/documentation/Darwin/Conceptual/FSEvents_ProgGuide/KernelQueues/KernelQueues.html)

由於uv只提供兩種events `UV_RENAME` 和 `UV_CHANGE` ，推測除了重新命名以外都是CHANGE事件

此外兩者最大不同為callback不一樣，poll回傳stat_t結構，event回傳事件

雖然events直接使用kernel提供的功能，且為事件驅動，顯然較高效

poll並不見得就比較heavy，但latency會受到polling interval所限制。
