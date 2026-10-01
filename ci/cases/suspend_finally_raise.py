# 职责: finally 挂起时在途异常传播
# 比对: same_output

# finally 体内 sleep 挂起时, 进行中的异常照常传播 (与 CPython 一致)

import time


def plain():
    try:
        raise ValueError("v")
    finally:
        time.sleep(0)
        print("fin1")


try:
    plain()
except ValueError as e:
    print("caught1", e)


# finally 内两次 sleep, 在途异常保持


def two_sleep():
    try:
        raise ValueError("t")
    finally:
        time.sleep(0)
        print("f-a")
        time.sleep(0)
        print("f-b")


try:
    two_sleep()
except ValueError as e:
    print("caught2", e)


# finally 抛出新异常: 取代在途异常, 原异常进入 __context__


def fin_new():
    try:
        raise ValueError("old")
    finally:
        time.sleep(0)
        raise KeyError("new")


try:
    fin_new()
except Exception as e:
    print("caught3", type(e).__name__, e)
    print("ctx3", type(e.__context__).__name__)


# try 体 return, finally 挂起后返回值保留


def with_ret():
    try:
        return "ret"
    finally:
        time.sleep(0)
        print("fin4")


print("ret4", with_ret())


# 嵌套 try/finally 均挂起, 异常穿两层


def inner_suspend():
    try:
        raise ValueError("in")
    finally:
        time.sleep(0)
        print("fin-in")


def outer_nested():
    try:
        try:
            raise ValueError("out")
        except TypeError:
            print("never1")
        finally:
            time.sleep(0)
            print("fin-out1")
    finally:
        time.sleep(0)
        print("fin-out2")


try:
    outer_nested()
except ValueError as e:
    print("caught5", e)


# 裸 raise 重抛, 重抛语句与 finally 均挂起


def reraise_chain():
    try:
        raise ValueError("first")
    except ValueError:
        try:
            time.sleep(0)
            raise
        finally:
            time.sleep(0)
            print("fin6")


try:
    reraise_chain()
except ValueError as e:
    print("caught6", e)


# except 处理器内 sleep + 外层 finally, 处理完毕不再向外传播


def handler_sleep():
    try:
        raise ValueError("h")
    except ValueError as e:
        time.sleep(0)
        print("handler", e)
    finally:
        time.sleep(0)
        print("fin7")


try:
    handler_sleep()
except Exception:
    print("never2")


# 循环中 break 丢弃语义与 finally 挂起
for i in range(3):
    try:
        if i == 1:
            break
        print("iter", i)
    finally:
        time.sleep(0)
        print("fin-loop", i)


# 生成器 yield from 委托链: 子生成器 finally 挂起, 在途异常穿两层


def sub_gen():
    try:
        yield 1
        raise ValueError("g")
    finally:
        time.sleep(0)
        print("gfin")


def deleg():
    yield from sub_gen()


try:
    for x in deleg():
        print("got", x)
except ValueError as e:
    print("caught8", e)


# 普通函数调用时立即 raise: for 迭代开始前异常即抛出
# (生成器体内挂起后 raise 的场景见 suspend_nested)
def late_raise():
    try:
        time.sleep(0)
        raise ValueError("k")
    finally:
        print("fin9")


try:
    for y in late_raise():
        print("never3", y)
except ValueError as e:
    print("caught9", e)

print("done")
