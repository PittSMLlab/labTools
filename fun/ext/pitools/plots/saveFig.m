function saveFig(h, dir, fileName, sizeFlag)
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

arguments
    h
    dir      {mustBeTextScalar}
    fileName {mustBeTextScalar}
    sizeFlag = []
end

exportResolution = 600;  % DPI for EPS and PNG raster export

%% Configure Figure
% 'auto' causes print to size output from the figure's screen dimensions,
% matching what hgexport produced for raster formats.
set(h, 'PaperPositionMode', 'auto');
if isempty(sizeFlag)
    set(h, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]);
end

%% Create Output Directories
if ~exist(dir, 'dir')
    mkdir(dir);
end
figDir = fullfile(dir, 'fig');
epsDir = fullfile(dir, 'eps');
pngDir = fullfile(dir, 'png');
if ~exist(figDir, 'dir')
    mkdir(figDir);
end
if ~exist(epsDir, 'dir')
    mkdir(epsDir);
end
if ~exist(pngDir, 'dir')
    mkdir(pngDir);
end

%% Save FIG Format
savefig(h, fullfile(figDir, [fileName '.fig']), 'compact');

%% Save EPS Format
% Uses OpenGL rendering (rasterised) rather than painters (true vector).
% OpenGL preserves transparency; painters introduces quantisation
% artefacts when projecting 3-D objects and cannot handle transparency.
print(h, fullfile(epsDir, [fileName '.eps']), ...
    '-depsc', sprintf('-r%d', exportResolution), '-opengl');

%% Save PNG Format
print(h, fullfile(pngDir, [fileName '.png']), ...
    '-dpng', sprintf('-r%d', exportResolution), '-opengl');

end
