
function contractBody = getContractBody(blkParams,inputs,outputs)
    L = nasa_toLustre.ToLustreImport.L;
    import(L{:})
    contractBody = {};
    % y is bounded when there is no extrapolation
    if blkParams.yIsBounded
        contractBody{end+1} = ContractGuaranteeExpr('', ...
            BinaryExpr(BinaryExpr.AND, ...
                       BinaryExpr(BinaryExpr.GTE, ...
                                    outputs{1},...
                                    RealExpr(blkParams.tableMin)), ...
                        BinaryExpr(BinaryExpr.LTE, ...
                                    outputs{1},...
                                    RealExpr(blkParams.tableMax))));
        %sprintf('guarantee  %s >= %.15f and %s <= %.15f;',outputs{1},blkParams.tableMin, outputs{1},blkParams.tableMax);
    else
        % if u is inside boundary polytop, then y is also
        % bounded by table min and max
        %code = {};
        terms = cell(1,2*numel(inputs));
        counter = 0;
        for i=1:numel(inputs)
            counter = counter + 1;
            terms{counter} = BinaryExpr(BinaryExpr.GTE, ...
                                    inputs{i}{1},...
                                    RealExpr(min(blkParams.BreakpointsForDimension{i})));
            counter = counter + 1;
            terms{counter} = BinaryExpr(BinaryExpr.LTE, ...
                                    inputs{i}{1},...
                                    RealExpr(max(blkParams.BreakpointsForDimension{i})));
            % code{end + 1} = sprintf('%s >= %.15f',inputs{i}{1},min(blkParams.BreakpointsForDimension{i}));
            % code{end + 1} = sprintf('%s <= %.15f',inputs{i}{1},max(blkParams.BreakpointsForDimension{i}));
        end
        %P = MatlabUtils.strjoin(code, ' and ');
        P = BinaryExpr.BinaryMultiArgs(BinaryExpr.AND,terms);
        %Q = sprintf('%s >= %.15f and  %s <= %.15f', outputs{1},blkParams.tableMin, outputs{1},blkParams.tableMax);
        Q = BinaryExpr(BinaryExpr.AND,...
                       BinaryExpr(BinaryExpr.GTE, ...
                                  outputs{1},...
                                  RealExpr(blkParams.tableMin)),...
                       BinaryExpr(BinaryExpr.LTE, ...
                                  outputs{1},...
                                  RealExpr(blkParams.tableMax)));
        contractBody{end+1} = ContractGuaranteeExpr('', ...
            BinaryExpr(BinaryExpr.IMPLIES,...
                       P,...
                       Q));
        %sprintf('guarantee %s => %s;', P, Q);       check to see
                                                   % if using BinaryExpr.AND for "=>" is correct
    end

    % contract for each element in total mesh
    if blkParams.NumberOfTableDimensions == 1
        for i=1:numel(blkParams.BreakpointsForDimension{1})-1
            curTable = [];
            curTable(1) = blkParams.Table(1,i);
            curTable(2) = blkParams.Table(1,i+1);
            P = BinaryExpr(BinaryExpr.AND,...
                           BinaryExpr(BinaryExpr.GTE, ...
                                  inputs{1},...
                                  RealExpr(blkParams.BreakpointsForDimension{1}(i))),...
                           BinaryExpr(BinaryExpr.LTE, ...
                                  inputs{1},...
                                  RealExpr(blkParams.BreakpointsForDimension{1}(i+1))));
            Q = BinaryExpr(BinaryExpr.AND,...
                           BinaryExpr(BinaryExpr.GTE, ...
                                  outputs{1},...
                                  RealExpr(min(curTable))),...
                           BinaryExpr(BinaryExpr.LTE, ...
                                  outputs{1},...
                                  RealExpr(max(curTable))));
            % code{end + 1} = sprintf('%s >= %.15f and %s <= %.15f',inputs{j}{1},blkParams.BreakpointsForDimension{1}(i),inputs{j}{1},blkParams.BreakpointsForDimension{1}(i+1));
            %Q = sprintf('%s >= %.15f and  %s <= %.15f', outputs{1},min(curTable), outputs{1},max(curTable));
            contractBody{end+1} = ContractGuaranteeExpr('', ...
                BinaryExpr(BinaryExpr.IMPLIES,...
                           P,...
                           Q));
            %contractBody{end+1} = sprintf('guarantee %s => %s;', P, Q);
        end
    elseif blkParams.NumberOfTableDimensions == 2
        for i=1:numel(blkParams.BreakpointsForDimension{1})-1
            for j=1:numel(blkParams.BreakpointsForDimension{2})-1
                curTable = [];
                curTable(1) = blkParams.Table(i,j);
                curTable(2) = blkParams.Table(i,j+1);
                curTable(3) = blkParams.Table(i+1,j);
                curTable(4) = blkParams.Table(i+1,j+1);     
                P1_1 = BinaryExpr(BinaryExpr.GTE, ...
                                  inputs{1}{1},...
                                  RealExpr(blkParams.BreakpointsForDimension{1}(i)));   % dim 1 lower
                P1_2 =   BinaryExpr(BinaryExpr.LTE, ...
                                    inputs{1}{1},...
                                    RealExpr(blkParams.BreakpointsForDimension{1}(i+1)));   % dim 1 upper                 
                P2_1 = BinaryExpr(BinaryExpr.GTE, ...
                                  inputs{2}{1},...
                                  RealExpr(blkParams.BreakpointsForDimension{2}(j))); % dim 2 lower
                P2_2 = BinaryExpr(BinaryExpr.LTE, ...
                                  inputs{2}{1},...
                                  RealExpr(blkParams.BreakpointsForDimension{2}(j+1)));   %dim 2 upper                      

                %code{end + 1} = sprintf('%s >= %.15f and %s <= %.15f',inputs{1}{1},blkParams.BreakpointsForDimension{1}(i),inputs{1}{1},blkParams.BreakpointsForDimension{1}(i+1));
                %code{end + 1} = sprintf('%s >= %.15f and %s <= %.15f',inputs{2}{1},blkParams.BreakpointsForDimension{2}(j),inputs{2}{1},blkParams.BreakpointsForDimension{2}(j+1));
                P = BinaryExpr.BinaryMultiArgs(BinaryExpr.AND,{P1_1, P1_2, P2_1, P2_2});
                Q = BinaryExpr(BinaryExpr.AND,...
                               BinaryExpr(BinaryExpr.GTE, ...
                                      outputs{1},...
                                      RealExpr(min(curTable))),...
                               BinaryExpr(BinaryExpr.LTE, ...
                                      outputs{1},...
                                      RealExpr(max(curTable))));
                %Q = sprintf('%s >= %.15f and  %s <= %.15f', outputs{1},min(curTable), outputs{1},max(curTable));
                contractBody{end+1} = ContractGuaranteeExpr('', ...
                    BinaryExpr(BinaryExpr.IMPLIES,...
                               P,...
                               Q));
                %contractBody{end+1} = sprintf('guarantee %s => %s;', P, Q);
            end
        end
    elseif blkParams.NumberOfTableDimensions == 3
        curTable = [];
        terms = {};
        for i=1:numel(blkParams.BreakpointsForDimension{1})-1
            for j=1:numel(blkParams.BreakpointsForDimension{2})-1
                for k=1:numel(blkParams.BreakpointsForDimension{3})-1
                    curTable = [];
                    curTable(1) = blkParams.Table(i,j,k);
                    curTable(2) = blkParams.Table(i,j+1,k);
                    curTable(3) = blkParams.Table(i+1,j,k);
                    curTable(4) = blkParams.Table(i+1,j+1,k);
                    curTable(5) = blkParams.Table(i,j,k+1);
                    curTable(6) = blkParams.Table(i,j+1,k+1);
                    curTable(7) = blkParams.Table(i+1,j,k+1);
                    curTable(8) = blkParams.Table(i+1,j+1,k+1);                            

                    P1_1 = BinaryExpr(BinaryExpr.GTE, ...
                        inputs{1}{1},...
                        RealExpr(blkParams.BreakpointsForDimension{1}(i)));   % dim 1 lower
                    P1_2 =   BinaryExpr(BinaryExpr.LTE, ...
                        inputs{1}{1},...
                        RealExpr(blkParams.BreakpointsForDimension{1}(i+1)));   % dim 1 upper
                    P2_1 = BinaryExpr(BinaryExpr.GTE, ...
                        inputs{2}{1},...
                        RealExpr(blkParams.BreakpointsForDimension{2}(j))); % dim 2 lower
                    P2_2 = BinaryExpr(BinaryExpr.LTE, ...
                        inputs{2}{1},...
                        RealExpr(blkParams.BreakpointsForDimension{2}(j+1)));   %dim 2 upper
                    P3_1 = BinaryExpr(BinaryExpr.GTE, ...
                        inputs{3}{1},...
                        RealExpr(blkParams.BreakpointsForDimension{3}(k))); % dim 3 lower
                    P3_2 = BinaryExpr(BinaryExpr.LTE, ...
                        inputs{3}{1},...
                        RealExpr(blkParams.BreakpointsForDimension{3}(k+1)));   %dim 3 upper                            

                    P = BinaryExpr.BinaryMultiArgs(BinaryExpr.AND,{P1_1, P1_2, P2_1, P2_2, P3_1, P3_2});
                    Q = BinaryExpr(BinaryExpr.AND,...
                                    BinaryExpr(BinaryExpr.GTE, ...
                                                outputs{1},...
                                                RealExpr(min(curTable))),...
                                    BinaryExpr(BinaryExpr.LTE, ...
                                                outputs{1},...
                                                RealExpr(max(curTable))));
                    contractBody{end+1} = ContractGuaranteeExpr('', ...
                        BinaryExpr(BinaryExpr.IMPLIES,...
                        P,...
                        Q));
                end
            end
        end                
    else
        display_msg(sprintf('More than 3 dimensions is not supported for contract in block %s',...
            HtmlItem.addOpenCmd(blk.Origin_path)), MsgType.ERROR, 'Lookup_nD_To_Lustre', '');
    end
end

