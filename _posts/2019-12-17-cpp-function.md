---
layout: post
title: c++裡的bind和lambda，為什麼沒辦法變成c-style function pointer
date: 2019-12-17 00:00 +0800
categories: C/C++
---

在c裡面，function pointer是一個儲存function位置的指標，可以拿來pass一個function讓別人呼叫，通常用來實作callback function。

例如nats c lib裡的[error handling](https://github.com/nats-io/nats.c#advanced-usage)，為了識別或做一些hacky技巧，還會指定一個void*讓它傳回來。

關於void*，最直觀的例子就是pthread_create裏頭的parameter了，例如[這個的example](http://man7.org/linux/man-pages/man3/pthread_create.3.html)

然而有些設計不良的API是沒有提供這個實用的方式的，於是我開始尋找使用C++的方式把這個東西丟進去，例如bind

{% highlight c++ linenos %}
typedef void(* handler) ();

void run(handler h)
{
    h();
}

void gg(int i) {}

int main() {
    run(bind(gg, 3));

    return 0;
}
{% endhighlight %}

然後編譯器就生氣了

```
error: cannot convert ‘std::_Bind_helper<false, void (&)(int), int>::type {aka std::_Bind<void (*(int))(int)>}’ to ‘handler {aka void (*)()}’ for argument ‘1’ to ‘void run(handler)’
```

一段一開始看不太懂的錯誤，上Stack Overflow找找看，發現有人提供轉成std::function的方法，馬上抄來試試看。

{% highlight c++ linenos %}
int main() {
    function<void()> f = (bind(gg, 3));
    handler *h = f.target<void(*)()>();
    if(!h) return 1;
    run(*h);

    return 0;
}
{% endhighlight %}

編譯過了，但是果然return 1。沒辦法了，試試看lambda吧。

{% highlight c++ linenos %}
int main() {
    int i = 3;
    function<void()> f = ([i]() {});
    handler *h = f.target<void(*)()>();
    if(!h) return 1;
    run(*h);

    return 0;
}
{% endhighlight %}

果不其然也return 1了。到底是為什麼呢，只好來仔細的研究看看。

先從bind開始吧，c++有個半殘但勉強能用的東西可以揭開他們的真面目..typeid(x)

{% highlight c++ linenos %}
int i = 3;
auto lambda = [i]() {};
auto b = bind(gg, i);
function<void()> f = ([i]() {});
cout << typeid(lambda).name() << endl;
cout << typeid(b).name() << endl;
cout << typeid(f).name() << endl;
{% endhighlight %}

果然印出一堆亂碼

```
Z4mainEUlvE_
St5_BindIFPFviEiEE
St8functionIFvvEE
```

做個[demangling](https://gcc.gnu.org/onlinedocs/libstdc++/manual/ext_demangling.html)

```
main::{lambda()#1}
std::_Bind<void (*(int))(int)>
std::function<void ()>
```

先來看bind，根據[source code](https://gcc.gnu.org/onlinedocs/gcc-7.4.0/libstdc++/api/a00071_source.html#l00450)

{% highlight c++ linenos %}
   template<typename _Signature>
        struct _Bind;
{% endhighlight %}

原來根本不是什麼function，是struct阿，那它是怎麼呼叫的呢，繼續往下找

{% highlight c++ linenos %}
       // Call unqualified
       template<typename... _Args,
           typename _Result = _Res_type<tuple<_Args...>>>
    _Result
    operator()(_Args&&... __args)
    {
      return this->__call<_Result>(
          std::forward_as_tuple(std::forward<_Args>(__args)...),
          _Bound_indexes());
    }
{% endhighlight %}

原來是overload operator()，再繼續往下看__call怎麼實作的

{% highlight c++ linenos %}
       // Call unqualified
       template<typename _Result, typename... _Args, std::size_t... _Indexes>
    _Result
    __call(tuple<_Args...>&& __args, _Index_tuple<_Indexes...>)
    {
      return std::__invoke(_M_f,
          _Mu<_Bound_args>()(std::get<_Indexes>(_M_bound_args), __args)...
          );
    }
{% endhighlight %}

內部用了invoke執行該function，而參數`_M_f`和`_M_bound_args`其實是struct的member

{% highlight c++ linenos %}
       _Functor _M_f;
       tuple<_Bound_args...> _M_bound_args;
{% endhighlight %}

而[std::function](https://gcc.gnu.org/onlinedocs/gcc-7.4.0/libstdc++/api/a06222.html#a8c5a08fdc36581c53fa597667322cf7d)其實就是個可以封裝各種functor物件或function pointer的class

把bind傳給std::function只是把它藏進去，還是沒辦法變成function pointer。也就是說std::function應該視為function的interface用來進行傳遞和呼叫。

而lambda就沒有實際出現在c++ header裡了，不過在[cppreference](https://en.cppreference.com/w/cpp/language/lambda)裡就有基本的說明

```
Constructs a closure: an unnamed function object capable of capturing variables in scope.
```

lambda也是個function object，但與bind最大的差別在bind要提供一個具名的function，但lambda儲存的是匿名function，並且是由編譯器幫忙完成的，相對的bind是藉由template展開來完成。
