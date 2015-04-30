function output=subFileList(input)

subs=input.IDs(:,1);
output={};

for i=1:length(subs)
    output{end+1}=[subs{i} 'params.mat'];
end