function matchControlsFixedGUI(demoFile)
% matchControlsFixedGUI  Fixed GUI to choose demographic matching factors
% Compatible with MATLAB R2024a.
% This tool was created via ChatGPT. NWB
%
% Usage:
%   matchControlsFixedGUI()                      % choose file with dialog
%   matchControlsFixedGUI('Demographics.xlsx')   % pass path
%
% GUI fields shown: Sex, Age (via DOB), Height, Weight, Years formal
% education, Race, Ethnicity
% Computes weighted distance across numeric variables and returns the top-2
% matches.
%
% Changes in this version:
%  - BOTH candidate and target height/weight values are converted to a
%    canonical unit (meters for height, kilograms for weight) *before*
%    computing distance and tolerance comparisons.
%  - Tolerances for height/weight are also converted into canonical unit.
%  - Adjusted layout: results area given more vertical space; left-panel
%    Weight / Tolerance / Data-units columns narrowed for readability.

arguments
    demoFile (1,:) char = ''
end

%% -----------------------------
% 0. Fixed variable keywords we want in GUI (used to find columns)
% -----------------------------
fixedVars = struct;
fixedVars.sex = {'sex','gender'};
fixedVars.age = {'age','age_years','age_year'};
fixedVars.dob = {'dob','birthdate','dateofbirth'};  % optional (for age)
fixedVars.height = {'height','ht','stature'};
fixedVars.weight = {'weight','wt','mass','bodymass'};
fixedVars.education = {'education','years_education','yrs_education', ...
    'yearsformaleducation','years_formal_education','years_schooling'};
fixedVars.race = {'race'};
fixedVars.ethnicity = {'ethnicity'};
fixedVars.matched = {'match'};

%% -----------------------------
% 1. Load table
% -----------------------------
if isempty(demoFile)
    [file,path] = uigetfile( ...
        {'*.xlsx;*.xls;*.csv','Demographic files (*.xlsx,*.xls,*.csv)'},...
        'Select demographic file');
    if isequal(file,0)
        disp('No file selected. Aborting.');
        return;
    end
    demoFile = fullfile(path,file);
end

try
    T = readtable(demoFile,'PreserveVariableNames',true);
catch ME
    error('Could not read demographic file: %s',ME.message);
end

% store sanitized variable names from table
varNames = T.Properties.VariableNames;
% TODO: sanitize 'varNames' to remove any whitespace and handle units,
% especially important for categorical variables used as 'struct' fields
nCols = numel(varNames);

% helper to find column by keywords (first match)
    function idx = findColumnByKeywords(keywords)
        idx = [];
        for jj = 1:nCols
            vn = lower(varNames{jj});
            for kk = 1:numel(keywords)
                if contains(vn,lower(keywords{kk}))
                    idx = jj;
                    return;
                end
            end
        end
    end

% find columns
colIdx.sex = findColumnByKeywords(fixedVars.sex);
colIdx.age = findColumnByKeywords(fixedVars.age);
colIdx.dob = findColumnByKeywords(fixedVars.dob);
colIdx.height = findColumnByKeywords(fixedVars.height);
colIdx.weight = findColumnByKeywords(fixedVars.weight);
colIdx.education = findColumnByKeywords(fixedVars.education);
colIdx.race = findColumnByKeywords(fixedVars.race);
colIdx.ethnicity = findColumnByKeywords(fixedVars.ethnicity);
colIdx.matched = findColumnByKeywords(fixedVars.matched);

%% -----------------------------
% 2. Prepare defaults (tolerances, unit assumptions)
% -----------------------------
numericVars = {'age','height','weight','education'};
defaultTol = struct();
for i = 1:numel(numericVars)
    key = numericVars{i};
    idx = colIdx.(key);
    if ~isempty(idx)
        col = T.(varNames{idx});
        if isnumeric(col)
            vals = col(~isnan(col));
            s = std(double(vals));
            if isempty(s) || s <= 0
                s = 1;
            end
            defaultTol.(key) = s;
        else
            defaultTol.(key) = 1;
        end
    else
        defaultTol.(key) = 1;
    end
end

% default dataset unit guesses (used as initial values in dropdowns)
defaultDataUnits.height = 'meters';
defaultDataUnits.weight = 'pounds';

% canonical units used for internal comparisons
canonicalUnits.height = 'meters';
canonicalUnits.weight = 'pounds';

%% -----------------------------
% 3. Build GUI (fixed layout) - R2024a: set Layout.* AFTER creation
% -----------------------------
fig = uifigure('Name','Match Controls (Fixed GUI)', ...
    'Position',[150 100 980 760]);
g = uigridlayout(fig,[11 6]);   % extra row for more space for results
% give more vertical space to results row (last row) by using '2x'
g.RowHeight = ...
    {'fit','fit','fit','1x','fit','fit','fit','fit','fit','fit','2x'};
% narrow some left-panel columns (weight/tolerance/data units) so
% 'Variable' shows better
g.ColumnWidth = {'1x','1x','1x','1x','1x','1x'};

% title label
lblTitle = uilabel(g);
lblTitle.Text = sprintf('Demographic file: %s',demoFile);
lblTitle.FontWeight = 'bold';
lblTitle.FontSize = 13;
lblTitle.Layout.Row = 1;
lblTitle.Layout.Column = [1 6];

