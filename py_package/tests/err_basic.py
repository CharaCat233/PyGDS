# Error: raise + except + as

try:
    raise ValueError("test error")
except ValueError as e:
    print("caught:", e)
