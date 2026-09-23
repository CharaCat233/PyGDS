# Error: 括号 yield 在推导式元素内 (Python: SyntaxError)

def f():
    return [(yield i) for i in range(3)]
