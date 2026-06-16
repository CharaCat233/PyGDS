# Edge: list.sort 参数 (key / reverse)

# 基本 sort
a = [3, 1, 2]
a.sort()
print(a)                       # [1, 2, 3]

# reverse
b = [3, 1, 2]
b.sort(reverse=True)
print(b)                       # [3, 2, 1]

# key 参数 (lambda)
c = ["bb", "a", "ccc"]
c.sort(key=len)
print(c)                       # ['a', 'bb', 'ccc']

# key 参数 (自定义函数)
def last_char(s):
    return s[-1]

d = ["ab", "ca", "bc"]
d.sort(key=last_char)
print(d)                       # ['ab', 'bc', 'ca']

# sorted (返回新列表)
e = [3, 1, 2]
f = sorted(e)
print(e)                       # [3, 1, 2] (原列表不变)
print(f)                       # [1, 2, 3] (新列表)

print("done")