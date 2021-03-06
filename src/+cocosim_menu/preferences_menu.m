%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Hamza Bourbouh <hamza.bourbouh@nasa.gov>
% Notices:
%
% Copyright @ 2020 United States Government as represented by the 
% Administrator of the National Aeronautics and Space Administration.  All 
% Rights Reserved.
%
% Disclaimers
%
% No Warranty: THE SUBJECT SOFTWARE IS PROVIDED "AS IS" WITHOUT ANY 
% WARRANTY OF ANY KIND, EITHER EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING,
% BUT NOT LIMITED TO, ANY WARRANTY THAT THE SUBJECT SOFTWARE WILL CONFORM 
% TO SPECIFICATIONS, ANY IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS 
% FOR A PARTICULAR PURPOSE, OR FREEDOM FROM INFRINGEMENT, ANY WARRANTY THAT
% THE SUBJECT SOFTWARE WILL BE ERROR FREE, OR ANY WARRANTY THAT 
% DOCUMENTATION, IF PROVIDED, WILL CONFORM TO THE SUBJECT SOFTWARE. THIS 
% AGREEMENT DOES NOT, IN ANY MANNER, CONSTITUTE AN ENDORSEMENT BY 
% GOVERNMENT AGENCY OR ANY PRIOR RECIPIENT OF ANY RESULTS, RESULTING 
% DESIGNS, HARDWARE, SOFTWARE PRODUCTS OR ANY OTHER APPLICATIONS RESULTING 
% FROM USE OF THE SUBJECT SOFTWARE.  FURTHER, GOVERNMENT AGENCY DISCLAIMS 
% ALL WARRANTIES AND LIABILITIES REGARDING THIRD-PARTY SOFTWARE, IF PRESENT 
% IN THE ORIGINAL SOFTWARE, AND DISTRIBUTES IT "AS IS."
%
% Waiver and Indemnity:  RECIPIENT AGREES TO WAIVE ANY AND ALL CLAIMS 
% AGAINST THE UNITED STATES GOVERNMENT, ITS CONTRACTORS AND SUBCONTRACTORS, 
% AS WELL AS ANY PRIOR RECIPIENT.  IF RECIPIENT'S USE OF THE SUBJECT 
% SOFTWARE RESULTS IN ANY LIABILITIES, DEMANDS, DAMAGES, EXPENSES OR 
% LOSSES ARISING FROM SUCH USE, INCLUDING ANY DAMAGES FROM PRODUCTS BASED 
% ON, OR RESULTING FROM, RECIPIENT'S USE OF THE SUBJECT SOFTWARE, RECIPIENT 
% SHALL INDEMNIFY AND HOLD HARMLESS THE UNITED STATES GOVERNMENT, ITS 
% CONTRACTORS AND SUBCONTRACTORS, AS WELL AS ANY PRIOR RECIPIENT, TO THE 
% EXTENT PERMITTED BY LAW.  RECIPIENT'S SOLE REMEDY FOR ANY SUCH MATTER 
% SHALL BE THE IMMEDIATE, UNILATERAL TERMINATION OF THIS AGREEMENT.
% 
% Notice: The accuracy and quality of the results of running CoCoSim 
% directly corresponds to the quality and accuracy of the model and the 
% requirements given as inputs to CoCoSim. If the models and requirements 
% are incorrectly captured or incorrectly input into CoCoSim, the results 
% cannot be relied upon to generate or error check software being developed. 
% Simply stated, the results of CoCoSim are only as good as
% the inputs given to CoCoSim.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function schema = preferences_menu(callbackInfo)
    %preferences_menu Define the preferences menu function.
    
    schema = sl_container_schema;
    schema.label = 'Preferences';
    schema.statustip = 'Preferences';
    schema.autoDisableWhen = 'Busy';
    
    CoCoSimPreferences = cocosim_menu.CoCoSimPreferences.load();
    
    schema.childrenFcns = {...
        {@getLustreCompiler, CoCoSimPreferences}, ...
        {@getNASACompilerPreferences, CoCoSimPreferences}, ...
        {@getNASACompilerAbstractions, CoCoSimPreferences}, ...
        {@getLustreBackend, CoCoSimPreferences}, ...
        {@getKind2Options, CoCoSimPreferences}, ...
        {@getLustrecBinary, CoCoSimPreferences}, ...
        {@PreferencesMenu.getVerificationTimeout, CoCoSimPreferences}, ...
        {@getDEDChecks, CoCoSimPreferences}, ...
        {@getVerbose, CoCoSimPreferences}, ...
        {@resetSettings, CoCoSimPreferences} ...
        };
