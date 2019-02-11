
function names = getDataName(d)
    if isfield(d, 'CompiledSize')
        CompiledSize = str2num(d.CompiledSize);
    elseif isfield(d, 'ArraySize')
        CompiledSize = str2num(d.ArraySize);
    else
        CompiledSize = 1;
    end
    CompiledSize = prod(CompiledSize);
    if CompiledSize == 1 || CompiledSize == -1
        names = {d.Name};
    else
        for i=1:CompiledSize
            names{i} = sprintf('%s__ID%.0f_Index%d', d.Name, d.Id, i);
        end
    end
end
