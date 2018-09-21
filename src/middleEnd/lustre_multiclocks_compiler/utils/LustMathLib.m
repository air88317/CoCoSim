classdef LustMathLib
    %LustMathLib This class  is a set of Lustre math libraries.
    
    properties
    end
    
    methods(Static)
        
        function [node, external_nodes_i, opens, abstractedNodes] = template(varargin)
            opens = {};
            abstractedNodes = {};
            external_nodes_i = {};
            node = '';
        end
        
        %% Min Max
        function [node, external_nodes_i, opens, abstractedNodes] = getMinMax(minOrMAx, dt)
            opens = {};
            abstractedNodes = {};
            external_nodes_i = {};
            node_name = strcat('_', minOrMAx, '_', dt);
            if strcmp(minOrMAx, 'min')
                op = BinaryExpr.LT;
            else
                op = BinaryExpr.GT;
            end
            %node_format = 'node %s (x, y: %s)\nreturns(z:%s);\nlet\n\t z = if (x %s y) then x else y;\ntel\n\n';
            %node  = sprintf(node_format, node_name, dt, dt, op);
            bodyElts = LustreEq(...
                VarIdExpr('z'), ...
                IteExpr(...
                    BinaryExpr(op, VarIdExpr('x'), VarIdExpr('y')), ...
                    VarIdExpr('x'), ...
                    VarIdExpr('y'))...
                );
            node = LustreNode();
            node.setName(node_name);
            node.setInputs({LustreVar('x', dt), LustreVar('y', dt)});
            node.setOutputs(LustreVar('z', dt));
            node.setBodyEqs(bodyElts);           
            node.setIsMain(false);
        end
        function [node, external_nodes_i, opens, abstractedNodes] = get__min_int(varargin)
            [node, external_nodes_i, opens, abstractedNodes] = LustMathLib.getMinMax('min', 'int');
        end
        
        function [node, external_nodes_i, opens, abstractedNodes] = get__min_real(varargin)
            [node, external_nodes_i, opens, abstractedNodes] = LustMathLib.getMinMax('min', 'real');
        end
        
        function [node, external_nodes_i, opens, abstractedNodes] = get__max_int(varargin)
            [node, external_nodes_i, opens, abstractedNodes] = LustMathLib.getMinMax('max', 'int');
        end
        
        function [node, external_nodes_i, opens, abstractedNodes] = get__max_real(varargin)
            [node, external_nodes_i, opens, abstractedNodes] = LustMathLib.getMinMax('max', 'real');
        end
        
        %%
        function [node, external_nodes_i, opens, abstractedNodes] = get_lustrec_math(varargin)
            opens = {'lustrec_math'};
            abstractedNodes = {'lustrec_math library'};
            external_nodes_i = {};
            node = '';
        end
        
        function [node, external_nodes_i, opens, abstractedNodes] = get_simulink_math_fcn(varargin)
            opens = {'simulink_math_fcn'};
            abstractedNodes = {'simulink_math_fcn library'};
            external_nodes_i = {};
            node = '';
        end
        
        %% fabs, abs
        function [node, external_nodes_i, opens, abstractedNodes] = get__fabs(varargin)
            opens = {};
            abstractedNodes = {};
            external_nodes_i = {};
            %             format = 'node _fabs (x:real)\nreturns(z:real);\nlet\n\t';
            %             format = [format, 'z= if (x >= 0.0)  then x \n\t'];
            %             format = [format, 'else -x;\ntel\n\n'];
            
            bodyElts{1} = LustreEq(...
                VarIdExpr('z'), ...
                IteExpr(...
                    BinaryExpr(BinaryExpr.GTE, VarIdExpr('x'), VarIdExpr('0.0')), ...
                    VarIdExpr('x'), ...
                    UnaryExpr(UnaryExpr.NEG, VarIdExpr('x')))...
                );
            node = LustreNode();
            node.setName('_fabs');
            node.setInputs(LustreVar('x', 'real'));
            node.setOutputs(LustreVar('z', 'real'));
            node.setBodyEqs(bodyElts);           
            node.setIsMain(false);
        end
        
        function [node, external_nodes_i, opens, abstractedNodes] = get_abs_int(varargin)
            opens = {};
            abstractedNodes = {};
            external_nodes_i = {};
            %             format = 'node abs_int (x: int)\nreturns(y:int);\nlet\n\t';
            %             format = [format, 'y= if x >= 0 then x \n\t'];
            %             format = [format, 'else -x;\ntel\n\n'];
            bodyElts{1} = LustreEq(...
                VarIdExpr('y'), ...
                IteExpr(...
                    BinaryExpr(BinaryExpr.GTE, VarIdExpr('x'), VarIdExpr('0')), ...
                    VarIdExpr('x'), ...
                    UnaryExpr(UnaryExpr.NEG, VarIdExpr('x')))...
                );
            node = LustreNode();
            node.setName('abs_int');
            node.setInputs(LustreVar('x', 'int'));
            node.setOutputs(LustreVar('y', 'int'));
            node.setBodyEqs(bodyElts);           
            node.setIsMain(false);
        end
        
        function [node, external_nodes_i, opens, abstractedNodes] = get_abs_real(varargin)
            opens = {};
            abstractedNodes = {};
            external_nodes_i = {};
%             format = 'node abs_real (x: real)\nreturns(y:real);\nlet\n\t';
%             format = [format, 'y= if x >= 0.0 then x \n\t'];
%             format = [format, 'else -x;\ntel\n\n'];
            bodyElts{1} = LustreEq(...
                VarIdExpr('y'), ...
                IteExpr(...
                    BinaryExpr(BinaryExpr.GTE, VarIdExpr('x'), VarIdExpr('0.0')), ...
                    VarIdExpr('x'), ...
                    UnaryExpr(UnaryExpr.NEG, VarIdExpr('x')))...
                );
            node = LustreNode();
            node.setName('abs_real');
            node.setInputs(LustreVar('x', 'real'));
            node.setOutputs(LustreVar('y', 'real'));
            node.setBodyEqs(bodyElts);           
            node.setIsMain(false);
        end
        %% Bitwise operators
        function [node, external_nodes, opens, abstractedNodes] = getBitwiseSigned(op, n)
            opens = {};
            abstractedNodes = {};
            extNode = sprintf('int_to_int%d',n);
            UnsignedNode =  sprintf('_%s_Bitwise_Unsigned_%d',op, n);
            external_nodes = {strcat('LustDTLib_', extNode),...
                strcat('LustMathLib_', UnsignedNode)};
            
            node_name = sprintf('_%s_Bitwise_Signed_%d', op, n);
            v2_pown = 2^(n);
