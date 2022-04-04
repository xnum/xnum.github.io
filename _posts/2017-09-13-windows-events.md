---
layout: post
title: Windows Events API 使用
categories:
- windows programming
---

[MSDN連結](https://msdn.microsoft.com/en-us/library/windows/desktop/ms682655(v=vs.85).aspx)

用於行程間同步

支援兩種模式：自動重設(接收到訊號後自動重置為Off)、手動重設(設定訊號後會一直為On的狀態)

使用WaitForSingleObject、WaitForMultipleObjects等待

建立使用CreateEvent

```c
HANDLE WINAPI CreateEvent(
_In_opt_ LPSECURITY_ATTRIBUTES lpEventAttributes,
_In_     BOOL                  bManualReset, /* Event模式 */
_In_     BOOL                  bInitialState, 
_In_opt_ LPCTSTR               lpName /* 自訂的Event名稱 */
);
```

從其他Process取得Handle時，使用OpenEvent

```c
HANDLE WINAPI OpenEvent(
_In_ DWORD   dwDesiredAccess,
_In_ BOOL    bInheritHandle,
_In_ LPCTSTR lpName
);
```

{% highlight c linenos %}
#define UNICODE
#include <windows.h>
#include <stdio.h>

// client 

void error()
{
    char buf[256] = {};
    FormatMessageA(FORMAT_MESSAGE_FROM_SYSTEM, NULL, GetLastError(),
    MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), buf, 256, NULL);
    puts(buf);
}

int main()
{
    // use Global
    HANDLE hEvent = OpenEvent(SYNCHRONIZE, FALSE, L"Global\\AlertServiceEvent");
    if (hEvent == NULL)
    {
        printf("OpenEvent: ");
        error();
        return -1;
    }

    while (TRUE)
    {
        printf("Wait...\n");
        WaitForSingleObject(hEvent, INFINITE);
        printf("Get!\n");
    }

    return 0;
}
{% endhighlight %}

{% highlight c linenos %}
#define UNICODE
#include <windows.h>
#include <stdio.h>

/* server */
void error()
{
    char buf[256] = {};
    FormatMessageA(FORMAT_MESSAGE_FROM_SYSTEM, NULL, GetLastError(),
    MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), buf, 256, NULL);
    puts(buf);
}

int main()
{
    // use Global
    HANDLE hEvent = CreateEvent(NULL, FALSE, FALSE, L"Global\\AlertServiceEvent");
    if (hEvent == NULL)
    {
        printf("OpenEvent:");
        error();
        return -1;
    }

    while(1)
    {
        printf("Sending\n");
        if(0 == PulseEvent(hEvent))
        {
            printf("PulseEvent:");
            error();
        } 
        sleep(1);
    }

    return 0;
}
{% endhighlight %}
