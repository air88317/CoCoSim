function [code, exp_dt] = expression_To_Lustre(BlkObj, tree, parent, blk, data_map, inputs, expected_dt, isSimulink, isStateFlow)
    %this function is extended to be used by If-Block,
    %SwitchCase and Fcn blocks. Also it is used by Stateflow
    %actions
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    import nasa_toLustre.blocks.Stateflow.utils.MExpToLusAST
    
    narginchk(1, 9);
    if isempty(BlkObj), BlkObj = nasa_toLustre.blocks.DummyBlock_To_Lustre; end
    if nargin < 3, parent = []; end
    if nargin < 4, blk = []; end
    if nargin < 5, data_map = containers.Map; end
    if nargin < 6, inputs = {}; end
    if nargin < 7, expected_dt = ''; end
    if nargin < 8, isSimulink = false; end
    if nargin < 9, isStateFlow = false; end
    
    
    % we assume this function returns cell.
    code = {};
    exp_dt = '';
    if isempty(tree)
        return;
    end
    if iscell(tree) && numel(tree) == 1
        tree = tree{1};
    end
    if ~isfield(tree, 'type')
        if isfield(tree, 'text')
            ME = MException('COCOSIM:TREE2CODE', ...
                'Parser Failed: Matlab AST of expression "%s" has no attribute type.',...
                tree.text);
        else
            ME = MException('COCOSIM:TREE2CODE', ...
                'Parser Failed: Matlab AST has no attribute type.');
        end
        throw(ME);
    end
    tree_type = tree.type;
    switch tree_type
        case {'relopAND', 'relopelAND',...
                'relopOR', 'relopelOR', ...
                'relopGL', 'relopEQ_NE', ...
                'plus_minus', 'mtimes', 'times', ...
                'mrdivide', 'mldivide', 'rdivide', 'ldivide', ...
                'mpower', 'power'}
            [code, exp_dt] = MExpToLusAST.binaryExpression_To_Lustre(BlkObj, tree, parent, blk, data_map, inputs, expected_dt, isSimulink, isStateFlow);
        otherwise
            % we use the name of tree_type to call the associated function
            func_name = strcat(tree_type, '_To_Lustre');
            func_handle = str2func(strcat('MExpToLusAST.', func_name));
            try
                [code, exp_dt] = func_handle(BlkObj, tree, parent, blk, data_map, inputs, expected_dt, isSimulink, isStateFlow);
            catch me
                if isequal(me.identifier, 'MATLAB:UndefinedFunction')
                    ME = MException('COCOSIM:TREE2CODE', ...
                        ['Parser ERROR: No method with name "%s".'...
                        ' Expression "%s" with type "%s" is not handled yet in CoCoSim Parser'],...
                        func_name, tree.text, tree_type);
                    throw(ME);
                else
                    display_msg(me.getReport(), MsgType.DEBUG, 'MExpToLusAST.expression_To_Lustre', '');
                    ME = MException('COCOSIM:TREE2CODE', ...
                        'Parser ERROR for Expression "%s" with type "%s"',...
                        tree.text, tree_type);
                    throw(ME);
                end
            end
    end
    % convert tree DT to what is expected.
    code = MExpToLusDT.convertDT(BlkObj, code, exp_dt, expected_dt);
    if ~isempty(expected_dt), exp_dt = expected_dt; end
    
end