# 职责: 用户类上下文管理器协议语义 (__exit__ 参数形态, 抑制真值表, 异常取代与嵌套展开)
# 比对: same_output

# __exit__ 异常参数形态: t 为异常类 (str 后与 CPython 的 <class 'X'> 一致),
# v 为异常实例; tb 参数 PyGDS 恒传 None (无 traceback 对象, 既定形态不做双端比对)
class Probe:
    def __enter__(self):
        return self

    def __exit__(self, t, v, tb):
        print("args:", t if t is None else str(t), type(t).__name__ if t else None)
        print("val:", v if v is None else repr(str(v)))
        return False


try:
    with Probe():
        raise KeyError("k")
except KeyError as e:
    print("caught", e)

with Probe():
    print("clean-body")

# 用户异常子类: t 是用户类对象, 实例经 v 取回消息
class MyErr(Exception):
    pass


class Probe2:
    def __enter__(self):
        return self

    def __exit__(self, t, v, tb):
        print("user-err:", str(t), v.args[0])
        return False


try:
    with Probe2():
        raise MyErr("mine")
except MyErr:
    print("user-caught")

# 抑制真值表: 真值返回抑制在途异常, 假值 (None/0/空串/False) 放行
def make_exit(ret):
    class R:
        def __enter__(self):
            return self

        def __exit__(self, t, v, tb):
            return ret
    return R()


for ret, label in [(True, "T"), (1, "1"), ("s", "s"), (None, "N"), (0, "0"), ("", "e"), (False, "F")]:
    try:
        with make_exit(ret):
            raise ValueError("v")
        print(label, "suppressed")
    except ValueError:
        print(label, "propagated")

# 抑制后管理器嵌套展开: 内层抑制, 外层收到无异常参数
log = []


class Sup:
    def __init__(self, name):
        self.name = name

    def __enter__(self):
        return self

    def __exit__(self, t, v, tb):
        log.append("%s:%s" % (self.name, "none" if t is None else str(t)))
        return True


class Passthrough:
    def __init__(self, name):
        self.name = name

    def __enter__(self):
        return self

    def __exit__(self, t, v, tb):
        log.append("%s:%s" % (self.name, "none" if t is None else str(t)))
        return False


with Sup("inner"), Passthrough("outer"):
    raise ValueError("boom")
print("after-suppress")
print(log)

# __exit__ 内新异常取代在途异常: 旧异常记录为 __context__ (CPython 语义)
class BoomExit:
    def __enter__(self):
        return self

    def __exit__(self, t, v, tb):
        raise RuntimeError("in-exit")


try:
    with BoomExit():
        raise ValueError("orig")
except Exception as e:
    print("exit-raise:", type(e).__name__, e, "ctx:", type(e.__context__).__name__)

# 内层 __exit__ 抛新异常: 外层管理器的 __exit__ 仍以新异常继续逆序调用 (嵌套语义)
log.clear()
try:
    with Passthrough("p1"), BoomExit():
        print("never")
except RuntimeError as e:
    print("exit-raise-nested:", e)
print(log)

# 后续管理器 __enter__ 失败: 已进入的管理器仍逆序退出并收到异常 (多管理器嵌套语义)
class BadEnter:
    def __enter__(self):
        raise KeyError("bad-enter")

    def __exit__(self, t, v, tb):
        return False


log.clear()
try:
    with Passthrough("p2"), BadEnter():
        print("never-entered")
except KeyError as e:
    print("enter-fail:", e)
print(log)

# 无异常时 __exit__ 返回真值被忽略: 体正常结束不受影响
class AlwaysTrue:
    def __enter__(self):
        return self

    def __exit__(self, t, v, tb):
        return True


with AlwaysTrue():
    print("true-exit-clean")
