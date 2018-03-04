setfenv(1, POC)
function IdSort(hash, key, debug)
    local function compare(a, b)
	print(tostring(a))
	local na = tonumber(a[key])
	local nb = tonumber(b[key])
	if na == nil and nb == nil then
	    return a < b
	end
	if na == nil then
	    return false
	end
	if nb == nil then
	    return true
	end
	return  a[key] < b[key]
    end
    local ret = {}
    for _,v in pairs(hash) do
	table.insert(ret, v)
    end

    table.sort(ret, compare)
    return ret
end

function Error(x)
    d("POC error: " .. x)
end
