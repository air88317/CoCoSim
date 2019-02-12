
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [body, outputs, inputs, variables, external_libraries, validDestination_cond, Termination_cond] = ...
        evaluate_Transition(t, data_map, isDefaultTrans, parentPath, ...
        validDestination_cond, Termination_cond, cond_prefix, fullPathT, variables)
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    global SF_STATES_NODESAST_MAP SF_JUNCTIONS_PATH_MAP;
    body = {};
    outputs = {};
    inputs = {};
    external_libraries = {};
    % Transition is marked for evaluation.
    % Does the transition have a condition?
    [trans_cond, outputs_i, inputs_i, external_libraries] = ...
        getPseudoLusAction(t.Condition, data_map, true, parentPath);
    if iscell(trans_cond)
        if numel(trans_cond) == 1
            trans_cond = trans_cond{1};
        elseif numel(trans_cond) > 1
            trans_cond = BinaryExpr.BinaryMultiArgs(BinaryExpr.AND, ...
                trans_cond);
        end
    end
    outputs = [outputs, outputs_i];
    inputs = [inputs, inputs_i];
    [event, outputs_i, inputs_i, ~] = ...
        getPseudoLusAction(t.Event,data_map, true, parentPath);
    if iscell(event)
        if numel(event) == 1
            event = event{1};
        elseif numel(event) > 1
            event = BinaryExpr.BinaryMultiArgs(BinaryExpr.AND, ...
                event);
        end
    end
    outputs = [outputs, outputs_i];
    inputs = [inputs, inputs_i];  
    if ~isempty(trans_cond) && ~isempty(event)
        trans_cond = BinaryExpr(BinaryExpr.AND, trans_cond, event);
    elseif ~isempty(event)
        trans_cond = event;
    end
    % add cond_prefix
    if ~isempty(cond_prefix)
        if ~isempty(trans_cond)
            trans_cond = BinaryExpr(BinaryExpr.AND, cond_prefix, trans_cond);
        else
            trans_cond = cond_prefix;
        end
    end
    % add condition variable so the condition action can not change
    % the truth value of the condition.
    if ~isempty(trans_cond)
        condName = StateflowTransition_To_Lustre.getCondActionName(t);
        if VarIdExpr.ismemberVar(condName, variables)
            i = 1;
            new_condName = strcat(condName, num2str(i));
            while(VarIdExpr.ismemberVar(new_condName, variables))
                i = i + 1;
                new_condName = strcat(condName, num2str(i));
            end
            condName = new_condName;
        end
        body{end+1} = LustreEq(VarIdExpr(condName), trans_cond);
        trans_cond = VarIdExpr(condName);
        variables{end+1} = LustreVar(condName, 'bool');
    end

    % add no valid transition path was found
    if ~isempty(Termination_cond)
        if ~isempty(trans_cond)
            trans_cond_with_termination = BinaryExpr(BinaryExpr.AND, ...
                UnaryExpr(UnaryExpr.NOT, Termination_cond), trans_cond);
        else
            trans_cond_with_termination = UnaryExpr(UnaryExpr.NOT, Termination_cond);
        end
    else
        trans_cond_with_termination = trans_cond;
    end



    %execute condition action

    transCondActionNodeName = ...
        StateflowTransition_To_Lustre.getCondActionNodeName(t);
    if isKey(SF_STATES_NODESAST_MAP, transCondActionNodeName)
        %condition Action exists.
        actionNodeAst = SF_STATES_NODESAST_MAP(transCondActionNodeName);
        [call, oututs_Ids] = actionNodeAst.nodeCall();
        if isempty(trans_cond_with_termination)
            body{end+1} = LustreEq(oututs_Ids, call);
            outputs = [outputs, actionNodeAst.getOutputs()];
            inputs = [inputs, actionNodeAst.getInputs()];
        else
            body{end+1} = LustreEq(oututs_Ids, ...
                IteExpr(trans_cond_with_termination, call, TupleExpr(oututs_Ids)));
            outputs = [outputs, actionNodeAst.getOutputs()];
            inputs = [inputs, actionNodeAst.getOutputs()];
            inputs = [inputs, actionNodeAst.getInputs()];
        end
    end


    %Is the destination a state or a junction?
    destination = t.Destination;
    isHJ = false;
    if strcmp(destination.Type,'Junction') 
        %the destination is a junction
        if isKey(SF_JUNCTIONS_PATH_MAP, destination.Name)
            hobject = SF_JUNCTIONS_PATH_MAP(destination.Name);
            if isequal(hobject.Type, 'HISTORY')
                isHJ = true;
            else
                %Does the junction have any outgoing transitions?
                transitions2 = SF_To_LustreNode.orderObjects(...
                    SF_JUNCTIONS_PATH_MAP(destination.Name).OuterTransitions, ...
                    'ExecutionOrder');
                if isempty(transitions2)
                    %the junction has no outgoing transitions
                    %update termination condition
                    condName = StateflowTransition_To_Lustre.getTerminationCondName();
                    [Termination_cond, body, outputs, variables] = ...
                        StateflowTransition_To_Lustre.updateTerminationCond(...
                        Termination_cond, condName, trans_cond, body, outputs, variables, true);
                else
                    %the junction has outgoing transitions
                    %Repeat the algorithm
                    [body_i, outputs_i, inputs_i, variables, ...
                        external_libraries_i, ...
                        validDestination_cond, Termination_cond] = ...
                        StateflowTransition_To_Lustre.transitions_code(...
                        transitions2, data_map, isDefaultTrans, ...
                        parentPath, ...
                        validDestination_cond, Termination_cond, ...
                        trans_cond, fullPathT, variables);
                    body = [body, body_i];
                    outputs = [outputs, outputs_i];
                    inputs = [inputs, inputs_i];
                    external_libraries = [external_libraries, external_libraries_i];
                end
                return;
            end
        else
            display_msg(...
                sprintf('%s not found in SF_JUNCTIONS_PATH_MAP',...
                destination.Name), ...
                MsgType.ERROR, 'StateflowTransition_To_Lustre', '');
            return;
        end
    end
    %the destination is a state or History Junction
    % Exit action should be executed.
    if ~isDefaultTrans
        [body_i, outputs_i, inputs_i] = ...
            StateflowTransition_To_Lustre.full_tran_exit_actions(...
            fullPathT, parentPath, trans_cond_with_termination);
        body = [body, body_i];
        outputs = [outputs, outputs_i];
        inputs = [inputs, inputs_i];
    end
    % Transition actions
    [body_i, outputs_i, inputs_i] = ...
        StateflowTransition_To_Lustre.full_tran_trans_actions(...
        fullPathT, trans_cond_with_termination);
    body = [body, body_i];
    outputs = [outputs, outputs_i];
    inputs = [inputs, inputs_i];

    % Entry actions
    [body_i, outputs_i, inputs_i] = ...
        StateflowTransition_To_Lustre.full_tran_entry_actions(...
        fullPathT, parentPath, trans_cond_with_termination, isHJ);
    body = [body, body_i];
    outputs = [outputs, outputs_i];
    inputs = [inputs, inputs_i];

    %update termination condition
    condName = StateflowTransition_To_Lustre.getTerminationCondName();
    [Termination_cond, body, outputs, variables] = ...
        StateflowTransition_To_Lustre.updateTerminationCond(...
        Termination_cond, condName, trans_cond, body, outputs, variables, true);
    %validDestination_cond only updated if the final destination is a state

    if ~isDefaultTrans
        condName = StateflowTransition_To_Lustre.getValidPathCondName();
        [validDestination_cond, body, outputs, variables] = ...
            StateflowTransition_To_Lustre.updateTerminationCond(...
            validDestination_cond, condName, trans_cond, body, outputs, variables, false);
    end
end

