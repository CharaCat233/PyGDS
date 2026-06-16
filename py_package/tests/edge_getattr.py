# Edge: __getattr__ / __setattr__ / __delattr__

class Proxy:
    def __init__(self):
        self._data = {}

    def __getattr__(self, name):
        if name.startswith("_"):
            raise AttributeError(name)
        return self._data.get(name, "N/A")

    def __setattr__(self, name, value):
        if name.startswith("_"):
            object.__setattr__(self, name, value)
        else:
            self._data[name] = value

    def __delattr__(self, name):
        if name.startswith("_"):
            object.__delattr__(self, name)
        elif name in self._data:
            del self._data[name]

p = Proxy()
p.foo = 42
p.bar = "hello"
print(p.foo)                 # 42
print(p.bar)                 # hello
print(p.baz)                 # N/A (default from __getattr__)

del p.foo
print(p.foo)                 # N/A (已删除)

print("done")