# 职责: chain/product/组合排列与 islice
# 比对: same_output

# itertools 模块测试: chain / product / combinations / permutations / islice

from itertools import chain, product, combinations, permutations, islice

# chain 拼接多个可迭代对象
print(list(chain([1, 2], [3], [4, 5])))  # [1, 2, 3, 4, 5]
print(list(chain("ab", "cd")))  # ['a', 'b', 'c', 'd']
print(list(chain([1], [2], [3])))  # [1, 2, 3]

# product 笛卡尔积
print(list(product([1, 2], [3, 4])))  # [(1, 3), (1, 4), (2, 3), (2, 4)]
print(list(product([1, 2], [3])))  # [(1, 3), (2, 3)]
print(list(product("ab", "12")))  # [('a', '1'), ('a', '2'), ('b', '1'), ('b', '2')]

# combinations 组合
print(list(combinations([1, 2, 3], 2)))  # [(1, 2), (1, 3), (2, 3)]
print(
    list(combinations([1, 2, 3, 4], 3))
)  # [(1, 2, 3), (1, 2, 4), (1, 3, 4), (2, 3, 4)]
print(list(combinations([1, 2, 3], 1)))  # [(1,), (2,), (3,)]

# permutations 排列
print(list(permutations([1, 2], 2)))  # [(1, 2), (2, 1)]
print(
    list(permutations([1, 2, 3], 2))
)  # [(1, 2), (1, 3), (2, 1), (2, 3), (3, 1), (3, 2)]
print(list(permutations([1, 2])))  # [(1, 2), (2, 1)]

# islice 切片
print(list(islice([1, 2, 3, 4, 5], 1, 4)))  # [2, 3, 4]
print(list(islice([1, 2, 3, 4, 5], 3)))  # [1, 2, 3]
print(list(islice([1, 2, 3, 4, 5], 0, 5, 2)))  # [1, 3, 5]
print(list(islice([1, 2, 3], 5)))  # [1, 2, 3]


# combinations/repeat/permutations/product 数值实参校验
from itertools import combinations, permutations, product, repeat

# combinations r 负值报 ValueError (此前静默 [])
try:
    print(list(combinations([1], -1)))
except ValueError as e:
    print("VE:", str(e))

# combinations r 大数报 OverflowError (此前大数 value=0 得 [()])
try:
    print(list(combinations([1], 10**20)))
except OverflowError as e:
    print("OE:", str(e))

# repeat times 大数报 OverflowError
try:
    print(list(repeat(1, 10**100)))
except OverflowError as e:
    print("OE:", str(e))

# repeat times bool 按 int (True -> 1)
print(list(repeat(1, True)))
print(list(repeat(1, False)))

# repeat times 负数: 空列表
print(list(repeat(1, -1)))

# product repeat 大数
try:
    print(list(product([1], repeat=10**30)))
except OverflowError as e:
    print("OE:", str(e))

# product repeat=True 按 1
print(list(product([1], repeat=True)))

# permutations r 大数
try:
    print(list(permutations([1], 10**20)))
except OverflowError as e:
    print("OE:", str(e))

# islice 的 bool 实参按 int
from itertools import islice

print(list(islice([1, 2, 3], True)))
print(list(islice([1, 2, 3], False)))

# 正常路径不受影响
print(list(combinations([1, 2], 1)))
print(list(combinations([1, 2], 0)))
print(list(product([1, 2], repeat=2)))

# filterfalse / batched
import itertools

print("ff:", list(itertools.filterfalse(lambda x: x % 2, range(10))))
print("ffn:", list(itertools.filterfalse(None, [0, 1, 0, 2, 3])))
print("batched:", list(itertools.batched("ABCDEFG", 3)))
print("batched2:", list(itertools.batched(range(5), 2)))
try:
    list(itertools.batched([1, 2], 0))
except ValueError as e:
    print("batched0:", str(e))


# itertools.count 非数值步长报 CPython 文案 (a number is required)
def _show_it(label, fn):
    try:
        print(label, "OK", fn())
    except Exception as e:
        print(label, type(e).__name__, str(e))


_show_it("count_str_step", lambda: itertools.count(0, "a"))
_show_it("count_str_start", lambda: itertools.count("a"))
_show_it("count_ok", lambda: list(itertools.islice(itertools.count(3, 2), 4)))

# islice step=0 / 负数报 CPython 文案
_show_it("islice_step0", lambda: list(itertools.islice([1, 2, 3], 0, 3, 0)))
_show_it("islice_stepneg", lambda: list(itertools.islice([1, 2, 3], 0, 3, -1)))
_show_it("islice_step1", lambda: list(itertools.islice([1, 2, 3], 0, 3, 1)))

# islice 消费 count(0.5, 0.5) 浮点步长
_show_it("count_float", lambda: list(itertools.islice(itertools.count(0.5, 0.5), 5)))
