# 职责: 用户 __next__ 抛 StopIteration 子类终止迭代
# 比对: same_output

# 用户迭代器的 __next__ 抛 StopIteration 子类此前异常原样传播
# 改为子类同样视为迭代耗尽信号 (与 CPython 一致)


class MyStop(StopIteration):
    pass


class It:
    def __init__(self):
        self.n = 0

    def __iter__(self):
        return self

    def __next__(self):
        self.n += 1
        if self.n > 3:
            raise MyStop
        return self.n


print(list(It()))
it = It()
print(list(it))
print(list(it))  # 已耗尽


# 子类带参数 (StopIteration.value 语义)
class StopVal(StopIteration):
    pass


class ItVal:
    def __iter__(self):
        return self

    def __next__(self):
        raise StopVal(42)


g = ItVal()
print(list(g))


# 生成器体内 StopIteration 子类经 PEP 479 转 RuntimeError (与普通 StopIteration 一致)
def gen():
    yield 1
    raise MyStop


try:
    list(gen())
except RuntimeError as e:
    print("RE:", str(e))


# 非 StopIteration 的异常正常传播
class ItErr:
    def __iter__(self):
        return self

    def __next__(self):
        raise ValueError("boom")


try:
    list(ItErr())
except ValueError as e:
    print("VE:", str(e))


# SystemExit.code 属性
print(SystemExit(3).code)
print(SystemExit().code)
print(SystemExit("msg").code)
print(SystemExit(1, 2).code)
print(SystemExit(3).args)
