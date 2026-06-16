# Error: 异常传播

caught_outer = False
try:
    try:
        raise ValueError("inner uncaught")
    except TypeError:
        caught_outer = False
except ValueError:
    caught_outer = True
print(caught_outer)
