function saveFig(h,dir,fileName)
%saveFig saves figure h as .fig and .png for further reference

set(h,'Units','Normalized','OuterPosition',[0 0 1 1])
fullName=[dir fileName];
if ~exist(dir,'dir')
    mkdir(dir)
end
%print(h, '-painters', '-dpng', '-r900', [fullName '.png']);
saveas(h,[fullName '.fig']) ;
%set(h,'Renderer','opengl');
hgexport(h, [fullName '.png'], hgexport('factorystyle'), 'Format', 'png');

end

