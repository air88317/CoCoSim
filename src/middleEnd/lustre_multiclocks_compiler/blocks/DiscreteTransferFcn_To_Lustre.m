classdef DiscreteTransferFcn_To_Lustre < Block_To_Lustre
    % DiscreteTransferFcn_To_Lustre
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Trinh, Khanh V <khanh.v.trinh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, varargin)
           
        end
        
        function options = getUnsupportedOptions(obj, parent, blk, varargin)
            obj.unsupported_options = {...
                sprintf('Block %s is supported by Pre-processing check the pre-processing errors.',...
                blk.Origin_path)};
            options = obj.unsupported_options;
        end
    end
    
    
    methods(Static)
      
        
        
    end
    
end

