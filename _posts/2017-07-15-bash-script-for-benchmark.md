---
layout: post
title: bash shell script 高精度時間測量範例
categories: ['shell script']
---

想測量傳輸效能，檔案傳輸完後程式不會結束，改用diff比對

使用`time`只能取到秒，改用`date`可以取到ns

```bash
#!/usr/bin/env bash

function waitTransfer()
{
    while true
    do
        diff -r --binary --brief $1 $1_dest
        if [ $? -eq 0 ]; then
            break
        fi
        sleep 0.01
    done
}

SIZE_TYPE='file1M file5M file50M'
for sizeType in $SIZE_TYPE
do
    mkdir ${sizeType}_dest
    echo 'Run  --- ' $sizeType

    begin=$(date +%s%N)


    # do Something

    waitTransfer $sizeType


    end=$(date +%s%N)
    elapsed=$((end - begin))
    echo 'Done --- ' $sizeType
    bc -l <<< "$elapsed / 1000000000"

    echo "======================"
    rm -rf ${sizeType}_dest
done


exit

```
