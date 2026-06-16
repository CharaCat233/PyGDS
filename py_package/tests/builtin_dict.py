# Builtin: dict 操作


d = dict()
d["name"] = "Alice"
d["age"] = 30
print(d)  # {'name': Alice, 'age': 30}

# dict.get
print(d.get("name", "???") == "Alice")  # True
print(d.get("missing", "???") == "???")  # True

# dict.keys / dict.values
keys = d.keys()
print(keys)  # ['name', 'age'] (order may vary)
vals = d.values()
print(vals)  # ['Alice', 30]

# dict.items
items = d.items()
item_count = 0
for kv in items:
    print(kv[0], kv[1])
    item_count = item_count + 1
print("item count:", item_count == 2)  # True

# dict.pop
age = d.pop("age", -1)
print(age, d)  # 30 {'name': Alice}

# dict.update
d2 = dict()
d2["city"] = "NYC"
d2["name"] = "Bob"
d.update(d2)
print(d)  # {'name': Bob, 'city': NYC}

# dict.copy + dict.clear
d3 = d.copy()
print(d3)  # {'name': Bob, 'city': NYC}
d3.clear()
print(d3)  # {}

# dict constructor from list of pairs
d4 = dict([[1, "one"], [2, "two"]])
print(d4)  # {'1': one, '2': two}
