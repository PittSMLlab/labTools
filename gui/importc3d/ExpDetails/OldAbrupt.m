%OG study: old subjects adapted abruptly

expDes.group='Old Abrupt';

%condition numbers
for cond = 1:10
    expDes.(['condition' num2str(cond)])=cond;
end
expDes.numofconds=10;  

%condition names
expDes.condName1='OG base';
expDes.condName2='slow base';
expDes.condName3='short split';
expDes.condName4='fast base';
expDes.condName5='TM base';
expDes.condName6='adaptation';
expDes.condName7='catch';
expDes.condName8='re-adaptation';
expDes.condName9='OG post';
expDes.condName10='TM post';

%condition descriptions
expDes.description1='8m walkway for 6 min';
expDes.description2='150 strides at 0.5 m/s';
expDes.description3='10 strides 2:1, 1 m/s and 0.5 m/s';
expDes.description4='150 strides at 1 m/s';
expDes.description5='150 strides at 0.75 m/s';
expDes.description6='150 strides 2:1, 1 m/s and 0.5 m/s';
expDes.description7='10 strides at 0.75 m/s';
expDes.description8='150 strides 2:1, 1 m/s and 0.5 m/s';
expDes.description9='8 m walkway for 6 min';
expDes.description10='150 strides at 0.75 m/s';

%trial numbers for each condition
expDes.trialnum1='1:6';
expDes.trialnum2='7';
expDes.trialnum3='8';
expDes.trialnum4='9';
expDes.trialnum5='10';
expDes.trialnum6='11:14';
expDes.trialnum7='15';
expDes.trialnum8='16 17';
expDes.trialnum9='18:23';
expDes.trialnum10='24:26';

%set trial types
for t=[1 9]
    expDes.(['type' num2str(t)])='OG';
end
for t=[2:8 10]
    expDes.(['type' num2str(t)])='TM';
end
