# __iter__ 返回非迭代对象的文案 (alpha.5, P2-43)
class I:
    def __iter__(self):
        return 5
try:
    for x in I():
        pass
except TypeError as e:
    print("TI:", e)
class L:
    def __iter__(self):
        return [1, 2]
try:
    for x in L():
        pass
except TypeError as e:
    print("TL:", e)
class Self:
    def __iter__(self):
        return self
    def __next__(self):
        raise StopIteration
print(list(Self()))
