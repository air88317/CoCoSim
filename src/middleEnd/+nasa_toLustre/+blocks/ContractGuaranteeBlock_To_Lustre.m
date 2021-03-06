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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef ContractGuaranteeBlock_To_Lustre < nasa_toLustre.blocks.SubSystem_To_Lustre
    % ContractGuaranteeBlock_To_Lustre

    
    properties
    end
    
    methods
        
        function  write_code(obj, parent, blk, xml_trace, lus_backend, ...
                coco_backend, main_sampleTime, varargin)
            
            write_code@nasa_toLustre.blocks.SubSystem_To_Lustre(obj, ...
                parent, blk, xml_trace, lus_backend, ...
                coco_backend, main_sampleTime, varargin{:});
            [outputs, ~] = ...
                nasa_toLustre.utils.SLX2LusUtils.getBlockOutputsNames(parent, blk);
            if length(outputs) > 1
                prop = nasa_toLustre.lustreAst.BinaryExpr.BinaryMultiArgs(...
                    nasa_toLustre.lustreAst.BinaryExpr.AND, outputs);
            elseif length(outputs) == 1
                prop = outputs{1};
            else
                return;
            end
            prop_ID =nasa_toLustre.utils.SLX2LusUtils.node_name_format(blk);
            isInsideContract =nasa_toLustre.utils.SLX2LusUtils.isContractBlk(parent);
            if coco_nasa_utils.LusBackendType.isKIND2(lus_backend) && isInsideContract
                obj.addCode(...
                    nasa_toLustre.lustreAst.ContractGuaranteeExpr(...
                    prop_ID, prop));
            else
                obj.addCode(nasa_toLustre.lustreAst.LocalPropertyExpr(...
                    prop_ID, prop));
            end
            xml_trace.add_Property(...
                blk.Origin_path, ...
                nasa_toLustre.utils.SLX2LusUtils.node_name_format(parent),...
                prop_ID, 1, 'guarantee')
        end
        
        function options = getUnsupportedOptions(obj, parent, blk,...
                lus_backend, varargin)
            getUnsupportedOptions@nasa_toLustre.blocks.SubSystem_To_Lustre(obj,...
                parent, blk, lus_backend, varargin{:});
            options = obj.unsupported_options;
        end
        %%
        function is_Abstracted = isAbstracted(varargin)
            is_Abstracted = false;
        end
    end
    
end