end

%% Lustre compiler
function schema = getLustreCompiler(callbackInfo)
    schema = sl_container_schema;
    schema.label = 'Simulink To Lustre compiler';
    schema.statustip = 'Lustre compiler';
    schema.autoDisableWhen = 'Busy';
    CoCoSimPreferences = callbackInfo.userdata;
    compilerNames = {'NASA Compiler', 'IOWA Compiler'};
    callbacks = cell(1, length(compilerNames));
    for i=1:length(compilerNames)
        callbacks{i} = @(x) lustreCompilerCallback(compilerNames{i}, i, ...
            CoCoSimPreferences, x);
    end
    schema.childrenFcns = callbacks;
end

function schema = lustreCompilerCallback(compilerName, compilerIndex, CoCoSimPreferences, varargin)
    schema = sl_toggle_schema;
    schema.label = compilerName;
    compilerNameValues = {'NASA', 'IOWA'};
    if strcmp(CoCoSimPreferences.lustreCompiler, compilerNameValues{compilerIndex})
        schema.checked = 'checked';
    else
        schema.checked = 'unchecked';
    end
    schema.callback = @(x) setCompilerOption(compilerNameValues{compilerIndex}, ...
        CoCoSimPreferences, x);
end

function setCompilerOption(compilerNameValue, CoCoSimPreferences, varargin)
    CoCoSimPreferences.lustreCompiler = compilerNameValue;
    CoCoSimPreferences.irToLustreCompiler = strcmp(compilerNameValue, 'IOWA');
    cocosim_menu.CoCoSimPreferences.save(CoCoSimPreferences);
end

%% NASA Compiler preferences
function schema = getNASACompilerPreferences(callbackInfo)
    schema = sl_container_schema;
    schema.label = 'NASA compiler preferences';
    schema.statustip = 'NASA compiler preferences';
    schema.autoDisableWhen = 'Busy';
    CoCoSimPreferences = callbackInfo.userdata;
    schema.childrenFcns = {...
        {@getSkip_unsupportedblocks, CoCoSimPreferences},...
        {@getSkip_pp, CoCoSimPreferences},...
        {@getSkip_defected_pp, CoCoSimPreferences},...
        {@getSkip_optim, CoCoSimPreferences},...
        {@getForceCodeGen, CoCoSimPreferences},...
        {@getSkip_sf_actions_check, CoCoSimPreferences}...
        };
end


% skip_unsupportedblocks
function schema = getSkip_unsupportedblocks(callbackInfo)
    schema = sl_toggle_schema;
    schema.label = 'Skip compatibility check.';
    CoCoSimPreferences = callbackInfo.userdata;
    schema.checked = 'checked';
    if ~CoCoSimPreferences.skip_unsupportedblocks
        schema.checked = 'unchecked';
    end
    schema.callback = @skip_unsupportedblocks;
    schema.userdata = CoCoSimPreferences;
end
function skip_unsupportedblocks(callbackInfo)
    CoCoSimPreferences = callbackInfo.userdata;
    CoCoSimPreferences.skip_unsupportedblocks = ~ CoCoSimPreferences.skip_unsupportedblocks;
    cocosim_menu.CoCoSimPreferences.save(CoCoSimPreferences);
end




%getSkip_pp
function schema = getSkip_pp(callbackInfo)
    schema = sl_toggle_schema;
    schema.label = 'Skip pre-processing (not recommended).';
    CoCoSimPreferences = callbackInfo.userdata;
    schema.checked = 'checked';
    if ~CoCoSimPreferences.skip_pp
        schema.checked = 'unchecked';
    end
    if ~NASAPPUtils.isAlreadyPP(bdroot(gcs))
        schema.state = 'disabled';
    end
    schema.callback = @skip_pp;
    schema.userdata = CoCoSimPreferences;
end
function skip_pp(callbackInfo)
    CoCoSimPreferences = callbackInfo.userdata;
    CoCoSimPreferences.skip_pp = ~ CoCoSimPreferences.skip_pp;
    cocosim_menu.CoCoSimPreferences.save(CoCoSimPreferences);
