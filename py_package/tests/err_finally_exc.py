# Error: finally 在异常上下文中

finally_ran2 = False
try:
    try:
        raise RuntimeError("boom")
    except RuntimeError:
        _ = 1
finally:
    finally_ran2 = True
print(finally_ran2)
