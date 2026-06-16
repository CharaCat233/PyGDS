# Edge: assert 语句

assert True, "should not fail"
print("passed 1")

try:
    assert False, "custom message"
except AssertionError as e:
    print(str(e))          # custom message

try:
    assert False
except AssertionError as e:
    print(str(e) == "")    # True (bare assert)

# assert 带表达式的条件
x = 5
assert x == 5
print("passed 2")

try:
    assert x == 6, "x != 6"
except AssertionError as e:
    print(type(e).__name__) # AssertionError

print("done")
