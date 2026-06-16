# Error: 基类匹配 (except Exception)

base_caught = False
try:
    raise TypeError("subclass")
except Exception:
    base_caught = True
print(base_caught)
