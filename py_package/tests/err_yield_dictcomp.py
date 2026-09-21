# Error: yield 在字典推导式内 (Python: SyntaxError: 'yield' inside dict comprehension)

def f():
    return {i: (yield i) for i in range(3)}
