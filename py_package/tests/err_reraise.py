# Error: raise 重新抛出

caught_re = False
try:
    try:
        raise ValueError("to re-raise")
    except ValueError:
        raise
except ValueError:
    caught_re = True
print(caught_re)
