---
layout: post
title: ksh shell functions以及它的隱藏陷阱
categories:
- UNIX
---

在debug ksh的shell sscript時，發現一些隱藏設定，跟bash、zsh不同，以為行為一樣的情況下就容易踩到地雷

經過一些測試後完整解釋了所有現象，以下是一些ksh一些特別之處..

## options

set -x -e等，在function內不會繼承設定

因此如set -x，將不會列印fnuction內執行什麼指令

```
set -x

function swp {
        tmp=$1
        a=$2
        b=$tmp
}

a=1
b=2
echo $a $b
swp $a $b
echo $a $b $tmp
```

```
$ ksh k.sh
+ a=1
+ b=2
+ echo 1 2
1 2
+ swp 1 2
+ echo 2 1 1
2 1 1
```

## Traps

同樣的Traps在function內也不被繼承

```
trap 'echo "Run $LINENO"' DEBUG

function f {
        pwd
}

cd /opt
f
cd /
f
```

```
$ ksh j.sh
Run 7
/opt
Run 8
Run 9
/
Run 10
Run 10
```

但是trap會在function外產生作用

function沒有return 0被視為發生錯誤

```
trap 'echo "Fatal"; exit' ERR

function f {
        echo "Return Bad Status"
        return 5
}

echo "Hello"
f
echo "exited gracefully"
```

```
$ ksh n.sh
Hello
Return Bad Status
Fatal
```

## return value

沒有return value時，會返回最後一條執行的指令

```
trap 'echo "Fatal"; exit' ABRT

function f {
        echo "Run ./abort and it will raise SIGABRT"
        ./abort
}

echo "Hello"
f
echo $?
echo "exited gracefully"
```

特別的是ksh把該指令的訊號也當成自己的訊號

所以當最後一條指令出錯，該function會被視為發出了該訊號

ksh就會自殺...

```
$ ksh n.sh
Hello
Run ./abort and it will raise SIGABRT
n.sh[2]: 9176 中斷(核心傾印)
Fatal
```

在bash和zsh上都不會有這種行為

```
$ bash n.sh
Hello
Run ./abort and it will raise SIGABRT
中斷 (core dumped)
134
exited gracefully

$ zsh n.sh
n.sh:trap:1: undefined signal: ABRT
Hello
Run ./abort and it will raise SIGABRT
134
exited gracefully
```

ref: 
ksh trap: 
https://docstore.mik.ua/orelly/unix3/korn/ch08_04.htm
https://www.ibm.com/developerworks/aix/library/au-usingtraps/index.html
ksh shell functions:
https://www.ibm.com/support/knowledgecenter/en/ssw_aix_71/com.ibm.aix.osdevice/korn_shell_func.htm

