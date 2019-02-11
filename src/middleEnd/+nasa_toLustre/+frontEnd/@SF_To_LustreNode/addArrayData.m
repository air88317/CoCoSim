
function SF_DATA_MAP = addArrayData(SF_DATA_MAP, d_list)
    import nasa_toLustre.frontEnd.SF_To_LustreNode
    for i=1:numel(d_list)
        names = SF_To_LustreNode.getDataName(d_list{i});
        if numel(names) > 1
            for j=1:numel(names)
                d = d_list{i};
                d.Name = names{j};
                d.ArraySize = '1';
                d.CompiledSize = '1';
                try
                    [v, ~, ~] = ...
                        SLXUtils.evalParam(gcs, [], [], d.InitialValue);
                catch
                    v = 0;
                end
                if numel(v) >= j
                    v = v(j);
                else
                    v = v(1);
                end
                d.InitialValue = num2str(v);
                SF_DATA_MAP(names{j}) = d;
            end
        end
    end
end
