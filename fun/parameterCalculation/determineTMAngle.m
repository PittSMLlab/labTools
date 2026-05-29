function ang = determineTMAngle(trialData)
%DETERMINETMANGLE Extract treadmill incline angle from trial description.
%
%   Parses the trial description string to extract a numeric treadmill
% incline angle in degrees. If the description contains 'deg', the
% function locates the numeric value immediately preceding it and
% determines the sign from keywords ('decline'/'downhill' = negative,
% all others = positive incline). If no valid angle is parsed, prompts
% the user to enter the value manually. Returns 0 if the description
% contains no 'deg' substring.
%
% Inputs:
%   trialData - object with fields .description (string or cell array
%               containing the trial name/condition) and .type
%               (string used in the manual input prompt on failure)
%
% Outputs:
%   ang - treadmill incline angle in degrees; positive = uphill,
%         negative = downhill, 0 = level
%
% Toolbox Dependencies:
%   None
%
% See also COMPUTEFORCEPARAMETERS, CALCPARAMETERS.
%
% Author: CJS, 08/2016

arguments
    trialData (1,1)
end

%% Parse Trial Description
% NOTE: assuredly a more robust approach exists using regexp pattern
% matching, but this is functional for current naming conventions
trial = trialData.description;
if iscell(trial)
    trial = trial{1};
end
if iscell(trial)
    trial = char(trial);
end

%% Determine Treadmill Angle
% (old condition):
% (~iscell(regexp(trial, 'deg')) && ~iscell(cell2mat(regexp(trial, 'deg'))))|| ~iscell(regexp(trial, '8.5')) %~isempty(cell2mat(regexp(trial, 'deg'))) || ~isempty(cell2mat(regexp(trial, '8.5')))
failRead = false;
if ~isempty(strfind(trial, 'deg'))
    %     if ~isempty(strfind(trial, '8.5 deg incline')) || ~isempty(strfind(trial, '8.5 deg uphill'))
    %         ang=8.5;
    %     elseif ~isempty(strfind(trial, '8.5 deg decline')) || ~isempty(strfind(trial, '8.5 decline')) || ~isempty(strfind(trial, '8.5 deg downhill'))
    %         ang=-8.5;
    %     elseif ~isempty(cell2mat(regexp(trial, '5 deg incline')))|| ~isempty(cell2mat(regexp(trial, '5 deg uphill'))) || ~isempty(cell2mat(regexp(trial, '5 deg')))
    %         ang=5;
    %     elseif ~isempty(cell2mat(regexp(trial, '5 deg decline')))|| ~isempty(cell2mat(regexp(trial, '5 deg downhill')))
    %         ang=-5;
    %     else
    %         ang=input(['What angle (in degrees) was the study run at ', trial, ': ',trialData.type ,'?   ']);
    %     end
    if ~isempty(strfind(trial, 'decline')) || ...
            ~isempty(strfind(trial, 'downhill'))
        angleSign = -1;
    else  % assume incline by default
        angleSign = 1;
    end
    degIdx = strfind(trial, 'deg');
    degIdx = degIdx(1);  % use first occurrence if multiple
    % Extract substring ending at 'deg'; start up to 6 chars before.
    % max([degIdx, 7]) - 6 clamps the start index to 1 when degIdx <= 6
    degSubstr = trial(max([degIdx, 7]) - 6 : degIdx);
    % NOTE: assumes angle digits precede 'deg' by at most 5 characters
    digitInds = regexp(degSubstr, '\d');
    if ~isempty(digitInds)
        % extracting only digit chars drops the decimal point from the value
        numVal        = str2double(degSubstr(digitInds));
        firstDigitPos = digitInds(1);
        lastDigitPos  = digitInds(end);
        if firstDigitPos ~= lastDigitPos
            dotInds = regexp(degSubstr, '\.');
            % Check that digit and dot positions form a consecutive
            % sequence with no gaps, as expected for a numeric literal
            sortedInds = sort([digitInds dotInds], 'ascend');
            if any((sortedInds - firstDigitPos - ...
                    (0:length(sortedInds) - 1)) ~= 0)
                failRead = true;
            end
            if ~isempty(dotInds)
                dotInds    = dotInds(1);
                decimalPos = lastDigitPos - dotInds;
                numVal     = numVal / 10^decimalPos;
            end
        end
        if firstDigitPos > 1 && degSubstr(firstDigitPos - 1) == '-'
            angleSign = -1;  % minus sign in description overrides keyword
        end
        ang = numVal * angleSign;
    else  % no digits found before 'deg'
        failRead = true;
    end
    if failRead
        prompt = ['What angle (in degrees) was the study run at (' ...
            trial '): ' trialData.type '?   '];
        ang = input(prompt);
    end
else
    ang = 0;
end

end

