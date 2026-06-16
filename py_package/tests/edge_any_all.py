# Edge: any / all

print(any([True, False]))    # True
print(any([False, False]))   # False
print(any([]))               # False
print(any([0, "", []]))      # False
print(any([0, "hi"]))        # True

print(all([True, True]))     # True
print(all([True, False]))    # False
print(all([]))               # True
print(all([1, "hi", [1]]))   # True
print(all([1, "", [1]]))     # False

print("done")