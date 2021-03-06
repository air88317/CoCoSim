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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function  [main_node, external_nodes, external_libraries ] = ...
        write_Action(T, data_map, source_state, type, isDefaultTrans)
    global SF_STATES_NODESAST_MAP
    main_node = {};
    external_nodes = {};
    external_libraries = {};
    if strcmp(type, 'ConditionAction')
        t_act_node_name = nasa_toLustre.blocks.Stateflow.StateflowTransition_To_Lustre.getCondActionNodeName(T, source_state, isDefaultTrans);
        action = T.ConditionAction;
    else
        t_act_node_name = nasa_toLustre.blocks.Stateflow.StateflowTransition_To_Lustre.getTranActionNodeName(T, source_state, isDefaultTrans);
        action = T.TransitionAction;
    end
    if isKey(SF_STATES_NODESAST_MAP, t_act_node_name)
        %Node already defined.
        %TODO: investigate why nodes are twice generated, specially the
        %ones inside Stateflow Functions. I assume the chart has access to
        %the content of the Function, therefore they are defined twice in
        %Internal Representation.
        return;
    end
    if isDefaultTrans
        suffix = 'Default Transition';
    else
        suffix = '';
    end
    transitionPath = sprintf('Transition from %s %s to %s ExecutionOrder %d %s',...
        source_state.Origin_path,...
        suffix, ...
        T.Destination.Origin_path, ...
        T.ExecutionOrder, type);
    [main_node, external_nodes, external_libraries ] = ...
        nasa_toLustre.blocks.Stateflow.StateflowTransition_To_Lustre.write_Action_Node(action, data_map, t_act_node_name, transitionPath);
    if ~isempty(main_node)
        comment = nasa_toLustre.lustreAst.LustreComment(transitionPath, true);
        main_node.setMetaInfo(comment);
    end


end