% instruction label
instr = uilabel(g);
instr.Text = ['Select variables to use for matching, set weights & ' ...
    'tolerances (numbers). Enter target participant info (right).'];
instr.Layout.Row = 2;
instr.Layout.Column = [1 6];

% left block: checkboxes + weight/tol + units
varsPanel = uipanel(g);
varsPanel.Title = 'Matching Factors & Numeric Settings';
varsPanel.Layout.Row = [3 9];      % <-- Match targetPanel row span
varsPanel.Layout.Column = [1 3];   % <-- Use left 3 columns
varsPanel.Scrollable = true;
% varsPanel.RowHeight = {50, '1x', '2x'};


% grid inside panel: columns:
%   Use | Variable | Weight | Tolerance | DataUnit (if applicable)
numVars = 7;
pv = uigridlayout(varsPanel,[numVars+1 6]);
pv.Scrollable = true;
% --- narrow these internal columns so 'Variable' column has more room:
% use 'fit' for checkbox column, '1x' wide for variable label, numeric
% columns narrower in px
pv.RowHeight = repmat({'fit'},1,numVars+1);
pv.ColumnWidth = {'fit','1x',60,60,80,'fit'};   % columns 3..5 narrowed

% header labels
h1 = uilabel(pv); h1.Text = 'Use';
h2 = uilabel(pv); h2.Text = 'Variable';
h3 = uilabel(pv); h3.Text = 'Weight';
h4 = uilabel(pv); h4.Text = 'Tolerance';
h5 = uilabel(pv); h5.Text = 'Data Units';
h1.FontWeight = 'bold'; h1.Layout.Row = 1; h1.Layout.Column = 1;
h2.FontWeight = 'bold'; h2.Layout.Row = 1; h2.Layout.Column = 2;
h3.FontWeight = 'bold'; h3.Layout.Row = 1; h3.Layout.Column = 3;
h4.FontWeight = 'bold'; h4.Layout.Row = 1; h4.Layout.Column = 4;
h5.FontWeight = 'bold'; h5.Layout.Row = 1; h5.Layout.Column = 5;

labels = ...
    {'Sex','Age','Height','Weight','Education (years)','Race','Ethnicity'};
isNumericArr = [false true true true true false false];

chkUse = gobjects(1,numVars);
edWeight = gobjects(1,numVars);
edTol = gobjects(1,numVars);
dataUnitDd = gobjects(1,numVars);

for i = 1:numVars
    row = i + 1;
    % checkbox: include this variable in the matching
    chkUse(i) = uicheckbox(pv);
    chkUse(i).Text = ''; chkUse(i).Value = true;
    chkUse(i).Layout.Row = row; chkUse(i).Layout.Column = 1;

    % variable name label
    lbl = uilabel(pv); lbl.Text = labels{i};
    lbl.Layout.Row = row; lbl.Layout.Column = 2;
    lbl.HorizontalAlignment = 'left';

    if isNumericArr(i)
        % numeric: weight & tolerance numeric fields
        edWeight(i) = uieditfield(pv,'numeric');
        edTol(i) = uieditfield(pv,'numeric');
        if i == 2
            edWeight(i).Value = 3;          % Age weight preset
            edTol(i).Value = 2.5;             % Age tolerance preset
        elseif i == 3
            edWeight(i).Value = 1;
            edTol(i).Value = 4;             % height in inches
        elseif i == 4
            edWeight(i).Value = 1;
            edTol(i).Value = 30;            % weight in pounds
        elseif i == 5
            edWeight(i).Value = 2;
            edTol(i).Value = 3;             % years education
        else
            edWeight(i).Value = 1;
            edTol(i).Value = 1;
        end
        edWeight(i).Limits = [0 Inf];
        edWeight(i).Layout.Row = row; edWeight(i).Layout.Column = 3;
        edTol(i).Layout.Row = row; edTol(i).Layout.Column = 4;
    else
        % non-numeric: show 'N/A' placeholders (disabled)
        edWeight(i) = uieditfield(pv,'text');
        edWeight(i).Value = 'N/A'; edWeight(i).Editable = 'off';
        edWeight(i).Layout.Row = row; edWeight(i).Layout.Column = 3;
        edTol(i) = uieditfield(pv,'text');
        edTol(i).Value = 'N/A'; edTol(i).Editable = 'off';
        edTol(i).Layout.Row = row; edTol(i).Layout.Column = 4;
    end

    % data unit dropdown only for height/weight rows (indices 3 and 4)
    if i == 3
        % dataset unit for height (user should pick units from table)
        dataUnitDd(i) = uidropdown(pv);
        dataUnitDd(i).Items = {'meters','centimeters','inches'};
        dataUnitDd(i).Value = 'inches';
        dataUnitDd(i).Layout.Row = row; dataUnitDd(i).Layout.Column = 5;
    elseif i == 4
        % dataset unit for weight
        dataUnitDd(i) = uidropdown(pv);
        dataUnitDd(i).Items = {'kilograms','pounds'};
        dataUnitDd(i).Value = defaultDataUnits.weight;
        dataUnitDd(i).Layout.Row = row; dataUnitDd(i).Layout.Column = 5;
    else
        dataUnitDd(i) = uidropdown(pv); dataUnitDd(i).Items = {'--'};
        dataUnitDd(i).Value = '--'; dataUnitDd(i).Enable = 'off';
        dataUnitDd(i).Layout.Row = row; dataUnitDd(i).Layout.Column = 5;
    end