end
%getSkip_defected_pp
function schema = getSkip_defected_pp(callbackInfo)
    schema = sl_toggle_schema;
    schema.label = 'Skip defected pre-processing blocks (recommended).';
    CoCoSimPreferences = callbackInfo.userdata;
    schema.checked = 'checked';
    if ~CoCoSimPreferences.skip_defected_pp
        schema.checked = 'unchecked';
    end
    schema.callback = @skip_defected_pp;
    schema.userdata = CoCoSimPreferences;
end
function skip_defected_pp(callbackInfo)
    CoCoSimPreferences = callbackInfo.userdata;
    CoCoSimPreferences.skip_defected_pp = ~ CoCoSimPreferences.skip_defected_pp;
    cocosim_menu.CoCoSimPreferences.save(CoCoSimPreferences);
end
%getSkip_optim
function schema = getSkip_optim(callbackInfo)
    schema = sl_toggle_schema;
    schema.label = 'Skip Lustre code optimization';
    CoCoSimPreferences = callbackInfo.userdata;
    schema.checked = 'checked';
    if ~CoCoSimPreferences.skip_optim
        schema.checked = 'unchecked';
    end
    schema.callback = @skip_optim;
    schema.userdata = CoCoSimPreferences;
end
function skip_optim(callbackInfo)
    CoCoSimPreferences = callbackInfo.userdata;
    CoCoSimPreferences.skip_optim = ~ CoCoSimPreferences.skip_optim;
    cocosim_menu.CoCoSimPreferences.save(CoCoSimPreferences);
end
%getForceCodeGen
function schema = getForceCodeGen(callbackInfo)
    schema = sl_toggle_schema;
    schema.label = 'Force Lustre code Generation (i.e., ignore errors).';
    CoCoSimPreferences = callbackInfo.userdata;
    schema.checked = 'checked';
    if ~CoCoSimPreferences.forceCodeGen
        schema.checked = 'unchecked';
    end
    schema.callback = @forceCodeGen;
    schema.userdata = CoCoSimPreferences;
end
function forceCodeGen(callbackInfo)
    CoCoSimPreferences = callbackInfo.userdata;
    CoCoSimPreferences.forceCodeGen = ~ CoCoSimPreferences.forceCodeGen;
    cocosim_menu.CoCoSimPreferences.save(CoCoSimPreferences);
end
%getSkip_sf_actions_check
function schema = getSkip_sf_actions_check(callbackInfo)
    schema = sl_toggle_schema;
    schema.label = 'Skip Stateflow parser check (not recommended).';
    CoCoSimPreferences = callbackInfo.userdata;
    schema.checked = 'checked';
    if ~CoCoSimPreferences.skip_sf_actions_check
        schema.checked = 'unchecked';
    end
    schema.callback = @skip_sf_actions_check;
    schema.userdata = CoCoSimPreferences;
end
function skip_sf_actions_check(callbackInfo)
    CoCoSimPreferences = callbackInfo.userdata;
    CoCoSimPreferences.skip_sf_actions_check = ~ CoCoSimPreferences.skip_sf_actions_check;
    cocosim_menu.CoCoSimPreferences.save(CoCoSimPreferences);
end

%% NASA Compiler abstractions
function schema = getNASACompilerAbstractions(callbackInfo)
    schema = sl_container_schema;
    schema.label = 'NASA compiler abstractions';
    schema.statustip = 'NASA compiler abstractions';
    schema.autoDisableWhen = 'Busy';
    CoCoSimPreferences = callbackInfo.userdata;
    schema.childrenFcns = {...
        {@getForceTypecastingOfInt, CoCoSimPreferences},...
        {@useMorePreciseAbstraction, CoCoSimPreferences},...
        {@getAbstract_unsupported_blocks_forverification, CoCoSimPreferences}, ...
        {@getAbstract_lookuptables_forverification, CoCoSimPreferences} ...
        };
