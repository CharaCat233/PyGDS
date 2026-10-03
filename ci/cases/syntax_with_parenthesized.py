# 职责: 括号化管理器列表 (3.10) 与元组歧义回退
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


# 括号化多管理器: 进入按序退出逆序, as 绑定可用
with (CM("a") as x, CM("b")):
    print("body", x)
print(log)

# 尾随逗号: 单管理器与多管理器形态均合法
log.clear()
with (CM("c"),):
    pass
print(log)
log.clear()
with (CM("d"), CM("e"),):
    pass
print(log)

# 无 as 的括号化: 仍是管理器列表 (非元组, CPython 同)
log.clear()
with (CM("f"), CM("g")):
    pass
print(log)

# 单管理器括号表达式
log.clear()
with (CM("j")):
    pass
print(log)

# 括号化 + 异常: 退出路径与裸形态一致
log.clear()
try:
    with (CM("k") as x, CM("l")):
        raise ValueError("boom")
except ValueError as e:
    print("caught", e)
print(log)

# 元组歧义: 右括号后随 as → 回退为元组表达式, 元组非上下文管理器
try:
    with (CM("h"), CM("i")) as t:
        pass
    print("never")
except TypeError as e:
    print("tuple-as:", type(e).__name__)

# 嵌套括号: 外层为管理器列表, 内层元组作为单一管理器
try:
    with ((CM("m"), CM("n")),):
        pass
    print("never-nested")
except TypeError as e:
    print("nested-tuple:", type(e).__name__)
