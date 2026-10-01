# 职责: list/str/tuple 负索引与越界报错
# 比对: same_output


lst = [10, 20, 30, 40]
print(lst[-1])             # 40
print(lst[-2])             # 30
print(lst[-4])             # 10

# str 负索引
s = "abcd"
print(s[-1])               # d
print(s[-3])               # b

# tuple 负索引
tup = (1, 2, 3)
print(tup[-1])             # 3
print(tup[-2])             # 2

# 越界负索引
try:
    print(lst[-5])
except Exception as e:
    print(type(e).__name__)

# str / tuple 的越界报错
try:
    "ab"[5]
except Exception as e:
    print("str-oob:", type(e).__name__)
try:
    (1, 2)[5]
except Exception as e:
    print("tuple-oob:", type(e).__name__)
