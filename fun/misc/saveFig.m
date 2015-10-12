function saveFig(h,dir,fileName,sizeFlag)
%saveFig saves figure h as .fig and .png for further reference

if nargin<4 || isempty(sizeFlag)
set(h,'Units','Normalized','OuterPosition',[0 0 1 1])
end
fullName=[dir fileName];
if ~exist(dir,'dir')
    mkdir(dir)
end

%set(h,'Color','None')
%print(h, '-painters', '-dpng', '-r900', [fullName '.png']);
savefig(h,[fullName '.fig'],'compact') ;
hgexport(h, [fullName '.png'], hgexport('factorystyle'), 'Format', 'png');

end

