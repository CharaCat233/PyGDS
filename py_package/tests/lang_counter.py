# Counter.most_common 测试

from collections import Counter

c = Counter("abracadabra")
# most_common 全部 (按次数降序, 同次数按插入顺序)
print(c.most_common())          # [('a', 5), ('b', 2), ('r', 2), ('c', 1), ('d', 1)]
# most_common(n) 取前 n
print(c.most_common(2))         # [('a', 5), ('b', 2)]
print(c.most_common(1))         # [('a', 5)]
print(c.most_common(0))         # []

# 数值计数
c2 = Counter([1, 1, 2, 3, 3, 3])
print(c2.most_common())         # [(3, 3), (1, 2), (2, 1)]
print(c2.most_common(2))        # [(3, 3), (1, 2)]

# 空 Counter
print(Counter().most_common())  # []

# most_common 不影响原 Counter
print(c["a"])                   # 5

print("done")
