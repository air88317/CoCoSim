classdef Subsystem_To_Lustre < Block_To_Lustre
    %Subsystem_To_Lustre translates a subsystem call to Lustre.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, varargin)
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(blk);
            [inputs] = SLX2LusUtils.getBlockInputsNames(parent, blk);
            node_name = SLX2LusUtils.node_name_format(blk);
            codes = {};
            [isEnabledSubsystem, ShowOutputPortIsOn] = ...
                Subsystem_To_Lustre.hasEnablePort(blk);
            blk_name = SLX2LusUtils.name_format(blk.Name);
            if isEnabledSubsystem
                node_name = strcat(node_name, '_automaton');
                if ShowOutputPortIsOn
                    [Enableinputs] = SLX2LusUtils.getSubsystemEnableInputsNames(parent, blk);
                    inputs = [inputs, Enableinputs];
                end
                
                EnableCondName = sprintf('EnableCond_of_%s', blk_name);
                EnableCondVar = sprintf('%s:bool;', EnableCondName);
                obj.addVariable(EnableCondVar);
                enableportDataType = blk.CompiledPortDataTypes.Enable{1};
                [lusEnableportDataType, zero] = SLX2LusUtils.get_lustre_dt(enableportDataType);
                enableInputs = SLX2LusUtils.getBlockEnableInputsNames(parent, blk);
                cond = {};
                for i=1:blk.CompiledPortWidths.Enable
                    if strcmp(lusEnableportDataType, 'bool')
                        cond{i} = sprintf('%s', enableInputs{i});
                    else
                        cond{i} = sprintf('%s > %s', enableInputs{i}, zero);
                    end
                end
                EnableCond = MatlabUtils.strjoin(cond, ' or ');
                codes{numel(codes) + 1} = sprintf('%s = %s;\n\t'...
                    ,EnableCondName,  EnableCond);
                inputs{numel(inputs) + 1} = EnableCondName;
            end
            x = MatlabUtils.strjoin(inputs, ',\n\t\t');
            y = MatlabUtils.strjoin(outputs, ',\n\t');
            
            [isResetSubsystem, ResetType] =Subsystem_To_Lustre.hasResetPort(blk);
            if isResetSubsystem
                ResetCondName = sprintf('ResetCond_of_%s', blk_name);
                ResetCondVar = sprintf('%s:bool;', ResetCondName);
                obj.addVariable(ResetCondVar);
                resetportDataType = blk.CompiledPortDataTypes.Reset{1};
                [lusResetportDataType, zero] = SLX2LusUtils.get_lustre_dt(resetportDataType);
                resetInputs = SLX2LusUtils.getSubsystemResetInputsNames(parent, blk);
                cond = {};
                for i=1:blk.CompiledPortWidths.Reset
                    cond{i} = SLX2LusUtils.getResetCode(blk, ...
                        ResetType, lusResetportDataType, resetInputs{i} , zero);
                end
                ResetCond = MatlabUtils.strjoin(cond, ' or ');
                codes{numel(codes) + 1} = sprintf('%s = %s;\n\t'...
                    ,ResetCondName,  ResetCond);
                
                codes{numel(codes) + 1} = ...
                    sprintf('(%s) = %s(%s) every %s;\n\t', ...
                    y, node_name, x, ResetCondName);
            else
                codes{numel(codes) + 1} = ...
                    sprintf('(%s) = %s(%s);\n\t', y, node_name, x);
            end
            
            
            obj.setCode( MatlabUtils.strjoin(codes, ''));
            obj.addVariable(outputs_dt);
        end
        
        function options = getUnsupportedOptions(obj, varargin)
            % add your unsuported options list here
            options = obj.unsupported_options;
        end
    end
    methods (Static = true)
        function [b, ShowOutputPortIsOn] = hasEnablePort(blk)
            fields = fieldnames(blk.Content);
            fields = ...
                fields(...
                cellfun(@(x) isfield(blk.Content.(x),'BlockType'), fields));
            enablePortsFields = fields(...
                cellfun(@(x) strcmp(blk.Content.(x).BlockType,'EnablePort'), fields));
            b = ~isempty(enablePortsFields);
            
            if b
                ShowOutputPortIsOn =  ...
                    strcmp(blk.Content.(enablePortsFields{1}).ShowOutputPort, 'on');
            else
                ShowOutputPortIsOn = 0;
            end
            
        end
        function [b, ResetType] = hasResetPort(blk)
            fields = fieldnames(blk.Content);
            fields = ...
                fields(...
                cellfun(@(x) isfield(blk.Content.(x),'BlockType'), fields));
            resetPortsFields = fields(...
                cellfun(@(x) strcmp(blk.Content.(x).BlockType,'ResetPort'), fields));
            b = ~isempty(resetPortsFields);
            
            if b
                ResetType = blk.Content.(resetPortsFields{1}).ResetTriggerType;
            else
                ResetType = '';
            end
        end
    end
end

