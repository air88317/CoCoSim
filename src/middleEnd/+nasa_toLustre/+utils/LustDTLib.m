classdef LustDTLib
    %LustDTLib This class is a set of Lustre dataType conversions.
    properties
    end
    
    methods(Static)
        
        function [node, external_nodes_i, opens, abstractedNodes] = template(varargin)
            import nasa_toLustre.lustreAst.*
            opens = {};
            abstractedNodes = {};
            external_nodes_i = {};
            node = '';
        end
        
        %%
        function [node, external_nodes_i, opens, abstractedNodes] = getToBool(dt)
            import nasa_toLustre.lustreAst.*
            opens = {};
            abstractedNodes = {};
            external_nodes_i = {};
            node_name = strcat(dt, '_to_bool');
            if strcmp(dt, 'int')
                zero = IntExpr(0);
            else
                zero = RealExpr('0.0');
            end
            %format = 'node %s (x: %s)\nreturns(y:bool);\nlet\n\t y= (x <> %s);\ntel\n\n';
            %node = sprintf(format, node_name, dt, zero);
            bodyElts{1} = LustreEq(...
                VarIdExpr('y'), ...
                BinaryExpr(BinaryExpr.NEQ, ...
                VarIdExpr('x'),...
                zero));
            
            node = LustreNode();
            node.setName(node_name);
            node.setInputs(LustreVar('x', dt));
            node.setOutputs(LustreVar('y', 'bool'));
            node.setBodyEqs(bodyElts);
            node.setIsMain(false);
            
        end
        
        function [node, external_nodes_i, opens, abstractedNodes] = getBoolTo(dt)
            import nasa_toLustre.lustreAst.*
            opens = {};
            abstractedNodes = {};
            external_nodes_i = {};
            
            node_name = strcat('bool_to_', dt);
            if strcmp(dt, 'int')
                zero = IntExpr(0);
                one = IntExpr(1);
            else
                zero = RealExpr('0.0');
                one = RealExpr('1.0');
            end
            %format = 'node %s (x: bool)\nreturns(y:%s);\nlet\n\t y= if x then %s else %s;\ntel\n\n';
            %node = sprintf(format, node_name, dt, one, zero);
            
            bodyElts{1} = LustreEq(...
                VarIdExpr('y'), ...
                IteExpr(VarIdExpr('x'),...
                one,...
                zero)...
                );
            
            node = LustreNode();
            node.setName(node_name);
            node.setInputs(LustreVar('x', 'bool'));
            node.setOutputs(LustreVar('y', dt));
            node.setBodyEqs(bodyElts);
            node.setIsMain(false);
        end
        
        function [node, external_nodes_i, opens, abstractedNodes] = get_real_to_bool(varargin)
            [node, external_nodes_i, opens, abstractedNodes] = nasa_toLustre.utils.LustDTLib.getToBool('real');
        end
        
        function [node, external_nodes_i, opens, abstractedNodes] = get_int_to_bool(varargin)
            [node, external_nodes_i, opens, abstractedNodes] = nasa_toLustre.utils.LustDTLib.getToBool('int');
        end
        
        function [node, external_nodes_i, opens, abstractedNodes] = get_bool_to_int(varargin)
            [node, external_nodes_i, opens, abstractedNodes] = nasa_toLustre.utils.LustDTLib.getBoolTo('int');
        end
        
        function [node, external_nodes_i, opens, abstractedNodes] = get_bool_to_real(varargin)
            [node, external_nodes_i, opens, abstractedNodes] = nasa_toLustre.utils.LustDTLib.getBoolTo('real');
        end
        
        %%
        function [node, external_nodes, opens, abstractedNodes] = getIntToInt(dt)
            import nasa_toLustre.lustreAst.*
            opens = {};
            abstractedNodes = {};
            v_max = double(intmax(dt));% we need v_max as double variable
            v_min = double(intmin(dt));% we need v_min as double variable
            nb_int = (v_max - v_min + 1);
            node_name = strcat('int_to_', dt);
            
            % format = 'node %s (x: int)\nreturns(y:int);\nlet\n\t';
            % format = [format, 'y= if x > v_max then v_min + rem_int_int((x - v_max - 1),nb_int) \n\t'];
            % format = [format, 'else if x < v_min then v_max + rem_int_int((x - (v_min) + 1),nb_int) \n\telse x;\ntel\n\n'];
            % node = sprintf(format, node_name, v_max, v_min, v_max, nb_int,...
            %     v_min, v_max, v_min, nb_int);
            
            conds{1} = BinaryExpr(BinaryExpr.GT, ...
                VarIdExpr('x'), ...
                IntExpr(v_max));
            conds{2} = BinaryExpr(BinaryExpr.LT, ...
                VarIdExpr('x'), ...
                IntExpr(v_min));
            %  %d + rem_int_int((x - %d - 1),%d)
            thens{1} = BinaryExpr(...
                BinaryExpr.PLUS, ...
                IntExpr(v_min),...
                NodeCallExpr('rem_int_int',...
                {BinaryExpr.BinaryMultiArgs(BinaryExpr.MINUS,...
                {VarIdExpr('x'), IntExpr(v_max), IntExpr(1)}),...
                IntExpr(nb_int)}));
            %d + rem_int_int((x - (%d) + 1),%d)
            if v_min == 0, neg_vmin = 0; else, neg_vmin = -v_min; end
            thens{2} = BinaryExpr(...
                BinaryExpr.PLUS, ...
                IntExpr(v_max),...
                NodeCallExpr('rem_int_int', ...
                {BinaryExpr.BinaryMultiArgs(...
                BinaryExpr.PLUS,...
                {VarIdExpr('x'),...
                IntExpr(neg_vmin),...
                IntExpr(1)}),...
                IntExpr(nb_int)}));
            thens{3} = VarIdExpr('x');
            bodyElts{1} = LustreEq(...
                VarIdExpr('y'), ...
                IteExpr.nestedIteExpr(conds, thens));
            
            
            node = LustreNode();
            node.setName(node_name);
            node.setInputs(LustreVar('x', 'int'));
            node.setOutputs(LustreVar('y', 'int'));
            node.setBodyEqs(bodyElts);
            node.setIsMain(false);
            external_nodes = {strcat('LustMathLib_', 'rem_int_int')};
            
        end
        function [node, external_nodes, opens, abstractedNodes] = getIntToIntSaturate(dt)
            import nasa_toLustre.lustreAst.*
            opens = {};
            abstractedNodes = {};
            external_nodes = {};
            node_name = sprintf('int_to_%s_saturate', dt);
            % format = 'node %s (x: int)\nreturns(y:int);\nlet\n\t';
            % format = [format, 'y= if x > %d then %d  \n\t'];
            % format = [format, 'else if x < %d then %d \n\telse x;\ntel\n\n'];
            %
            % node = sprintf(format, node_name, v_max, v_max, v_min, v_min);
            
            v_max = IntExpr(intmax(dt));
            v_min = IntExpr(intmin(dt));
            conds{1} = BinaryExpr(BinaryExpr.GT, VarIdExpr('x'),v_max);
            conds{2} = BinaryExpr(BinaryExpr.LT, VarIdExpr('x'), v_min);
            thens{1} = v_max;
            thens{2} = v_min;
            thens{3} = VarIdExpr('x');
            bodyElts{1} =   LustreEq(...
                VarIdExpr('y'), ...
                IteExpr.nestedIteExpr(conds, thens));
            
            node = LustreNode();
            node.setName(node_name);
            node.setInputs(LustreVar('x', 'int'));
            node.setOutputs(LustreVar('y', 'int'));
            node.setBodyEqs(bodyElts);
            node.setIsMain(false);
            
        end
        
        
        function [node, external_nodes_i, opens, abstractedNodes] = get_int_to_int8(varargin)
            [node, external_nodes_i, opens, abstractedNodes] = nasa_toLustre.utils.LustDTLib.getIntToInt('int8');
        end
        function [node, external_nodes_i, opens, abstractedNodes] = get_int_to_uint8(varargin)
            [node, external_nodes_i, opens, abstractedNodes] = nasa_toLustre.utils.LustDTLib.getIntToInt('uint8');
        end
        function [node, external_nodes_i, opens, abstractedNodes] = get_int_to_int16(varargin)
            [node, external_nodes_i, opens, abstractedNodes] = nasa_toLustre.utils.LustDTLib.getIntToInt('int16');
        end
        function [node, external_nodes_i, opens, abstractedNodes] = get_int_to_uint16(varargin)
            [node, external_nodes_i, opens, abstractedNodes] = nasa_toLustre.utils.LustDTLib.getIntToInt('uint16');
        end
        function [node, external_nodes_i, opens, abstractedNodes] = get_int_to_int32(varargin)
            [node, external_nodes_i, opens, abstractedNodes] = nasa_toLustre.utils.LustDTLib.getIntToInt('int32');
        end
        function [node, external_nodes_i, opens, abstractedNodes] = get_int_to_uint32(varargin)
            [node, external_nodes_i, opens, abstractedNodes] = nasa_toLustre.utils.LustDTLib.getIntToInt('uint32');
        end
        function [node, external_nodes_i, opens, abstractedNodes] = get_int_to_int8_saturate(varargin)
            [node, external_nodes_i, opens, abstractedNodes] = nasa_toLustre.utils.LustDTLib.getIntToIntSaturate('int8');
        end
        function [node, external_nodes_i, opens, abstractedNodes] = get_int_to_uint8_saturate(varargin)
            [node, external_nodes_i, opens, abstractedNodes] = nasa_toLustre.utils.LustDTLib.getIntToIntSaturate('uint8');
        end
        function [node, external_nodes_i, opens, abstractedNodes] = get_int_to_int16_saturate(varargin)
            [node, external_nodes_i, opens, abstractedNodes] = nasa_toLustre.utils.LustDTLib.getIntToIntSaturate('int16');
        end
        function [node, external_nodes_i, opens, abstractedNodes] = get_int_to_uint16_saturate(varargin)
            [node, external_nodes_i, opens, abstractedNodes] = nasa_toLustre.utils.LustDTLib.getIntToIntSaturate('uint16');
        end
        function [node, external_nodes_i, opens, abstractedNodes] = get_int_to_int32_saturate(varargin)
            [node, external_nodes_i, opens, abstractedNodes] = nasa_toLustre.utils.LustDTLib.getIntToIntSaturate('int32');
        end
        function [node, external_nodes_i, opens, abstractedNodes] = get_int_to_uint32_saturate(varargin)
            [node, external_nodes_i, opens, abstractedNodes] = nasa_toLustre.utils.LustDTLib.getIntToIntSaturate('uint32');
        end
        
        %%
        function [node, external_nodes_i, opens, abstractedNodes] = get_conv(varargin)
            opens = {'conv'};
            abstractedNodes = {'lustrec DataType conversion Library'};
            external_nodes_i = {};
            node = '';
        end
        
        function [node, external_nodes, opens, abstractedNodes] = get_int_to_real(lus_backend, varargin)
            if LusBackendType.isKIND2(lus_backend)
                import nasa_toLustre.lustreAst.*
                opens = {};
                abstractedNodes = {};
                external_nodes = {};
                node = LustreNode();
                node.setName('int_to_real');
                node.setInputs(LustreVar('x', 'int'));
                node.setOutputs(LustreVar('y', 'real'));
                node.setIsMain(false);
                node.setBodyEqs(LustreEq(VarIdExpr('y'), ...
                    UnaryExpr(UnaryExpr.REAL, VarIdExpr('x'))));
            else
                opens = {'conv'};
                abstractedNodes = {};
                external_nodes = {};
                node = {};
            end
        end
        
        function [node, external_nodes, opens, abstractedNodes] = get_real_to_int(lus_backend, varargin)
            if LusBackendType.isKIND2(lus_backend)
                import nasa_toLustre.lustreAst.*
                opens = {};
                abstractedNodes = {};
                external_nodes = {'LustDTLib__Floor', 'LustDTLib__Ceiling'};
                node = LustreNode();
                node.setName('real_to_int');
                node.setInputs(LustreVar('x', 'real'));
                node.setOutputs(LustreVar('y', 'int'));
                node.setIsMain(false);
                ifAst = IteExpr(...
                    BinaryExpr(BinaryExpr.GTE, VarIdExpr('x'), RealExpr('0.0')), ...
                    NodeCallExpr('_Floor', VarIdExpr('x')), ...
                    NodeCallExpr('_Ceiling', VarIdExpr('x')));
                node.setBodyEqs(LustreEq(VarIdExpr('y'), ifAst));
            else
                opens = {'conv'};
                abstractedNodes = {};
                external_nodes = {};
                node = {};
            end
        end
        
        function [node, external_nodes, opens, abstractedNodes] = get__Floor(lus_backend, varargin)
            if LusBackendType.isKIND2(lus_backend)
                abstractedNodes = {};
                import nasa_toLustre.lustreAst.*
                opens = {};
                external_nodes = {};
                node = LustreNode();
                node.setName('_Floor');
                node.setInputs(LustreVar('x', 'real'));
                node.setOutputs(LustreVar('y', 'int'));
                node.setIsMain(false);
                node.setBodyEqs(LustreEq(VarIdExpr('y'), ...
                    UnaryExpr(UnaryExpr.INT, VarIdExpr('x'))));
            else
                opens = {'conv'};
                abstractedNodes = {};
                external_nodes = {};
                node = {};
            end
            
        end
        % this one for "Rounding" Simulink block, it is different from Floor by
        % returning a real instead of int.
        function [node, external_nodes, opens, abstractedNodes] = get__floor(lus_backend, varargin)
            if LusBackendType.isKIND2(lus_backend)
                abstractedNodes = {};
                import nasa_toLustre.lustreAst.*
                opens = {};
                external_nodes = {};
                % y  <= x < y + 1.0
                contractElts{1} = ContractGuaranteeExpr('', ...
                    BinaryExpr(BinaryExpr.AND, ...
                    BinaryExpr(BinaryExpr.LTE, ...
                    VarIdExpr('y'),...
                    VarIdExpr('x')),...
                    BinaryExpr(BinaryExpr.LT, ...
                    VarIdExpr('x'),...
                    BinaryExpr(BinaryExpr.PLUS, ...
                    VarIdExpr('y'), ...
                    RealExpr('1.0'), ...
                    false)...
                    ), ...
                    false));
                contract = LustreContract();
                contract.setBodyEqs(contractElts);
                node = LustreNode();
                node.setName('_floor');
                node.setInputs(LustreVar('x', 'real'));
                node.setOutputs(LustreVar('y', 'real'));
                node.setLocalContract(contract);
                node.setIsMain(false);
                node.setBodyEqs(LustreEq(VarIdExpr('y'), ...
                    UnaryExpr(UnaryExpr.REAL, ...
                    UnaryExpr(UnaryExpr.INT, VarIdExpr('x')))));
            else
                opens = {'conv'};
                abstractedNodes = {};
                external_nodes = {};
                node = {};
            end
        end
        
        
        function [node, external_nodes, opens, abstractedNodes] = get__Ceiling(lus_backend, varargin)
            if LusBackendType.isKIND2(lus_backend)
                import nasa_toLustre.lustreAst.*
                opens = {};
                abstractedNodes = {};
                external_nodes = {'LustDTLib__Floor'};
                node = LustreNode();
                node.setName('_Ceiling');
                node.setInputs(LustreVar('x', 'real'));
                node.setOutputs(LustreVar('y', 'int'));
                node.setIsMain(false);
                node.setBodyEqs(LustreEq(VarIdExpr('y'), ...
                    UnaryExpr(UnaryExpr.NEG, ...
                    NodeCallExpr('_Floor', ...
                    UnaryExpr(UnaryExpr.NEG, VarIdExpr('x'), false)))));
            else
                opens = {'conv'};
                abstractedNodes = {};
                external_nodes = {};
                node = {};
            end
            
        end
        % this one for "Rounding" block, it is different from Ceiling by
        % returning a real instead of int.
        function [node, external_nodes, opens, abstractedNodes] = get__ceil(lus_backend, varargin)
            if LusBackendType.isKIND2(lus_backend)
                import nasa_toLustre.lustreAst.*
                opens = {};
                abstractedNodes = {};
                external_nodes = {'LustDTLib__Ceiling'};
                
                % y - 1.0 < x <= y
                contractElts{1} = ContractGuaranteeExpr('', ...
                    BinaryExpr(BinaryExpr.AND, ...
                    BinaryExpr(BinaryExpr.LT, ...
                    BinaryExpr(BinaryExpr.MINUS, ...
                    VarIdExpr('y'), ...
                    RealExpr('1.0'), ...
                    false),...
                    VarIdExpr('x')), ...
                    BinaryExpr(BinaryExpr.LTE, ...
                    VarIdExpr('x'),...
                    VarIdExpr('y')),...
                    false));
                contract = LustreContract();
                contract.setBodyEqs(contractElts);
                node = LustreNode();
                node.setName('_ceil');
                node.setInputs(LustreVar('x', 'real'));
                node.setOutputs(LustreVar('y', 'real'));
                node.setLocalContract(contract);
                node.setIsMain(false);
                node.setBodyEqs(LustreEq(VarIdExpr('y'), ...
                    UnaryExpr(UnaryExpr.REAL, ...
                    NodeCallExpr('_Ceiling', VarIdExpr('x')))));
            else
                opens = {'conv'};
                abstractedNodes = {};
                external_nodes = {};
                node = {};
            end
            
        end
        
        
        % Round Rounds number to the nearest representable value.
        % If a tie occurs, rounds positive numbers toward positive infinity
        % and rounds negative numbers toward negative infinity.
        % Equivalent to the Fixed-Point Designer round function.
        function [node, external_nodes, opens, abstractedNodes] = get__Round(lus_backend, varargin)
            if LusBackendType.isKIND2(lus_backend)
                import nasa_toLustre.lustreAst.*
                opens = {};
                abstractedNodes = {};
                external_nodes = {'LustDTLib__Floor', 'LustDTLib__Ceiling'};
                node = LustreNode();
                node.setName('_Round');
                node.setInputs(LustreVar('x', 'real'));
                node.setOutputs(LustreVar('y', 'int'));
                node.setIsMain(false);
                ifAst = IteExpr(...
                    BinaryExpr(BinaryExpr.EQ, VarIdExpr('x'), RealExpr('0.0')),...
                    IntExpr(0), ...
                    IteExpr(...
                    BinaryExpr(BinaryExpr.GT, VarIdExpr('x'), RealExpr('0.0')), ...
                    NodeCallExpr('_Floor', ...
                    BinaryExpr(BinaryExpr.PLUS, VarIdExpr('x'), RealExpr('0.5'))), ...
                    NodeCallExpr('_Ceiling', ...
                    BinaryExpr(BinaryExpr.MINUS, VarIdExpr('x'), RealExpr('0.5')))));
                node.setBodyEqs(LustreEq(VarIdExpr('y'), ifAst));
            else
                opens = {'conv'};
                abstractedNodes = {};
                external_nodes = {};
                node = {};
            end
        end
        % this one for "Rounding" block, it is different from Round by
        % returning a real instead of int.
        function [node, external_nodes, opens, abstractedNodes] = get__round(lus_backend, varargin)
            if LusBackendType.isKIND2(lus_backend)
                import nasa_toLustre.lustreAst.*
                opens = {};
                abstractedNodes = {};
                external_nodes = {'LustMathLib_abs_real', 'LustDTLib_Round'};
                % abs(x - y) < 1.0
                contractElts{1} = ContractGuaranteeExpr('', ...
                    BinaryExpr(BinaryExpr.LTE, ...
                    NodeCallExpr('abs_real', ...
                    BinaryExpr(BinaryExpr.MINUS,...
                    VarIdExpr('x'), ...
                    VarIdExpr('y'), ...
                    false)),...
                    RealExpr('1.0'), ...
                    false));
                contract = LustreContract();
                contract.setBodyEqs(contractElts);
                node = LustreNode();
                node.setName('_round');
                node.setInputs(LustreVar('x', 'real'));
                node.setOutputs(LustreVar('y', 'real'));
                node.setLocalContract(contract);
                node.setIsMain(false);
                node.setBodyEqs(LustreEq(VarIdExpr('y'), ...
                    UnaryExpr(UnaryExpr.REAL, ...
                    NodeCallExpr('_Round', VarIdExpr('x')))));
            else
                opens = {'conv'};
                abstractedNodes = {};
                external_nodes = {};
                node = {};
            end
            
        end
        
        
        function [node, external_nodes, opens, abstractedNodes] = get__Convergent(varargin)
            %Rounds number to the nearest representable value.
            %If a tie occurs, rounds to the nearest even integer.
            %Equivalent to the Fixed-Point Designer? convergent function.
            import nasa_toLustre.lustreAst.*
            opens = {};
            abstractedNodes = {};
            node_name = '_Convergent';
            % y = floor(x+1/2) + ceiling((x-0.5)/2) - floor((x-0.5)/2) - 1
            bodyElts{1} = LustreEq(...
                VarIdExpr('y'), ...
                IteExpr(...
                BinaryExpr(BinaryExpr.EQ, VarIdExpr('x'), RealExpr('0.0')),...
                IntExpr(0), ...
                BinaryExpr.BinaryMultiArgs(BinaryExpr.PLUS, {...
                NodeCallExpr('_Floor', BinaryExpr(BinaryExpr.PLUS,VarIdExpr('x'),RealExpr('0.5'))), ...
                NodeCallExpr('_Ceiling', BinaryExpr(...
                BinaryExpr.DIVIDE,...
                BinaryExpr(BinaryExpr.MINUS,VarIdExpr('x'),RealExpr('0.5')),...
                RealExpr(2))), ...
                UnaryExpr(UnaryExpr.NEG, ...
                NodeCallExpr('_Floor', BinaryExpr(...
                BinaryExpr.DIVIDE,...
                BinaryExpr(BinaryExpr.MINUS,VarIdExpr('x'),RealExpr('0.5')),...
                RealExpr(2)))), ...
                IntExpr(-1)})));
            
            node = LustreNode();
            node.setMetaInfo('--Rounds number to the nearest representable value.');
            node.setName(node_name);
            node.setInputs(LustreVar('x', 'real'));
            node.setOutputs(LustreVar('y', 'int'));
            node.setBodyEqs(bodyElts);
            node.setIsMain(false);
            
            external_nodes = {strcat('LustMathLib_', 'fmod'), ...
                strcat('LustDTLib_', '_Floor'),...
                strcat('LustDTLib_', '_Ceiling')};
            
        end
        
        % Nearest Rounds number to the nearest representable value.
        %If a tie occurs, rounds toward positive infinity. Equivalent to the Fixed-Point Designer nearest function.
        function [node, external_nodes, opens, abstractedNodes] = get__Nearest(varargin)
            import nasa_toLustre.lustreAst.*
            opens = {};
            abstractedNodes = {};
            % format = '--Rounds number to the nearest representable value.\n--If a tie occurs, rounds toward positive infinity\n ';
            % format = [ format ,'node _Nearest (x: real)\nreturns(y:int);\nlet\n\t'];
            % format = [ format , 'y = if (_fabs(x) >= 0.5) then _Floor(x + 0.5)\n\t'];
            % format = [ format , ' else 0;'];
            % format = [ format , '\ntel\n\n'];
            %
            %
            % node = sprintf(format);
            
            node_name = '_Nearest';
            bodyElts{1} = LustreEq(...
                VarIdExpr('y'), ...
                IteExpr(BinaryExpr(BinaryExpr.GTE,...
                NodeCallExpr('_fabs', VarIdExpr('x')),...
                RealExpr('0.5')),... % cond
                NodeCallExpr('_Floor', ...
                BinaryExpr(BinaryExpr.PLUS, ...
                VarIdExpr('x'),...
                RealExpr('0.5'))),...
                IntExpr(0)));
            
            node = LustreNode();
            node.setMetaInfo('Rounds number to the nearest representable value.\n--If a tie occurs, rounds toward positive infinity');
            node.setName(node_name);
            node.setInputs(LustreVar('x', 'real'));
            node.setOutputs(LustreVar('y', 'int'));
            node.setBodyEqs(bodyElts);
            node.setIsMain(false);
            
            external_nodes = {strcat('LustMathLib_', '_fabs'), ...
                strcat('LustDTLib_', '_Floor'),...
                strcat('LustDTLib_', '_Ceiling')};
        end
        
        
        % Rounds each element of the input signal to the nearest integer towards zero.
        function [node, external_nodes, opens, abstractedNodes] = get__Fix(varargin)
            import nasa_toLustre.lustreAst.*
            opens = {};
            abstractedNodes = {};
            % format = '--Rounds number to the nearest integer towards zero.\n';
            % format = [ format ,'node _Fix (x: real)\nreturns(y:int);\nlet\n\t'];
            % format = [ format , 'y = if (x >= 0.5) then _Floor(x)\n\t\t'];
            % format = [ format , ' else if (x > -0.5) then 0 \n\t\t'];
            % format = [ format , ' else _Ceiling(x);'];
            % format = [ format , '\ntel\n\n'];
            % node = sprintf(format);
            
            node_name = '_Fix';
            bodyElts{1} = LustreEq(...
                VarIdExpr('y'), ...
                IteExpr.nestedIteExpr(...
                {...
                BinaryExpr(BinaryExpr.GTE, VarIdExpr('x'),RealExpr('0.5')),...
                BinaryExpr(BinaryExpr.GT, VarIdExpr('x'),RealExpr('-0.5'))...
                },...
                {...
                NodeCallExpr('_Floor', VarIdExpr('x')),...
                IntExpr(0),...
                NodeCallExpr('_Ceiling', VarIdExpr('x'))...
                }));
            
            node = LustreNode();
            node.setMetaInfo('Rounds number to the nearest integer towards zero');
            node.setName(node_name);
            node.setInputs(LustreVar('x', 'real'));
            node.setOutputs(LustreVar('y', 'int'));
            node.setBodyEqs(bodyElts);
            node.setIsMain(false);
            
            external_nodes = {strcat('LustDTLib_', '_Floor'),...
                strcat('LustDTLib_', '_Ceiling')};
        end
        % this one for "Rounding" block, it is different from Fix by
        % returning a real instead of int.
        function [node, external_nodes, opens, abstractedNodes] = get__fix(varargin)
            import nasa_toLustre.lustreAst.*
            opens = {};
            abstractedNodes = {};
            % format = '--Rounds number to the nearest integer towards zero.\n';
            % format = [ format ,'node _fix (x: real)\nreturns(y:real);\nlet\n\t'];
            % format = [ format , 'y = if (x >= 0.5) then _floor(x)\n\t\t'];
            % format = [ format , ' else if (x > -0.5) then 0.0 \n\t\t'];
            % format = [ format , ' else _ceil(x);'];
            % format = [ format , '\ntel\n\n'];
            % node = sprintf(format);
            
            node_name = '_fix';
            bodyElts{1} = LustreEq(...
                VarIdExpr('y'), ...
                IteExpr.nestedIteExpr(...
                {...
                BinaryExpr(BinaryExpr.GTE, VarIdExpr('x'),RealExpr('0.5')),...
                BinaryExpr(BinaryExpr.GT, VarIdExpr('x'),RealExpr('-0.5'))...
                },...
                {...
                NodeCallExpr('_floor', VarIdExpr('x')),...
                RealExpr('0.0'),...
                NodeCallExpr('_ceil', VarIdExpr('x'))...
                }));
            
            node = LustreNode();
            node.setMetaInfo('Rounds number to the nearest integer towards zero');
            node.setName(node_name);
            node.setInputs(LustreVar('x', 'real'));
            node.setOutputs(LustreVar('y', 'real'));
            node.setBodyEqs(bodyElts);
            node.setIsMain(false);
            
            external_nodes = {strcat('LustDTLib_', '_floor'),...
                strcat('LustDTLib_', '_ceil')};
        end
        
        
    end
    
end

