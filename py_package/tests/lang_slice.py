# slice 对象测试

# 构造 (slice(stop) / slice(start, stop) / slice(start, stop, step))
print(slice(3))                 # slice(None, 3, None)
print(slice(1, 3))              # slice(1, 3, None)
print(slice(1, 5, 2))           # slice(1, 5, 2)
print(slice(None, None, -1))    # slice(None, None, -1)

# 属性
s = slice(1, 4)
print(s.start)                  # 1
print(s.stop)                   # 4
print(s.step)                   # None

# 类型判定
print(isinstance(s, slice))     # True
print(type(s))                  # <class 'slice'>

# 用 slice 对象索引列表
lst = [0, 1, 2, 3, 4, 5]
print(lst[slice(1, 4)])         # [1, 2, 3]
print(lst[slice(None, 3)])      # [0, 1, 2]
print(lst[slice(0, 6, 2)])      # [0, 2, 4]
print(lst[slice(4, 0, -1)])     # [4, 3, 2, 1]

# 字符串切片
print("abcdef"[slice(1, 4)])    # bcd

# 复用保存的 slice 对象
sl = slice(0, 3)
print(lst[sl])                  # [0, 1, 2]
print(lst[sl])                  # [0, 1, 2]

print("done")