end
%forceTypeCastingOfInt
function schema = getForceTypecastingOfInt(callbackInfo)
    schema = sl_toggle_schema;
    schema.label = 'Abstract Integer machine types (int8, int16..) by Z ([-oo, +oo]).';
    CoCoSimPreferences = callbackInfo.userdata;
    schema.checked = 'checked';
    if CoCoSimPreferences.forceTypeCastingOfInt
        schema.checked = 'unchecked';
    end
    schema.callback = @forceTypecastingOfInt;
    schema.userdata = CoCoSimPreferences;
end
function forceTypecastingOfInt(callbackInfo)
    CoCoSimPreferences = callbackInfo.userdata;
    CoCoSimPreferences.forceTypeCastingOfInt = ~ CoCoSimPreferences.forceTypeCastingOfInt;
    cocosim_menu.CoCoSimPreferences.save(CoCoSimPreferences);
end

%useMorePreciseAbstraction
function schema = useMorePreciseAbstraction(callbackInfo)
    schema = sl_toggle_schema;
    schema.label = 'Use more precise abstraction for mathematical functions (sqrt, cos, ...).';
    CoCoSimPreferences = callbackInfo.userdata;
    schema.checked = 'checked';
    if ~CoCoSimPreferences.use_more_precise_abstraction
        schema.checked = 'unchecked';
    end
    schema.callback = @useMorePreciseAbstractionCallback;
    schema.userdata = CoCoSimPreferences;
end
function useMorePreciseAbstractionCallback(callbackInfo)
    CoCoSimPreferences = callbackInfo.userdata;
    CoCoSimPreferences.use_more_precise_abstraction = ~ CoCoSimPreferences.use_more_precise_abstraction;
    cocosim_menu.CoCoSimPreferences.save(CoCoSimPreferences);
end

%getAbstract_unsupported_blocks_forverification
function schema = getAbstract_unsupported_blocks_forverification(callbackInfo)
    schema = sl_toggle_schema;
    schema.label = 'Abstract unsupported blocks for verification (Kind2).';
    CoCoSimPreferences = callbackInfo.userdata;
    schema.checked = 'checked';
    if ~CoCoSimPreferences.abstract_unsupported_blocks
        schema.checked = 'unchecked';
    end
    schema.callback = @abstract_unsupported_blocks_forverification;
    schema.userdata = CoCoSimPreferences;
end
function abstract_unsupported_blocks_forverification(callbackInfo)
    CoCoSimPreferences = callbackInfo.userdata;
    CoCoSimPreferences.abstract_unsupported_blocks = ~ CoCoSimPreferences.abstract_unsupported_blocks;
    cocosim_menu.CoCoSimPreferences.save(CoCoSimPreferences);
end

%getAbstract_lookuptables_forverification
function schema = getAbstract_lookuptables_forverification(callbackInfo)
    schema = sl_toggle_schema;
    schema.label = 'Abstract Lookup Table blocks for verification using breakpoints/table.';
    CoCoSimPreferences = callbackInfo.userdata;
    schema.checked = 'checked';
    if ~CoCoSimPreferences.abstract_lookuptables
        schema.checked = 'unchecked';
    end
    schema.callback = @abstract_lookuptables_forverification;
    schema.userdata = CoCoSimPreferences;
end
function abstract_lookuptables_forverification(callbackInfo)
    CoCoSimPreferences = callbackInfo.userdata;
    CoCoSimPreferences.abstract_lookuptables = ~ CoCoSimPreferences.abstract_lookuptables;
    cocosim_menu.CoCoSimPreferences.save(CoCoSimPreferences);
end

%% Lustre Backend
function schema = getLustreBackend(callbackInfo)
    schema = sl_container_schema;
    schema.label = 'Verification Backend';
    schema.statustip = 'Lustre backend';
    schema.autoDisableWhen = 'Busy';
    CoCoSimPreferences = callbackInfo.userdata;
    
    backendNames = {coco_nasa_utils.LusBackendType.KIND2, coco_nasa_utils.LusBackendType.JKIND, ...
        coco_nasa_utils.LusBackendType.ZUSTRE};
    callbacks = cell(1, length(backendNames));
    for i=1:length(backendNames)
        callbacks{i} = @(x) lustreBackendCallback(backendNames{i}, ...
            CoCoSimPreferences, x);
    end
    schema.childrenFcns = callbacks;
end

