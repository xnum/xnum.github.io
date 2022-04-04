---
layout: post
title: 在沒有 clang 的環境使用 clang-tidy
date: 2020-10-21 15:36 +0800
categories: C/C++
---

下載靜態 binary (因為我懶得裝整套clang)

https://github.com/muttleyxd/clang-tools-static-binaries/releases

使用 cmake 參數 `-DCMAKE_EXPORT_COMPILE_COMMANDS=ON`

產生出`compile_commands.json`

偷窺 gcc default include path

`echo | gcc -E -Wp,-v -`

把參數幹過來

```
clang-tidy \
    -p=/src/build \
    --extra-arg-before='-I/usr/lib/gcc/x86_64-pc-linux-gnu/9.3.0/include' \
    --extra-arg-before='-I/usr/lib/gcc/x86_64-pc-linux-gnu/9.3.0/include-fixed' \
    --extra-arg-before='-I/usr/local/include' \
    --extra-arg-before='-I/usr/include' \
    /src/*.cxx`
```
