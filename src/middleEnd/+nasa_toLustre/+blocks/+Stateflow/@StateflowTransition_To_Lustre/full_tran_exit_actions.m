
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%exit actions
function [body, outputs, inputs] = ...
        full_tran_exit_actions(transitions, parentPath, trans_cond)
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    global SF_STATES_NODESAST_MAP SF_STATES_PATH_MAP;

    body = {};
    outputs = {};
    inputs = {};
    %Add Exit Actions
    first_source = SF_STATES_PATH_MAP(transitions{1}.Source);
    last_destination = transitions{end}.Destination;
    source_parent = first_source;
    if ~strcmp(source_parent.Path, parentPath)
        %Go to the same level of the destination.
        while ~StateflowTransition_To_Lustre.isParent(...
                StateflowTransition_To_Lustre.getParent(source_parent),...
                last_destination)
            source_parent = ...
                StateflowTransition_To_Lustre.getParent(source_parent);
        end
        if isequal(source_parent.Composition.Type,'AND')
            %Parallel state Exit.
            parent = ...
                StateflowTransition_To_Lustre.getParent(source_parent);
            siblings = SF_To_LustreNode.orderObjects(...
                StateflowState_To_Lustre.getSubStatesObjects(parent), ...
                'ExecutionOrder');
            nbrsiblings = numel(siblings);
            for i=nbrsiblings:-1:1
                exitNodeName = ...
                    StateflowState_To_Lustre.getExitActionNodeName(siblings{i});
                if isKey(SF_STATES_NODESAST_MAP, exitNodeName)
                    %condition Action exists.
                    actionNodeAst = SF_STATES_NODESAST_MAP(exitNodeName);
                    [call, oututs_Ids] = actionNodeAst.nodeCall(true, BooleanExpr(false));
                    if isempty(trans_cond)
                        body{end+1} = LustreEq(oututs_Ids, call);
                        outputs = [outputs, actionNodeAst.getOutputs()];
                        inputs = [inputs, actionNodeAst.getInputs()];
                    else
                        body{end+1} = LustreEq(oututs_Ids, ...
                            IteExpr(trans_cond, call, TupleExpr(oututs_Ids)));
                        outputs = [outputs, actionNodeAst.getOutputs()];
                        inputs = [inputs, actionNodeAst.getOutputs()];
                        inputs = [inputs, actionNodeAst.getInputs()];
                    end
                end

            end
        else
            %Not Parallel state Exit
            exitNodeName = ...
                StateflowState_To_Lustre.getExitActionNodeName(source_parent);
            if isKey(SF_STATES_NODESAST_MAP, exitNodeName)
                %condition Action exists.
                actionNodeAst = SF_STATES_NODESAST_MAP(exitNodeName);
                [call, oututs_Ids] = actionNodeAst.nodeCall(true, BooleanExpr(false));
                if isempty(trans_cond)
                    body{end+1} = LustreEq(oututs_Ids, call);
                    outputs = [outputs, actionNodeAst.getOutputs()];
                    inputs = [inputs, actionNodeAst.getInputs()];
                else
                    body{end+1} = LustreEq(oututs_Ids, ...
                        IteExpr(trans_cond, call, TupleExpr(oututs_Ids)));
                    outputs = [outputs, actionNodeAst.getOutputs()];
                    inputs = [inputs, actionNodeAst.getOutputs()];
                    inputs = [inputs, actionNodeAst.getInputs()];
                end
            end
        end
    else
        %the case of inner transition where we don't exit the parent state but we
        %exit active child
        exitNodeName = ...
            StateflowState_To_Lustre.getExitActionNodeName(source_parent);
        if isKey(SF_STATES_NODESAST_MAP, exitNodeName)
            %condition Action exists.
            actionNodeAst = SF_STATES_NODESAST_MAP(exitNodeName);
            [call, oututs_Ids] = actionNodeAst.nodeCall(true, BooleanExpr(true));
            if isempty(trans_cond)
                body{end+1} = LustreEq(oututs_Ids, call);
                outputs = [outputs, actionNodeAst.getOutputs()];
                inputs = [inputs, actionNodeAst.getInputs()];
            else
                body{end+1} = LustreEq(oututs_Ids, ...
                    IteExpr(trans_cond, call, TupleExpr(oututs_Ids)));
                outputs = [outputs, actionNodeAst.getOutputs()];
                inputs = [inputs, actionNodeAst.getOutputs()];
                inputs = [inputs, actionNodeAst.getInputs()];
            end
        end
    end
    %remove isInner input from the node inputs
    inputs_name = cellfun(@(x) x.getId(), ...
        inputs, 'UniformOutput', false);
    inputs = inputs(~strcmp(inputs_name, ...
        SF_To_LustreNode.isInnerStr()));
end

