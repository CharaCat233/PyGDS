# time 模块测试

import time

# sleep 是模块成员, 可当值传递; 返回 None
print(callable(time.sleep))
print(time.sleep(0) is None)

# 顶层与函数内 sleep (协作式挂起)
print("a")
time.sleep(0.01)
print("b")


def f():
    print("in")
    time.sleep(0.01)
    print("mid")
    return 42


print(f())

# 循环内 sleep
for i in range(2):
    print("loop", i)
    time.sleep(0.01)

# 单调时钟与时间戳
print(isinstance(time.time(), float))
print(isinstance(time.time_ns(), int))
print(isinstance(time.monotonic(), float))
print(time.monotonic_ns() > 0)

# 参数校验
try:
    time.sleep(-1)
except ValueError as e:
    print("ValueError:", e)
try:
    time.sleep("a")
except TypeError as e:
    print("TypeError:", e)

print("done")