end

% right block: target participant entries
targetPanel = uipanel(g);
targetPanel.Title = 'Target Participant Values';
targetPanel.Layout.Row = [3 9];
targetPanel.Layout.Column = [4 6];

pt = uigridlayout(targetPanel,[12 2]);
pt.RowHeight = repmat({'fit'},1,12);
pt.ColumnWidth = {'1x','1x'};
pt.Scrollable = true;

% header labels for target panel
lblVarHeader = uilabel(pt);
lblVarHeader.Text = 'Variable'; lblVarHeader.FontWeight = 'bold';
lblVarHeader.Layout.Row = 1; lblVarHeader.Layout.Column = 1;
lblEntryHeader = uilabel(pt);
lblEntryHeader.Text = 'Entry'; lblEntryHeader.FontWeight = 'bold';
lblEntryHeader.Layout.Row = 1; lblEntryHeader.Layout.Column = 2;

% Row 2: Sex (dropdown)
lblSex = uilabel(pt); lblSex.Text = 'Sex'; lblSex.Layout.Row = 2; lblSex.Layout.Column = 1;
targetSex = uidropdown(pt,'Items',{'','Male','Female','Other'},'Value','');
targetSex.Layout.Row = 2; targetSex.Layout.Column = 2;

% Row 3-5: DOB, assessment date, computed age
lblDOB = uilabel(pt); lblDOB.Text = 'Date of birth (DOB)'; lblDOB.Layout.Row = 3; lblDOB.Layout.Column = 1;
targetDOB = uidatepicker(pt,'Value',datetime('2000-01-01'),'DisplayFormat','yyyy-MM-dd');
targetDOB.Layout.Row = 3; targetDOB.Layout.Column = 2;

lblAssess = uilabel(pt); lblAssess.Text = 'Assessment date (for age calc)'; lblAssess.Layout.Row = 4; lblAssess.Layout.Column = 1;
targetAssessDate = uidatepicker(pt,'Value',datetime('today'),'DisplayFormat','yyyy-MM-dd');
targetAssessDate.Layout.Row = 4; targetAssessDate.Layout.Column = 2;

lblAgeDisp = uilabel(pt); lblAgeDisp.Text = 'Computed age (years)'; lblAgeDisp.Layout.Row = 5; lblAgeDisp.Layout.Column = 1;
% computed age displayed read-only
targetAgeDisp = uieditfield(pt,'numeric','Value',-Inf,'Editable','off');
targetAgeDisp.Layout.Row = 5; targetAgeDisp.Layout.Column = 2;

% Height input (target) - feet/inches or single field
lblHt = uilabel(pt); lblHt.Text = 'Height'; lblHt.Layout.Row = 8; lblHt.Layout.Column = 1;

htFeet = uieditfield(pt,'numeric','Value',0,'Limits',[0 Inf]);
htFeet.Layout.Row = 9; htFeet.Layout.Column = 2;
htFeet.Placeholder = 'Feet';

htInches = uieditfield(pt,'numeric','Value',0,'Limits',[0 11]);
htInches.Layout.Row = 9; htInches.Layout.Column = 3;
htInches.Placeholder = 'Inches';

htSingle = uieditfield(pt,'numeric','Value',0,'Limits',[0 Inf]);
htSingle.Layout.Row = 9; htSingle.Layout.Column = 2;
htSingle.Placeholder = 'Height';
htSingle.Visible = false; % Start hidden

lblHtUnit = uilabel(pt); lblHtUnit.Text = 'Height unit (target)'; lblHtUnit.Layout.Row = 9; lblHtUnit.Layout.Column = 1;
targetHeightUnit = uidropdown(pt,'Items',{'meters','centimeters','inches','Feet and Inches'},'Value','Feet and Inches');
targetHeightUnit.Layout.Row = 8; targetHeightUnit.Layout.Column = 2;

% Callback to update visibility
targetHeightUnit.ValueChangedFcn = @(src,evt) updateHeightFields();

function updateHeightFields()
    if strcmp(targetHeightUnit.Value, 'Feet and Inches')
        htFeet.Visible = true;
        htInches.Visible = true;
        htSingle.Visible = false;
    else
        htFeet.Visible = false;
        htInches.Visible = false;
        htSingle.Visible = true;
    end
end

% Call once to set initial visibility
updateHeightFields();

% Weight input
lblWt = uilabel(pt); lblWt.Text = 'Weight (target)'; lblWt.Layout.Row = 6; lblWt.Layout.Column = 1;
targetWeight = uieditfield(pt,'numeric','Value',Inf,'Limits',[0 Inf]);
targetWeight.Layout.Row = 7; targetWeight.Layout.Column = 2;

lblWtUnit = uilabel(pt); lblWtUnit.Text = 'Weight unit (target)'; lblWtUnit.Layout.Row = 7; lblWtUnit.Layout.Column = 1;
targetWeightUnit = uidropdown(pt,'Items',{'kilograms','pounds'},'Value',defaultDataUnits.weight);
targetWeightUnit.Layout.Row = 6; targetWeightUnit.Layout.Column = 2;

