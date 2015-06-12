function output=subFileList(input)

subs=input.IDs(:,1);
output=cell(1,length(subs));

for i=1:length(subs)
    %output{end+1}=[subs{i} 'params.mat'];
    output{i}=input.IDs{i,9};
end