function schema = lustreBackendCallback(backendName, CoCoSimPreferences, varargin)
    schema = sl_toggle_schema;
    schema.label = backendName;
    if ~strcmp(backendName, coco_nasa_utils.LusBackendType.KIND2)
        schema.state = 'Disabled';
        schema.label = strcat(backendName, ' (Currently unsupported)');
    else
        schema.label = backendName;
    end
    if strcmp(backendName, CoCoSimPreferences.lustreBackend)
        schema.checked = 'checked';
    else
        schema.checked = 'unchecked';
    end
    
    schema.callback = @(x) setBackendOption(backendName, ...
        CoCoSimPreferences, x);
end

function setBackendOption(backendName, CoCoSimPreferences, varargin)
    CoCoSimPreferences.lustreBackend = backendName;
    cocosim_menu.CoCoSimPreferences.save(CoCoSimPreferences);
end

%% Kind2 options
function schema = getKind2Options(callbackInfo)
    schema = sl_container_schema;
    schema.label = 'Kind2 Preferences';
    schema.statustip = 'Kind2 Preferences';
    schema.autoDisableWhen = 'Busy';
    
    CoCoSimPreferences = callbackInfo.userdata;
    
    schema.childrenFcns = {...
        {@PreferencesMenu.getCompositionalAnalysis, CoCoSimPreferences}, ...
        {@PreferencesMenu.getKind2Binary, CoCoSimPreferences},...
        {@getKind2Solver, CoCoSimPreferences},...
        {@getKind2CheckSatAssume, CoCoSimPreferences}...
        };
end

function schema = getKind2Solver(callbackInfo)
    schema = sl_container_schema;
    schema.label = 'Smt Solver';
    schema.statustip = 'Smt Solver';
    schema.autoDisableWhen = 'Busy';
    
    CoCoSimPreferences = callbackInfo.userdata;
    
    options = {'Z3', 'Yices2'};
    callbacks = cell(1, length(options));
    for i=1:length(options)
        callbacks{i} = @(x) kind2SolverCallback(options{i}, ...
            CoCoSimPreferences, x);
    end
    schema.childrenFcns = callbacks;
    
end
function schema = kind2SolverCallback(name, CoCoSimPreferences, varargin)
    schema = sl_toggle_schema;
    schema.label = name;

    if strcmp(name, CoCoSimPreferences.kind2SmtSolver)
        schema.checked = 'checked';
    else
        schema.checked = 'unchecked';
    end
    
    schema.callback = @(x) setkind2SolverOption(name, ...
        CoCoSimPreferences, x);
end

function setkind2SolverOption(name, CoCoSimPreferences, varargin)
    CoCoSimPreferences.kind2SmtSolver = name;
    cocosim_menu.CoCoSimPreferences.save(CoCoSimPreferences);
end

%

function schema = getKind2CheckSatAssume(callbackInfo)
    schema = sl_toggle_schema;
    schema.label = 'Use check-sat-assuming';

    CoCoSimPreferences = callbackInfo.userdata;
    
    if CoCoSimPreferences.kind2CheckSatAssume
        schema.checked = 'checked';
    else
        schema.checked = 'unchecked';
    end
    
    schema.callback = @(x) setkind2CheckSatAssume(CoCoSimPreferences, x);
end

function setkind2CheckSatAssume(CoCoSimPreferences, varargin)
    CoCoSimPreferences.kind2CheckSatAssume = ~ CoCoSimPreferences.kind2CheckSatAssume;
    cocosim_menu.CoCoSimPreferences.save(CoCoSimPreferences);
end
%% Lustrec options
function schema = getLustrecBinary(callbackInfo)
    schema = sl_container_schema;
    schema.label = 'Lustrec binary';
    schema.statustip = 'Lustrec binary';
    schema.autoDisableWhen = 'Busy';
    
    CoCoSimPreferences = callbackInfo.userdata;
    
    options = {'Docker', 'Local'};
    callbacks = cell(1, length(options));
    for i=1:length(options)
        callbacks{i} = @(x) lustreBinaryCallback(options{i}, ...
            CoCoSimPreferences, x);
    end
    schema.childrenFcns = callbacks;
end

function schema = lustreBinaryCallback(name, CoCoSimPreferences, varargin)
    schema = sl_toggle_schema;
    schema.label = name;
    schema.label = name;
    if strcmp(name, CoCoSimPreferences.lustrecBinary)
        schema.checked = 'checked';
    else
        schema.checked = 'unchecked';
    end
    
    schema.callback = @(x) setlustreBinarydOption(name, ...
        CoCoSimPreferences, x);
