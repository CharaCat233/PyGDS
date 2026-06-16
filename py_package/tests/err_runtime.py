# Error: 运行时 TypeError 捕获

caught_runtime = False
err_msg = ""
try:
    len(1, 2)
except TypeError as e:
    caught_runtime = True
    err_msg = str(e)
print(caught_runtime)
print(err_msg != "")
