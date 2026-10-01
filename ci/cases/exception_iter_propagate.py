# 职责: 用户迭代器 __next__ 异常穿透消费器
# 比对: same_output

# StopIteration 视为耗尽, 其余异常须穿透内建消费器向外传播

class It:
    def __init__(self):
        self.n = 0
    def __iter__(self):
        return self
    def __next__(self):
        self.n += 1
        if self.n > 1:
            raise ValueError("iter")
        return 1

try:
    print("IT:", list(It()))
except ValueError as e:
    print("caught:", e)

# 生成器体内 raise 同样穿透 list()
def gr():
    yield 1
    raise ValueError("gen")

try:
    print(list(gr()))
except ValueError as e:
    print("caught gen:", e)

# StopIteration 仍是正常耗尽, 不得误报异常
class Stop:
    def __iter__(self):
        return self
    def __next__(self):
        raise StopIteration

print(list(Stop()))
print("done")
