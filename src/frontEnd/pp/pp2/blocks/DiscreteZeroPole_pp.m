function [status, errors_msg] = DiscreteZeroPole_pp(model)
% DiscreteZeroPole_pp searches for DiscreteZeroPole blocks and replaces them by a
% PP-friendly equivalent.
%   model is a string containing the name of the model to search in
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (c) 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Processing Gain blocks
status = 0;
errors_msg = {};

dzp_list = find_system(model,...
    'LookUnderMasks', 'all', 'BlockType','DiscreteZeroPole');
dzp_list = [dzp_list; find_system(model,'BlockType','ZeroPole')];
if not(isempty(dzp_list))
    display_msg('Replacing DiscreteTransferFcn blocks...', MsgType.INFO,...
        'DiscreteZeroPole_pp', '');
    
    
    
    %% pre-processing blocks
    for i=1:length(dzp_list)
        display_msg(dzp_list{i}, MsgType.INFO, ...
            'DiscreteZeroPole_pp', '');
        
        try
        
        % Obtaining z-expression parameters
        Zeros_str = get_param(dzp_list{i}, 'Zeros');
        [Zeros, ~, status] = SLXUtils.evalParam(...
            model, ...
            get_param(dzp_list{i}, 'Parent'), ...
            dzp_list{i}, ...
            Zeros_str);
        if status
            display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                Zeros_str, dzp_list{i}), ...
                MsgType.ERROR, 'DiscreteZeroPole_pp', '');
            continue;
        end
        
        Poles_str = get_param(dzp_list{i}, 'Poles');
        [Poles, ~, status] = SLXUtils.evalParam(...
            model, ...
            get_param(dzp_list{i}, 'Parent'), ...
            dzp_list{i}, ...
            Poles_str);
        if status
            display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                Poles_str, dzp_list{i}), ...
                MsgType.ERROR, 'DiscreteZeroPole_pp', '');
            continue;
        end
        
        Gain_str = get_param(dzp_list{i}, 'Gain');
        [Gain, ~, status] = SLXUtils.evalParam(...
            model, ...
            get_param(dzp_list{i}, 'Parent'), ...
            dzp_list{i}, ...
            Gain_str);
        if status
            display_msg(sprintf('Variable %s in block %s not found neither in Matlab workspace or in Model workspace',...
                Gain_str, dzp_list{i}), ...
                MsgType.ERROR, 'DiscreteZeroPole_pp', '');
            continue;
        end
        
        [n,m] = size(Zeros);
        if m > 1 && n > 1
            if numel(Gain) == 1
                Gain = Gain*ones(1, m);
            end
        end
        blocktype= get_param(dzp_list{i}, 'BlockType');
        
        % Computing state space representation
        [A,B,C,D]=zp2ss(Zeros,Poles,Gain);
        if strcmp(blocktype, 'ZeroPole')
            ST = SLXUtils.getModelCompiledSampleTime(model);
            [A, B] = PPUtils.c2d(A, B ,ST);
            ST = '-1';
        else
            ST = get_param(dzp_list{i},'SampleTime');
        end
        A = mat2str(A);
        B = mat2str(B);
        C = mat2str(C);
        D = mat2str(D);
        
        % replacing
        PPUtils.replace_one_block(dzp_list{i},'pp_lib/DZP');
        %restoring info
        set_param(strcat(dzp_list{i},'/A'),...
            'Value',A);
        set_param(strcat(dzp_list{i},'/B'),...
            'Value',B);
        set_param(strcat(dzp_list{i},'/C'),...
            'Value',C);
        set_param(strcat(dzp_list{i},'/D'),...
            'Value',D);
        set_param(strcat(dzp_list{i},'/X0'),...
            'SampleTime',ST);
        catch
            status = 1;
            errors_msg{end + 1} = sprintf('DiscreteZeroPole_pp pre-process has failed for block %s', dzp_list{i});
            continue;
        end        
    end
    display_msg('Done\n\n', MsgType.INFO, 'DiscreteZeroPole_pp', '');
end
end