% Education
lblEd = uilabel(pt); lblEd.Text = 'Years formal education'; lblEd.Layout.Row = 10; lblEd.Layout.Column = 1;
targetEducation = uieditfield(pt,'numeric','Value',16,'Limits',[0 100]);
targetEducation.Layout.Row = 10; targetEducation.Layout.Column = 2;

% Race
lblRace = uilabel(pt); lblRace.Text = 'Race';
lblRace.Layout.Row = 11; lblRace.Layout.Column = 1;
targetRace = uidropdown(pt,'Items',{'White','Black'},'Value','White');
targetRace.Layout.Row = 11; targetRace.Layout.Column = 2;

% Ethnicity
lblEth = uilabel(pt); lblEth.Text = 'Ethnicity';
lblEth.Layout.Row = 12; lblEth.Layout.Column = 1;
targetEthnicity = uidropdown(pt,'Items',{'Not Hispanic or Latino', ...
    'Hispanic or Latino'},'Value','Not Hispanic or Latino');
targetEthnicity.Layout.Row = 12; targetEthnicity.Layout.Column = 2;

% update computed age when dob or assessment date changes
targetDOB.ValueChangedFcn = @(s,e) updateComputedAge();
targetAssessDate.ValueChangedFcn = @(s,e) updateComputedAge();
updateComputedAge();

% Buttons
btnCompute = uibutton(g,'push','Text','Compute Matches','FontWeight','bold');
btnCompute.Layout.Row = 9; btnCompute.Layout.Column = 1;
btnCompute.ButtonPushedFcn = @(btn,event) computeMatches();

btnPreview = uibutton(g,'push','Text','Preview candidates after categorical filters');
btnPreview.Layout.Row = 9; btnPreview.Layout.Column = 2;
btnPreview.ButtonPushedFcn = @(btn,event) previewCandidates();

btnViewTable = uibutton(g,'push','Text','View demographic table');
btnViewTable.Layout.Row = 9; btnViewTable.Layout.Column = 3;
btnViewTable.ButtonPushedFcn = @(btn,event) openTable();

% Results area (now gets more vertical space due to RowHeight '2x' on last row)
resPanel = uipanel(g);
resPanel.Title = 'Results (top matches + within-tolerance)';
% place results in the last row which has '2x' to give more room
resPanel.Layout.Row = 11; resPanel.Layout.Column = [1 6];

% inside results, two columns: matches table (left) and within-tolerance (right)
resGrid = uigridlayout(resPanel,[2,2]);
resGrid.RowHeight = {'fit','1x'};
% Give more horizontal room to left matches table and a bit to right
resGrid.ColumnWidth = {'2x','1x'};

lblMatches = uilabel(resGrid); lblMatches.Text = 'Top matches (closest first):'; lblMatches.FontWeight = 'bold';
lblMatches.Layout.Row = 1; lblMatches.Layout.Column = 1;
tblMatches = uitable(resGrid);
tblMatches.Layout.Row = 2; tblMatches.Layout.Column = 1;

lblWithin = uilabel(resGrid); lblWithin.Text = 'Within-tolerance for numeric variables (rows = matches):'; lblWithin.FontWeight = 'bold';
lblWithin.Layout.Row = 1; lblWithin.Layout.Column = 2;
tblWithin = uitable(resGrid);
tblWithin.Layout.Row = 2; tblWithin.Layout.Column = 2;

statusLabel = uilabel(g);
statusLabel.Text = 'Status: ready';
statusLabel.Layout.Row = 1; statusLabel.Layout.Column = 6;

% disable checkboxes for missing columns and warn user
mappingMessages = {};
if isempty(colIdx.sex)
    mappingMessages{end+1} = ...
        'Sex column not found. Sex matching disabled.';
    chkUse(1).Enable = 'off';
end
if isempty(colIdx.age) && isempty(colIdx.dob)
    mappingMessages{end+1} = 'Neither Age nor DOB found. Age disabled.';
    chkUse(2).Enable = 'off';
end
if isempty(colIdx.height)
    mappingMessages{end+1} = 'Height not found. Height disabled.';
    chkUse(3).Enable = 'off';
end
if isempty(colIdx.weight)
    mappingMessages{end+1} = 'Weight not found. Weight disabled.';
    chkUse(4).Enable = 'off';
end
if isempty(colIdx.education)
    mappingMessages{end+1} = 'Education not found. Education disabled.';
    chkUse(5).Enable = 'off';
end
if isempty(colIdx.race)
    mappingMessages{end+1} = 'Race not found. Race disabled.';
    chkUse(6).Enable = 'off';
end
if isempty(colIdx.ethnicity)
    mappingMessages{end+1} = 'Ethnicity not found. Ethnicity disabled.';
    chkUse(7).Enable = 'off';
end

if ~isempty(mappingMessages)
    statusLabel.Text = strjoin(mappingMessages,' ');
end

