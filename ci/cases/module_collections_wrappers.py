# 职责: ChainMap/UserDict/UserList 的协议面: parents 属性/get/pop/迭代键序/映射相等/data 属性/repr 与列表方法族
# 比对: same_output

from collections import ChainMap, UserDict, UserList


def t(label, fn):
    try:
        print(label, fn())
    except Exception as e:
        print(label, type(e).__name__, str(e))


# --- ChainMap ---
cm = ChainMap({"a": 1}, {"b": 2})
# parents 为属性 (其余映射组成的 ChainMap)
t("cm-parents", lambda: repr(cm.parents))
t("cm-parents-len", lambda: len(cm.parents.maps))
# get: 链式查找与缺省
t("cm-get", lambda: cm.get("a"))
t("cm-get-d", lambda: cm.get("zz", 7))
# pop: 只弹首映射; 缺键有 default 返回之, 缺省报 KeyError
t("cm-pop", lambda: ChainMap({"a": 1}, {"a": 2}).pop("a"))
t("cm-pop-d", lambda: ChainMap({}, {}).pop("a", 9))
t("cm-pop-missing", lambda: ChainMap({}, {}).pop("a"))
# del 缺键: 消息为 KeyError("Key not found in the first mapping: 'a'")
def _del_cm_missing():
    cm2 = ChainMap({}, {})
    del cm2["a"]


t("cm-del-missing", _del_cm_missing)
# 映射相等 (与 dict / 同类比较)
t("cm-eq", lambda: ChainMap({"a": 1}) == {"a": 1})
t("cm-eq2", lambda: ChainMap({"a": 1}) == ChainMap({"a": 1}))
t("cm-ne", lambda: ChainMap({"a": 1}) != {"a": 2})
# 迭代键序: 从最后一张映射开始 update 的字典序 (b 在前), 值由最靠前的含键映射决定
t("cm-iter", lambda: [k for k in ChainMap({"a": 1}, {"b": 2})])
t("cm-keys", lambda: list(ChainMap({"a": 1}, {"b": 2}).keys()))
t("cm-iter-dup", lambda: [k for k in ChainMap({"a": 1, "c": 5}, {"a": 9, "b": 2})])
t("cm-values", lambda: list(ChainMap({"a": 1}, {"b": 2}).values()))
t("cm-items", lambda: list(ChainMap({"a": 1}, {"b": 2}).items()))
t("cm-len", lambda: len(cm))
t("cm-copy", lambda: repr(ChainMap({"a": 1}).copy()))
t("cm-in", lambda: "a" in cm)
t("cm-newchild", lambda: repr(ChainMap({"a": 1}).new_child({"b": 2})))

# --- UserDict ---
ud = UserDict({"a": 1, "b": 2})
# data 为属性 (包装的 dict 本身)
t("ud-data", lambda: repr(ud.data))
t("ud-repr", lambda: repr(ud))
t("ud-eq", lambda: UserDict({"a": 1}) == {"a": 1})
t("ud-eq2", lambda: UserDict({"a": 1}) == UserDict({"a": 1}))
t("ud-ne", lambda: UserDict({"a": 1}) != {"a": 2})
t("ud-in", lambda: "a" in UserDict({"a": 1}))
t("ud-in-missing", lambda: "zz" in UserDict({"a": 1}))
t("ud-keys", lambda: sorted(UserDict({"a": 1, "b": 2}).keys()))
t("ud-values", lambda: sorted(UserDict({"a": 1, "b": 2}).values()))
t("ud-items", lambda: sorted(UserDict({"a": 1, "b": 2}).items()))
t("ud-iter", lambda: [k for k in UserDict({"a": 1, "b": 2})])
t("ud-get", lambda: UserDict({"a": 1}).get("zz", 5))
t("ud-pop", lambda: UserDict({"a": 1}).pop("a"))
t("ud-update", lambda: (UserDict({"a": 1}).update({"c": 3}), 1)[1])


def _del_ud_missing():
    ud3 = UserDict({"a": 1})
    del ud3["zz"]


t("ud-del-expr", _del_ud_missing)
t("ud-missing", lambda: ud["zz"])

# --- UserList ---
ul = UserList([1, 2])
# data 为属性
t("ul-data", lambda: repr(ul.data))
# repr 为包装列表自身的列表形态
t("ul-repr", lambda: repr(ul))
t("ul-eq", lambda: UserList([1]) == [1])
t("ul-eq2", lambda: UserList([1]) == UserList([1]))
t("ul-ne", lambda: UserList([1]) != [2])
t("ul-append", lambda: (ul.append(3), ul.data))
t("ul-delitem", lambda: UserList([1, 2]).__delitem__(0))
t("ul-getitem", lambda: UserList([1, 2])[1])
t("ul-insert", lambda: (UserList([1, 2]).insert(0, 9), 1)[1])
t("ul-pop", lambda: UserList([1, 2]).pop())
t("ul-remove", lambda: (UserList([1, 2]).remove(1), 1)[1])
t("ul-extend", lambda: (UserList([1]).extend([2, 3]), 1)[1])
t("ul-reverse", lambda: (UserList([1, 2]).reverse(), 1)[1])
t("ul-sort", lambda: (UserList([2, 1]).sort(), 1)[1])
t("ul-count", lambda: UserList([1, 1, 2]).count(1))
t("ul-index", lambda: UserList([1, 2]).index(2))
t("ul-clear", lambda: (UserList([1]).clear(), 1)[1])
t("ul-copy", lambda: repr(UserList([1, 2]).copy()))
t("ul-add", lambda: UserList([1]) + [2])
t("ul-iadd", lambda: (lambda u: (u.__iadd__([2]), u)[1])(UserList([1])))
t("ul-mul", lambda: UserList([1]) * 2)
t("ul-slice", lambda: UserList([1, 2, 3])[0:2])
t("ul-len", lambda: len(UserList([1, 2])))
t("ul-iter", lambda: [x for x in UserList([1, 2])])
t("ul-in", lambda: 1 in UserList([1, 2]))
t("ul-lt", lambda: UserList([1]) < [2])
