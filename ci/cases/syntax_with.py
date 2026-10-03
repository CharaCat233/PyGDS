# 职责: with 语句文法主体, 多管理器次序, 流控穿越与 try/finally 对照
# 比对: same_output

# 单管理器: __enter__ 值绑定到 as 目标, 体正常结束走 __exit__ (无异常传 None)
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


with CM("a") as x:
    print("body", x)
print(log)

# 多管理器逗号形式等价于嵌套 with: 进入按序, 退出逆序 (CPython 实测次序)
log.clear()
with CM("a") as x, CM("b") as y:
    print("body", x, y)
print(log)

# 无 as 的管理器: __enter__ 返回值不绑定
log.clear()
with CM("c"):
    print("body-c")
print(log)

# 行内体: 冒号后单条语句 (与 if/while 同一 block 机制)
log.clear()
with CM("d"): log.append("inline-body")
print(log)

# 嵌套 with: 内层先进入也先退出
log.clear()
with CM("outer"):
    with CM("inner"):
        log.append("nested-body")
print(log)

# break 穿越体: __exit__ 仍触发且收到无异常参数, 与等价 try/finally 形态逐条对照
log.clear()
for i in range(3):
    with CM("w%d" % i):
        if i == 1:
            break
    log.append("after-%d" % i)
print(log)

log.clear()
for i in range(3):
    try:
        if i == 1:
            break
    finally:
        log.append("exit:w%d" % i)
    log.append("after-%d" % i)
print(log)

# continue 穿越体: 每轮都触发 __exit__
log.clear()
for i in range(3):
    with CM("c%d" % i):
        if i % 2 == 0:
            continue
    log.append("after-%d" % i)
print(log)

# return 穿越体: __exit__ 触发后函数返回体的返回值, 不被 __exit__ 返回值污染
def ret_through():
    with CM("r"):
        return 42


print(ret_through())

# 体抛异常且 __exit__ 返回假值: 异常继续传播, 外层 except 捕获
log.clear()
try:
    with CM("e"):
        raise ValueError("boom")
except ValueError as err:
    print("caught", err)
print(log)

# as 目标是函数局部名: 绑定进函数作用域 (局部名集合收集覆盖 with 目标)
def scoped():
    with CM("s") as v:
        return v


print(scoped())

# with open(...): 文件对象支持上下文管理器协议, 退出时关闭且幂等
with open("ci_open_case_data.tmp", "w") as f:
    f.write("w1\n")
    f.write("w2\n")
print(f.closed)
with open("ci_open_case_data.tmp") as g:
    print(g.read(), g.closed)
with open("ci_open_case_data.tmp") as h:
    h.__exit__(None, None, None)
print(h.closed)
