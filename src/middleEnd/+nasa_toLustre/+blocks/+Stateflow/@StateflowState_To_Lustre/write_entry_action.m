%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
% Notices:
%
% Copyright @ 2020 United States Government as represented by the 
% Administrator of the National Aeronautics and Space Administration.  All 
% Rights Reserved.
%
% Disclaimers
%
% No Warranty: THE SUBJECT SOFTWARE IS PROVIDED "AS IS" WITHOUT ANY 
% WARRANTY OF ANY KIND, EITHER EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING,
% BUT NOT LIMITED TO, ANY WARRANTY THAT THE SUBJECT SOFTWARE WILL CONFORM 
% TO SPECIFICATIONS, ANY IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS 
% FOR A PARTICULAR PURPOSE, OR FREEDOM FROM INFRINGEMENT, ANY WARRANTY THAT
% THE SUBJECT SOFTWARE WILL BE ERROR FREE, OR ANY WARRANTY THAT 
% DOCUMENTATION, IF PROVIDED, WILL CONFORM TO THE SUBJECT SOFTWARE. THIS 
% AGREEMENT DOES NOT, IN ANY MANNER, CONSTITUTE AN ENDORSEMENT BY 
% GOVERNMENT AGENCY OR ANY PRIOR RECIPIENT OF ANY RESULTS, RESULTING 
% DESIGNS, HARDWARE, SOFTWARE PRODUCTS OR ANY OTHER APPLICATIONS RESULTING 
% FROM USE OF THE SUBJECT SOFTWARE.  FURTHER, GOVERNMENT AGENCY DISCLAIMS 
% ALL WARRANTIES AND LIABILITIES REGARDING THIRD-PARTY SOFTWARE, IF PRESENT 
% IN THE ORIGINAL SOFTWARE, AND DISTRIBUTES IT "AS IS."
%
% Waiver and Indemnity:  RECIPIENT AGREES TO WAIVE ANY AND ALL CLAIMS 
% AGAINST THE UNITED STATES GOVERNMENT, ITS CONTRACTORS AND SUBCONTRACTORS, 
% AS WELL AS ANY PRIOR RECIPIENT.  IF RECIPIENT'S USE OF THE SUBJECT 
% SOFTWARE RESULTS IN ANY LIABILITIES, DEMANDS, DAMAGES, EXPENSES OR 
% LOSSES ARISING FROM SUCH USE, INCLUDING ANY DAMAGES FROM PRODUCTS BASED 
% ON, OR RESULTING FROM, RECIPIENT'S USE OF THE SUBJECT SOFTWARE, RECIPIENT 
% SHALL INDEMNIFY AND HOLD HARMLESS THE UNITED STATES GOVERNMENT, ITS 
% CONTRACTORS AND SUBCONTRACTORS, AS WELL AS ANY PRIOR RECIPIENT, TO THE 
% EXTENT PERMITTED BY LAW.  RECIPIENT'S SOLE REMEDY FOR ANY SUCH MATTER 
% SHALL BE THE IMMEDIATE, UNILATERAL TERMINATION OF THIS AGREEMENT.
% 
% Notice: The accuracy and quality of the results of running CoCoSim 
% directly corresponds to the quality and accuracy of the model and the 
% requirements given as inputs to CoCoSim. If the models and requirements 
% are incorrectly captured or incorrectly input into CoCoSim, the results 
% cannot be relied upon to generate or error check software being developed. 
% Simply stated, the results of CoCoSim are only as good as
% the inputs given to CoCoSim.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ENTRY ACTION
function [main_node, external_libraries] = ...
        write_entry_action(state, data_map)
    
    global SF_STATES_NODESAST_MAP SF_STATES_PATH_MAP;
    external_libraries = {};
    main_node = {};
    body = {};
    outputs = {};
    inputs = {};
    %set state as active
    parentName = fileparts(state.Path);
    if isfield(state, 'isChart')
        isChart =  state.isChart;
    else
        isChart = isempty(parentName);
    end
    if ~isChart
        if ~isKey(SF_STATES_PATH_MAP, parentName)
            ME = MException('COCOSIM:STATEFLOW', ...
                'COMPILER ERROR: Not found state "%s" in SF_STATES_PATH_MAP', parentName);
            throw(ME);
        end
        state_parent = SF_STATES_PATH_MAP(parentName);
        idParentName = nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getStateIDName(state_parent);
        [stateEnumType, childName] = ...
            nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.addStateEnum(state_parent, state);
        body{1} = nasa_toLustre.lustreAst.LustreComment('set state as active');
        body{2} = nasa_toLustre.lustreAst.LustreEq(nasa_toLustre.lustreAst.VarIdExpr(idParentName), childName);
        outputs{1} = nasa_toLustre.lustreAst.LustreVar(idParentName, stateEnumType);

        %isInner variable that tells if the transition that cause this
        %exit action is an inner Transition
        isInner = nasa_toLustre.lustreAst.VarIdExpr(nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.isInnerStr());
        inputs{end + 1} = nasa_toLustre.lustreAst.LustreVar(isInner, 'bool');
        %actions code
        actions = nasa_toLustre.IR_pp.stateflow_IR_pp.SFIRPPUtils.split_actions(state.Actions.Entry);
        nb_actions = numel(actions);
        for i=1:nb_actions
            try
                [lus_action, outputs_i, inputs_i, external_libraries_i] = ...
                    nasa_toLustre.blocks.Stateflow.utils.getPseudoLusAction(actions{i}, data_map, false, state.Path);
                outputs = [outputs, outputs_i];
                inputs = [inputs, inputs_i, outputs_i];
                external_libraries = [external_libraries, external_libraries_i];
                new_assignements = nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.addInnerCond(lus_action, isInner, actions{i}, state);
                body = coco_nasa_utils.MatlabUtils.concat(body, new_assignements);
            catch me
                if strcmp(me.identifier, 'COCOSIM:STATEFLOW')
                    display_msg(me.message, MsgType.ERROR, 'write_entry_action', '');
                else
                    display_msg(me.getReport(), MsgType.DEBUG, 'write_entry_action', '');
                end
                display_msg(sprintf('Entry Action failed for state %s', ...
                    state.Origin_path),...
                    MsgType.ERROR, 'write_entry_action', '');
            end
        end
    end
    %write children states entry action
    [actions, outputs_i, inputs_i] = ...
        nasa_toLustre.blocks.Stateflow.StateflowState_To_Lustre.write_children_actions(state, 'Entry');
    body = [body, actions];
    outputs = [outputs, outputs_i];
    inputs = [inputs, inputs_i];
    %create the node
    act_node_name = ...
        nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.getEntryActionNodeName(state);
    main_node = nasa_toLustre.lustreAst.LustreNode();
    main_node.setName(act_node_name);
    comment = nasa_toLustre.lustreAst.LustreComment(...
        sprintf('Entry action of state %s',...
        state.Origin_path), true);
    main_node.setMetaInfo(comment);
    main_node.setBodyEqs(body);
    outputs = nasa_toLustre.lustreAst.LustreVar.uniqueVars(outputs);
    inputs = nasa_toLustre.lustreAst.LustreVar.uniqueVars(inputs);
    if isempty(inputs)
        inputs{1} = ...
            nasa_toLustre.lustreAst.LustreVar(nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.virtualVarStr(), 'bool');
    elseif numel(inputs) > 1
        inputs = nasa_toLustre.lustreAst.LustreVar.removeVar(inputs, nasa_toLustre.blocks.Stateflow.utils.SF2LusUtils.virtualVarStr());
    end
    main_node.setOutputs(outputs);
    main_node.setInputs(inputs);
    SF_STATES_NODESAST_MAP(act_node_name) = main_node;
end
