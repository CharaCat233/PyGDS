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
