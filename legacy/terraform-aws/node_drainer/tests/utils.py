import collections

from types import SimpleNamespace


def dict_to_simple_namespace(orig_dict, skip={}):
    def _dict_to_simple_namespace(d, path=""):
        res = {}
        for k, v in d.items():
            cur_path = path + "." + k
            if skip.get(cur_path):
                res[k] = v
            elif isinstance(v, list):
                res[k] = [SimpleNamespace(**_dict_to_simple_namespace(x, path=cur_path)) for x in v]
            elif isinstance(v, collections.abc.Mapping):
                res[k] = SimpleNamespace(**_dict_to_simple_namespace(v, path=cur_path))
            else:
                res[k] = v
        return res

    return SimpleNamespace(**_dict_to_simple_namespace(orig_dict))