end

function setlustreBinarydOption(name, CoCoSimPreferences, varargin)
    CoCoSimPreferences.lustrecBinary = name;
    cocosim_menu.CoCoSimPreferences.save(CoCoSimPreferences);
end

%% DED Checks
function schema = getDEDChecks(callbackInfo)
    schema = sl_container_schema;
    schema.label = 'Design Error Detection Checks';
    schema.statustip = 'Design Error Detection';
    schema.autoDisableWhen = 'Busy';
    CoCoSimPreferences = callbackInfo.userdata;
    checksNames = {coco_nasa_utils.CoCoBackendType.DED_DIVBYZER,coco_nasa_utils.CoCoBackendType.DED_INTOVERFLOW ,...
        coco_nasa_utils.CoCoBackendType.DED_OUTOFBOUND, coco_nasa_utils.CoCoBackendType.DED_OUTMINMAX };
    callbacks = cell(1, length(checksNames));
    for i=1:length(checksNames)
        callbacks{i} = @(x) checkNameCallback(checksNames{i}, ...
            CoCoSimPreferences, x);
    end
    schema.childrenFcns = callbacks;
end

function schema = checkNameCallback(checkName, CoCoSimPreferences, varargin)
    schema = sl_toggle_schema;
    if ~strcmp(checkName, coco_nasa_utils.CoCoBackendType.DED_OUTMINMAX)
        schema.state = 'Disabled';
        schema.label = strcat(checkName, ' (Work in progress)');
    else
        schema.label = checkName;
    end
    if ismember(checkName, CoCoSimPreferences.dedChecks)
        schema.checked = 'checked';
    else
        schema.checked = 'unchecked';
    end
    schema.callback = @(x) setCheckOption(checkName, ...
        CoCoSimPreferences, x);
end

function setCheckOption(checkName, CoCoSimPreferences, varargin)
    if ismember(checkName, CoCoSimPreferences.dedChecks)
        CoCoSimPreferences.dedChecks = CoCoSimPreferences.dedChecks(...
            ~strcmp(CoCoSimPreferences.dedChecks, checkName));
    else
        CoCoSimPreferences.dedChecks{end+1} = checkName;
    end
    cocosim_menu.CoCoSimPreferences.save(CoCoSimPreferences);
end

%% Verbose options
function schema = getVerbose(callbackInfo)
    schema = sl_container_schema;
    schema.label = 'Verbose level';
    schema.statustip = 'Verbose level';
    schema.autoDisableWhen = 'Busy';
    
    CoCoSimPreferences = callbackInfo.userdata;
    
    options = {0, 1, 2, 3};
    callbacks = cell(1, length(options));
    for i=1:length(options)
        callbacks{i} = @(x) verboseCallback(options{i}, ...
            CoCoSimPreferences, x);
    end
    schema.childrenFcns = callbacks;
end

function schema = verboseCallback(v, CoCoSimPreferences, varargin)
    schema = sl_toggle_schema;
    schema.label = num2str(v);
    try
        ws_v = evalin('base', 'cocosim_verbose');
    catch
        assignin('base', 'cocosim_verbose', CoCoSimPreferences.cocosim_verbose);
        ws_v = CoCoSimPreferences.cocosim_verbose;
    end
        
    if v == ws_v
        schema.checked = 'checked';
    else
        schema.checked = 'unchecked';
    end
    
    schema.callback = @(x) setVerboseOption(v, ...
        CoCoSimPreferences, x);
end

function setVerboseOption(v, CoCoSimPreferences, varargin)
    CoCoSimPreferences.cocosim_verbose = v;
    assignin('base', 'cocosim_verbose', v);
    cocosim_menu.CoCoSimPreferences.save(CoCoSimPreferences);
end

%% Reset Settings
function schema = resetSettings(callbackInfo)
    schema = sl_action_schema;
    schema.label = 'Reset preferences';
    schema.statustip = 'Reset preferences';
    schema.autoDisableWhen = 'Busy';
    CoCoSimPreferences = callbackInfo.userdata;
    schema.callback = @(x) cocosim_menu.CoCoSimPreferences.deletePreferences(CoCoSimPreferences);
end