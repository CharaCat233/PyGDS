# 职责: len 传参数量错误触发 TypeError 被捕获
# 比对: same_output


caught_runtime = False
err_msg = ""
try:
    len(1, 2)
except TypeError as e:
    caught_runtime = True
    err_msg = str(e)
print(caught_runtime)
print(err_msg != "")

# 错误路径: 对象不可求长度
try:
    len(5)
except TypeError as e:
    print("TE:", e)
