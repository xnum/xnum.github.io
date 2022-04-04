---
layout: post
title: 使用libuv裡的Queue儲存資料
categories:
- UNIX
---

正如Linux kernel裡有rbtree、UNIX系列有sys/queue.h，libuv裡也有[queue](https://github.com/libuv/libuv/blob/v1.x/src/queue.h)作為資料結構

相較於sys/queue而言更加簡潔易用，也沒有license問題，作為list or queue(可以抄來用)的終極方案當仁不讓

```c
#include <stdio.h>
#include <stdlib.h>

#include "queue.h"

typedef struct data_s {
    char msg[256];
    QUEUE queue;
} data_t;

int main()
{
    QUEUE head;
    QUEUE_INIT(&head);

    for(int i = 0; i < 5; ++i) {
        data_t *node = calloc(1, sizeof(data_t));
        sprintf(node->msg, "%d", i+10000);
        QUEUE_INSERT_HEAD(&head, &node->queue); // or INSERT_TAIL
    }

    QUEUE *it;
    QUEUE_FOREACH(it, &head) {
        data_t *node = QUEUE_DATA(it, data_t, queue);
        printf("%s\n", node->msg);
    }

    puts("=======");

    QUEUE_REMOVE(QUEUE_HEAD(&head));

    QUEUE_FOREACH(it, &head) {
        data_t *node = QUEUE_DATA(it, data_t, queue);
        printf("%s\n", node->msg);
    }

    return 0;
}
```
