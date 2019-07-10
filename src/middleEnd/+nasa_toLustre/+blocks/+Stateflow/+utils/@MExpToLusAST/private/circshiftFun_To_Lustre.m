function [code, exp_dt, dim] = circshiftFun_To_Lustre(BlkObj, tree, parent, blk,...
        data_map, inputs, expected_dt, isSimulink, isStateFlow, isMatlabFun)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2019 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Francois Conzelmann <francois.conzelmann@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    [X, X_dt, X_dim] = nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST.expression_To_Lustre(BlkObj, tree.parameters(1),...
        parent, blk, data_map, inputs, expected_dt, ...
        isSimulink, isStateFlow, isMatlabFun);
    [Y, ~, ~] = nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST.expression_To_Lustre(BlkObj, tree.parameters(2),...
        parent, blk, data_map, inputs, 'int', ...
        isSimulink, isStateFlow, isMatlabFun);
    
    X_reshp = reshape(X, X_dim);
    
    if numel(Y) == 1
        Y = Y{1}.value;
    elseif numel(Y) == 2
        Y = [Y{1}.value Y{2}.value];
    else
        % TODO support more than 2 dim
        ME = MException('COCOSIM:TREE2CODE', ...
            'Function in expression "%s" second argument is %d-dimension, more than 2 is not supported.',...
            tree.text, numel(Y));
        throw(ME);
    end
    
    if (length(tree.parameters) > 2)
        [d, ~, ~] = nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST.expression_To_Lustre(BlkObj, tree.parameters(3),...
            parent, blk, data_map, inputs, 'int', ...
            isSimulink, isStateFlow, isMatlabFun);
        code1 = circshift(X_reshp, Y, d{1}.value);
    else
        code1 = circshift(X_reshp, Y);
    end
    exp_dt = X_dt;
    code = reshape(code1, [1 prod(X_dim)]);
    dim = X_dim;
end

