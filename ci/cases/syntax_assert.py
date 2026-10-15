# 职责: assert 报错消息与 AssertionError
# 比对: same_output


assert True, "should not fail"
print("passed 1")

try:
    assert False, "custom message"
except AssertionError as e:
    print(str(e))  # custom message

try:
    assert False
except AssertionError as e:
    print(str(e) == "")  # True (bare assert)

# assert 带表达式的条件
x = 5
assert x == 5
print("passed 2")

try:
    assert x == 6, "x != 6"
except AssertionError as e:
    print(type(e).__name__)  # AssertionError


# assert 消息表达式求值异常优先传播 (此前被顶替为 AssertionError)
try:
    assert False, undefined_qq
except NameError:
    print("nameerror")
except AssertionError:
    print("assertionerror")

# except 类型表达式求值异常立即传播, 不落入后续子句
try:
    try:
        raise ValueError("v")
    except undefined_qq:
        pass
    except NameError:
        print("swallowed")
except NameError:
    print("propagated")

try:
    assert True, undefined_qq
    print("assert-ok")
except NameError:
    print("assert-ok-ne")

try:
    assert False, "plain msg"
except AssertionError as e:
    print("AE:", e)