%% -----------------------------
% helper function: normalize categorical values for reliable comparison
% - special handling for Sex: maps common short codes to canonical labels.
% - for other categorical variables we use trimmed lowercase strings.
% -----------------------------
    function out = normalizeCategorical(vals,varKey)
        % normalize input values (vals can be string array, char, numeric, cell)
        % varKey: name of the variable (e.g., 'sex','race') to allow special-casing
        s = string(vals);              % convert to string array (handles mixed types)
        s = lower(strtrim(s));         % lowercase and trim whitespace
        % replace missing with empty string
        s(ismissing(s)) = "";
        out = s;
        % special mapping for sex-like fields
        if contains(lower(varKey),'sex')
            femaleTokens = ["f","female","fem","woman","w"];
            maleTokens   = ["m","male","man"];
            otherTokens  = ["other","o","nonbinary","non-binary","nb","genderqueer","trans","nonbinary"];
            for ii = 1:numel(out)
                v = out(ii);
                if v=="" , continue; end
                cleaned = regexprep(char(v),'[^a-z0-9]',''); % strip punctuation/spaces
                cleaned = string(cleaned);
                if any(cleaned == femaleTokens)
                    out(ii) = "female";
                elseif any(cleaned == maleTokens)
                    out(ii) = "male";
                elseif any(cleaned == otherTokens)
                    out(ii) = "other";
                else
                    out(ii) = cleaned; % fallback lowercase cleaned token
                end
            end
        else
            % generic cleaning for other categorical values
            for ii = 1:numel(out)
                v = out(ii);
                if v=="" , continue; end
                cleaned = regexprep(char(v),'^\s+|\s+$','');    % trim ends
                cleaned = regexprep(cleaned,'\s+',' ');        % collapse interior whitespace
                out(ii) = lower(string(cleaned));
            end
        end
    end

%% -----------------------------
% Unit conversion helper
% - Note: convertUnits(varName, fromUnit, toUnit, vals)
% - Supports height units: meters, centimeters, inches
% - Supports weight units: kilograms, pounds
% -----------------------------
    function out = convertUnits(varName, fromUnit, toUnit, vals)
        out = vals;
        if isempty(fromUnit) || isempty(toUnit) || strcmpi(fromUnit,toUnit), return; end
        lname = lower(varName);
        if contains(lname,'height')
            % normalize: convert 'fromUnit' values into meters, then to 'toUnit'
            switch lower(fromUnit)
                case 'meters'
                    meters = vals;
                case 'centimeters'
                    meters = vals/100;
                case 'inches'
                    meters = vals*0.0254;
                case {'feet', 'ft'}
                    meters = vals*0.3048;
                case {'feet and inches', 'ftin', 'ft/in'}
                    % Expect vals as Nx2: [feet, inches] or a single value (total inches)
                    if ismatrix(vals) && size(vals,2) == 2
                        meters = vals(:,1)*0.3048 + vals(:,2)*0.0254;
                    else
                        meters = vals*0.0254; % fallback: treat as total inches
                    end
                otherwise
                    meters = vals; % assume already meters if unknown
            end
            switch lower(toUnit)
                case 'meters'
                    out = meters;
                case 'centimeters'
                    out = meters*100;
                case 'inches'
                    out = meters/0.0254; % meters -> inches
                case {'feet', 'ft'}
                    out = meters/0.3048;
                case {'feet and inches', 'ftin', 'ft/in'}
                    % Return Nx2: [feet, inches]
                    feet = floor(meters/0.3048);
                    inches = (meters - feet*0.3048)/0.0254;
                    out = [feet, inches];
                otherwise
                    out = meters;
            end
        elseif contains(lname,'weight')
            % convert 'fromUnit' values into kilograms, then to 'toUnit'
            switch lower(fromUnit)
                case 'kilograms', kg = vals;
                case 'pounds', kg = vals*0.45359237;
                otherwise, kg = vals; % assume kilograms if unknown
            end
            switch lower(toUnit)
                case 'kilograms', out = kg;
                case 'pounds', out = kg / 0.45359237;
                otherwise, out = kg;
            end
        end
    end

%% -----------------------------
% update computed age display (DOB -> decimal years)
% -----------------------------
    function updateComputedAge()
        dob = targetDOB.Value;
        ref = targetAssessDate.Value;
        if isempty(dob) || isempty(ref) || ref < dob
            targetAgeDisp.Value = NaN;
            return;
        end
        daysDiff = days(ref - dob);
        ageYears = daysDiff / 365.2425;
        targetAgeDisp.Value = round(ageYears,4);
    end

