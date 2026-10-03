# 职责: with as 目标全形态 (元组解包, 嵌套, 星形, 属性, 下标) 与绑定失败时仍退出
# 比对: same_output

log = []


class CM:
    def __init__(self, name):
        self.name = name

    def __enter__(self):
        log.append("enter:" + self.name)
        return self.name

    def __exit__(self, t, v, tb):
        log.append("exit:" + self.name)
        return False


class Pair:
    def __init__(self, items):
        self.items = items

    def __enter__(self):
        log.append("enter:pair")
        return self.items

    def __exit__(self, t, v, tb):
        log.append("exit:pair")
        return False


class Host:
    pass


# 元组解包目标
with Pair((1, 2)) as (p, q):
    print("unpack", p, q)

# 嵌套解包目标
with Pair(((1, 2), 3)) as ((a, b), c):
    print("nested", a, b, c)

# 星形目标捕获剩余元素
with Pair((1, 2, 3)) as (head, *tail):
    print("star", head, tail)

# 属性目标与下标目标
host = Host()
with CM("attr") as host.label:
    print("attr", host.label)
d = {}
with CM("item") as d["k"]:
    print("item", d["k"])

# 括号化多管理器 (3.10 语法) 不支持前, 单管理器的括号包裹表达式仍可用:
# 管理器表达式本身带括号是普通表达式, 与 3.10 的管理器列表括号不同
with (CM("paren")) as v:
    print("paren", v)

# 多管理器各自带目标: 绑定按进入次序逐个生效
with CM("m1") as x, CM("m2") as y:
    print("multi", x, y)

# 解包计数不匹配: ValueError 抛出, 但管理器已进入, __exit__ 仍收到异常 (CPython 实测)
log.clear()
try:
    with Pair((1, 2)) as (only_one,):
        print("never")
except ValueError as err:
    print("unpack-err", err)
print(log)
