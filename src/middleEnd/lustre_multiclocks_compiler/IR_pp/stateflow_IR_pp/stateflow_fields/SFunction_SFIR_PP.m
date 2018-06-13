function [ new_ir, status ] = SFunction_SFIR_PP( new_ir )
%SFunction_SFIR_PP add emty attribute GraphicalFunctions to
%GraphicalFunctions, so it can be handled as chart

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

status = 0;
if isfield(new_ir, 'GraphicalFunctions')
    for i=1:numel(new_ir.GraphicalFunctions)
        new_ir.GraphicalFunctions{i}.GraphicalFunctions = {};
    end
end
end

