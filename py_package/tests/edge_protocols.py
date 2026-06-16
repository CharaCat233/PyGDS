# Edge: __len__ / __contains__ / __iter__ / __next__

# __len__
class MyCollection:
    def __init__(self, items):
        self.items = items
    def __len__(self):
        return len(self.items)
    def __contains__(self, item):
        return item in self.items
    def __iter__(self):
        return iter(self.items)

mc = MyCollection([1, 2, 3, 4, 5])
print(len(mc))               # 5
print(3 in mc)               # True
print(6 in mc)               # False

for item in mc:
    print(item, end=" ")     # 1 2 3 4 5
print()

# 转列表
print(list(mc))              # [1, 2, 3, 4, 5]

print("done")