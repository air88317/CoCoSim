function [node, external_nodes_i, opens, abstractedNodes] = get__AND_Bitwise_Signed_32(varargin)
    [node, external_nodes_i, opens, abstractedNodes] = nasa_toLustre.utils.LustMathLib.getBitwiseSigned('AND', 32);
end