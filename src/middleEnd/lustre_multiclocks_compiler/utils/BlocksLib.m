classdef BlocksLib
    %BlocksLib This class is a set of Simulink blocks as Lustre libraries.
    
    properties
    end
    
    methods(Static)
        
        function [node, external_nodes_i, opens] = template(varargin)
            opens = {};
            external_nodes_i = {};
            node = '';
        end
        
    end
    
end