%% -----------------------------
% preview candidates (categorical filters)
%   uses normalized categorical comparison
% -----------------------------
    function previewCandidates()
        selCats = struct();
        if chkUse(1).Value && ~isempty(colIdx.sex)
            val = string(targetSex.Value);
            if strlength(strtrim(val)) == 0
                uialert(fig, ...
                    'Please enter target Sex (or uncheck Sex).', ...
                    'Missing input');
                return;
            end
            selCats.(varNames{colIdx.sex}) = val;
        end
        if chkUse(6).Value && ~isempty(colIdx.race)
            val = strtrim(string(targetRace.Value));
            if isempty(val)
                uialert(fig, ...
                    'Please enter target Race (or uncheck Race).', ...
                    'Missing input');
                return;
            end
            selCats.(varNames{colIdx.race}) = val;
        end
        if chkUse(7).Value && ~isempty(colIdx.ethnicity)
            val = strtrim(string(targetEthnicity.Value));
            if isempty(val)
                uialert(fig, ...
                    ['Please enter target Ethnicity (or uncheck ' ...
                    'Ethnicity).'],'Missing input');
                return;
            end
            selCats.(varNames{colIdx.ethnicity}) = val;
        end
        if ~isempty(colIdx.matched)
            selCats.(varNames{colIdx.matched}) = "";
        end

        if isempty(fieldnames(selCats))
            uialert(fig,['No categorical filters selected or assigned ' ...
                'matched control; all rows are candidates.'],'Preview');
            tblToShow = T;
        else
            mask = true(height(T),1);
            fn = fieldnames(selCats);
            for ii = 1:numel(fn)
                colname = fn{ii};
                targ = selCats.(colname);
                col = T.(colname);

                % normalize both column and target for comparison
                colNorm = normalizeCategorical(col,colname);
                targNorm = normalizeCategorical(targ,colname);

                if isnumeric(col)
                    tn = str2double(targ);
                    if ~isnan(tn)
                        mask = mask & (col == tn);
                    else
                        mask = mask & false;
                    end
                else
                    mask = mask & (colNorm == targNorm);
                end
            end
            tblToShow = T(mask,:);
        end

        if isempty(tblToShow) || height(tblToShow) == 0
            uialert(fig,['No candidates remain after categorical ' ...
                'filters.'],'Preview');
        else
            w = uifigure('Name','Filtered Candidates', ...
                'Position',[300 200 900 450]);
            uitable(w,'Data',tblToShow,'Position',[10 10 880 430]);
        end
    end

%% -----------------------------
% open table (full demographics)
% -----------------------------
    function openTable()
        if isempty(T) || height(T) == 0
            uialert(fig,'Table empty.','Table');
            return;
        end
        w = uifigure('Name','Demographic Table', ...
            'Position',[300 200 900 450]);
        uitable(w,'Data',T,'Position',[10 10 880 430]);
    end

