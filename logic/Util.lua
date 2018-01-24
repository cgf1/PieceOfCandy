function POC_IdSort(hash, key)
    local ret = {}
    for n, v in pairs(hash) do
        ret[tonumber(v[key])] = v
    end
    return ret
end
