# Error: handler 中抛出新异常

new_exc_caught = False
try:
    try:
        raise ValueError("original")
    except ValueError:
        raise RuntimeError("new from handler")
except RuntimeError:
    new_exc_caught = True
print(new_exc_caught)
