---
layout: post
title: Linux開啟coredump設定
categories: Linux
---

設定pattern

```
echo "/tmp/cores/core.%e.%p.%h.%t" > /proc/sys/kernel/core_pattern
```

開啟ulimit

```
/etc/security/limits.conf

*  soft  core  unlimited
```

程式內開啟

```
#include <sys/resource.h>

void enable_coredump()
{
    struct rlimit core_limits;
    core_limits.rlim_cur = core_limits.rlim_max = RLIM_INFINITY;
    setrlimit(RLIMIT_CORE, &core_limits);
}
```

測試

```
kill -s SIGSEGV $$
```
