# 职责: groupby 状态机跨语句存活与 sleep 重放
# 比对: same_output

# groupby 状态机跨语句持久: 单语句直消 / for 驱动 / 急切推导式 / 手工 next

import time
import itertools

def g2():
    for i in [0, 1, 2]:
        time.sleep(0)
        yield i

# 单语句直接消费 (重放轮整体重建)
print([(k, list(v)) for k, v in itertools.groupby(g2(), key=lambda x: x < 2)])

# 变量持有 + for 驱动 (状态机跨语句存活, 重放不得回退源游标)
gb = itertools.groupby(g2(), key=lambda x: x < 2)
for k, v in gb:
    print(k, list(v))

# 变量持有 + 急切推导式 (推导式从零重排时组对须从日志重读)
gb2 = itertools.groupby(g2(), key=lambda x: x < 2)
print([(k, list(v)) for k, v in gb2])

# 无 key 形式
print([(k, list(v)) for k, v in itertools.groupby(g2())])

# 手工 next 推进外层迭代器
gb3 = itertools.groupby(g2(), key=lambda x: x % 2)
k1, v1 = next(gb3)
print(k1, list(v1))