%% -----------------------------
% main: computeMatches
% - applies categorical filters using normalizeCategorical (robust)
% - converts target & candidate height/weight to canonical units BEFORE
%   computing distance
% - converts tolerance into canonical units too
% -----------------------------
    function computeMatches()
        % which checkboxes selected
        useIdx = find(arrayfun(@(c) c.Value,chkUse));
        if isempty(useIdx)
            uialert(fig,['Please select at least one variable to use ' ...
                'for matching.'],'No variables');
            return;
        end

        % build categorical mask using normalized comparison
        catMask = true(height(T),1);

        % sex categorical filter (normalized)
        if chkUse(1).Value
            if isempty(colIdx.sex)
                uialert(fig, ...
                    'Sex selected but Sex column missing.','Error');
                return;
            end
            val = string(targetSex.Value);
            if strlength(strtrim(val)) == 0
                uialert(fig, ...
                    'Please enter target Sex or uncheck Sex.','Missing');
                return;
            end
            colname = varNames{colIdx.sex};
            col = T.(colname);
            if isnumeric(col)
                vnum = str2double(val);
                if ~isnan(vnum)
                    catMask = catMask & (col == vnum);
                else
                    catMask = catMask & false;
                end
            else
                colNorm = normalizeCategorical(col,colname);
                targNorm = normalizeCategorical(val,colname);
                catMask = catMask & (colNorm == targNorm);
            end
        end

        % race
        if chkUse(6).Value
            if isempty(colIdx.race)
                uialert(fig, ...
                    'Race selected but Race column missing.','Error');
                return;
            end
            val = strtrim(targetRace.Value);
            if isempty(val)
                uialert(fig, ...
                    'Please enter target Race or uncheck Race.','Missing');
                return;
            end
            colname = varNames{colIdx.race}; col = T.(colname);
            if isnumeric(col)
                vnum = str2double(val);
                if ~isnan(vnum)
                    catMask = catMask & (col == vnum);
                else
                    catMask = catMask & false;
                end
            else
                colNorm = normalizeCategorical(col,colname);
                targNorm = normalizeCategorical(val,colname);
                catMask = catMask & (colNorm == targNorm);
            end
        end

        % ethnicity
        if chkUse(7).Value
            if isempty(colIdx.ethnicity)
                uialert(fig,['Ethnicity selected but Ethnicity column ' ...
                    'missing.'],'Error');
                return;
            end
            val = strtrim(targetEthnicity.Value);
            if isempty(val)
                uialert(fig,['Please enter target Ethnicity or uncheck' ...
                    ' Ethnicity.'],'Missing');
                return;
            end
            colname = varNames{colIdx.ethnicity}; col = T.(colname);
            if isnumeric(col)
                vnum = str2double(val);
                if ~isnan(vnum)
                    catMask = catMask & (col == vnum);
                else
                    catMask = catMask & false;
                end
            else
                colNorm = normalizeCategorical(col,colname);
                targNorm = normalizeCategorical(val,colname);
                catMask = catMask & (colNorm == targNorm);
            end
        end

        % already matched participants
        if ~isempty(colIdx.matched)
            val = "";
            colname = varNames{colIdx.matched}; col = T.(colname);
            colNorm = normalizeCategorical(col,colname);
            targNorm = normalizeCategorical(val,colname);
            catMask = catMask & (colNorm == targNorm);
        end

        % candidate count after categorical filters
        nCandidates = sum(catMask);
        if nCandidates == 0
            statusLabel.Text = ['Status: no candidates remain after ' ...
                'categorical filtering.'];
            tblMatches.Data = {}; tblWithin.Data = {};
            return;
        end

        % which numeric variables selected? [age,height,weight,education]
        numericSelected = false(1,4);
        % positions in chkUse corresponding to numericVars
        mapping = [2,3,4,5];
        for k = 1:4
            if any(useIdx==mapping(k)) && ...
                    (~isempty(colIdx.(numericVars{k})) || ...
                    (k == 1 && ~isempty(colIdx.dob)))
                numericSelected(k) = true;
            end
        end

        % if no numeric variables, return top 5 rows in filtered table
        if ~any(numericSelected)
            candidates = T(catMask,:);
            nReturn = min(5,height(candidates));
            tblMatches.Data = candidates(1:nReturn,:);
            tblWithin.Data = {};
            statusLabel.Text = sprintf(['Status: %d candidates after ' ...
                'categorical filtering; no numeric variables ' ...
                'selected.'],nCandidates);
            return;
        end

        % build target numeric values (convert into canonical units)
        targetVals = struct();

        % age (decimal years)
        if numericSelected(1)
            dob = targetDOB.Value; ref = targetAssessDate.Value;
            if isempty(dob) || isempty(ref) || ref < dob
                uialert(fig,['Invalid DOB or assessment date for age ' ...
                    'calculation.'],'Error');
                return;
            end
            targetVals.age = days(ref - dob)/365.2425;
        end

        % height: convert target to canonical unit (meters)
        if numericSelected(2)
            tUnit = targetHeightUnit.Value;
            if strcmpi(tUnit, 'Feet and Inches')
                feet = htFeet.Value;
                inches = htInches.Value;
                if isempty(feet), feet = 0; end
                if isempty(inches), inches = 0; end
                ht = [feet, inches];
            else
                ht = htSingle.Value;
            end
            if isempty(ht) || any(isnan(ht))
                uialert(fig,['Height selected but target height not ' ...
                    'entered.'],'Missing');
                return;
            end
            % Convert target height to canonical unit (meters)
            targetVals.height = double(convertUnits('height', tUnit, canonicalUnits.height, ht));
            % also convert tolerance (entered in edTol(3)) -> canonical
            tol_raw = edTol(3).Value;
            if isempty(tol_raw) || ~isnumeric(tol_raw) || isnan(tol_raw)
                tol_raw = defaultTol.height;
            end
            dataUnit = dataUnitDd(3).Value;
            tol_canonical = double(convertUnits('height', dataUnit, canonicalUnits.height, tol_raw));
            if tol_canonical <= 0
                tol_canonical = defaultTol.height;
            end
            targetVals.heightTol = tol_canonical;
            % convert candidate heights (from dataset) to canonical later
        end

        % weight: convert target to canonical unit (kilograms)
        if numericSelected(3)
            wt = targetWeight.Value;
            if isempty(wt) || isnan(wt)
                uialert(fig,['Weight selected but target weight not ' ...
                    'entered.'],'Missing');
                return;
            end
            tUnit = targetWeightUnit.Value;
            dataUnit = dataUnitDd(4).Value;
            targetVals.weight = double(convertUnits('weight',tUnit, ...
                canonicalUnits.weight,wt));
            tol_raw = edTol(4).Value;
            if isempty(tol_raw) || ~isnumeric(tol_raw) || isnan(tol_raw)
                tol_raw = defaultTol.weight;
            end
            tol_canonical = double(convertUnits('weight',dataUnit, ...
                canonicalUnits.weight,tol_raw));
            if tol_canonical <= 0
                tol_canonical = defaultTol.weight;
            end
            targetVals.weightTol = tol_canonical;
        end

        % education (no units)
        if numericSelected(4)
            ed = targetEducation.Value;
            if isempty(ed) || isnan(ed)
                uialert(fig,['Education selected but target education ' ...
                    'not entered.'],'Missing');
                return;
            end
            targetVals.education = double(ed);
            % tolerance stored in edTol(5) (no unit conversion needed)
        end

        % compute weighted normalized squared distances for each candidate
        candidates = T(catMask,:);
        m = height(candidates);
        dist2 = zeros(m,1);
        withinMat = [];
        withinColNames = {};

        % =============== Age Contribution =================
        if numericSelected(1)
            % get candidate ages from numeric age column or from dob column
            if ~isempty(colIdx.age) && isnumeric(T.(varNames{colIdx.age}))
                candAges = double(candidates.(varNames{colIdx.age}));
            elseif ~isempty(colIdx.dob)
                dobCol = candidates.(varNames{colIdx.dob});
                candAges = nan(m,1);
                for r = 1:m
                    try
                        val = dobCol(r);
                        if isdatetime(val)
                            dt = val;
                        else
                            dt = datetime(val);
                        end
                        candAges(r) = ...
                            days(targetAssessDate.Value - dt) / 365.2425;
                    catch
                        candAges(r) = NaN;
                    end
                end
            else
                candAges = nan(m,1);
            end
            w = edWeight(2).Value; tol = edTol(2).Value;
            if tol<=0
                tol = defaultTol.age;
            end
            tval = targetVals.age;
            diffsq = ((tval - candAges)./tol).^2;
            if any(~isnan(diffsq))
                mx = max(diffsq(~isnan(diffsq)));
            else
                mx = 1;
            end
            diffsq(isnan(diffsq)) = (mx + 1e6);
            dist2 = dist2 + w .* diffsq;
            withinColNames{end+1} = sprintf( ...
                'Age (\x00B1%g yrs)',tol);
            withinMat(:,end+1) = abs(tval - candAges) <= tol;
        end

        % =============== Height Contribution =================
        if numericSelected(2)
            % candidate raw values as stored in dataset (user indicates
            % their unit with dataUnitDd(3))
            cvals_raw = double(candidates.(varNames{colIdx.height}));
            % dataUnit = dataUnitDd(3).Value; % dataset unit selection (height)
            % convert candidates from 'dataUnit' -> canonical (meters)
            cvals_canonical = double(convertUnits('height','meters', ...
                canonicalUnits.height,cvals_raw));
            % target converted to canonical earlier: targetVals.height
            tval = targetVals.height;
            % tolerance converted to canonical as targetVals.heightTol
            tol_canonical = targetVals.heightTol;
            % compute normalized squared difference
            diffsq = ((tval - cvals_canonical)./tol_canonical).^2;
            if any(~isnan(diffsq))
                mx = max(diffsq(~isnan(diffsq)));
            else
                mx = 1;
            end
            % penalize missing candidate values strongly
            diffsq(isnan(diffsq)) = (mx + 1e6);
            w = edWeight(3).Value;
            dist2 = dist2 + w .* diffsq;
            % TODO: fix hardcoding
            withinColNames{end+1} = sprintf( ...
                'Height (\x00B1%g %s)',edTol(3).Value,'inches');
            withinMat(:,end+1) = ...
                abs(tval - cvals_canonical) <= tol_canonical;
        end

        % =============== Weight Contribution =================
        if numericSelected(3)
            cvals_raw = double(candidates.(varNames{colIdx.weight}));
            % dataUnit = dataUnitDd(4).Value; % dataset unit selection
            cvals_canonical = double(convertUnits('weight','kilograms', ...
                canonicalUnits.weight,cvals_raw));
            tval = targetVals.weight;
            tol_canonical = targetVals.weightTol;
            diffsq = ((tval - cvals_canonical)./tol_canonical).^2;
            if any(~isnan(diffsq))
                mx = max(diffsq(~isnan(diffsq)));
            else
                mx = 1;
            end
            diffsq(isnan(diffsq)) = (mx + 1e6);
            w = edWeight(4).Value;
            dist2 = dist2 + w .* diffsq;
            withinColNames{end+1} = sprintf( ...
                'Weight (\x00B1%g %s)',edTol(4).Value,dataUnit);
            withinMat(:,end+1) = ...
                abs(tval - cvals_canonical) <= tol_canonical;
        end

        % =============== Education Contribution =================
        if numericSelected(4)
            cvals = double(candidates.(varNames{colIdx.education}));
            w = edWeight(5).Value; tol = edTol(5).Value;
            if tol <= 0
                tol = defaultTol.education;
            end
            tval = targetVals.education;
            diffsq = ((tval - cvals)./tol).^2;
            if any(~isnan(diffsq))
                mx = max(diffsq(~isnan(diffsq)));
            else
                mx = 1;
            end
            diffsq(isnan(diffsq)) = (mx + 1e6);
            dist2 = dist2 + w .* diffsq;
            withinColNames{end+1} = sprintf( ...
                'Education (\x00B1%g yrs)',tol);
            withinMat(:,end+1) = abs(tval - cvals) <= tol;
        end

        % finalize: compute Euclidean distance (sqrt of weighted sum)
        dist = sqrt(dist2);
        [sortedDist, sidx] = sort(dist,'ascend','ComparisonMethod','real');
        nReturn = min(5,numel(sortedDist));
        if nReturn == 0
            statusLabel.Text = 'No numeric comparisons available.';
            tblMatches.Data = {}; tblWithin.Data = {};
            return;
        end
        pickIdx = sidx(1:nReturn);
        matched = candidates(pickIdx,:);

        % prepare within-tolerance output table
        withinReturn = withinMat(pickIdx,:);
        outCell = cell(nReturn,size(withinReturn,2)+1);
        for r = 1:nReturn
            outCell{r,1} = sortedDist(r);
            for c = 1:size(withinReturn,2)
                outCell{r,c+1} = logical(withinReturn(r,c));
            end
        end
        headers = ['Distance' withinColNames];

        % display results
        tblMatches.Data = matched;
        tblMatches.ColumnName = matched.Properties.VariableNames;
        tblWithin.Data = outCell;
        tblWithin.ColumnName = headers;

        statusLabel.Text = sprintf(['Status: %d candidates after ' ...
            'categorical filtering; returning %d match(es)'], ...
            nCandidates,nReturn);
    end

% Combine feet and inches to total inches
feet = htFeet.Value;
inches = htInches.Value;
totalInches = feet * 12 + inches;
end