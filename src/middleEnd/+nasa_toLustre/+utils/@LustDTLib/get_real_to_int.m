function [node, external_nodes, opens, abstractedNodes] = get_real_to_int(lus_backend, varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if LusBackendType.isKIND2(lus_backend)
        import nasa_toLustre.lustreAst.*
        opens = {};
        abstractedNodes = {};
        external_nodes = {'LustDTLib__Floor', 'LustDTLib__Ceiling'};
        node = LustreNode();
        node.setName('real_to_int');
        node.setInputs(LustreVar('x', 'real'));
        node.setOutputs(LustreVar('y', 'int'));
        node.setIsMain(false);
        ifAst = IteExpr(...
            BinaryExpr(BinaryExpr.GTE, VarIdExpr('x'), RealExpr('0.0')), ...
            NodeCallExpr('_Floor', VarIdExpr('x')), ...
            NodeCallExpr('_Ceiling', VarIdExpr('x')));
        node.setBodyEqs(LustreEq(VarIdExpr('y'), ifAst));
    else
        opens = {'conv'};
        abstractedNodes = {};
        external_nodes = {};
        node = {};
    end
end