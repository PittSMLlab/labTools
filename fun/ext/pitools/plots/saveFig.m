function saveFig(h,dir,fileName,sizeFlag)
set(h,'PaperPositionMode','manual')
if nargin<4 || isempty(sizeFlag)
    set(h,'Units','Normalized','OuterPosition',[0 0 1 1])
end
if ~exist(dir,'dir')
    mkdir(dir)
end
%SAVEFIG Save figure as .fig, .eps, and .png in organised subdirectories.
%
%   Creates fig/, eps/, and png/ subdirectories under dir and writes one
% file per format. EPS export uses OpenGL rendering (rasterised at 600
% DPI), which handles transparency correctly but is not true vector
% output. PNG export renders at 600 DPI with a white background.
%
%   When sizeFlag is provided and non-empty, the caller is responsible
% for setting the figure size before calling saveFig. Otherwise the
% figure is maximised to fill the screen.
%
% Inputs:
%   h        - handle to the figure to save
%   dir      - output directory path (trailing separator optional)
%   fileName - base file name, without extension
%   sizeFlag - (optional) when non-empty, skips auto-maximise
%
% Outputs:
%   None
%
% Toolbox Dependencies: None
%
% See also PRINT, SAVEFIG.

%Save fig:
if ~exist([dir 'fig/'],'dir')
    mkdir([dir 'fig/'])
arguments
    h
    dir      {mustBeTextScalar}
    fileName {mustBeTextScalar}
    sizeFlag = []
end
savefig(h,[dir 'fig/' fileName '.fig'],'compact') ;

%Save eps:
if ~exist([dir 'eps/'],'dir')
    mkdir([dir 'eps/'])
end
%hgexport(h,[dir 'eps/' fileName '.eps'], hgexport('factorystyle'), 'Format', 'eps');
%saveas(h,[dir 'eps/' fileName '.eps'], 'epsc');

%print(h,[dir 'eps/' fileName 'vect.eps'],'-depsc','-painters') %Painters is true vectorial
%Pros of vectorial: light size, no compression needed, can renderize at high resolution at any time.
%Cons: can't handle transparency, bad handling of 3D objects into 2D image (position quantization artifacts).

print(h,[dir 'eps/' fileName '.eps'],'-depsc','-r600','-opengl') %Opengl forces a bitmap (NOT vector graphics).
%Pros of rendered eps: can deal with transparency, which vector eps cannot.
%The image is rendered EXACTLY as it is seen. Vector export does some ugly math that can't guarantee this.
%Cons: Matlab saves the eps in an ugly way that will cause white lines to appear because of antialiasing preferences in most viewers.
%The workaround is to import in gimp and export back again (lines go away).

%print(h,[dir 'eps/' fileName '.tif'],'-dtiff','-r600','-opengl') %Compressed tif

%Save png:
if ~exist([dir 'png/'],'dir')
    mkdir([dir 'png/'])
end
fullName=[dir 'png/' fileName];
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
set(h,'color',[1 1 1]);

%Save svg
% if ~exist([dir 'svg/'],'dir')
%     mkdir([dir 'svg/'])
% end
% saveas(h,[dir 'svg/' fileName '.svg'], 'svg');

end