%             format = 'node %s (x, y: int)\nreturns(z:int);\nvar x2, y2:int;\nlet\n\t';
%             format = [format, 'x2 = if x < 0 then %d + x else x;\n\t'];
%             format = [format, 'y2 = if y < 0 then %d + y else y;\n\t'];
%             format = [format, 'z = %s(%s(x2, y2));\ntel\n\n'];
%             node = sprintf(format, node_name, v2_pown, v2_pown, extNode, UnsignedNode);
            bodyElts{1} = LustreEq(...
                VarIdExpr('x2'), ...
                IteExpr(...
                    BinaryExpr(BinaryExpr.LT, VarIdExpr('x'), VarIdExpr('0')), ...
                    BinaryExpr(BinaryExpr.PLUS, IntExpr(v2_pown),VarIdExpr('x')), ...
                    VarIdExpr('x'))...
                );
            bodyElts{end + 1} = LustreEq(...
                VarIdExpr('y2'), ...
                IteExpr(...
                    BinaryExpr(BinaryExpr.LT, VarIdExpr('y'), VarIdExpr('0')), ...
                    BinaryExpr(BinaryExpr.PLUS, IntExpr(v2_pown),VarIdExpr('y')), ...
                    VarIdExpr('y'))...
                );
            bodyElts{end + 1} = LustreEq(...
                VarIdExpr('z'), ...
                NodeCallExpr(extNode, ...
                            NodeCallExpr(UnsignedNode, ...
                                   {VarIdExpr('x2'), VarIdExpr('y2')}))...
                );
            node = LustreNode();
            node.setName(node_name);
            node.setInputs({LustreVar('x', 'int'), LustreVar('y', 'int')});
            node.setOutputs(LustreVar('z', 'int'));
            node.setLocalVars({LustreVar('x2', 'int'), LustreVar('y2', 'int')})
            node.setBodyEqs(bodyElts);           
            node.setIsMain(false);
        end
        
        %AND
        function [node, external_nodes, opens, abstractedNodes] = getANDBitwiseUnsigned(n)
            opens = {};
            abstractedNodes = {};
            external_nodes = {};
            
            args = cell(1, n);
            %code{1} = sprintf('(x mod 2)*(y mod 2)');
            args{1} = BinaryExpr(...
                BinaryExpr.MULTIPLY, ...
                BinaryExpr(BinaryExpr.MOD, VarIdExpr('x'), IntExpr(2)), ...
                BinaryExpr(BinaryExpr.MOD, VarIdExpr('y'), IntExpr(2)));
            for i=1:n-1
                v2_pown = 2^i;
                %code{end+1} = sprintf('%d*((x / %d) mod 2)*((y / %d) mod 2)', v2_pown, v2_pown, v2_pown);
                %((x / %d) mod 2)
                x_term = BinaryExpr(...
                    BinaryExpr.MOD, ...
                    BinaryExpr(BinaryExpr.DIVIDE, VarIdExpr('x'), IntExpr(v2_pown)),...
                    IntExpr(2));
                %((y / %d) mod 2)
                y_term = BinaryExpr(...
                    BinaryExpr.MOD, ...
                    BinaryExpr(BinaryExpr.DIVIDE, VarIdExpr('y'), IntExpr(v2_pown)),...
                    IntExpr(2));
                args{i + 1} = BinaryExpr.BinaryMultiArgs(...
                    BinaryExpr.MULTIPLY, ...
                    {IntExpr(v2_pown), x_term, y_term});
            end
            %code = MatlabUtils.strjoin(code, ' \n\t+ ');
            rhs = BinaryExpr.BinaryMultiArgs(BinaryExpr.PLUS, args);
            node_name = strcat('_AND_Bitwise_Unsigned_', num2str(n));
            
            %             format = 'node %s (x, y: int)\nreturns(z:int);\nlet\n\t';
            %             format = [format, 'z = %s;\ntel\n\n'];
            %             node = sprintf(format, node_name, code);
            bodyElts = LustreEq(...
                VarIdExpr('z'), ...
                rhs);
            node = LustreNode();
            node.setName(node_name);
            node.setInputs({LustreVar('x', 'int'), LustreVar('y', 'int')});
            node.setOutputs(LustreVar('z', 'int'));
            node.setBodyEqs(bodyElts);           
            node.setIsMain(false);
        end 
        %NAND
        function [node, external_nodes, opens, abstractedNodes] = getNANDBitwiseUnsigned(n)
            opens = {};
            abstractedNodes = {};
            notNode = sprintf('_NOT_Bitwise_Unsigned_%d', n);
            UnsignedNode =  sprintf('_AND_Bitwise_Unsigned_%d', n);
            external_nodes = {strcat('LustMathLib_', notNode),...
                strcat('LustMathLib_', UnsignedNode)};
            
            node_name = sprintf('_NAND_Bitwise_Unsigned_%d', n);
            %             format = 'node %s (x, y: int)\nreturns(z:int);\nlet\n\t';
            %             format = [format, 'z = %s(%s(x, y));\ntel\n\n'];
            %             node = sprintf(format, node_name, notNode, UnsignedNode);
            bodyElts{1} = LustreEq(...
                VarIdExpr('z'), ...
                NodeCallExpr(notNode, ...
                            NodeCallExpr(UnsignedNode, ...
                                   {VarIdExpr('x'), VarIdExpr('y')}))...
                );
            node = LustreNode();
            node.setName(node_name);
            node.setInputs({LustreVar('x', 'int'), LustreVar('y', 'int')});
            node.setOutputs(LustreVar('z', 'int'));
            node.setBodyEqs(bodyElts);           
            node.setIsMain(false);
        end
        %NOR
        function [node, external_nodes, opens, abstractedNodes] = getNORBitwiseUnsigned(n)
            opens = {};
            abstractedNodes = {};
            notNode = sprintf('_NOT_Bitwise_Unsigned_%d', n);
            UnsignedNode =  sprintf('_OR_Bitwise_Unsigned_%d', n);
            external_nodes = {strcat('LustMathLib_', notNode),...
                strcat('LustMathLib_', UnsignedNode)};
            
            node_name = sprintf('_NOR_Bitwise_Unsigned_%d', n);
            %             format = 'node %s (x, y: int)\nreturns(z:int);\nlet\n\t';
            %             format = [format, 'z = %s(%s(x, y));\ntel\n\n'];
            %             node = sprintf(format, node_name, notNode, UnsignedNode);
            bodyElts{1} = LustreEq(...
                VarIdExpr('z'), ...
                NodeCallExpr(notNode, ...
                            NodeCallExpr(UnsignedNode, ...
                                   {VarIdExpr('x'), VarIdExpr('y')}))...
                );
            node = LustreNode();
            node.setName(node_name);
            node.setInputs({LustreVar('x', 'int'), LustreVar('y', 'int')});
            node.setOutputs(LustreVar('z', 'int'));
            node.setBodyEqs(bodyElts);           
            node.setIsMain(false);
        end
        %OR
        function [node, external_nodes, opens, abstractedNodes] = getORBitwiseUnsigned(n)
            opens = {};
            abstractedNodes = {};
            external_nodes = {};
            
            %code = {};
            %code{1} = sprintf('( ((x mod 2) + (y mod 2) + (x mod 2)*(y mod 2))  mod 2)');
            args = cell(1, n);
            args{1} =   ...
                BinaryExpr(BinaryExpr.MOD,...
                   BinaryExpr.BinaryMultiArgs(BinaryExpr.PLUS, ...
                    {BinaryExpr(BinaryExpr.MOD, VarIdExpr('x'), IntExpr(2)), ...
                     BinaryExpr(BinaryExpr.MOD, VarIdExpr('y'), IntExpr(2)), ...
                     BinaryExpr(...
                        BinaryExpr.MULTIPLY, ...
                        BinaryExpr(BinaryExpr.MOD, VarIdExpr('x'), IntExpr(2)), ...
                        BinaryExpr(BinaryExpr.MOD, VarIdExpr('y'), IntExpr(2)))...
                        }),...
                   IntExpr(2));
            for i=1:n-1
                v2_pown = 2^i;
                %code{end+1} = sprintf('%d*(((((x / %d) mod 2) + ((y / %d) mod 2) + ((x / %d) mod 2)*((y / %d) mod 2))) mod 2)',...
                %    v2_pown, v2_pown, v2_pown, v2_pown, v2_pown);
                x_term = BinaryExpr(...
                    BinaryExpr.DIVIDE, VarIdExpr('x'), IntExpr(v2_pown));
                y_term = BinaryExpr(...
                    BinaryExpr.DIVIDE, VarIdExpr('y'), IntExpr(v2_pown));
                args{i + 1} =   ...
                    BinaryExpr(...
                        BinaryExpr.MULTIPLY, ...
                        IntExpr(v2_pown), ...
                        BinaryExpr(BinaryExpr.MOD,...
                            BinaryExpr.BinaryMultiArgs(BinaryExpr.PLUS, ...
                                {BinaryExpr(BinaryExpr.MOD, x_term, IntExpr(2)), ...
                                 BinaryExpr(BinaryExpr.MOD, y_term, IntExpr(2)), ...
                                 BinaryExpr(...
                                    BinaryExpr.MULTIPLY, ...
                                    BinaryExpr(BinaryExpr.MOD, x_term, IntExpr(2)), ...
                                    BinaryExpr(BinaryExpr.MOD, y_term, IntExpr(2)))...
                                    }),...
                             IntExpr(2))...
                            );
            end
            %code = MatlabUtils.strjoin(code, ' \n\t+ ');
            rhs = BinaryExpr.BinaryMultiArgs(BinaryExpr.PLUS, args);
            node_name = strcat('_OR_Bitwise_Unsigned_', num2str(n));
            
            %             format = 'node %s (x, y: int)\nreturns(z:int);\nlet\n\t';
            %             format = [format, 'z = %s;\ntel\n\n'];
            %             node = sprintf(format, node_name, code);
            bodyElts{1} = LustreEq(VarIdExpr('z'), rhs);
            node = LustreNode();
            node.setName(node_name);
            node.setInputs({LustreVar('x', 'int'), LustreVar('y', 'int')});
            node.setOutputs(LustreVar('z', 'int'));
            node.setBodyEqs(bodyElts);           
            node.setIsMain(false);
        end
        %XOR
        function [node, external_nodes, opens, abstractedNodes] = getXORBitwiseUnsigned(n)
            opens = {};
            abstractedNodes = {};
            external_nodes = {};
            
            %code = {};
            %code{1} = sprintf('((x + y) mod 2)');
            args = cell(1, n);
            args{1} =   ...
                BinaryExpr(BinaryExpr.MOD,...
                   BinaryExpr(...
                        BinaryExpr.PLUS, ...
                        VarIdExpr('x'), ...
                        VarIdExpr('y')...
                   ),...
                   IntExpr(2));
            for i=1:n-1
                v2_pown = 2^i;
                %code{end+1} = sprintf('%d*(((x / %d) + (y / %d)) mod 2)', v2_pown, v2_pown, v2_pown);
                x_term = BinaryExpr(...
                    BinaryExpr.DIVIDE, VarIdExpr('x'), IntExpr(v2_pown));
                y_term = BinaryExpr(...
                    BinaryExpr.DIVIDE, VarIdExpr('y'), IntExpr(v2_pown));
                args{i + 1} =   ...
                    BinaryExpr(...
                        BinaryExpr.MULTIPLY, ...
                        IntExpr(v2_pown), ...
                        BinaryExpr(BinaryExpr.MOD,...
                             BinaryExpr(BinaryExpr.PLUS, x_term, y_term),...
                             IntExpr(2))...
                    );
            end
            %code = MatlabUtils.strjoin(code, ' \n\t+ ');
            rhs = BinaryExpr.BinaryMultiArgs(BinaryExpr.PLUS, args);
            node_name = strcat('_XOR_Bitwise_Unsigned_', num2str(n));
            
            % format = 'node %s (x, y: int)\nreturns(z:int);\nlet\n\t';
            % format = [format, 'z = %s;\ntel\n\n'];
            % node = sprintf(format, node_name, code);
            bodyElts{1} = LustreEq(VarIdExpr('z'), rhs);
            node = LustreNode();
            node.setName(node_name);
            node.setInputs({LustreVar('x', 'int'), LustreVar('y', 'int')});
            node.setOutputs(LustreVar('z', 'int'));
            node.setBodyEqs(bodyElts);           
            node.setIsMain(false);
        end
        
        
        function [node, external_nodes, opens, abstractedNodes] = getNOTBitwiseUnsigned(n)
            opens = {};
            abstractedNodes = {};
            external_nodes = {};
            node_name = strcat('_NOT_Bitwise_Unsigned_', num2str(n));
            v2_pown = 2^n - 1;
            %format = 'node %s (x: int)\nreturns(y:int);\nlet\n\t';
            %format = [format, 'y=  %d - x ;\ntel\n\n'];
            %node = sprintf(format, node_name,v2_pown);
            bodyElts{1} = LustreEq(...
                VarIdExpr('y'), ...
                BinaryExpr(BinaryExpr.MINUS, IntExpr(v2_pown), VarIdExpr('x'))...
                );
            node = LustreNode();
            node.setName(node_name);
            node.setInputs(LustreVar('x', 'int'));
            node.setOutputs(LustreVar('y', 'int'));
            node.setBodyEqs(bodyElts);           
            node.setIsMain(false);
        end
        function [node, external_nodes, opens, abstractedNodes] = getNOTBitwiseSigned()
            opens = {};
            abstractedNodes = {};
            external_nodes = {};
            node_name = strcat('_NOT_Bitwise_Signed');
            %format = 'node %s (x: int)\nreturns(y:int);\nlet\n\t';
            %format = [format, 'y=   - x - 1;\ntel\n\n'];
            %node = sprintf(format, node_name);
            bodyElts{1} = LustreEq(...
                VarIdExpr('y'), ...
                BinaryExpr(BinaryExpr.MINUS, ...
                    UnaryExpr(UnaryExpr.NEG ,VarIdExpr('x')),...
                    IntExpr(1) )...
                );
            node = LustreNode();
            node.setName(node_name);
            node.setInputs(LustreVar('x', 'int'));
            node.setOutputs(LustreVar('y', 'int'));
            node.setBodyEqs(bodyElts);           
            node.setIsMain(false);
        end
        
        %AND
        function [node, external_nodes_i, opens, abstractedNodes] = get__AND_Bitwise_Unsigned_8(varargin)
            [node, external_nodes_i, opens, abstractedNodes] = LustMathLib.getANDBitwiseUnsigned(8);
        end
        function [node, external_nodes_i, opens, abstractedNodes] = get__AND_Bitwise_Unsigned_16(varargin)
            [node, external_nodes_i, opens, abstractedNodes] = LustMathLib.getANDBitwiseUnsigned(16);
        end
        function [node, external_nodes_i, opens, abstractedNodes] = get__AND_Bitwise_Unsigned_32(varargin)
            [node, external_nodes_i, opens, abstractedNodes] = LustMathLib.getANDBitwiseUnsigned(32);
        end
        function [node, external_nodes_i, opens, abstractedNodes] = get__AND_Bitwise_Signed_8(varargin)
            [node, external_nodes_i, opens, abstractedNodes] = LustMathLib.getBitwiseSigned('AND', 8);
        end
        function [node, external_nodes_i, opens, abstractedNodes] = get__AND_Bitwise_Signed_16(varargin)
            [node, external_nodes_i, opens, abstractedNodes] = LustMathLib.getBitwiseSigned('AND', 16);
        end
        function [node, external_nodes_i, opens, abstractedNodes] = get__AND_Bitwise_Signed_32(varargin)
            [node, external_nodes_i, opens, abstractedNodes] = LustMathLib.getBitwiseSigned('AND', 32);
        end
        %NAND
        function [node, external_nodes_i, opens, abstractedNodes] = get__NAND_Bitwise_Unsigned_8(varargin)
            [node, external_nodes_i, opens, abstractedNodes] = LustMathLib.getNANDBitwiseUnsigned(8);
        end
        function [node, external_nodes_i, opens, abstractedNodes] = get__NAND_Bitwise_Unsigned_16(varargin)
            [node, external_nodes_i, opens, abstractedNodes] = LustMathLib.getNANDBitwiseUnsigned(16);
        end
        function [node, external_nodes_i, opens, abstractedNodes] = get__NAND_Bitwise_Unsigned_32(varargin)
            [node, external_nodes_i, opens, abstractedNodes] = LustMathLib.getNANDBitwiseUnsigned(32);
        end
        function [node, external_nodes_i, opens, abstractedNodes] = get__NAND_Bitwise_Signed_8(varargin)
            [node, external_nodes_i, opens, abstractedNodes] = LustMathLib.getBitwiseSigned('NAND', 8);
        end
        function [node, external_nodes_i, opens, abstractedNodes] = get__NAND_Bitwise_Signed_16(varargin)
            [node, external_nodes_i, opens, abstractedNodes] = LustMathLib.getBitwiseSigned('NAND', 16);
        end
        function [node, external_nodes_i, opens, abstractedNodes] = get__NAND_Bitwise_Signed_32(varargin)
            [node, external_nodes_i, opens, abstractedNodes] = LustMathLib.getBitwiseSigned('NAND', 32);
        end
       
        %OR
        function [node, external_nodes_i, opens, abstractedNodes] = get__OR_Bitwise_Unsigned_8(varargin)
            [node, external_nodes_i, opens, abstractedNodes] = LustMathLib.getORBitwiseUnsigned(8);
        end
        function [node, external_nodes_i, opens, abstractedNodes] = get__OR_Bitwise_Unsigned_16(varargin)
            [node, external_nodes_i, opens, abstractedNodes] = LustMathLib.getORBitwiseUnsigned(16);
        end
        function [node, external_nodes_i, opens, abstractedNodes] = get__OR_Bitwise_Unsigned_32(varargin)
            [node, external_nodes_i, opens, abstractedNodes] = LustMathLib.getORBitwiseUnsigned(32);
        end
        function [node, external_nodes_i, opens, abstractedNodes] = get__OR_Bitwise_Signed_8(varargin)
            [node, external_nodes_i, opens, abstractedNodes] = LustMathLib.getBitwiseSigned('OR', 8);
        end
        function [node, external_nodes_i, opens, abstractedNodes] = get__OR_Bitwise_Signed_16(varargin)
            [node, external_nodes_i, opens, abstractedNodes] = LustMathLib.getBitwiseSigned('OR', 16);
        end
        function [node, external_nodes_i, opens, abstractedNodes] = get__OR_Bitwise_Signed_32(varargin)
            [node, external_nodes_i, opens, abstractedNodes] = LustMathLib.getBitwiseSigned('OR', 32);
        end
        %NOR
        function [node, external_nodes_i, opens, abstractedNodes] = get__NOR_Bitwise_Unsigned_8(varargin)
            [node, external_nodes_i, opens, abstractedNodes] = LustMathLib.getNORBitwiseUnsigned(8);
        end
        function [node, external_nodes_i, opens, abstractedNodes] = get__NOR_Bitwise_Unsigned_16(varargin)
            [node, external_nodes_i, opens, abstractedNodes] = LustMathLib.getNORBitwiseUnsigned(16);
        end
        function [node, external_nodes_i, opens, abstractedNodes] = get__NOR_Bitwise_Unsigned_32(varargin)
            [node, external_nodes_i, opens, abstractedNodes] = LustMathLib.getNORBitwiseUnsigned(32);
        end
        function [node, external_nodes_i, opens, abstractedNodes] = get__NOR_Bitwise_Signed_8(varargin)
            [node, external_nodes_i, opens, abstractedNodes] = LustMathLib.getBitwiseSigned('NOR', 8);
        end
        function [node, external_nodes_i, opens, abstractedNodes] = get__NOR_Bitwise_Signed_16(varargin)
            [node, external_nodes_i, opens, abstractedNodes] = LustMathLib.getBitwiseSigned('NOR', 16);
        end
        function [node, external_nodes_i, opens, abstractedNodes] = get__NOR_Bitwise_Signed_32(varargin)
            [node, external_nodes_i, opens, abstractedNodes] = LustMathLib.getBitwiseSigned('NOR', 32);
        end
       
        %XOR
        function [node, external_nodes_i, opens, abstractedNodes] = get__XOR_Bitwise_Unsigned_8(varargin)
            [node, external_nodes_i, opens, abstractedNodes] = LustMathLib.getXORBitwiseUnsigned(8);
        end
        function [node, external_nodes_i, opens, abstractedNodes] = get__XOR_Bitwise_Unsigned_16(varargin)
            [node, external_nodes_i, opens, abstractedNodes] = LustMathLib.getXORBitwiseUnsigned(16);
        end
        function [node, external_nodes_i, opens, abstractedNodes] = get__XOR_Bitwise_Unsigned_32(varargin)
            [node, external_nodes_i, opens, abstractedNodes] = LustMathLib.getXORBitwiseUnsigned(32);
        end
        function [node, external_nodes_i, opens, abstractedNodes] = get__XOR_Bitwise_Signed_8(varargin)
            [node, external_nodes_i, opens, abstractedNodes] = LustMathLib.getBitwiseSigned('XOR', 8);
        end
        function [node, external_nodes_i, opens, abstractedNodes] = get__XOR_Bitwise_Signed_16(varargin)
            [node, external_nodes_i, opens, abstractedNodes] = LustMathLib.getBitwiseSigned('XOR', 16);
        end
        function [node, external_nodes_i, opens, abstractedNodes] = get__XOR_Bitwise_Signed_32(varargin)
            [node, external_nodes_i, opens, abstractedNodes] = LustMathLib.getBitwiseSigned('XOR', 32);
        end
        
        %NOT
        function [node, external_nodes_i, opens, abstractedNodes] = get__NOT_Bitwise_Signed(varargin)
            [node, external_nodes_i, opens, abstractedNodes] = LustMathLib.getNOTBitwiseSigned();
        end
        function [node, external_nodes_i, opens, abstractedNodes] = get__NOT_Bitwise_Unsigned_8(varargin)
            [node, external_nodes_i, opens, abstractedNodes] = LustMathLib.getNOTBitwiseUnsigned(8);
        end
        function [node, external_nodes_i, opens, abstractedNodes] = get__NOT_Bitwise_Unsigned_16(varargin)
            [node, external_nodes_i, opens, abstractedNodes] = LustMathLib.getNOTBitwiseUnsigned(16);
        end
        function [node, external_nodes_i, opens, abstractedNodes] = get__NOT_Bitwise_Unsigned_32(varargin)
            [node, external_nodes_i, opens, abstractedNodes] = LustMathLib.getNOTBitwiseUnsigned(32);
        end
        %% Integer division
        
        % The following functions assume "/" and "mod" in Lustre as in
        % euclidean division for integers.
        
        function [node, external_nodes_i, opens, abstractedNodes] = get_int_div_Ceiling(varargin)
            opens = {};
            abstractedNodes = {};
            external_nodes_i = {strcat('LustMathLib_', 'abs_int')};
            %             format = '--Rounds positive and negative numbers toward positive infinity\n ';
            %             format = [format,  'node int_div_Ceiling (x, y: int)\nreturns(z:int);\nlet\n\t'];
            %             format = [format, 'z= if y = 0 then (if x>0 then 2147483647 else -2147483648)\n\t'];
            %             format = [format, 'else if x mod y = 0 then x/y\n\t'];
            %             format = [format, 'else if (abs_int(y) > abs_int(x) and x*y>0) then 1 \n\t'];
            %             format = [format, 'else if (abs_int(y) > abs_int(x) and x*y<0) then 0 \n\t'];
            %             format = [format, 'else if (x>0 and y < 0) then x/y \n\t'];
            %             format = [format, 'else if (x<0 and y > 0) then (-x)/(-y) \n\t'];
            %             format = [format, 'else if (x<0 and y < 0) then (-x)/(-y) + 1 \n\t'];
            %             format = [format, 'else x/y + 1;\ntel\n\n'];
            %             node = sprintf(format);
            
            %y = 0
            conds{1} = BinaryExpr(BinaryExpr.EQ, VarIdExpr('y'), IntExpr(0));
            %if x>0 then 2147483647 else -2147483648
            thens{1} = IteExpr(...
                BinaryExpr(BinaryExpr.GT, VarIdExpr('x'), IntExpr(0)),...
                IntExpr(2147483647), IntExpr(-2147483648),...
                true);
            % x mod y = 0
            conds{2} = BinaryExpr(...
                BinaryExpr.EQ, ...
                BinaryExpr(BinaryExpr.MOD, VarIdExpr('x'), VarIdExpr('y')), ...
                IntExpr(0));
            % x/y
            thens{2} = BinaryExpr(BinaryExpr.DIVIDE, VarIdExpr('x'), VarIdExpr('y'));
            %(abs_int(y) > abs_int(x) and x*y>0)
            conds{3} = BinaryExpr(...
                BinaryExpr.AND, ...
                BinaryExpr(BinaryExpr.GT, ...
                           NodeCallExpr('abs_int', VarIdExpr('y')),...
                           NodeCallExpr('abs_int', VarIdExpr('x'))), ...
                BinaryExpr(BinaryExpr.GT, ...
                           BinaryExpr(BinaryExpr.MULTIPLY, VarIdExpr('x'), VarIdExpr('y')),...
                           IntExpr(0))...
                );
            % 1
            thens{3} = IntExpr(1);
            %(abs_int(y) > abs_int(x) and x*y<0)
            conds{4} = BinaryExpr(...
                BinaryExpr.AND, ...
                BinaryExpr(BinaryExpr.GT, ...
                           NodeCallExpr('abs_int', VarIdExpr('y')),...
                           NodeCallExpr('abs_int', VarIdExpr('x'))), ...
                BinaryExpr(BinaryExpr.LT, ...
                           BinaryExpr(BinaryExpr.MULTIPLY, VarIdExpr('x'), VarIdExpr('y')),...
                           IntExpr(0))...
                );
            % 0
            thens{4} = IntExpr(0);
            % (x>0 and y < 0)
            conds{5} = BinaryExpr(...
                BinaryExpr.AND, ...
                BinaryExpr(BinaryExpr.GT, ...
                           VarIdExpr('x'),...
                           IntExpr(0)), ...
                BinaryExpr(BinaryExpr.LT, ...
                           VarIdExpr('y'),...
                           IntExpr(0))...
                );
            %x/y
            thens{5} = BinaryExpr(BinaryExpr.DIVIDE, VarIdExpr('x'), VarIdExpr('y'));
            % (x<0 and y > 0)
            conds{6} = BinaryExpr(...
                BinaryExpr.AND, ...
                BinaryExpr(BinaryExpr.LT, ...
                           VarIdExpr('x'),...
                           IntExpr(0)), ...
                BinaryExpr(BinaryExpr.GT, ...
                           VarIdExpr('y'),...
                           IntExpr(0))...
                );
            %(-x)/(-y)
            thens{6} = BinaryExpr(...
                BinaryExpr.DIVIDE, ...
                UnaryExpr(UnaryExpr.NEG, VarIdExpr('x')), ...
                UnaryExpr(UnaryExpr.NEG, VarIdExpr('y')));
            
            % (x < 0 and y < 0)
            conds{7} = BinaryExpr(...
                BinaryExpr.AND, ...
                BinaryExpr(BinaryExpr.LT, ...
                           VarIdExpr('x'),...
                           IntExpr(0)), ...
                BinaryExpr(BinaryExpr.LT, ...
                           VarIdExpr('y'),...
                           IntExpr(0))...
                );
            %(-x)/(-y) + 1
            thens{7} = BinaryExpr(BinaryExpr.PLUS,...
                BinaryExpr(...
                    BinaryExpr.DIVIDE, ...
                    UnaryExpr(UnaryExpr.NEG, VarIdExpr('x')), ...
                    UnaryExpr(UnaryExpr.NEG, VarIdExpr('y'))),...
                IntExpr(1));
            %x/y + 1
            thens{8} = BinaryExpr(BinaryExpr.PLUS,...
                BinaryExpr(BinaryExpr.DIVIDE, VarIdExpr('x'), VarIdExpr('y')),...
                IntExpr(1));
            bodyElts{1} = LustreEq(...
                VarIdExpr('z'), ...
                IteExpr.nestedIteExpr(conds, thens)...
                );
            node = LustreNode();
            node.setMetaInfo('Rounds positive and negative numbers toward positive infinity');
            node.setName('int_div_Ceiling');
            node.setInputs({LustreVar('x', 'int'), LustreVar('y', 'int')});
            node.setOutputs(LustreVar('z', 'int'));
            node.setBodyEqs(bodyElts);           
            node.setIsMain(false);
        end
        %Floor: Rounds positive and negative numbers toward negative infinity.
        function [node, external_nodes_i, opens, abstractedNodes] = get_int_div_Floor(varargin)
            opens = {};
            abstractedNodes = {};
            external_nodes_i = {strcat('LustMathLib_', 'abs_int')};
            % format = '--Rounds positive and negative numbers toward negative infinity\n ';
            % format = [format,  'node int_div_Floor (x, y: int)\nreturns(z:int);\nlet\n\t'];
            % format = [format, 'z= if y = 0 then if x>0 then 2147483647 else -2147483648\n\t'];
            % format = [format, 'else if x mod y = 0 then x/y\n\t'];
            % format = [format, 'else if (abs_int(y) > abs_int(x) and x*y>0) then 0 \n\t'];
            % format = [format, 'else if (abs_int(y) > abs_int(x) and x*y<0) then -1 \n\t'];
            % format = [format, 'else if (x>0 and y < 0) then x/y - 1\n\t'];
            % format = [format, 'else if (x<0 and y > 0) then (-x)/(-y) - 1\n\t'];
            % format = [format, 'else if (x<0 and y < 0) then (-x)/(-y)\n\t'];
            % format = [format, 'else x/y;\ntel\n\n'];
            % node = sprintf(format);
             %y = 0
            conds{1} = BinaryExpr(BinaryExpr.EQ, VarIdExpr('y'), IntExpr(0));
            %if x>0 then 2147483647 else -2147483648
            thens{1} = IteExpr(...
                BinaryExpr(BinaryExpr.GT, VarIdExpr('x'), IntExpr(0)),...
                IntExpr(2147483647), IntExpr(-2147483648),...
                true);
            % x mod y = 0
            conds{2} = BinaryExpr(...
                BinaryExpr.EQ, ...
                BinaryExpr(BinaryExpr.MOD, VarIdExpr('x'), VarIdExpr('y')), ...
                IntExpr(0));
            % x/y
            thens{2} = BinaryExpr(BinaryExpr.DIVIDE, VarIdExpr('x'), VarIdExpr('y'));
            %(abs_int(y) > abs_int(x) and x*y>0)
            conds{3} = BinaryExpr(...
                BinaryExpr.AND, ...
                BinaryExpr(BinaryExpr.GT, ...
                           NodeCallExpr('abs_int', VarIdExpr('y')),...
                           NodeCallExpr('abs_int', VarIdExpr('x'))), ...
                BinaryExpr(BinaryExpr.GT, ...
                           BinaryExpr(BinaryExpr.MULTIPLY, VarIdExpr('x'), VarIdExpr('y')),...
                           IntExpr(0))...
                );
            % 0
            thens{3} = IntExpr(0);
            %(abs_int(y) > abs_int(x) and x*y<0)
            conds{4} = BinaryExpr(...
                BinaryExpr.AND, ...
                BinaryExpr(BinaryExpr.GT, ...
                           NodeCallExpr('abs_int', VarIdExpr('y')),...
                           NodeCallExpr('abs_int', VarIdExpr('x'))), ...
                BinaryExpr(BinaryExpr.LT, ...
                           BinaryExpr(BinaryExpr.MULTIPLY, VarIdExpr('x'), VarIdExpr('y')),...
                           IntExpr(0))...
                );
            % -1
            thens{4} = IntExpr(-1);
            % (x>0 and y < 0)
            conds{5} = BinaryExpr(...
                BinaryExpr.AND, ...
                BinaryExpr(BinaryExpr.GT, ...
                           VarIdExpr('x'),...
                           IntExpr(0)), ...
                BinaryExpr(BinaryExpr.LT, ...
                           VarIdExpr('y'),...
                           IntExpr(0))...
                );
            %x/y - 1
            thens{5} = BinaryExpr(...
                    BinaryExpr.MINUS, ...
                    BinaryExpr(BinaryExpr.DIVIDE, VarIdExpr('x'), VarIdExpr('y')), ...
                    IntExpr(1));
            % (x<0 and y > 0)
            conds{6} = BinaryExpr(...
                BinaryExpr.AND, ...
                BinaryExpr(BinaryExpr.LT, ...
                           VarIdExpr('x'),...
                           IntExpr(0)), ...
                BinaryExpr(BinaryExpr.GT, ...
                           VarIdExpr('y'),...
                           IntExpr(0))...
                );
            %(-x)/(-y) - 1
            thens{6} = BinaryExpr(...
                    BinaryExpr.MINUS, ...
                    BinaryExpr(...
                        BinaryExpr.DIVIDE, ...
                        UnaryExpr(UnaryExpr.NEG, VarIdExpr('x')), ...
                        UnaryExpr(UnaryExpr.NEG, VarIdExpr('y'))), ...
                    IntExpr(1));
            
            % (x < 0 and y < 0)
            conds{7} = BinaryExpr(...
                BinaryExpr.AND, ...
                BinaryExpr(BinaryExpr.LT, ...
                           VarIdExpr('x'),...
                           IntExpr(0)), ...
                BinaryExpr(BinaryExpr.LT, ...
                           VarIdExpr('y'),...
                           IntExpr(0))...
                );
            %(-x)/(-y) 
            thens{7} = BinaryExpr(...
                    BinaryExpr.DIVIDE, ...
                    UnaryExpr(UnaryExpr.NEG, VarIdExpr('x')), ...
                    UnaryExpr(UnaryExpr.NEG, VarIdExpr('y')));
            %x/y
            thens{8} = BinaryExpr(BinaryExpr.DIVIDE, VarIdExpr('x'), VarIdExpr('y'));
            bodyElts{1} = LustreEq(...
                VarIdExpr('z'), ...
                IteExpr.nestedIteExpr(conds, thens)...
                );
            node = LustreNode();
            node.setMetaInfo('Rounds positive and negative numbers toward negative infinity');
            node.setName('int_div_Floor');
            node.setInputs({LustreVar('x', 'int'), LustreVar('y', 'int')});
            node.setOutputs(LustreVar('z', 'int'));
            node.setBodyEqs(bodyElts);           
            node.setIsMain(false);
        end
        function [node, external_nodes_i, opens, abstractedNodes] = get_int_div_Nearest(varargin)
            opens = {};
            abstractedNodes = {};
            external_nodes_i = {'LustMathLib_int_div_Ceiling'};
            % format = '--Rounds number to the nearest representable value. If a tie occurs, rounds toward positive infinity\n ';
            % format = [format,  'node int_div_Nearest (x, y: int)\nreturns(z:int);\nlet\n\t'];
            % format = [format, 'z= if y = 0 then if x>0 then 2147483647 else -2147483648\n\t'];
            % format = [format, 'else if x mod y = 0 then x/y\n\t'];
            %                    else if (((x mod y) * 2) = y) then
            %                       int_div_Ceiling(x,y)
            % format = [format, 'else if (y > 0) and ((x mod y)*2 >= y ) then x/y+1 \n\t'];
            % format = [format, 'else if (y < 0) and ((x mod y)*2 >= (-y))  then x/y-1 \n\t'];
            % format = [format, 'else x/y;\ntel\n\n'];
            % node = sprintf(format);
            conds = {};
            thens = {};
            %y = 0
            conds{1} = BinaryExpr(BinaryExpr.EQ, VarIdExpr('y'), IntExpr(0));
            %if x>0 then 2147483647 else -2147483648
            thens{1} = IteExpr(...
                BinaryExpr(BinaryExpr.GT, VarIdExpr('x'), IntExpr(0)),...
                IntExpr(2147483647), IntExpr(-2147483648),...
                true);
            % x mod y = 0
            conds{end + 1} = BinaryExpr(...
                BinaryExpr.EQ, ...
                BinaryExpr(BinaryExpr.MOD, VarIdExpr('x'), VarIdExpr('y')), ...
                IntExpr(0));
            % x/y
            thens{end + 1} = BinaryExpr(BinaryExpr.DIVIDE, VarIdExpr('x'), VarIdExpr('y'));
            %(((x mod y) * 2) = y)
            conds{end + 1} = BinaryExpr(BinaryExpr.EQ, ...
                           BinaryExpr(BinaryExpr.MULTIPLY, ...
                                      BinaryExpr(BinaryExpr.MOD, ...
                                                 VarIdExpr('x'), ...
                                                 VarIdExpr('y')),...
                                      IntExpr(2)),...
                           VarIdExpr('y'));
            %int_div_Ceiling(x,y)
            thens{end + 1} = NodeCallExpr('int_div_Ceiling',...
                {VarIdExpr('x'), VarIdExpr('y')});
            %(y > 0) and ((x mod y)*2 >= y )
            conds{end + 1} = BinaryExpr(...
                BinaryExpr.AND, ...
                BinaryExpr(BinaryExpr.GT, ...
                           VarIdExpr('y'),...
                           IntExpr(0)), ...
                BinaryExpr(BinaryExpr.GT, ...
                           BinaryExpr(BinaryExpr.MULTIPLY, ...
                                      BinaryExpr(BinaryExpr.MOD, ...
                                                 VarIdExpr('x'), ...
                                                 VarIdExpr('y')),...
                                      IntExpr(2)),...
                           VarIdExpr('y'))...
                );
            % x/y + 1
            thens{end + 1} = BinaryExpr(...
                    BinaryExpr.PLUS, ...
                    BinaryExpr(BinaryExpr.DIVIDE, VarIdExpr('x'), VarIdExpr('y')), ...
                    IntExpr(1));
            %(y < 0) and ((x mod y)*2 >= (-y))
            conds{end + 1} = BinaryExpr(...
                BinaryExpr.AND, ...
                BinaryExpr(BinaryExpr.LT, ...
                           VarIdExpr('y'),...
                           IntExpr(0)), ...
                BinaryExpr(BinaryExpr.GT, ...
                           BinaryExpr(BinaryExpr.MULTIPLY, ...
                                      BinaryExpr(BinaryExpr.MOD, ...
                                                 VarIdExpr('x'), ...
                                                 VarIdExpr('y')),...
                                      IntExpr(2)),...
                           UnaryExpr(UnaryExpr.NEG,VarIdExpr('y')))...
                );
            % x/y - 1
            thens{end + 1} = BinaryExpr(...
                    BinaryExpr.MINUS, ...
                    BinaryExpr(BinaryExpr.DIVIDE, VarIdExpr('x'), VarIdExpr('y')), ...
                    IntExpr(1));    
            %x/y
            thens{end + 1} = BinaryExpr(BinaryExpr.DIVIDE, VarIdExpr('x'), VarIdExpr('y'));
            bodyElts{1} = LustreEq(...
                VarIdExpr('z'), ...
                IteExpr.nestedIteExpr(conds, thens)...
                );
            node = LustreNode();
            node.setMetaInfo('Rounds number to the nearest representable value. If a tie occurs, rounds toward positive infinity');
            node.setName('int_div_Nearest');
            node.setInputs({LustreVar('x', 'int'), LustreVar('y', 'int')});
            node.setOutputs(LustreVar('z', 'int'));
            node.setBodyEqs(bodyElts);           
            node.setIsMain(false);
        end
        
        function [node, external_nodes_i, opens, abstractedNodes] = get_int_div_Zero(varargin)
            opens = {};
            abstractedNodes = {};
            external_nodes_i = {strcat('LustMathLib_', 'abs_int')};
            % format = '--Rounds positive and negative numbers toward positive infinity\n ';
            % format = [format,  'node int_div_Zero (x, y: int)\nreturns(z:int);\nlet\n\t'];
            % format = [format, 'z= if y = 0 then if x>0 then 2147483647 else -2147483648\n\t'];
            % format = [format, 'else if x mod y = 0 then x/y\n\t'];
            % format = [format, 'else if (abs_int(y) > abs_int(x)) then 0 \n\t'];
            % format = [format, 'else if (x>0) then x/y \n\t'];
            % format = [format, 'else (-x)/(-y);\ntel\n\n'];
            % node = sprintf(format);
            %y = 0
            conds{1} = BinaryExpr(BinaryExpr.EQ, VarIdExpr('y'), IntExpr(0));
            %if x>0 then 2147483647 else -2147483648
            thens{1} = IteExpr(...
                BinaryExpr(BinaryExpr.GT, VarIdExpr('x'), IntExpr(0)),...
                IntExpr(2147483647), IntExpr(-2147483648),...
                true);
            % x mod y = 0
            conds{2} = BinaryExpr(...
                BinaryExpr.EQ, ...
                BinaryExpr(BinaryExpr.MOD, VarIdExpr('x'), VarIdExpr('y')), ...
                IntExpr(0));
            % x/y
            thens{2} = BinaryExpr(BinaryExpr.DIVIDE, VarIdExpr('x'), VarIdExpr('y'));
            % (abs_int(y) > abs_int(x))
            conds{3} =  BinaryExpr(BinaryExpr.GT, ...
                           NodeCallExpr('abs_int', VarIdExpr('y')),...
                           NodeCallExpr('abs_int', VarIdExpr('x')));
            % 0
            thens{3} = IntExpr(0);
            % (x>0)
            conds{4} =  BinaryExpr(BinaryExpr.GT, ...
                            VarIdExpr('x'),...
                            IntExpr(0));
            % x/y
            thens{4} = BinaryExpr(BinaryExpr.DIVIDE, VarIdExpr('x'), VarIdExpr('y'));
            % (-x)/(-y)
            thens{5} = BinaryExpr(...
                    BinaryExpr.DIVIDE, ...
                    UnaryExpr(UnaryExpr.NEG, VarIdExpr('x')), ...
                    UnaryExpr(UnaryExpr.NEG, VarIdExpr('y')));
            bodyElts{1} = LustreEq(...
                VarIdExpr('z'), ...
                IteExpr.nestedIteExpr(conds, thens)...
                );
            node = LustreNode();
            node.setMetaInfo('Rounds positive and negative numbers toward positive infinity');
            node.setName('int_div_Zero');
            node.setInputs({LustreVar('x', 'int'), LustreVar('y', 'int')});
            node.setOutputs(LustreVar('z', 'int'));
            node.setBodyEqs(bodyElts);           
            node.setIsMain(false);
        end
        
        %% fmod, rem, mod
        function [node, external_nodes_i, opens, abstractedNodes] = get_fmod(varargin)
            opens = {'lustrec_math'};
            abstractedNodes = {'fmod'};
            external_nodes_i = {};
            node = '';
        end
        function [node, external_nodes_i, opens, abstractedNodes] = get_rem_int_int(varargin)
            opens = {};
            abstractedNodes = {};
            external_nodes_i = {strcat('LustMathLib_', 'abs_int')};
            % format = 'node rem_int_int (x, y: int)\nreturns(z:int);\nlet\n\t';
            % format = [format, 'z = if (y = 0 or x = 0) then 0\n\t\telse\n\t\t (x mod y) - (if (x mod y <> 0 and x <= 0) then abs_int(y) else 0);\ntel\n\n'];
            % node = sprintf(format);
            cond = BinaryExpr(...
                BinaryExpr.OR, ...
                BinaryExpr(BinaryExpr.EQ, VarIdExpr('y'), IntExpr(0)), ...
                BinaryExpr(BinaryExpr.EQ, VarIdExpr('x'), IntExpr(0)));
            cond2 = BinaryExpr(...
                BinaryExpr.AND, ...
                BinaryExpr( BinaryExpr.NEQ,...
                            BinaryExpr(BinaryExpr.MOD, VarIdExpr('x'), VarIdExpr('y')),...
                            IntExpr(0)), ...
                BinaryExpr(BinaryExpr.LTE, VarIdExpr('x'), IntExpr(0)));
            elseExp =  BinaryExpr(...
                BinaryExpr.MINUS, ...
                BinaryExpr(BinaryExpr.MOD, VarIdExpr('x'), VarIdExpr('y')),...
                IteExpr(cond2, ...
                        NodeCallExpr('abs_int',  VarIdExpr('y')),...
                        IntExpr(0),...
                        true)...
                 );
            rhs = IteExpr(cond, IntExpr(0), elseExp);
            bodyElts{1} = LustreEq(...
                VarIdExpr('z'), ...
                rhs...
                );
            node = LustreNode();
            node.setName('rem_int_int');
            node.setInputs({LustreVar('x', 'int'), LustreVar('y', 'int')});
            node.setOutputs(LustreVar('z', 'int'));
            node.setBodyEqs(bodyElts);           
            node.setIsMain(false);
        end
        function [node, external_nodes_i, opens, abstractedNodes] = get_mod_int_int(varargin)
            opens = {};
            abstractedNodes = {};
            external_nodes_i = {strcat('LustMathLib_', 'abs_int')};
            % format = 'node mod_int_int (x, y: int)\nreturns(z:int);\nlet\n\t';
            % format = [format, 'z = if (y = 0 or x = 0) then x\n\t\telse\n\t\t (x mod y) - (if (x mod y <> 0 and y <= 0) then (if y > 0 then y else -y) else 0);\ntel\n\n'];
            % node = sprintf(format);
             cond = BinaryExpr(...
                BinaryExpr.OR, ...
                BinaryExpr(BinaryExpr.EQ, VarIdExpr('y'), IntExpr(0)), ...
                BinaryExpr(BinaryExpr.EQ, VarIdExpr('x'), IntExpr(0)));
            cond2 = BinaryExpr(...
                BinaryExpr.AND, ...
                BinaryExpr( BinaryExpr.NEQ,...
                            BinaryExpr(BinaryExpr.MOD, VarIdExpr('x'), VarIdExpr('y')),...
                            IntExpr(0)), ...
                BinaryExpr(BinaryExpr.LTE, VarIdExpr('y'), IntExpr(0)));
            elseExp =  BinaryExpr(...
                BinaryExpr.MINUS, ...
                BinaryExpr(BinaryExpr.MOD, VarIdExpr('x'), VarIdExpr('y')),...
                IteExpr(cond2, ...
                        NodeCallExpr('abs_int',  VarIdExpr('y')),...
                        IntExpr(0),...
                        true)...
                 );
            rhs = IteExpr(cond, VarIdExpr('x'), elseExp);
            bodyElts{1} = LustreEq(...
                VarIdExpr('z'), ...
                rhs...
                );
            node = LustreNode();
            node.setName('mod_int_int');
            node.setInputs({LustreVar('x', 'int'), LustreVar('y', 'int')});
            node.setOutputs(LustreVar('z', 'int'));
            node.setBodyEqs(bodyElts);           
            node.setIsMain(false);
        end
        
        
        
        %% Matrix inversion
        function [node, external_nodes_i, opens, abstractedNodes] = get__inv_M_2x2(varargin)
            opens = {};
            abstractedNodes = {};
            external_nodes_i ={};
            node_name = '_inv_M_2x2';
            body = {};
            vars = {}; 
            
            a = VarIdExpr('a');
            b = VarIdExpr('b');
            c = VarIdExpr('c');
            d = VarIdExpr('d');    
            ainv = VarIdExpr('a_inv');
            binv = VarIdExpr('b_inv');
            cinv = VarIdExpr('c_inv');
            dinv = VarIdExpr('d_inv'); 
            det = VarIdExpr('det');
            vars{1} = LustreVar(det,'real');
            
            term1 = BinaryExpr(BinaryExpr.MULTIPLY,a,d);
            term2 = BinaryExpr(BinaryExpr.MULTIPLY,b,c);
            body{1} = LustreEq(det,BinaryExpr(BinaryExpr.MINUS,term1,term2));
            body{end+1} = LustreEq(ainv,BinaryExpr(BinaryExpr.DIVIDE,d,det));
            body{end+1} = LustreEq(binv,BinaryExpr(BinaryExpr.DIVIDE,...
                UnaryExpr(UnaryExpr.NEG, b),det));
            body{end+1} = LustreEq(cinv,BinaryExpr(BinaryExpr.DIVIDE,...
                UnaryExpr(UnaryExpr.NEG, c),det));
            body{end+1} = LustreEq(dinv,BinaryExpr(BinaryExpr.DIVIDE,a,det));            
            node = LustreNode();
            node.setName(node_name);
            node.setInputs({LustreVar(a, 'real'), LustreVar(b, 'real'),...
                LustreVar(c, 'real'), LustreVar(d, 'real')});
            node.setOutputs({LustreVar(ainv, 'real'), LustreVar(binv, 'real'),...
                LustreVar(cinv, 'real'), LustreVar(dinv, 'real')});
            node.setBodyEqs(body);   
            node.setLocalVars(vars);
            node.setIsMain(false);
        end
        
        function [node, external_nodes_i, opens, abstractedNodes] = get__inv_M_3x3(varargin)
            % define i: row, j: column to follow 
            opens = {};
            abstractedNodes = {};
            external_nodes_i ={};
            node_name = '_inv_M_3x3';
            body = {};
            vars = {}; 
            
            % inputs
            a11 = VarIdExpr('a11');
            a21 = VarIdExpr('a21');
            a31 = VarIdExpr('a31');
            a12 = VarIdExpr('a12');   
            a22 = VarIdExpr('a22');
            a32 = VarIdExpr('a32');
            a13 = VarIdExpr('a13');
            a23 = VarIdExpr('a23'); 
            a33 = VarIdExpr('a33'); 
            % outputs
            a11i = VarIdExpr('a11i');
            a21i = VarIdExpr('a21i');
            a31i = VarIdExpr('a31i');
            a12i = VarIdExpr('a12i');   
            a22i = VarIdExpr('a22i');
            a32i = VarIdExpr('a32i');
            a13i = VarIdExpr('a13i');
            a23i = VarIdExpr('a23i'); 
            a33i = VarIdExpr('a33i'); 
            % det
            det = VarIdExpr('det');
            % adjugate
            a11adj = VarIdExpr('a11adj');
            a21adj = VarIdExpr('a21adj');
            a31adj = VarIdExpr('a31adj');
            a12adj = VarIdExpr('a12adj');   
            a22adj = VarIdExpr('a22adj');
            a32adj = VarIdExpr('a32adj');
            a13adj = VarIdExpr('a13adj');
            a23adj = VarIdExpr('a23adj'); 
            a33adj = VarIdExpr('a33adj');             
            
            % define local variables
            vars{1} = LustreVar(det,'real');
            vars{end+1} = LustreVar(a11adj,'real');
            vars{end+1} = LustreVar(a21adj,'real');
            vars{end+1} = LustreVar(a31adj,'real');
            vars{end+1} = LustreVar(a12adj,'real');
            vars{end+1} = LustreVar(a22adj,'real');
            vars{end+1} = LustreVar(a32adj,'real');
            vars{end+1} = LustreVar(a13adj,'real');
            vars{end+1} = LustreVar(a23adj,'real');
            vars{end+1} = LustreVar(a33adj,'real');
            
            % define det
            term1 =  BinaryExpr(BinaryExpr.MULTIPLY,a11,a11adj);
            term2 =  BinaryExpr(BinaryExpr.MULTIPLY,a12,a21adj);
            term4 = BinaryExpr(BinaryExpr.PLUS,term1,term2);
            term3 =  BinaryExpr(BinaryExpr.MULTIPLY,a13,a31adj);
            body{1} = LustreEq(det,BinaryExpr(BinaryExpr.PLUS,term4,term3));
            
            % define adjugate
            term1 = BinaryExpr(BinaryExpr.MULTIPLY,a22,a33);
            term2 = BinaryExpr(BinaryExpr.MULTIPLY,a23,a32);            
            body{end+1} = LustreEq(a11adj,BinaryExpr(BinaryExpr.MINUS,term1,term2));

            term1 = BinaryExpr(BinaryExpr.MULTIPLY,a23,a31);
            term2 = BinaryExpr(BinaryExpr.MULTIPLY,a21,a33);            
            body{end+1} = LustreEq(a21adj,BinaryExpr(BinaryExpr.MINUS,term1,term2));            
            
            term1 = BinaryExpr(BinaryExpr.MULTIPLY,a21,a32);
            term2 = BinaryExpr(BinaryExpr.MULTIPLY,a31,a22);            
            body{end+1} = LustreEq(a31adj,BinaryExpr(BinaryExpr.MINUS,term1,term2));   
            
            term1 = BinaryExpr(BinaryExpr.MULTIPLY,a13,a32);
            term2 = BinaryExpr(BinaryExpr.MULTIPLY,a33,a12);            
            body{end+1} = LustreEq(a12adj,BinaryExpr(BinaryExpr.MINUS,term1,term2));  
            
            term1 = BinaryExpr(BinaryExpr.MULTIPLY,a11,a33);
            term2 = BinaryExpr(BinaryExpr.MULTIPLY,a13,a31);            
            body{end+1} = LustreEq(a22adj,BinaryExpr(BinaryExpr.MINUS,term1,term2));    
            
            term1 = BinaryExpr(BinaryExpr.MULTIPLY,a12,a31);
            term2 = BinaryExpr(BinaryExpr.MULTIPLY,a32,a11);            
            body{end+1} = LustreEq(a32adj,BinaryExpr(BinaryExpr.MINUS,term1,term2));   
            
            term1 = BinaryExpr(BinaryExpr.MULTIPLY,a12,a23);
            term2 = BinaryExpr(BinaryExpr.MULTIPLY,a22,a13);            
            body{end+1} = LustreEq(a13adj,BinaryExpr(BinaryExpr.MINUS,term1,term2));  
            
            term1 = BinaryExpr(BinaryExpr.MULTIPLY,a13,a21);
            term2 = BinaryExpr(BinaryExpr.MULTIPLY,a23,a11);            
            body{end+1} = LustreEq(a23adj,BinaryExpr(BinaryExpr.MINUS,term1,term2));  
            
            term1 = BinaryExpr(BinaryExpr.MULTIPLY,a11,a22);
            term2 = BinaryExpr(BinaryExpr.MULTIPLY,a21,a12);            
            body{end+1} = LustreEq(a33adj,BinaryExpr(BinaryExpr.MINUS,term1,term2));            
                     
            % define inverse
            body{end+1} = LustreEq(a11i,BinaryExpr(BinaryExpr.DIVIDE,a11adj,det));
            body{end+1} = LustreEq(a21i,BinaryExpr(BinaryExpr.DIVIDE,a21adj,det));
            body{end+1} = LustreEq(a31i,BinaryExpr(BinaryExpr.DIVIDE,a31adj,det));
            body{end+1} = LustreEq(a12i,BinaryExpr(BinaryExpr.DIVIDE,a12adj,det));
            body{end+1} = LustreEq(a22i,BinaryExpr(BinaryExpr.DIVIDE,a22adj,det));
            body{end+1} = LustreEq(a32i,BinaryExpr(BinaryExpr.DIVIDE,a32adj,det));
            body{end+1} = LustreEq(a13i,BinaryExpr(BinaryExpr.DIVIDE,a13adj,det));
            body{end+1} = LustreEq(a23i,BinaryExpr(BinaryExpr.DIVIDE,a23adj,det));
            body{end+1} = LustreEq(a33i,BinaryExpr(BinaryExpr.DIVIDE,a33adj,det));

          
            node = LustreNode();
            node.setName(node_name);
            node.setInputs({LustreVar(a11, 'real'), LustreVar(a21, 'real'),...
                LustreVar(a31, 'real'), LustreVar(a12, 'real'),...
                LustreVar(a22, 'real'), LustreVar(a32, 'real'),...
                LustreVar(a13, 'real'), LustreVar(a23, 'real'),LustreVar(a33, 'real')});
            node.setOutputs({LustreVar(a11i, 'real'), LustreVar(a21i, 'real'),...
                LustreVar(a31i, 'real'), LustreVar(a12i, 'real'),...
                LustreVar(a22i, 'real'), LustreVar(a32i, 'real'),...
                LustreVar(a13i, 'real'), LustreVar(a23i, 'real'),LustreVar(a33i, 'real')});
            node.setBodyEqs(body);   
            node.setLocalVars(vars);
            node.setIsMain(false);            
        end
        
%         function [node, external_nodes_i, opens, abstractedNodes] = get__inv_M_4x4(varargin)
%             
%         end
%         
%         function [node, external_nodes_i, opens, abstractedNodes] = get__inv_M_5x5(varargin)
%             
%         end        
%         
%         function [node, external_nodes_i, opens, abstractedNodes] = get__inv_M_6x6(varargin)
%             
%         end      
%         
%         function [node, external_nodes_i, opens, abstractedNodes] = get__inv_M_7x7(varargin)
%             
%         end        
        
    end
    
end

