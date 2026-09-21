# 连续 if 语句的条件求值 (resume_info 泄漏回归测试)
# 修复前: 真值 if 之后的 if 会跳过条件求值, 直接执行其 then 分支

# 真值 if 之后的假值 if 必须跳过其分支
if True:
    print("first")
if False:
    print("should not print")
print("after")

# 中间有其他语句时同样成立
if 1:
    print("second")
x = 10
if x > 100:
    print("should not print")
print("after2")

# 连续多个 if
a = 1
if a == 1:
    print("a1")
if a == 2:
    print("should not print")
if a == 1:
    print("a1 again")

# if / elif / else 链连续出现
if a == 2:
    print("branch2")
elif a == 1:
    print("branch1")
else:
    print("branch-else")
if a == 1:
    print("branch1-2")
elif a == 2:
    print("should not print")
else:
    print("should not print")


# 函数体内的连续 if
def check(v):
    if v > 0:
        print("pos")
    if v > 100:
        print("should not print")
    if v < 0:
        print("neg")
    return v


print(check(5))
print(check(-5))

# 条件表达式带副作用时, 每个条件只应求值一次
calls = []


def cond(name, result):
    calls.append(name)
    return result


if cond("c1", True):
    print("t1")
if cond("c2", False):
    print("should not print")
if cond("c3", True):
    print("t3")
print(calls)

# while / for 紧随 if 之后
i = 0
if True:
    print("pre-while")
while i < 2:
    print(i)
    i += 1
if True:
    print("pre-for")
for j in range(2):
    print(j)

# if 之后紧跟 for-else
if True:
    print("pre-for-else")
for k in range(2):
    print(k)
else:
    print("for-else")

# 嵌套块中的连续 if
if True:
    if True:
        print("nested-t")
    if False:
        print("should not print")
    print("nested-end")

print("done")
