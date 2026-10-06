# 职责: 旧式 __getitem__ 迭代协议的挂起重放
# 比对: same_output
# ref: I2-62

# 仅定义 __getitem__ 的对象按连续下标迭代: __getitem__ 体内 sleep 挂起时,
# 下标迭代器必须置 suspended 交消费器传播并交语句重放 (此前 null 返回被
# 当作迭代结束, 消费器拿到部分结果且语句不重放)。重放轮经帧复用续做
# 被中断的 __getitem__, 睡眠去重保证不重复等待, 输出与 CPython 一致

import time

class OldStyle:
    def __getitem__(self, i):
        time.sleep(0)
        return [10, 20, 30][i]

# 内建消费器
print(list(OldStyle()))
print([x for x in OldStyle()])
print(sum(OldStyle()))
# for 循环消费
total = 0
for x in OldStyle():
    total += x
print(total)
# zip 双参: 两个独立下标迭代器并行消费
print(list(zip(OldStyle(), OldStyle())))
