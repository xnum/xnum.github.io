---
layout: post
title: c++自定class適用於foreach的寫法
categories:
- C/C++
---

只要在class提供iterator和const iterator

就可以用c++11支援的for loop來存取了

在閱讀上更為簡潔

{% highlight c++ %}
#include <vector>
#include <iostream>

using namespace std;

class List
{
    public:
        typedef vector<int>::iterator iterator;
        typedef vector<int>::const_iterator const_iterator;

        iterator begin() { return arr.begin(); }
        iterator end() { return arr.end(); }
        const_iterator begin() const { return arr.cbegin(); }
        const_iterator end() const { return arr.cend(); }

        void add(int n) { arr.push_back(n); }
    private:
        vector<int> arr;
};

int main()
{
    List m;
    m.add(1);
    m.add(2);
    m.add(3);

    for(int i : m) {
        cout << i << endl;
    }
    return 0;
}

{% endhighlight %}
