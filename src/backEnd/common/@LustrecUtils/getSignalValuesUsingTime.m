%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 

function signal_values = getSignalValuesUsingTime(ds, t)
    signal_values = [];
    if isa(ds, 'timeseries')
        signal_values = double(ds.getsampleusingtime(t).Data);
        signal_values = reshape(signal_values, [numel(signal_values), 1]);
    elseif isa(ds, 'struct')
        fields = fieldnames(ds);
        for i=1:numel(fields)
            signal_values = [signal_values ; ...
                LustrecUtils.getSignalValuesUsingTime(ds.(fields{i}), t)];
        end
    end
end
