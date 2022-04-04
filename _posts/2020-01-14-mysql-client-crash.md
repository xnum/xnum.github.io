---
layout: post
title: libmysqlclient crash debug
date: 2020-01-14 18:58 +0800
categories:
- DB
---

現象：

程式執行若干小時後突然出現一行便crash

```
missing DBUG_RETURN or DBUG_VOID_RETURN macro in function "?func"
```

Google一下大部分訊息沒有幫助，直接找source code

libmysqlclient是MySQL的C API，包含在MySQL Server的source code中

大概翻過後發現是debug的錯誤訊息，滿足條件於是exit自爆

```
void _db_return_(uint _line_, struct _db_stack_frame_ *_stack_frame_)
{
  int save_errno=errno;
  uint _slevel_= _stack_frame_->level & ~TRACE_ON;
  CODE_STATE *cs;
  get_code_state_or_return;

  if (cs->framep != _stack_frame_)
  {
    char buf[512];
    my_snprintf(buf, sizeof(buf), ERR_MISSING_RETURN, cs->func);
    DbugExit(buf);
  }
```

在docker compose yaml裡加上core dump設定

```
    privileged: true
    ulimits:
      core: -1
    volumes:
      - ./cores:/tmp/cores
```

然後過一陣子順利取得了core檔，丟進gdb印出stack

```
#0  0x00007f1308fee881 in abort () from /lib64/libc.so.6
#1  0x00007f1308639401 in DbugExit () from /usr/lib64/libmysqlclient.so.18
#2  0x00007f130863b36c in _db_return_ () from /usr/lib64/libmysqlclient.so.18
#3  0x00007f1308631afc in mysql_reconnect () from /usr/lib64/libmysqlclient.so.18
#4  0x00007f1308631f4d in cli_advanced_command () from /usr/lib64/libmysqlclient.so.18
#5  0x00007f130862cfef in mysql_send_query () from /usr/lib64/libmysqlclient.so.18
#6  0x00007f130862d0ca in mysql_real_query () from /usr/lib64/libmysqlclient.so.18
#7  0x00007f130cb834d2 in soci::mysql_statement_backend::execute(int) () from /usr/local/lib64/libsoci_mysql.so.4.0
#8  0x00007f130cb83c2a in soci::mysql_statement_backend::prepare_for_describe() () from /usr/local/lib64/libsoci_mysql.so.4.0
#9  0x00007f130c91e314 in soci::details::statement_impl::describe() () from /usr/local/lib64/libsoci_core.so.4.0
#10 0x00007f130c91d186 in soci::details::statement_impl::execute(bool) () from /usr/local/lib64/libsoci_core.so.4.0
```

嗯，不知道為什麼，找找看文件 https://dev.mysql.com/doc/refman/8.0/en/c-api-threaded-clients.html

找到了一些有趣的東西

```
When you call mysql_init(), MySQL creates a thread-specific variable for the thread that is used by the debug library (among other things). If you call a MySQL function before the thread has called mysql_init(), the thread does not have the necessary thread-specific variables in place and you are likely to end up with a core dump sooner or later. To avoid problems, you must do the following:

Call mysql_library_init() before any other MySQL functions. It is not thread-safe, so call it before threads are created, or protect the call with a mutex.

Arrange for mysql_thread_init() to be called early in the thread handler before calling any MySQL function. (If you call mysql_init(), it calls mysql_thread_init() for you.)

In the thread, call mysql_thread_end() before calling pthread_exit(). This frees the memory used by MySQL thread-specific variables.

The preceding notes regarding mysql_init() also apply to mysql_connect(), which calls mysql_init().
```

看起來有可能是因為某些thread沒有init。

因為設計上通常會使用Connection Pool避免反覆建立連線，如果有threade拿到連線直接送出查詢，而沒有先執行過`mysql_connect()`就可能炸掉了

解法有二

1. 編譯成Release mode，把相關debug功能關掉，眼不見為淨

2. 乖乖為每個thread call init.. 但是有些thread是gRPC管理的，沒辦法hook，會比較難搞
