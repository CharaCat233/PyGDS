# Error: finally 在 except 之后

finally_val = 0
try:
    raise ValueError("test")
except ValueError:
    finally_val = 1
finally:
    finally_val = finally_val + 10
print(finally_val)
