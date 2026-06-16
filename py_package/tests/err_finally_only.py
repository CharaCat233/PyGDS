# Error: try-finally 无 except

finally_only = 0
try:
    finally_only = 1
finally:
    finally_only = 2
print(finally_only)
