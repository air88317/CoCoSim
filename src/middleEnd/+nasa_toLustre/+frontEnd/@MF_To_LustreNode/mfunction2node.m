function [main_node, external_nodes, external_libraries ] = ...
        mfunction2node(parent,  blk,  xml_trace, lus_backend, coco_backend, main_sampleTime, varargin)
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    external_nodes = {};
    external_libraries = {};
    % get Matlab Function parameters
    is_main_node = false;
    isEnableORAction = false;
    isEnableAndTrigger = false;
    isContractBlk = false;
    isMatlabFunction = true;
    blk = MF_To_LustreNode.creatInportsOutports(blk);
    [node_name, node_inputs, node_outputs,...
        ~, ~] = ...
        nasa_toLustre.utils.SLX2LusUtils.extractNodeHeader(parent, blk, is_main_node,...
        isEnableORAction, isEnableAndTrigger, isContractBlk, isMatlabFunction, ...
        main_sampleTime, xml_trace);
    %script = blk.Script;
    comment = LustreComment(...
        sprintf('Original block name: %s', blk.Origin_path), true);
    main_node = LustreNode(...
        comment, ...
        node_name,...
        node_inputs, ...
        node_outputs, ...
        {}, ...
        {}, ...
        {}, ...
        false);
    main_node.setIsImported(true);
    
end