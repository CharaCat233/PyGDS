# Lang: 任意装饰器与带参装饰器

LOG = []


def trace(fn):
    def wrapper(*args, **kwargs):
        LOG.append("call " + str(args[0]))
        return fn(*args, **kwargs)
    return wrapper


def tag(t):
    def deco(fn):
        LOG.append("tag " + t)
        return fn
    return deco


@trace
def double(x):
    return x * 2


@tag("alpha")
@trace
def triple(x):
    return x * 3


print(double(4))
print(triple(5))
print(LOG)


def add_id(cls):
    cls.id = 100
    return cls


@add_id
class Widget:
    name = "w"


print(Widget.name, Widget.id)


REG = []


def collect(fn):
    REG.append("got")
    return fn


class Service:
    @collect
    def run(self):
        return "run"

    @staticmethod
    @collect
    def ping():
        return "ping"


print(REG)
print(Service().run(), Service.ping())


def passthrough(prop):
    return prop


class Temp:
    @passthrough
    @property
    def val(self):
        return 9


print(Temp().val)

try:
    @5
    def broken():
        pass
except TypeError as e:
    print("deco err:", e)


def deco(fn):
    return fn


@deco
def gen():
    yield 1
    yield 2


print(list(gen()))

import time


def slow_deco(fn):
    def wrapper(x):
        time.sleep(0.01)
        return fn(x) + 1
    return wrapper


@slow_deco
def add_one(x):
    return x


print(add_one(9))


def make_deco():
    time.sleep(0.01)
    return deco


@make_deco()
def late():
    return "late"


print(late())

EVENTS = []


def factory(name):
    EVENTS.append("make " + name)

    def deco(fn):
        EVENTS.append("apply " + name)
        return fn
    return deco


@factory("a")
@factory("b")
def ordered():
    pass


print(EVENTS)
