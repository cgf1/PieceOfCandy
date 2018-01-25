function POC_IdSort(hash, key)
    local ret = {}
    local last
    -- Assumes one and only one non-numeric, i.e. "MIA"
    for n, v in pairs(hash) do
        local x = tonumber(v[key])
        if x == nil then
            last = v
        else
            ret[x] = v
        end
    end
    if last ~= nil then
        table.insert(ret, last)
    end
    return ret
end
