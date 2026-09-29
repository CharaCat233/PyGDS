# Error: 内部错误站点直接构造的异常对象形态
import random

random.seed(7)
try:
    random.choice({'a': 1})
except KeyError as e:
    print(type(e).__name__)
    print(e)
    print(repr(e))
    print(e.args)

try:
    {}[3]
except KeyError as e:
    print(e)
    print(e.args)

try:
    d = {}
    d.pop('k')
except KeyError as e:
    print(e)
    print(repr(e))
    print(e.args)
    print(e.__cause__)
    print(e.__suppress_context__)

try:
    del undefined_var
except NameError as e:
    print(e)
    print(e.args)

try:
    for x in 5:
        pass
except TypeError as e:
    print(e)
    print(e.args)
