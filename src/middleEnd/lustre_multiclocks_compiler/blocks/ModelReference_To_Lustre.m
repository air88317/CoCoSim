classdef ModelReference_To_Lustre < Block_To_Lustre
    % ModelReference_To_Lustre translates ModelReferences call as Subsystem
    % call
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, main_sampleTime, varargin)
            ssObj = SubSystem_To_Lustre();
            ssObj.write_code( parent, blk, xml_trace, main_sampleTime, varargin);
            obj.addVariable(ssObj.getVariables());
            obj.addExternal_libraries(ssObj.getExternalLibraries());
            obj.addExtenal_node(ssObj.getExternalNodes());
            obj.setCode(ssObj.getCode());
            
        end
        
        function options = getUnsupportedOptions(obj,parent, blk, varargin)
            ssObj = SubSystem_To_Lustre();
            obj.addUnsupported_options(ssObj.getUnsupportedOptions(parent, blk, varargin));
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
end

