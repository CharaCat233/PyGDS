# Edge: 切片语法

lst = [0, 1, 2, 3, 4, 5]
print(lst[1:3])                # [1, 2]
print(lst[1:])                 # [1, 2, 3, 4, 5]
print(lst[:3])                 # [0, 1, 2]
print(lst[:])                  # [0, 1, 2, 3, 4, 5]
print(lst[::2])                # [0, 2, 4]
print(lst[::-1])               # [5, 4, 3, 2, 1, 0]
print(lst[1:5:2])              # [1, 3]
print(lst[-1])                 # 5
print(lst[-3:])                # [3, 4, 5]
print(lst[-3:-1])              # [3, 4]
print(lst[:-2])                # [0, 1, 2, 3]

# 字符串切片
s = "hello"
print(s[1:3])                  # el
print(s[::-1])                 # olleh

# 元组切片
tup = (0, 1, 2, 3, 4)
print(tup[1:3])                # (1, 2)
print(tup[::-1])               # (4, 3, 2, 1, 0)

print("done")