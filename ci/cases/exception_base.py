# 职责: BaseException 捕获语义与自定义直接子类
# 比对: same_output

# BaseException 注册为可引用名 (P1-62)
print(issubclass(ValueError, BaseException))
print(issubclass(BaseException, BaseException))
print(issubclass(Exception, BaseException))
print(issubclass(GeneratorExit, BaseException), issubclass(GeneratorExit, Exception))
print(issubclass(KeyError, BaseException))
print(type(BaseException).__name__ if isinstance(BaseException, type) else "obj")


# except BaseException 捕获一切异常
try:
    raise ValueError("v")
except BaseException as e:
    print("caught:", type(e).__name__, e)

# except Exception 不捕获裸 BaseException
try:
    raise BaseException("be")
except Exception:
    print("wrong")
except BaseException as e:
    print("be:", str(e))


# 自定义 BaseException 直接子类
class Fatal(BaseException):
    pass


f = Fatal("msg")
print(type(f).__name__, f.args)
try:
    raise Fatal("down")
except BaseException as e:
    print("fatal:", type(e).__name__)
try:
    raise Fatal("f2")
except Exception:
    print("wrong2")
except Fatal as e:
    print("as-fatal:", e)

# GeneratorExit 经 except BaseException 可见 (生成器 close 场景)
def gen():
    try:
        yield 1
    except BaseException:
        print("gen saw base")
        raise
    finally:
        print("gen fin")


it = gen()
print(next(it))
it.close()
print("closed")

# 用户子类继承 GeneratorExit
class MyExit(GeneratorExit):
    pass


me = MyExit("m")
print(me.args)
print(issubclass(MyExit, BaseException), issubclass(MyExit, Exception))
