# 职责: except* 语义 (子组匹配与形态, 自动包装, 多子句消费余量, else/finally, 处理器异常)
# 比对: same_output

# 裸异常自动包装: 消息空串的 ExceptionGroup, as 直接绑定组 (恒为组, CPython 同)
def t2():
    try:
        raise ValueError("v")
    except* ValueError as e:
        print("t2:", type(e).__name__, repr(str(e)), len(e.exceptions))


t2()


# 多子句逐个消费余量: 每个命中的子句都执行
def t1():
    try:
        raise ExceptionGroup("g", [ValueError("v"), TypeError("t")])
    except* TypeError as e:
        print("t1-ty:", str(e), len(e.exceptions))
    except* ValueError as e:
        print("t1-ve:", str(e), len(e.exceptions))


t1()


# 余量以组形态传播 (剩余成员重建同型同消息组)
def t3():
    try:
        raise ExceptionGroup("g", [ValueError("a"), ValueError("b"), TypeError("t")])
    except* ValueError as e:
        print("t3:", len(e.exceptions))


try:
    t3()
except Exception as e:
    print("t3-rest:", type(e).__name__, str(e), len(e.exceptions))


# 全不命中: 余量整体传播
def t5():
    try:
        raise ExceptionGroup("g", [KeyError("k"), ValueError("v")])
    except* ValueError as e:
        print("t5-never")


try:
    t5()
except Exception as e:
    print("t5-rest:", type(e).__name__, str(e), len(e.exceptions))


# 裸异常不匹配: 传播原裸异常 (非包装组)
def t6():
    try:
        raise ValueError("v")
    except* TypeError as e:
        print("t6-never")


try:
    t6()
except Exception as e:
    print("t6-rest:", type(e).__name__, str(e))

# finally 与 else
def t7():
    try:
        raise ExceptionGroup("g", [ValueError("v")])
    except* ValueError as e:
        print("t7-ve")
    finally:
        print("t7-fin")


t7()


def t8():
    try:
        pass
    except* ValueError as e:
        print("t8-never")
    else:
        print("t8-else")


t8()


# as 名在子句后删除
def t9():
    try:
        raise ExceptionGroup("g", [ValueError("v")])
    except* ValueError as e:
        print("t9-bound:", type(e).__name__)


t9()
try:
    print(e)
except NameError:
    print("t9-deleted: NameError")

# 处理器内新异常: 余量丢弃, __context__ 链记录
def t10():
    try:
        raise ExceptionGroup("g", [ValueError("v")])
    except* ValueError as e:
        raise KeyError("k")


try:
    t10()
except Exception as ex:
    print("t10:", type(ex).__name__, "ctx:", type(ex.__context__).__name__)

# 元组类型过滤器; 余量传播
def t11():
    try:
        raise ExceptionGroup("g", [ValueError("v"), TypeError("t")])
    except* (TypeError, KeyError) as e:
        print("t11:", str(e), len(e.exceptions))


try:
    t11()
except Exception as e:
    print("t11-rest:", str(e), len(e.exceptions))
