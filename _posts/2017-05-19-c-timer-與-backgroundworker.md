---
layout: post
title: 'C# Timer 與 BackgroundWorker'
categories: ['.Net']
---

最近寫程式在C#上用到需要較複雜IO的功能，不能單純用Blocking I/O卡死等待

而C#在跨執行緒存取控制項時會跳出InvalidOperationException

因為內部限制只有UI Thread可以存取控制項，以避免出現race condition問題

為了解決這個問題，可以使用BackgroundWorker作為控制IO的Thread及Producer

另外使用內建的ConcurrentQueue來完成Producer-Consumer模型

而在UI Thread使用Timer固定時間觸發來當Consumer

這樣就不需要在BackgroundWorker直接存取控制項

```C#
public class Form1 : Form
{
    private ConcurrentQueue<Data> queue;

    private void Producer_DoWork( ... )
    {
        while(true)
        {
            Data data = IO.Read();
            queue.Add(data);
        }

        // TODO: Compeleted
    }

    private void Consumer_Tick( ... )
    {
        Data data;
        if(!queue.TryTake(out data)) return;

        // TODO: Perform data
    }
}
```
