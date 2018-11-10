classdef Constant_To_Lustre < Block_To_Lustre
    %Constant_To_Lustre
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods
        function  write_code(obj, parent, blk, xml_trace, varargin)
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(parent, blk, [], xml_trace);
            obj.addVariable(outputs_dt);
            slx_dt = blk.CompiledPortDataTypes.Outport{1};
            lus_outputDataType = SLX2LusUtils.get_lustre_dt(slx_dt);
            [Value, ~, status] = ...
                Constant_To_Lustre.getValueFromParameter(parent, blk, blk.Value);
            if status
                display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                    blk.Value, HtmlItem.addOpenCmd(blk.Origin_path)), ...
                    MsgType.ERROR, 'Constant_To_Lustr', '');
                return;
            end
            %inline value
            max_width = blk.CompiledPortWidths.Outport;
            if numel(Value) < max_width
                Value = arrayfun(@(x) Value(1), (1:max_width));
            end
            
            width = numel(Value);
            values_AST = cell(1, width);
            for i=1:width
                values_AST{i} = SLX2LusUtils.num2LusExp(Value(i),...
                    lus_outputDataType, slx_dt);
            end
            
            codes = cell(1, numel(outputs));
            for j=1:numel(outputs)
                codes{j} = LustreEq(outputs{j}, values_AST{j});
            end
            
            
            obj.setCode( codes );
            
        end
        
        function options = getUnsupportedOptions(obj,parent, blk, varargin)
            % search the variable in Model workspace, if not raise
            % unsupported option
            [~, ~, status] = ...
                Constant_To_Lustre.getValueFromParameter(parent, blk, blk.Value);
            if status
                obj.addUnsupported_options(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                    blk.Value, HtmlItem.addOpenCmd(blk.Origin_path)));
            end
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    methods(Static = true)
        function [Value, valueDataType, status] = ...
                getValueFromParameter(parent, blk, param)
            model_name = regexp(HtmlItem.addOpenCmd(blk.Origin_path), filesep, 'split');
            model_name = model_name{1};
            [Value, valueDataType, status] = ...
                SLXUtils.evalParam(model_name, parent, blk, param);
        end
    end
    
    
end

