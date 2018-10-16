classdef Fcn_Exp_Parser
    %Fcn_Exp_Parser generates a tree from a mathematical expression in Fcn
    %Block. Fcn Block in Simulink has limited grammar.

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Copyright (c) 2017 United States Government as represented by the
    % Administrator of the National Aeronautics and Space Administration.
    % All Rights Reserved.
    % Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
    end
    
    methods(Static)
        function [tree, status, unsupportedExp] = parse(exp)
            exp = regexprep(exp, '\s*', '');
            try
                [tree, status, unsupportedExp] = Fcn_Exp_Parser.parseE(exp);
            catch me
                if strcmp(me.identifier, 'COCOSIM:Fcn_Exp_Parser')
                    display_msg(me.message, MsgType.ERROR, 'Fcn_Exp_Parser', '');
                end
                tree = {};
                status = 1;
                unsupportedExp = exp;
            end
        end
        
        %%
        function [tree, status, expr] = parseE(e)
            status = 0;
            [tree, expr] = Fcn_Exp_Parser.parseEA(e);
            if ~isempty(expr)
                status = 1;
            end
        end
        
        %%
        function [tree, expr, isAssignement] = parseEA(expr)
            isAssignement = 0;
            [sym1, expr] = Fcn_Exp_Parser.parseEN(expr);
            [match, expr] = Fcn_Exp_Parser.parsePlus(expr);
            if ~isempty(match)
                %the case of x++
                [match, expr] = Fcn_Exp_Parser.parsePlus(expr);
                if ~isempty(match)
                    %the case of x++
                    if ischar(sym1)
                        %sym1 is an ID
                        tree = {'=', sym1, {'Plus',sym1, '1.0'}};
                        isAssignement = 1;
                    else
                        tree = {'Plus',sym1, '1.0'};
                    end
                else
                    [sym2, expr1, isEQ] = Fcn_Exp_Parser.parseEA(expr);
                    if isEQ
                        ME = MException('COCOSIM:Fcn_Exp_Parser', ...
                            'PARSER ERROR: Assignement is not supported inside an expression in "%s"', ...
                            expr);
                        throw(ME);
                    end
                    expr = expr1;
                    if ~isempty(sym1)
                        tree = {'Plus',sym1,sym2};
                    else
                        tree = {'Plus','0.0',sym2};
                    end
                end
            else
                [match, expr] = Fcn_Exp_Parser.parseMinus(expr);
                if ~isempty(match)
                    [match, expr] = Fcn_Exp_Parser.parseMinus(expr);
                    if ~isempty(match)
                        %the case of x--
                        if ischar(sym1)
                            %sym1 is an ID
                            tree = {'=', sym1, {'Minus',sym1, '1.0'}};
                            isAssignement = 1;
                        else
                            tree = {'Minus',sym1, '1.0'};
                        end
                    else
                        [sym2, expr1, isEQ] = Fcn_Exp_Parser.parseEA(expr);
                        if isEQ
                            ME = MException('COCOSIM:Fcn_Exp_Parser', ...
                                'PARSER ERROR: Assignement is not supported inside an expression in "%s"', ...
                                expr);
                            throw(ME);
                        end
                        expr = expr1;
                        if ~isempty(sym1)
                            tree = {'Minus',sym1,sym2};
                        else
                            tree = {'Minus','0.0',sym2};
                        end
                    end
                else
                    [match, expr] = Fcn_Exp_Parser.parseRO(expr);
                    if ~isempty(match)
                        [sym2, expr1, isEQ] = Fcn_Exp_Parser.parseEA(expr);
                        if isEQ
                            ME = MException('COCOSIM:Fcn_Exp_Parser', ...
                                'PARSER ERROR: Assignement is not supported inside an expression in "%s"', ...
                                expr);
                            throw(ME);
                        end
                        expr = expr1;
                        tree = {match,sym1,sym2};
                    else
                        [match, expr] = Fcn_Exp_Parser.parseEQ(expr);
                        if ~isempty(match)
                            [sym2, expr1, isEQ] = Fcn_Exp_Parser.parseEA(expr);
                            if isEQ
                                ME = MException('COCOSIM:Fcn_Exp_Parser', ...
                                    'PARSER ERROR: Assignement is not supported inside an expression in "%s"', ...
                                    expr);
                                throw(ME);
                            end
                            expr = expr1;
                            tree = {match,sym1,sym2};
                        else
                            tree = sym1;
                        end
                    end
                end
            end
        end
        %% !
        function [tree, expr] = parseEN(expr)
            [match, expr] = Fcn_Exp_Parser.parseNot(expr);
            if ~isempty(match)
                [sym, expr] = Fcn_Exp_Parser.parseEN(expr);
                tree = {'Not',sym};
            else
                [tree, expr] = Fcn_Exp_Parser.parseUnaryMinus(expr);
            end
        end
        
        function [tree, expr] = parseUnaryMinus(expr)
            [match, expr] = Fcn_Exp_Parser.parseMinus(expr);
            if ~isempty(match)
                [sym, expr] = Fcn_Exp_Parser.parseSE(expr);
                sym1 = {'UnaryMinus',sym};
                [tree, expr] = Fcn_Exp_Parser.parseEM2(expr, sym1);
                
            else
                [tree, expr] = Fcn_Exp_Parser.parseEM(expr);
            end
        end
        %% *, /, ^
        function [tree, expr] = parseEM2(expr, sym1)
            [match, expr] = Fcn_Exp_Parser.parseMult(expr);
            if ~isempty(match)
                [sym2, expr1, isEQ] = Fcn_Exp_Parser.parseEA(expr);
                if isEQ
                    ME = MException('COCOSIM:Fcn_Exp_Parser', ...
                        'PARSER ERROR: Assignement is not supported inside an expression in "%s"', ...
                        expr);
                    throw(ME);
                end
                expr = expr1;
                tree = {'Mult',sym1,sym2};
            else
                [match, expr] = Fcn_Exp_Parser.parseDiv(expr);
                if ~isempty(match)
                    [sym2, expr1, isEQ] = Fcn_Exp_Parser.parseEA(expr);
                    if isEQ
                        ME = MException('COCOSIM:Fcn_Exp_Parser', ...
                            'PARSER ERROR: Assignement is not supported inside an expression in "%s"', ...
                            expr);
                        throw(ME);
                    end
                    expr = expr1;
                    tree = {'Div',sym1,sym2};
                else
                    tree = sym1;
                end
            end
        end
        function [tree, expr] = parseEM(expr)
            [sym1, expr] = Fcn_Exp_Parser.parseEP(expr);
            [match, expr] = Fcn_Exp_Parser.parseMult(expr);
            if ~isempty(match)
                [sym2, expr1, isEQ] = Fcn_Exp_Parser.parseEA(expr);
                if isEQ
                    ME = MException('COCOSIM:Fcn_Exp_Parser', ...
                        'PARSER ERROR: Assignement is not supported inside an expression in "%s"', ...
                        expr);
                    throw(ME);
                end
                expr = expr1;
                tree = {'Mult',sym1,sym2};
            else
                [match, expr] = Fcn_Exp_Parser.parseDiv(expr);
                if ~isempty(match)
                    [sym2, expr1, isEQ] = Fcn_Exp_Parser.parseEA(expr);
                    if isEQ
                        ME = MException('COCOSIM:Fcn_Exp_Parser', ...
                            'PARSER ERROR: Assignement is not supported inside an expression in "%s"', ...
                            expr);
                        throw(ME);
                    end
                    expr = expr1;
                    tree = {'Div',sym1,sym2};
                else
                    tree = sym1;
                end
            end
        end
        
        function [tree, expr] = parseEP(expr)
            [sym1, expr] = Fcn_Exp_Parser.parseSE(expr);
            [match, expr] = Fcn_Exp_Parser.parsePow(expr);
            if ~isempty(match)
                [sym2, expr] = Fcn_Exp_Parser.parseEP(expr);
                tree = {'Pow',sym1,sym2};
            else
                tree = sym1;
            end
        end
        
        %% Number, Function call, ()
        function [tree, expr] = parseSE(expr)
            [sym, expr] = Fcn_Exp_Parser.parseNum(expr);
            if isempty(sym)
                [sym, expr] = Fcn_Exp_Parser.parseFunc(expr);
                if isempty(sym)
                    [sym, expr] = Fcn_Exp_Parser.parseVar(expr);
                    if isempty(sym)
                        [tree, expr] = Fcn_Exp_Parser.parsePar(expr);
                    else
                        tree = sym;
                    end
                else
                    tree = sym;
                end
            else
                tree = sym;
            end
        end
        
        
        
        
        %% Elementary Pasers
        %
        function [tree, expr] = parsePar(expr)
            if startsWith(expr, '(')
                expr = regexprep(expr, '^\(', '');
                [sym, expr1, isEQ] = Fcn_Exp_Parser.parseEA(expr);
                if isEQ
                    ME = MException('COCOSIM:Fcn_Exp_Parser', ...
                        'PARSER ERROR: Assignement is not supported inside an expression in "%s"', ...
                        expr);
                    throw(ME);
                end
                expr = expr1;
                expr = regexprep(expr, '^\)', '');
                tree = {'Par', sym};
            else
                tree = '';
            end
        end
        
        function [tree, expr] = parseNum(expr)
            regex = '^-?\+?[0-9]+(\.[0-9]+)?(e-?[0-9]+)?';
            match = regexp(expr, regex, 'match', 'once');
            if ~isempty(match)
                tree = match;
                expr = regexprep(expr, regex, '');
            else
                tree = '';
            end
        end
        
        
        function [tree, expr] = parseFunc(expr)
            regex = '^[A-Za-z0-9]+\(';
            match = regexp(expr, regex, 'match', 'once');
            if ~isempty(match)
                funcname = regexp(expr, '^[A-Za-z0-9]+', 'match', 'once');
                expr = regexprep(expr, regex,'');
                if strcmp(funcname, 'u')
                    [arg, expr1, isEQ] = Fcn_Exp_Parser.parseEA(expr);
                    if isEQ
                        ME = MException('COCOSIM:Fcn_Exp_Parser', ...
                            'PARSER ERROR: Assignement is not supported inside an expression in "%s"', ...
                            expr);
                        throw(ME);
                    end
                    expr = expr1;
                    expr = regexprep(expr, '^(\)|\])','');
                    tree = {'Func',funcname,arg};
                else
                    tree = {'Func', funcname};
                    nbPar = 1;
                    i = 1;
                    args = {};
                    while(nbPar ~= 0)
                        if strcmp(expr(i), '(')
                            nbPar = nbPar + 1;
                            i = i+1;
                        elseif strcmp(expr(i), ')')
                            nbPar = nbPar - 1;
                            if nbPar == 0
                                args{end+1} = expr(1:i-1);
                                expr = expr(i+1:end);
                                i = 1;
                            else
                                i = i+1;
                            end
                        elseif strcmp(expr(i), ',') && nbPar == 1
                            args{end+1} = expr(1:i-1);
                            expr = expr(i+1:end);
                            i = 1;
                        else
                            i = i+1;
                        end
                    end
                    for i=1:numel(args)
                        [argi, ~, isEQ] = Fcn_Exp_Parser.parseEA(args{i});
                        if isEQ
                            ME = MException('COCOSIM:Fcn_Exp_Parser', ...
                                'PARSER ERROR: Assignement is not supported inside an expression in "%s"', ...
                                args{i});
                            throw(ME);
                        end
                        tree = [tree, {argi}];
                    end
                end
            else
                tree = '';
            end
        end
        
        function [tree, expr] = parseVar(expr)
            regex = '^[A-Za-z0-9_]+';
            match = regexp(expr, regex, 'match', 'once');
            if ~isempty(match)
                tree = match;
                expr = regexprep(expr, regex,'');
            else
                tree = '';
            end
        end
        
        function [tree, expr] = parsePlus(expr)
            regex = '^\+';
            match = regexp(expr, regex, 'match', 'once');
            if ~isempty(match)
                tree = match;
                expr = regexprep(expr, regex,'');
            else
                tree = '';
            end
        end
        
        function [tree, expr] = parseMinus(expr)
            regex = '^-';
            match = regexp(expr, regex, 'match', 'once');
            if ~isempty(match)
                tree = match;
                expr = regexprep(expr, regex,'');
            else
                tree = '';
            end
        end
        
        
        function [tree, expr] = parseNot(expr)
            regex = '^(!|~)';
            match = regexp(expr, regex, 'match', 'once');
            if ~isempty(match)
                tree = match;
                expr = regexprep(expr, regex,'');
            else
                tree = '';
            end
        end
        
        function [tree, expr] = parseMult(expr)
            regex = '^\*';
            match = regexp(expr, regex, 'match', 'once');
            if ~isempty(match)
                tree = match;
                expr = regexprep(expr, regex,'');
            else
                tree = '';
            end
        end
        
        function [tree, expr] = parseDiv(expr)
            regex = '^/';
            match = regexp(expr, regex, 'match', 'once');
            if ~isempty(match)
                tree = match;
                expr = regexprep(expr, regex,'');
            else
                tree = '';
            end
        end
        
        function [tree, expr] = parsePow(expr)
            regex =	'^\^';
            match = regexp(expr, regex, 'match', 'once');
            if ~isempty(match)
                tree = match;
                expr = regexprep(expr, regex,'');
            else
                tree = '';
            end
        end
        % > < <= >=, == !=, && ||
        function [tree, expr] = parseRO(expr)
            regex = '^(<=?|>=?|==|!=|~=|&&?|\|\|?)';
            match = regexp(expr, regex, 'match', 'once');
            if ~isempty(match)
                tree = match;
                expr = regexprep(expr, regex,'');
            else
                tree = '';
            end
        end
        % =
        function [tree, expr] = parseEQ(expr)
            regex = '^(=)';
            match = regexp(expr, regex, 'match', 'once');
            if ~isempty(match)
                tree = match;
                expr = regexprep(expr, regex,'');
            else
                tree = '';
            end
        end
    end
end