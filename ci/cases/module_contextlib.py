# 职责: contextlib 模块 (I1-71): contextmanager 生成器驱动与异常注入 / closing / suppress 多异常 / ExitStack 栈序与 pop_all / nullcontext, 生成器各阶段 sleep 挂起重放
# 比对: same_output
# 锚定: CPython 3.12
import time
from contextlib import contextmanager, closing, suppress, ExitStack, nullcontext


def t(label, fn):
    try:
        print(label + ":", repr(fn()))
    except Exception as e:
        print(label, type(e).__name__, ":", e)


@contextmanager
def cm(tag):
    print("enter", tag)
    try:
        yield tag * 2
    except ValueError as e:
        print("caught", e)
    finally:
        print("exit", tag)


t("cm_body", lambda: (lambda: [None for _ in [0]])())
with cm("a") as v:
    print("body", v)

try:
    with cm("b"):
        raise ValueError("boom")
except ValueError as e:
    print("outer", e)


@contextmanager
def cm2():
    yield 1


t("cm2_ok", lambda: None)
with cm2() as v2:
    print("cm2 body", v2)


@contextmanager
def cm3():
    yield 1
    raise RuntimeError("after")


try:
    with cm3():
        raise KeyError("k")
except KeyError as e:
    print("key propagates", e)
except RuntimeError as e:
    print("after", e)


class C:
    def close(self):
        print("closed")


with closing(C()) as c:
    print("using", c is not None)

with suppress(ValueError):
    raise ValueError("sup")
print("resumed")

with suppress(ValueError, KeyError):
    raise KeyError("k2")
print("resumed2")

try:
    with suppress(ValueError):
        raise TypeError("t")
except TypeError as e:
    print("notsup", e)


def cb(name):
    def _cb():
        print("cb", name)
    return _cb


with ExitStack() as stack:
    stack.callback(cb("first"))
    stack.callback(cb("second"))
    stack.enter_context(closing(C()))
print("stack done")

with ExitStack() as stack:
    stack.callback(cb("x"))
    later = stack.pop_all()
print("popped")
later.close()

try:
    with ExitStack() as stack:
        stack.callback(cb("e1"))
        raise ValueError("stack boom")
except ValueError as e:
    print("stack exc", e)

with nullcontext(5) as v:
    print("null", v)


def t(label, fn):
    try:
        print(label + ":", repr(fn()))
    except Exception as e:
        print(label, type(e).__name__, ":", e)


@contextmanager
def cms(tag):
    time.sleep(0)
    print("enter", tag)
    try:
        yield tag
    finally:
        time.sleep(0)
        print("exit", tag)


with cms("a") as v:
    print("body", v)
    time.sleep(0)
print("after")

try:
    with cms("b"):
        raise ValueError("boom")
except ValueError as e:
    print("outer", e)


def g():
    for i in [1, 2]:
        time.sleep(0)
        yield i


@contextmanager
def cmg():
    yield iter(g())


with cmg() as it:
    print("gen", list(it))


class C:
    def close(self):
        print("closed")


def slow_enter():
    time.sleep(0)
    return C()


with ExitStack() as stack:
    c = stack.enter_context(closing(slow_enter()))
    print("stack body")
print("stack done")
