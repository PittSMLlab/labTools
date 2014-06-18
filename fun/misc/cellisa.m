function b = cellisa(cell,type)
b=[];
for i=1:length(cell)
    b(i)=isa(cell{i},type);
end

end

