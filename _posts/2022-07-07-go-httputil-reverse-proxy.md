---
layout: post
title: go httputil.ReverseProxy 踩坑
categories: [golang]
keywords: go
---

std lib裡面有個reverse proxy的實作，不過裡面有一些奇怪的坑在裡面

照抄httputil.NewSingleHostReverseProxy()的話，request還是會打回到自己身上

要連req.Host都覆寫

另外是response如果有重複的header可能會有兩條一樣的header跑出來

這邊是原來的Allow-Origin在gin-contrib/cors又被加了一次上去

結果瀏覽器認為domain是`*, *`不給過

最後是它不會管gzip encoding，所以回應如果是gzip壓縮過的，而gin的middleware又加一次gzip

瀏覽器會解壓縮一次，結果還是拿到壓縮過的body

```
        url, _ := url.Parse("http://example.com")
        proxy := httputil.NewSingleHostReverseProxy(url)
        origDirector := proxy.Director
        proxy.Director = func(req *http.Request) {
                origDirector(req)
                req.Host = "example.com"
                req.Header.Set("Host", "example.com")
                req.Header.Set("Authorization", "Bearer abcd")
        }

        proxy.ModifyResponse = func(resp *http.Response) error {
                resp.Header.Del("Access-Control-Allow-Origin")
                resp.Header.Del("Vary")
                return nil
        }

        proxy.ServeHTTP(c.Writer, c.Request)
```
