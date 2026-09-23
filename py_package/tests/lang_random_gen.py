# random 抽样函数的参数类型规则 (与 CPython 一致)
# 随机数值序列不同, 故此处只断言错误类型/文案与结构性结果

import random
import time

random.seed(11)


def gen():
    yield 1
    yield 2
    yield 3


# 抽样函数需要序列 (内部取 len), 生成器一律被拒绝
try:
    random.choice(gen())
except TypeError as e:
    print("choice TypeError:", e)

try:
    random.choices(gen(), k=2)
except TypeError as e:
    print("choices TypeError:", e)

try:
    random.sample(gen(), 2)
except TypeError as e:
    print("sample TypeError:", e)

try:
    random.shuffle(gen())
except TypeError as e:
    print("shuffle TypeError:", e)

# 生成器表达式同样被拒绝
try:
    random.choices(x for x in range(3))
except TypeError as e:
    print("genexpr TypeError:", e)

# 集合不可下标, 故 choice 拒绝; sample 认为它不是序列
try:
    random.choice({1, 2, 3})
except TypeError as e:
    print("choice(set):", e)

try:
    random.sample({1, 2, 3}, 2)
except TypeError as e:
    print("sample(set):", e)

try:
    random.sample({"a": 1}, 1)
except TypeError as e:
    print("sample(dict):", e)

# shuffle 需要可写序列: 元组/字符串/range 不支持元素赋值
try:
    random.shuffle((1, 2, 3))
except TypeError as e:
    print("shuffle(tuple):", e)

try:
    random.shuffle("abc")
except TypeError as e:
    print("shuffle(str):", e)

try:
    random.shuffle(range(3))
except TypeError as e:
    print("shuffle(range):", e)

# choice 支持字符串与 range
print("choice(str) ok:", random.choice("abc") in "abc")
print("choice(range) ok:", random.choice(range(5)) in range(5))

# weights 只需可迭代, 生成器可接受 (CPython 不做 len 检查)
print("weights ok:", len(random.choices([1, 2, 3], weights=(1 for _ in range(3)), k=4)))


# weights 为含 sleep 的生成器: 消费中途挂起须重放, 不能拿半截权重去比对
def sleep_weights():
    n = 0
    while n < 3:
        time.sleep(0)
        n += 1
        yield 1


print("weights sleep:", len(random.choices([1, 2, 3], weights=sleep_weights(), k=4)))

# 序列参数正常支持 (仅结构性断言)
print(len(random.choices([1, 2, 3], k=5)))
print(len(random.sample(range(10), 3)))
print(sorted(random.sample("abcd", 4)) == ["a", "b", "c", "d"])
lst = [1, 2, 3]
random.shuffle(lst)
print(sorted(lst) == [1, 2, 3])
d = {0: "zero", 1: "one", 2: "two"}
random.shuffle(d)
print(len(d), d[0] in ["zero", "one", "two"])

print("done")
