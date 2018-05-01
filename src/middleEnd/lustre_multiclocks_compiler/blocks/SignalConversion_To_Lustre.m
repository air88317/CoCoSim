classdef SignalConversion_To_Lustre < Block_To_Lustre
    %SignalConversion_To_Lustre translates the SignalConversion block.
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
            [outputs, outputs_dt] = SLX2LusUtils.getBlockOutputsNames(parent, blk);
            obj.addVariable(outputs_dt);
            [inputs] = SLX2LusUtils.getBlockInputsNames(parent, blk);
            
            codes = {};
            % Thanks to inlining signals as well as BusCreator and BusSelector, 
            % Signal Conversion is passing the inputs
            for i=1:numel(outputs)
                codes{i} = sprintf('%s = %s;\n\t', outputs{i}, inputs{i});
            end
            
            obj.setCode( MatlabUtils.strjoin(codes, ''));
        end
        
        function options = getUnsupportedOptions(obj, parent, blk, varargin)
            options = obj.unsupported_options;
        end
    end
    
end

