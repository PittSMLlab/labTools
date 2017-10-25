function saveFig(h,dir,fileName,sizeFlag)
%saveFig saves figure h as .fig and .png for further reference

if nargin<4 || isempty(sizeFlag)
set(h,'Units','Normalized','OuterPosition',[0 0 1 1])
end
fullName=[dir fileName];
if ~exist(dir,'dir')
    mkdir(dir)
end

savefig(h,[fullName '.fig'],'compact') ;
hgexport(h, [fullName '.eps'], hgexport('factorystyle'), 'Format', 'eps');

%Workaround for transparent background (on png):
% save the original background color for later use
background = get(h, 'color'); 
% specify transparent background
set(h,'color',[0.8 0.8 0.8]);
% create output file
set(h,'InvertHardCopy','off'); 
%Write it once:
hgexport(h, [fullName '.png'], hgexport('factorystyle'), 'Format', 'png');
% write it back out - setting transparency info
cdata = imread([fullName '.png']);
imwrite(cdata, [fullName '.png'], 'png', 'BitDepth', 16, 'transparency', [0.8 0.8 0.8])%background)

end

