function [ ang ] = DetermineTMAngle( trial )
%UNTITLED This function determines what angle a trial was run at based on
%the trial districiption which must contain this information
%  08/2016, CJS, The input trial is the trial description

%There is assuredely a better way to do this, but for right now...
%trial

if iscell(trial)
    trial=char(trial);
end
% (~iscell(regexp(trial, 'deg')) && ~iscell(cell2mat(regexp(trial, 'deg'))))|| ~iscell(regexp(trial, '8.5')) %~isempty(cell2mat(regexp(trial, 'deg'))) || ~isempty(cell2mat(regexp(trial, '8.5'))) 

if ~isempty(findstr(trial, 'deg')) || ~isempty(findstr(trial, '8.5')) %( ~iscell(cell2mat(regexp(trial, 'deg'))))|| ~iscell(cell2mat(regexp(trial, '8.5'))) %~isempty(cell2mat(regexp(trial, 'deg'))) || ~isempty(cell2mat(regexp(trial, '8.5'))) 
    if ~isempty(findstr(trial, '8.5 deg incline')) || ~isempty(findstr(trial, '8.5 deg uphill')) %(~iscell(regexp(trial, '8.5 deg incline')) && ~isempty(cell2mat(regexp(trial, '8.5 deg incline')))) || (~iscell(regexp(trial, '8.5 deg uphill')) && ~isempty(cell2mat(regexp(trial, '8.5 deg uphill')))) %~isempty(cell2mat(regexp(trial, '8.5 deg incline'))) || ~isempty(cell2mat(regexp(trial, '8.5 deg uphill'))) %|| (~isempty(regexp(trial, '8.5 deg'))
        ang=8.5;
    elseif ~isempty(findstr(trial, '8.5 deg decline')) || ~isempty(findstr(trial, '8.5 decline')) || ~isempty(findstr(trial, '8.5 deg downhill')) %(~iscell(regexp(trial, '8.5 deg decline')) ) || (~iscell(regexp(trial, '8.5 deg downhill')) )|| (~iscell(regexp(trial, '8.5 decline'))) % || || 
        %(~iscell(regexp(trial, '8.5 deg decline')) && ~isempty(cell2mat(regexp(trial, '8.5 deg decline')))) || (~iscell(regexp(trial, '8.5 deg downhill')) && ~isempty(cell2mat(regexp(trial, '8.5 deg downhill'))))|| (~iscell(regexp(trial, '8.5 decline')) && ~isempty(cell2mat(regexp(trial, '8.5 decline')))) % || || 
        ang=-8.5;
%     elseif ~isempty(cell2mat(regexp(trial, '5 deg incline')))|| ~isempty(cell2mat(regexp(trial, '5 deg uphill'))) || ~isempty(cell2mat(regexp(trial, '5 deg')))
%         ang=5;
%     elseif ~isempty(cell2mat(regexp(trial, '5 deg decline')))|| ~isempty(cell2mat(regexp(trial, '5 deg downhill')))
%         ang=-5;
    else
        ang=input(['What angle (in degrees) was the study run at ', trial, ': ',trialData.type ,'?   ']);
    end
else
    ang=0;
end

end

