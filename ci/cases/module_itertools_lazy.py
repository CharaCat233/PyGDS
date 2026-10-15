# 职责: itertools 惰性迭代器: 类型名/空池保护/无限源惰性
# 比对: same_output
import itertools
from itertools import (
    chain,
    product,
    combinations,
    permutations,
    zip_longest,
    takewhile,
    dropwhile,
    accumulate,
    pairwise,
    starmap,
    count,
    islice,
)

# type(...).__name__ 返回迭代器类型名 (此前误为 'list')
print(type(chain([1], [2])).__name__)
print(type(chain.from_iterable([[1], [2]])).__name__)
print(type(product([1], [2])).__name__)
print(type(combinations([1, 2], 1)).__name__)
print(type(permutations([1, 2])).__name__)
print(type(zip_longest([1], [2])).__name__)
print(type(takewhile(lambda x: True, [1])).__name__)
print(type(dropwhile(lambda x: False, [1])).__name__)
print(type(accumulate([1, 2])).__name__)
print(type(pairwise([1, 2])).__name__)
print(type(starmap(lambda a, b: a + b, [(1, 2)])).__name__)

# 空池保护 (此前引擎级 SCRIPT ERROR, CPython 返回 [])
print(list(product([1], [])))
print(list(product([], [1, 2])))
print(list(product([])))

# 无限源惰性 (此前急切物化耗尽步数阀)
print(list(islice(chain(count(), [1, 2]), 5)))
print(list(islice(zip_longest(count(), [1]), 3)))
print(list(islice(takewhile(lambda x: x < 5, count()), 10)))
print(list(islice(accumulate(count(1)), 5)))

# 常规输出保持 (对照既有行为)
print(list(chain([1], [2], [3])))
print(list(product([1, 2], [3, 4])))
print(list(combinations([1, 2, 3], 2)))
print(list(permutations([1, 2, 3], 2)))
print(list(zip_longest([1], [2, 3], [4, 5, 6], fillvalue=0)))
print(list(takewhile(lambda x: x < 4, [1, 2, 5, 3])))
print(list(dropwhile(lambda x: x < 3, [1, 2, 3, 4, 1])))
print(list(accumulate([1, 2, 3, 4])))
print(list(accumulate([1, 2, 3], initial=10)))
print(list(pairwise([1, 2, 3, 4])))
print(list(pairwise([1])))
print(list(starmap(pow, [(2, 5), (3, 2)])))
