classdef UnaryExpr < nasa_toLustre.lustreAst.LustreExpr
    %UnaryExpr
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        op;
        expr;
        withPar; %with parentheses
    end
    properties(Constant)
        NOT = 'not';
        PRE = 'pre';
        LAST = 'last';
        NEG = '-';
        REAL = 'real';
        INT = 'int';
        
    end
    methods
        function obj = UnaryExpr(op, expr, withPar)
            obj.op = op;
            if iscell(expr) && numel(expr) == 1
                obj.expr = expr{1};
            else
                obj.expr = expr;
            end
            if exist('withPar', 'var')
                obj.withPar = withPar;
            else
                obj.withPar = true;
            end
        end
        function setPar(obj, withPar)
            obj.withPar = withPar;
        end
        function new_obj = deepCopy(obj)
            new_expr = obj.expr.deepCopy();
            new_obj = nasa_toLustre.lustreAst.UnaryExpr(obj.op, new_expr, obj.withPar);
        end
        
        %% simplify expression
        function new_obj = simplify(obj)
            import nasa_toLustre.lustreAst.*
            new_expr = obj.expr.simplify();
            if isa(new_expr, 'UnaryExpr') ...
                    && isequal(new_expr.op, obj.op) ...
                    && (isequal(obj.op, nasa_toLustre.lustreAst.UnaryExpr.NOT) || isequal(obj.op, nasa_toLustre.lustreAst.UnaryExpr.NEG))
                % - - x => x, not not b => b
                new_obj = new_expr.expr;
            else
                new_obj = nasa_toLustre.lustreAst.UnaryExpr(obj.op, new_expr, obj.withPar);
            end
        end
        %% nbOccuranceVar
        function nb_occ = nbOccuranceVar(obj, var)
            nb_occ = obj.expr.nbOccuranceVar(var);
        end
        %% substituteVars
        function obj = substituteVars(obj, var, newVar)
            new_expr = obj.expr.substituteVars(var, newVar);
            new_obj = nasa_toLustre.lustreAst.UnaryExpr(obj.op, new_expr, obj.withPar);
        end
        %% This function is used in substitute vars in LustreNode
        function all_obj = getAllLustreExpr(obj)
            all_obj = [{obj.expr}; obj.expr.getAllLustreExpr()];
        end
        
        %% This functions are used for ForIterator block
        function [new_obj, varIds] = changePre2Var(obj)
            import nasa_toLustre.lustreAst.*
            v = obj.expr;
            if isequal(obj.op, nasa_toLustre.lustreAst.UnaryExpr.PRE) && isa(v, 'VarIdExpr')
                varIds{1} = v;
                new_obj = nasa_toLustre.lustreAst.VarIdExpr(strcat('_pre_', v.getId()));
            else
                [new_expr, varIds] = v.changePre2Var();
                new_obj = nasa_toLustre.lustreAst.UnaryExpr(obj.op, new_expr, obj.withPar);
            end
        end
        function new_obj = changeArrowExp(obj, cond)
            new_expr = obj.expr.changeArrowExp(cond);
            new_obj = nasa_toLustre.lustreAst.UnaryExpr(obj.op, new_expr, obj.withPar);
        end
        %% This function is used by Stateflow function SF_To_LustreNode.getPseudoLusAction
        function varIds = GetVarIds(obj)
            varIds = obj.expr.GetVarIds();
        end
        % This function is used in Stateflow compiler to change from imperative
        % code to Lustre
        function [new_obj, outputs_map] = pseudoCode2Lustre(obj, outputs_map, isLeft)
            %UnaryExpr is always on the right of an Equation
            [new_expr, ~] = obj.expr.pseudoCode2Lustre(outputs_map, false);
            new_obj = nasa_toLustre.lustreAst.UnaryExpr(obj.op,...
                new_expr,...
                obj.withPar);
        end
        %% This function is used by KIND2 LustreProgram.print()
        function nodesCalled = getNodesCalled(obj)
            nodesCalled = {};
            function addNodes(objects)
                nodesCalled = [nodesCalled, objects.getNodesCalled()];
            end
            addNodes(obj.expr);
        end
        
        
        
        %%
        function code = print(obj, backend)
            %TODO: check if LUSTREC syntax is OK for the other backends.
            code = obj.print_lustrec(backend);
        end
        
        function code = print_lustrec(obj, backend) 
            if obj.withPar
                code = sprintf('(%s %s)', ...
                    obj.op, ...
                    obj.expr.print(backend));
            else
                code = sprintf('%s %s', ...
                    obj.op, ...
                    obj.expr.print(backend));
            end
        end
        
        function code = print_kind2(obj)
            code = obj.print_lustrec(LusBackendType.KIND2);
        end
        function code = print_zustre(obj)
            code = obj.print_lustrec(LusBackendType.ZUSTRE);
        end
        function code = print_jkind(obj)
            code = obj.print_lustrec(LusBackendType.JKIND);
        end
        function code = print_prelude(obj)
            code = obj.print_lustrec(LusBackendType.PRELUDE);
        end
    end
    
end

