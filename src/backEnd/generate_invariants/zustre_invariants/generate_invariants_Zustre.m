%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%new_model_path = generate_invariants_Zustre(model_path, contract_path)
% Inputs:
% model_path : the path of Simulink model
% contract_path : the Json that contains information about the Simulink
% model contract
% Outputs:
% new_model_path: the path of the new Simulink model that has the generated
% invariants of the associated model.

function new_model_path = generate_invariants_Zustre(model_path, contract_path, cocosim_trace_file)

[coco_dir, ~, ~] = fileparts(contract_path);
[model_dir, base_name, ~] = fileparts(model_path);
if ~exist('cocosim_trace_file', 'var')
    cocosim_trace_file = fullfile(coco_dir,strcat(base_name,'.cocosim.trace.xml'));
end
try
    bdclose('all')
    new_model_path = '';
    try
        filetext = fileread(contract_path);
    catch ME
        display_msg('No Contract file', MsgType.ERROR, 'Zustre ', '');
        rethrow(ME);
    end
    filetext = regexprep(filetext,'__','');
    %parse the data
    if strcmp(filetext, '')
        warndlg('No cocospec contracts were generated','CoCoSim: Warning');
        return;
    end
    data = json_decode(filetext);
    
    
    
    
    % we add a Postfix to differentiate it with the original Simulink model
    new_model_name = strcat(base_name,'_with_cocospec');
    new_name = fullfile(model_dir,strcat(new_model_name,'.slx'));
    
    display_msg(['Cocospec path: ' new_name ], MsgType.INFO, 'view_cocospec', '');
    
    if exist(new_name,'file')
        if bdIsLoaded(new_model_name)
            close_system(new_model_name,0)
        end
        delete(new_name);
    end
    
    %we load the original model
    load_system(model_path);
    %we save it as the output model
    close_system(new_name,0)
    save_system(model_path,new_name);
    load_system(new_name);
    
    %get tracability
    
    DOMNODE = xmlread(cocosim_trace_file);
    xRoot = DOMNODE.getDocumentElement;
    
    nb_coco = 0;
    
    
    [status, translated_nodes_path, ~]  = lus2slx(contract_path, coco_dir);
    if status
        return;
    end
    [~, translated_nodes, ~] = fileparts(translated_nodes_path);
    load_system(translated_nodes);
    
    nodes = data.nodes;
    for node = fieldnames(nodes)'
        original_name = nodes.(node{1}).original_name;
        simulink_block_name = XMLUtils.get_Simulink_block_from_lustre_node_name(xRoot, ...
            original_name, base_name, new_model_name);
        if strcmp(simulink_block_name, '')
            continue;
        elseif strcmp(simulink_block_name,base_name)
            isBaseName = true;
            simulink_block_name = strcat(new_model_name,'/',base_name);
        else
            try
                maskType =  get_param(simulink_block_name,'MaskType');
                if strcmp(maskType, 'Observer')
                    continue;
                end
            catch ME
                display_msg(ME.getReport(), MsgType.DEBUG, 'VIEW_COCOSPEC', '');
                continue;
            end
            isBaseName = false;
        end
        parent_block_name = fileparts(simulink_block_name);
        %for having a good order of blocks
        try
            if isBaseName
                position  = BUtils.get_obs_position(new_model_name);
            else
                position  = get_param(simulink_block_name,'Position');
            end
        catch ME
            msg = sprintf('There is no block called %s in your model\n', simulink_block_name);
            msg1 = [msg, sprintf('if the block %s exists, make sure it is atomic', simulink_block_name)];
            msg2 = sprintf('%s\n%s\n', msg1, ME.getReport());
            warndlg(msg1,'CoCoSim: Warning');
            fprintf(msg2);
            continue;
        end
        x = position(1);
        y = position(2)+250;
        
        %Adding the cocospec subsystem related with the Simulink subsystem
        %"simulink_block_name"
        cocospec_block_path = strcat(simulink_block_name,'_cocospec');
        n = 1;
        while getSimulinkBlockHandle(cocospec_block_path) ~= -1
            cocospec_block_path = strcat(cocospec_block_path, num2str(n));
            n = n + 1;
            y = y+250;
        end
        node_subsystem = strcat(translated_nodes, '/', BUtils.adapt_block_name(node{1}));
        add_block(node_subsystem,...
            cocospec_block_path,...
            'Position',[(x+100) y (x+250) (y+50)]);
        set_mask_parameters(cocospec_block_path);
        nb_coco = nb_coco + 1;
        
        %we plot the invariant of the block
        scope_block_path = strcat(simulink_block_name,'_scope',num2str(n));
        add_block('simulink/Commonly Used Blocks/Scope',...
            scope_block_path,...
            'Position',[(x+300) y (x+350) (y+50)]);
        
        %we link the Scope with cocospec block
        SrcBlkH = get_param(strcat(cocospec_block_path),'PortHandles');
        DstBlkH = get_param(scope_block_path, 'PortHandles');
        add_line(parent_block_name, SrcBlkH.Outport(1), DstBlkH.Inport(1), 'autorouting', 'on');
        
        blk_inputs = nodes.(node{1}).inputs;
        %link inputs to the subsystem.
        for index=1:numel(blk_inputs)
            var_name = BUtils.adapt_block_name(blk_inputs{index});
            input_block_name = get_input_block_name_from_variable(xRoot, original_name, var_name, base_name,new_model_name);
            link_block_with_its_cocospec(cocospec_block_path,  input_block_name, simulink_block_name, parent_block_name, index, isBaseName);
        end
    end
    
    if nb_coco == 0
        warndlg('No cocospec contracts were generated','CoCoSim: Warning');
        return;
    end
    save_system(new_name);
    new_model_path = new_name;
    open(new_name);
    save_system(new_name,[],'OverwriteIfChangedOnDisk',true);
    close_system(translated_nodes,0)
