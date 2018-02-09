classdef Kind2Utils
    %KIND2UTILS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods(Static = true)
         %% run compositional modular verification usin Kind2
        function [valid, IN_struct, time_max] = run_Kind2(...
                verif_lus_path,...
                output_dir,...
                node, ...
                KIND2, Z3, OPTS)
            
            IN_struct = [];
            time_max = 0;
            valid = -1;
            if nargin < 1
                error('Missing arguments to function call: LustrecUtils.run_Kind2')
            end
            if ~exist('OPTS', 'var')
                OPTS = '';
            end
            if nargin < 3  
                OPTS = [OPTS ' --modular true'];
            else
                if isempty(node)
                    OPTS = [OPTS '--modular true'];
                else
                    OPTS = sprintf('%s --lus_main %s', OPTS, node);
                end
            end
            if nargin < 4
                tools_config;
            end
            [file_dir, file_name, ~] = fileparts(verif_lus_path);
            if nargin < 2 || isempty(output_dir)
                output_dir = file_dir;
            end
            
            timeout = '200';
            PWD = pwd;
            cd(output_dir);
            
            command = sprintf('%s -xml  --z3_bin %s --timeout %s %s "%s"',...
                KIND2, Z3, timeout, OPTS,  verif_lus_path);
            display_msg(['KIND2_COMMAND ' command],...
                MsgType.DEBUG, 'Kind2Utils.run_verif', '');
            
            [~, solver_output] = system(command );
            display_msg(...
                solver_output,...
                MsgType.DEBUG,...
                'Kind2Utils.run_verif',...
                '');
            [valid, IN_struct] = ...
                Kind2Utils.extract_Kind2_Comp_Verif_answer(...
                solver_output,...
                file_name,  output_dir);
            
            cd(PWD);
            
        end
        function [valid, IN_struct] = extract_Kind2_Comp_Verif_answer(...
                solver_output, ...
                file_name, ...
                output_dir)
            valid = -1;
            IN_struct = [];
            if isempty(solver_output)
                return
            end
            solver_output = regexprep(solver_output, '<AnalysisStart ([^/]+)/>','<Analysis $1>');
            solver_output = regexprep(solver_output, 'concrete="[^"]+"','');
            solver_output = strrep(solver_output, '<AnalysisStop/>','</Analysis>');
            solver_output = regexprep(solver_output, '<Log class="note" [^/]+/Log>','');
            solver_output = regexprep(solver_output, '<Log class="warn" [^/]+/Log>','');
            solver_output = regexprep(solver_output, '\n\s*\n','\n');
            
            tmp_file = fullfile(...
                output_dir, ...
                strcat(file_name, '.kind2.xml'));
            i = 1;
            while exist(tmp_file, 'file')
                tmp_file = fullfile(...
                    output_dir, ...
                    strcat(file_name, '.kind2.', num2str(i), '.xml'));
                i = i +1;
            end
            fid = fopen(tmp_file, 'w');
            if fid == -1
                display_msg(['Couldn''t create file ' tmp_file],...
                    MsgType.ERROR, 'Kind2Utils.extract_answer', '');
                return;
            end
            fprintf(fid, solver_output);
            fclose(fid);
            if strfind(solver_output,'Wallclock timeout')
                msg = sprintf('Solver Result reached TIMEOUT. Check %s', ...
                    tmp_file);
                display_msg(msg, Constants.RESULT, 'Kind2Utils.extract_answer', '');
                return;
            end
            
            
            try
                xDoc = xmlread(tmp_file);
            catch
                msg = sprintf('Can not read file %s', ...
                    tmp_file);
                display_msg(msg, Constants.RESULT, 'Kind2Utils.extract_answer', '');
                return
            end
            xAnalysis = xDoc.getElementsByTagName('Analysis');
            nbSafe = 0;
            nbUnsafe = 0;
            for idx_analys=0:xAnalysis.getLength-1
                node_name = char(xAnalysis.item(idx_analys).getAttribute('top'));
                xProperties = xAnalysis.item(idx_analys).getElementsByTagName('Property');
                for idx_prop=0:xProperties.getLength-1
                    property = xProperties.item(idx_prop);
                    prop_name = char(xProperties.item(idx_prop).getAttribute('name'));
                    try
                        answer = ...
                            property.getElementsByTagName('Answer').item(0).getTextContent;
                    catch
                        answer = 'ERROR';
                    end
                    
                    if strcmp(answer, 'valid')
                        answer = 'SAFE';
                        if valid == -1; valid = 1; end
                    elseif strcmp(answer, 'falsifiable')
                        answer = 'UNSAFE';
                        valid = 0;
                    end
                    
                    if strcmp(answer, 'UNSAFE')
                        
                        xml_cex = property.getElementsByTagName('CounterExample');
                        if xml_cex.getLength > 0
                            CEX_XML = xml_cex;
                            [IN_struct_i, ~] =...
                                Kind2Utils.Kind2CEXTostruct(CEX_XML, node_name);
                            IN_struct = [IN_struct, IN_struct_i];
                        else
                            msg = sprintf('Could not parse counter example for node %s and property %s from %s', ...
                                node_name, prop_name, solver_output);
                            display_msg(msg, Constants.ERROR, 'Property Checking', '');
                        end
                        nbUnsafe = nbUnsafe + 1;
                    end
                    if strcmp(answer, 'SAFE')
                        nbSafe = nbSafe + 1;
                    end
                    msg = sprintf('Solver Result for node %s of property %s is %s', ...
                        node_name, prop_name, answer);
                    display_msg(msg, Constants.RESULT, 'Kind2Utils.extract_answer', '');
                end
            end
            msg = sprintf('Numer of properties SAFE are %d', ...
                nbSafe);
            display_msg(msg, Constants.RESULT, 'Kind2Utils.extract_answer', '');
            msg = sprintf('Numer of properties UNSAFE are %d', ...
                nbUnsafe);
            display_msg(msg, Constants.RESULT, 'Kind2Utils.extract_answer', '');
        end
        
        function [IN_struct, time_max] = Kind2CEXTostruct(...
                cex_xml, ...
                node_name)
            IN_struct = [];
            time_max = 0;
            nodes = cex_xml.item(0).getElementsByTagName('Node');
            node = [];
            for idx=0:(nodes.getLength-1)
                if strcmp(nodes.item(idx).getAttribute('name'), node_name)
                    node = nodes.item(idx);
                    break;
                end
            end
            if isempty(node)
                return;
            end
            IN_struct.node_name = node_name;
            streams = node.getElementsByTagName('Stream');
            node_streams = {};
            for i=0:(streams.getLength-1)
                if strcmp(streams.item(i).getParentNode.getAttribute('name'),...
                        node_name) && ...
                        strcmp(streams.item(i).getAttribute('class'),...
                        'input')
                    node_streams{numel(node_streams) + 1} = streams.item(i);
                end
            end
            for i=1:numel(node_streams)
                s_name = char(node_streams{i}.getAttribute('name'));
                s_dt =  char(LusValidateUtils.get_slx_dt(node_streams{i}.getAttribute('type')));
                
                IN_struct.signals(i).name = s_name;
                IN_struct.signals(i).datatype = s_dt;
                
                %TODO parse the type and extract dimension
                IN_struct.signals(i).dimensions =  1;
                
                [values, time_step] =...
                    LustrecUtils.extract_values(...
                    node_streams{i}, s_dt);
                IN_struct.signals(i).values = values';
                time_max = max(time_max, time_step);
            end
            min = -100; max_v = 100;
            for i=1:numel(IN_struct.signals)
                if numel(IN_struct.signals(i).values) < time_max + 1
                    nb_steps = time_max +1 - numel(IN_struct.signals(i).values);
                    dim = IN_struct.signals(i).dimensions;
                    if strcmp(...
                            LusValidateUtils.get_lustre_dt(IN_struct.signals(i).datatype),...
                            'bool')
                        values = ...
                            LusValidateUtils.construct_random_booleans(...
                            nb_steps, min, max_v, dim);
                    elseif strcmp(...
                            LusValidateUtils.get_lustre_dt(IN_struct.signals(i).datatype),...
                            'int')
                        values = ...
                            LusValidateUtils.construct_random_integers(...
                            nb_steps, min, max_v, IN_struct.signals(i).datatype, dim);
                    elseif strcmp(...
                            IN_struct.signals(i).datatype,...
                            'single')
                        values = ...
                            single(...
                            LusValidateUtils.construct_random_doubles(...
                            nb_steps, min, max_v, dim));
                    else
                        values = ...
                            LusValidateUtils.construct_random_doubles(...
                            nb_steps, min, max_v, dim);
                    end
                    IN_struct.signals(i).values =...
                        [IN_struct.signals(i).values, values];
                end
            end
            IN_struct.time = (0:1:time_max)';
        end
    end
    
end

