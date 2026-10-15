# duty: bisect 模块二分查找与插入, heapq 模块堆操作 (CPython 对齐)
# 比对: same_output
import bisect, heapq


def show(label, fn):
    try:
        print(label, "OK", repr(fn()))
    except Exception as e:
        print(label, type(e).__name__)


# bisect: 查找与插入
a = [1, 3, 5, 7, 9]
print("bl", bisect.bisect_left(a, 5))
print("br", bisect.bisect_right(a, 5))
print("b0", bisect.bisect_left(a, 0))
print("b10", bisect.bisect_right(a, 10))
print("blo", bisect.bisect_left(a, 5, 0, 3))
b = [1, 3, 5, 7]
bisect.insort_left(b, 5)
print("insL", b)
bisect.insort_right(b, 5)
print("insR", b)
show("badt", lambda: bisect.bisect_left([1, "x"], 2))

# heapq: 堆操作
h = []
heapq.heappush(h, 3)
heapq.heappush(h, 1)
heapq.heappush(h, 2)
print("hp", h)
print("pop", heapq.heappop(h), h)
h2 = [5, 3, 8, 1, 9, 2]
heapq.heapify(h2)
print("hf", h2)
print("hr", heapq.heapreplace(h2, 4), h2)
print("hpp", heapq.heappushpop(h2, 0), h2)
print("hpp2", heapq.heappushpop(h2, 100), h2)
show("badcmp", lambda: heapq.heappush([1, "x"], 2))

# bisect key= 语义 (此前 key 整体忽略静默错位, 且对 needle 也施加 key)
# CPython: key 只施加于列表元素, 不施加于检索值; 不可比较报 TypeError
show("bk1", lambda: bisect.bisect_left(["aaa", "bb", "c"], "cc", key=len))
data = [(1, "b"), (1, "a"), (0, "c")]
data.sort(key=lambda t: t[0])
show("bk2", lambda: bisect.bisect_left(data, (1, "z"), key=lambda t: t[0]))
show("bk3", lambda: bisect.bisect_right(data, (1, "z"), key=lambda t: t[0]))
show("bk4", lambda: bisect.bisect_left([1, 2, 3], 2, key=None))
show("bk5", lambda: bisect.bisect_left([1, 2], 1, key=5))

# bisect/insort 的 lo=/hi= 关键字实参生效 (此前只读位置实参); insort key= 生效
L95 = [1, 2, 3]
print(bisect.bisect_left(L95, 0, lo=1))
print(bisect.bisect_left(L95, 0, hi=1))
print(bisect.bisect_right(L95, 2, lo=1, hi=2))
print(bisect.bisect_left(L95, 0, lo=0, hi=3))
try:
    print(bisect.bisect_left(L95, 0, 1, lo=2))
except TypeError as e:
    print("TE:", e)
try:
    print(bisect.bisect_left(L95, 0, lo=None))
except TypeError as e:
    print("TE2:", e)
try:
    print(bisect.bisect_left(L95, 0, lo=1.5))
except TypeError as e:
    print("TE3:", e)
a95 = [1, 3, 5]
bisect.insort_left(a95, 4, lo=1)
print(a95)
b95 = [("a", 1), ("c", 3)]
bisect.insort_right(b95, ("b", 2), key=lambda t: t[1])
print(b95)
c95 = [1, 3, 5]
print(bisect.bisect_left(c95, 4, key=lambda v: v * 2))
d95 = [1, 3, 5]
bisect.insort_left(d95, 4, key=lambda v: v * 2)
print(d95)

# heapq nsmallest/nlargest/merge 补齐, heapreplace 空列表
try:
    heapq.heapreplace([], 1)
except IndexError as e:
    print("hr0:", str(e))
print("ns:", heapq.nsmallest(3, [5, 1, 8, 2, 9, 3]))
print("nl:", heapq.nlargest(2, [5, 1, 8, 2]))
print(
    "ns-key:", heapq.nsmallest(3, [{"n": 3}, {"n": 1}, {"n": 2}], key=lambda x: x["n"])
)
print("mg:", list(heapq.merge([1, 3, 5], [2, 4, 6])))
print("mg3:", list(heapq.merge([1, 4], [2, 3], [0, 5])))
