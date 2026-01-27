package fa

FixedMap :: struct($K, $T: typeid, $V: i32) {
    v_data: [V]T,
    k_data: [V]K,
    len, cap: i32,
    v_empty: T,
    k_empty: K,
}

fixed_map :: proc {
    fixed_map_simple,
    fixed_map_custom,
}

fixed_map_simple :: proc($K, $T: typeid, $V: i32) -> FixedMap(K, T, V) {
    res: FixedMap(K, T, V);
    res.cap = V;
    return res;
}

fixed_map_custom :: proc($K, $T: typeid, $V: i32, 
    v_empty: T, k_empty: K) -> FixedMap(K, T, V) {
    res: FixedMap(K, T, V);

    for i in 0..<V {
        res.v_data[i] = v_empty;
        res.k_data[i] = k_empty;
    }

    res.cap = V;
    res.v_empty = v_empty;
    res.k_empty = k_empty;
    return res;
}

map_set :: proc(_map: ^$T/FixedMap, k: $K, v: $E) {
    _map.v_data[_map.len] = v;
    _map.k_data[_map.len] = k;

    if (_map.len == _map.cap) do return;

    _map.len += 1;
}

map_pair :: proc(_map: FixedMap($K, $T, $V), #any_int id: i32) -> (K, T) {
    return _map.k_data[id], _map.v_data[id];
}

map_value :: proc(_map: FixedMap($K, $T, $V), k: K) -> T {
    id := map_index(_map, k);

    if (id == -1) {
        return _map.v_empty;
    }

    return _map.v_data[id];
}

map_remove :: proc(_map: ^$T/FixedMap, k: $K) {
    for i in map_index(_map^, k)..<_map.cap - 1 {
        _map.k_data[i] = _map.k_data[i + 1];
        _map.v_data[i] = _map.v_data[i + 1];
    }

    _map.k_data[_map.cap - 1] = _map.k_empty;
    _map.v_data[_map.cap - 1] = _map.v_empty;

    _map.len -= 1;
}

map_index :: proc(_map: FixedMap($K, $T, $V), k: K) -> i32 {
    for i in 0..<_map.len {
        if (_map.k_data[i] == k) {
            return i;
        }
    }
    return -1;
}

map_clear :: proc(_map: ^$T/FixedMap) {
    for i in 0..<_map.cap {
        _map.k_data[i] = _map.k_empty;
        _map.v_data[i] = _map.v_empty;
    }
    _map.len = 0;
}
