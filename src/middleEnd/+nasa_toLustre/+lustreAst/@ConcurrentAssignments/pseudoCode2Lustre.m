function [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft, node, data_map)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2019 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    old_outputs_map = containers.Map(outputs_map.keys, outputs_map.values);
    new_assignments = cell(numel(obj.assignments), 1);
    for i=1:numel(obj.assignments)
        if isa(obj.assignments{i}, 'nasa_toLustre.lustreAst.LustreEq')

            if isa(obj.assignments{i}.getRhs(), 'nasa_toLustre.lustreAst.IteExpr')
                [rhs, ~] = ...
                    obj.assignments{i}.getRhs().pseudoCode2Lustre_OnlyElseExp(...
                    outputs_map, old_outputs_map, node, data_map);
            else
                [rhs, ~] = ...
                    obj.assignments{i}.getRhs().pseudoCode2Lustre(...
                    old_outputs_map, false, node, data_map);
            end
            [lhs, outputs_map] = ...
                obj.assignments{i}.getLhs().pseudoCode2Lustre(...
                outputs_map, true, node, data_map);
            new_assignments{i} = nasa_toLustre.lustreAst.LustreEq(lhs, rhs);
        else
            [new_assignments{i}, outputs_map] = ...
                obj.assignments{i}.pseudoCode2Lustre(outputs_map, isLeft, node, data_map);
        end
    end
    new_obj = nasa_toLustre.lustreAst.ConcurrentAssignments(new_assignments);
end
