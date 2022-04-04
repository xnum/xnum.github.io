---
layout: post
title: Windows Named Pipe
categories:
- windows programming
---

補充上次的session 0問題，呼叫named pipe來達成通訊需求

對需要雙向傳輸訊息時非常有用。

{% highlight c %}
/* pipe server */
#include <stdio.h>
#include <windows.h>

void error()
{
    char buf[256] = {};
    FormatMessageA(FORMAT_MESSAGE_FROM_SYSTEM, NULL, GetLastError(),
                   MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), buf, 256, NULL);
    puts(buf);
}

typedef struct {
    char name[256];
    int type;
    long long time;
} Info;

void print(Info info)
{
    printf("%s %d %ld\n", info.name, info.type, info.time);
}

int main(void)
{
    HANDLE hPipe;
	Info info = { "ABC", 0x7f, 0xdeadbeef };
    DWORD dwRead;

    hPipe = CreateNamedPipe(TEXT("\\\\.\\pipe\\Pipe"),
                            PIPE_ACCESS_OUTBOUND,
                            PIPE_TYPE_MESSAGE | PIPE_READMODE_MESSAGE | PIPE_WAIT,
                            1,
                            1024 * 16,
                            1024 * 16,
                            NMPWAIT_USE_DEFAULT_WAIT,
                            NULL);

    if (hPipe == INVALID_HANDLE_VALUE) {
        printf("CreateNamedPipe: ");
        error();
        return 1;
    }
    
    print(info);

    while(1) {
        if (ConnectNamedPipe(hPipe, NULL) != FALSE) { // wait for someone to connect to the pipe
            while (WriteFile(hPipe, &info, sizeof(Info), &dwRead, NULL) != FALSE) {
                printf("Write Ok\n");
            }
        }

        DisconnectNamedPipe(hPipe);
    }

    return 0;
}
{% endhighlight %}

{% highlight c %}
/* pipe client */
#include <stdio.h>
#include <windows.h>

void error()
{
    char buf[256] = {};
    FormatMessageA(FORMAT_MESSAGE_FROM_SYSTEM, NULL, GetLastError(),
                   MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), buf, 256, NULL);
    puts(buf);
}

typedef struct {
    char name[256];
    int type;
    long long time;
} Info;

void print(Info info)
{
    printf("%s %d %ld\n", info.name, info.type, info.time);
}

int main(void)
{
    HANDLE hPipe;
    Info info;
    DWORD dwRead;

    if(FALSE == WaitNamedPipe(TEXT("\\\\.\\pipe\\Pipe"), 60)) {
        printf("WaitNamedPipe: ");
        error();
        return -1;
    }

    hPipe = CreateFile(TEXT("\\\\.\\pipe\\Pipe"), GENERIC_READ, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);

    if (hPipe == INVALID_HANDLE_VALUE) {
        printf("CreateFile: ");
        error();
        return 1;
    }

    while(1) {
        if(FALSE == ReadFile(hPipe, &info, sizeof(Info), &dwRead, NULL))
            break;
        print(info);
    }

    return 0;
}
{% endhighlight %}
