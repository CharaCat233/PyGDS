# Error: yield 在列表推导式内 (Python: SyntaxError: invalid syntax)

def f():
    return [yield i for i in range(3)]