catch ME
    display_msg(ME.message, MsgType.ERROR, 'VIEW_COCOSPEC', '');
    display_msg(ME.getReport(), MsgType.DEBUG, 'VIEW_COCOSPEC', '');
    rethrow(ME);
end
end



%%
function input_block_name = get_input_block_name_from_variable(xRoot, node, var_name, Sim_file_name,new_model_name)

input_block_name = XMLUtils.get_block_name_from_variable_using_xRoot(xRoot, node, var_name);
input_block_name = regexprep(input_block_name,strcat('^',Sim_file_name,'/(\w)'),strcat(new_model_name,'/$1'));
end


%%
function link_block_with_its_cocospec( cocospec_bloc_path, input_block_name, simulink_block_name, parent_block_name, index, isBaseName)


DstBlkH = get_param(cocospec_bloc_path, 'PortHandles');
inport_or_outport = get_param(input_block_name,'BlockType');
Port_number = get_param(input_block_name,'Port');
if strcmp(inport_or_outport,'Inport')
    if isBaseName
        SrcBlkH = get_param(input_block_name,'PortHandles');
        inport_handle = SrcBlkH.Outport(1);
    else
        SrcBlkH = get_param(simulink_block_name,'PortHandles');
        inport_handle = SrcBlkH.Inport(str2num(Port_number));
    end
    l = get_param(inport_handle,'line');
    SrcPortHandle = get_param(l ,'SrcPortHandle');
    add_line(parent_block_name, SrcPortHandle, DstBlkH.Inport(index), 'autorouting', 'on');
elseif strcmp(inport_or_outport,'Outport')
    if isBaseName
        SrcBlkH = get_param(input_block_name,'PortHandles');
        inport_handle = SrcBlkH.Inport(1);
        l = get_param(inport_handle,'line');
        SrcPortHandle = get_param(l ,'SrcPortHandle');
    else
        SrcBlkH = get_param(simulink_block_name,'PortHandles');
        SrcPortHandle = SrcBlkH.Outport(str2num(Port_number));
    end
    add_line(parent_block_name, SrcPortHandle, DstBlkH.Inport(index), 'autorouting', 'on');
end
end




function set_mask_parameters(observer_path)

mask = Simulink.Mask.create(observer_path);
mask.Display = sprintf('%s', get_observer_display());
mask.IconUnits = 'normalized';
mask.Type = 'Observer';
mask.Description = get_obs_description();
mask.addParameter('Type', 'popup', 'Prompt', 'Type of annotation (pre/post...)', 'Name', 'AnnotationType', 'TypeOptions', {'ensures','requires','assert','observer'}, 'Value', 'assert', 'Callback', get_obs_callback());
mask.addParameter('Type', 'edit', 'Prompt', 'Observer type', 'Name', 'ObserverType', 'TypeOptions', {'Ellipsoid'}, 'Callback', get_obs_callback(), 'Evaluate', 'off');
set_param(observer_path, 'ForegroundColor', 'red');
set_param(observer_path, 'BackgroundColor', 'white');

end

%% Returns the Display parameter value for the Observer block
function [display] = get_observer_display()
display = sprintf('color(''red'')\n');
display = [display sprintf('text(0.5, 0.5, [''CoCoSpec: '''''' get_param(gcb,''name'') ''''''''], ''horizontalAlignment'', ''center'');\n')];
display = [display 'text(0.99, 0.03, ''{\bf\fontsize{12}'];
display = [display char('INVARIANT')];
display = [display '}'', ''hor'', ''right'', ''ver'', ''bottom'', ''texmode'', ''on'');'];
end

function [desc] = get_obs_description()

desc = sprintf('Set an observer for the system.\n');
desc = [desc sprintf('The annotation type parameter sets the type of observer:\n')];
desc = [desc sprintf('- requires : pre-condition\n')];
desc = [desc sprintf('- ensures : post-condition\n')];
desc = [desc sprintf('- assert : an assertion\n')];
desc = [desc sprintf('- observer : the observer computes a special type of properties')];

end
%% Retrieve the Callback parameter value
function [call] = get_obs_callback()

call = sprintf('paramStr = get_param(gcb, ''MaskValues'');\n');
call = [call sprintf('if strcmp(paramStr{1}(1),''o'')\n')];
call = [call sprintf('set_param(gcb,''MaskVisibilities'',{''on'';''on''});\n')];
call = [call sprintf('paramStr{2} = ''ellipsoid'';\n')];
call = [call sprintf('set_param(gcb,''MaskValues'',paramStr);\n')];
call = [call sprintf('else\n')];
call = [call sprintf('set_param(gcb,''MaskVisibilities'',{''on'';''off''});\n')];
call = [call sprintf('end\n')];
call = [call sprintf('clear paramStr;\n')];

end