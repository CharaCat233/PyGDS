# Edge: sorted / reversed / enumerate / zip

# sorted
print(sorted([3, 1, 2]))              # [1, 2, 3]
print(sorted([3, 1, 2], reverse=True)) # [3, 2, 1]
print(sorted(["bb", "a", "ccc"], key=len)) # ['a', 'bb', 'ccc']

# reversed
print(list(reversed([1, 2, 3])))     # [3, 2, 1]
print(list(reversed("abc")))         # ['c', 'b', 'a']

# enumerate
print(list(enumerate(["a", "b", "c"]))) # [(0, 'a'), (1, 'b'), (2, 'c')]
print(list(enumerate(["a", "b"], start=5))) # [(5, 'a'), (6, 'b')]

# zip
print(list(zip([1, 2, 3], ["a", "b", "c"]))) # [(1, 'a'), (2, 'b'), (3, 'c')]
print(list(zip([1, 2], ["a", "b", "c"])))    # [(1, 'a'), (2, 'b')]
print(list(zip([1, 2, 3], ["a", "b"])))      # [(1, 'a'), (2, 'b')]

print("done")