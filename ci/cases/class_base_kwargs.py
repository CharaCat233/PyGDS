# 职责: 类定义基类关键字参数 (P1-72, PEP 487): kw= 与 ** 解包转发 __init_subclass__, 默认钩子拒绝, metaclass 边界
# 比对: same_output

rec = []


class B:
    def __init_subclass__(cls, **kw):
        rec.append((cls.__name__, kw))


# 类头关键字转发 __init_subclass__
class C(B, k=1, m='x'):
    pass
print(rec)

# type() 三参的关键字同样转发
T = type('D', (B,), {}, k=5)
print(rec)

# ** 字典解包与多 ** 合并 (源码序)
class F(B, **{'j': 2}):
    pass
class G(B, **{'j': 2}, **{'h': 3}):
    pass
print(rec)

# 关键字值的求值先于钩子检查 (副作用发生)
order = []
try:
    class E(*[], k=order.append('k')):
        pass
except TypeError as e:
    print("nohook:", e)
print(order)

# 空 ** 解包
class R(B, **{}):
    print("empty-starkw ok")

# 运行期重复 (字面 kw 与 ** 键冲突)
try:
    class RDup(B, k=1, **{'k': 2}):
        pass
except TypeError as e:
    print("runtimedup:", e)

# 无任何 __init_subclass__ 时默认 object 钩子不接受关键字
try:
    class NoHook(k=1):
        pass
except TypeError as e:
    print("nohook2:", e)


# 显式钩子无 ** 形参: 标准绑定错误 (限定名)
class P:
    def __init_subclass__(cls):
        pass
try:
    class Q(P, k=1):
        pass
except TypeError as e:
    print("no-kw-hook:", e)

# metaclass=type 为默认机制, 合法
try:
    class MM(metaclass=type):
        pass
    print("meta-type ok")
except TypeError as e:
    print("meta-type:", e)

# 非可调用元类: CPython 按调用错误文案
try:
    class MC(metaclass=123):
        pass
except TypeError as e:
    print("meta-custom:", e)

# super().__init_subclass__() 链式转发 (链根消费 kw, object 默认钩子不接受 kw)
chain = []


class Base1:
    def __init_subclass__(cls, **kw):
        chain.append(("base1", kw))


class Mid(Base1):
    def __init_subclass__(cls, **kw):
        chain.append(("mid", kw))
        super().__init_subclass__()


class Leaf(Mid, tag=3):
    pass
print(chain)
print("done")
