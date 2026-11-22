# 职责: 异常实例的 args 读写与删除保护, add_note 与 __notes__, StopIteration.value
# 比对: same_output

e = ValueError("x")
print(e.args)
e.args = (1, 2)
print(e.args, str(e))
try:
    e.args = 5
except TypeError as err:
    print("args-type:", err)
try:
    del e.args
except TypeError as err:
    print("args-del:", err)
try:
    del e.__traceback__
except TypeError as err:
    print("tb-del:", err)
try:
    del e.__cause__
except TypeError as err:
    print("cause-del:", err)
try:
    del e.__suppress_context__
except TypeError as err:
    print("sup-del:", err)

n = ValueError("y")
n.add_note("first")
n.add_note("second")
print(n.__notes__)
try:
    n.add_note(1)
except TypeError as err:
    print("note-type:", err)
try:
    n.add_note()
except TypeError as err:
    print("note-arity:", err)
del n.__notes__
try:
    print(n.__notes__)
except AttributeError as err:
    print("notes-missing:", err)


def gen():
    yield 1
    return 7


it = gen()
print(next(it))
try:
    next(it)
except StopIteration as stop:
    print("value:", stop.value, "args:", stop.args, "str:", str(stop))
