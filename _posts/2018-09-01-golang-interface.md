---
layout: post
title: golang interface advanced
date: 2018-09-01 10:29 +0800
categories:
- golang
---

紀錄golang中interface的各種進階奇葩用法。

interface的設計在golang中是一個非常強大的東西，任何struct只要實作該interface的所有方法，就可以轉型為該interface來使用。

最經典的interface就是fmt.Stringer，struct只要實作`func String() string`這個function signature就能自訂列印成字串的方法。

---

## Basic

基本的interface寫法如下：

{% highlight golang linenos %}
type LineReader interface {
    ReadLine() (line string, done bool, err error)
}

type FileReader struct {}
func (f *FileReader) ReadLine() (string, bool, error) {
    panic("not impl")
}

func process(r LineReader) ([]string, error) {
    var ret []string
    for {
        str, done, e := r.ReadLine()
        if e != nil {
            return nil, e
        }
        if done {
            return ret, nil
        }
        ret = append(ret, str)
    }
}

func main() {
    f := &FileReader{}
    process(f)
}
{% endhighlight %}

將一個實作了`LineReader interface`的`struct FileReader`丟給`process()`使用，function不需要知道是由哪個struct實作。

---

## Composing Interface

在golang中可以將interfaces組合成一個新的interface，寫法如下：


{% highlight golang linenos %}
type ReadCloser interface {
    Reader
    Closer
}
{% endhighlight %}

當function需要對Reader新增行為時，不需要修改Reader，只要定義一個新的interface就好。

但是這個組合技我也還沒應用過...

---

## Accept interfaces return concrete types

不知道從哪裡謠傳這句quote，在寫golang程式時，通常應該讓function接受interface當作參數，而回傳一個實際的型別(而非interface)。

interface當參數應該不難理解，對於擴充性和單元測試顯得更有彈性，比如以下這段程式：

{% highlight golang linenos %}
func WriteHeader(w *io.Writer) error {
    ...
}

func WriteHeader(f *os.File) error {
    ...
}

func Write() {
    var f *os.File = newFile(...)
    WriteHeader(f)
}
{% endhighlight %}

如果要測試WriterHeader的時候，只要把原本傳入的File改為MockFile就可以驗證行為，但是return concrete types就不是那麼直觀了。

當我們觀察function回傳值時，如果是一個interface，通常只能根據function signature和註解來猜測程式行為。如果想知道實作就需要先知道回傳的是哪個struct，在trace code和debug讓人很不方便。

然而也不是一定不能回傳interface，要寫factory pattern時就只能回傳interface了。

因此對於interface的設計一定要考慮封裝的是否乾淨，而且實作不會有曖昧不明的結果，使得user需要回去看實作是怎麼寫的。

---

## Embedding Types

另一個用法是embedding types組合技，struct可以使用anonymous field把其他struct整個塞進來，該struct實作的interface就可以一併使用，還可以overwrite掉function。

{% highlight golang linenos %}
type HttpClient interface {
	Get(url string)
}

type BaseClient struct{}

func (c *BaseClient) Get(url string) {
	fmt.Printf("BaseClient.Get(%v)\n", url)
}

type PrettyClient struct {
	BaseClient
}

func (c *PrettyClient) Get(url string) {
	c.BaseClient.Get(url)
	fmt.Printf("PrettyClient.Get(%v)\n", url)
}

func do(c HttpClient, url string) {
	c.Get(url)
}

func main() {
	c := &PrettyClient{}
	do(c, "node1")

	b := &BaseClient{}
	do(b, "node2")
}
{% endhighlight %}

會印出
```
BaseClient.Get(node1)
PrettyClient.Get(node1)
BaseClient.Get(node2)
```

雖然這招十分強大，但是容易引起user難以閱讀而開始`git blame`。

如下所示：

{% highlight golang linenos %}
type Worker interface {
	Add(string)
	Filter()
	Run()
}

type BaseWorker struct {
	arr []string
}

func (w *BaseWorker) Add(s string) {
	w.arr = append(w.arr, s)
}

func (w *BaseWorker) Filter() {
	return
}

func (w *BaseWorker) Run() {
	for i, s := range w.arr {
		fmt.Println(i, s)
	}
}

type DerivedWorker struct {
	BaseWorker
}

func (w *DerivedWorker) Filter() {
	var arr []string
	for i, s := range w.arr {
		if strings.HasPrefix(s, "B") {
			fmt.Println("Illegal input: ", i)
			continue
		}
		arr = append(arr, s)
	}
	w.arr = arr
}

func Prepare(w Worker) {
	w.Add("A")
	w.Add("B")
	w.Add("C")
}

func Work(w Worker) {
	w.Filter()
	w.Run()
}

func main() {
	fmt.Println("BaseWorker ====")
	b := &BaseWorker{}
	Prepare(b)
	Work(b)
	fmt.Println("\nDerivedWorker ====")
	d := &DerivedWorker{}
	Prepare(d)
	Work(d)
}
{% endhighlight %}

output:

```
BaseWorker ====
A
B
C

DerivedWorker ====
A
C
```

reading/writing DerivedWorker的人需要反覆對照BaseWorker才能確保行為正確。而且違反了open/close原則。當Worker是由factory pattern動態產生就更難以追蹤了。

在golang中比較好的作法應該是BaseWorker不直接實作Interface，而是寫出對應的private function，使DerivedWorker既可reuse source code，也強迫在沒有實作interface時必須自己呼叫base class的function。

## Conclusion

警語：過度使用interface容易導致程式閱讀困難..務必謹慎思考是否無其他解法。
