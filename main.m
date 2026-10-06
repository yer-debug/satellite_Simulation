function result = main(options)
%MAIN  Run the SPACE_SIMULATION 3-D orbit and coordinate-system visualisation.
%
%   main                       run until the window is closed or Q is pressed
%   main('MaxFrames', 300)     stop after 300 frames (smoke tests, video capture)
%   main('Config', struct('orbit', struct('eccentricity', 0.1, 'inclinationDeg', 98)))
%   result = main(...)         also return the final scene, orbit and state
%
%   Data flow:
%       Earth -> Orbit -> Position vector -> Angles -> Coordinate transforms -> 3-D view
%
%   Keys:  space pause | up/down speed x2 | t trail | c construction
%          b local basis | r restart | q or Esc quit | mouse drag rotates the view
%
%   Requires MATLAB R2019b or newer (arguments blocks, vecnorm).
%
%   See also: simulationConfig, createOrbit, satelliteState, updateScene.

arguments
    options.Config (1,1) struct = struct()
    options.MaxFrames (1,1) double {mustBePositive} = Inf
end

% Make every sub-folder visible for the duration of the run
root = fileparts(mfilename('fullpath'));
folders = genpath(root);
addpath(folders);
pathCleanup = onCleanup(@() rmpath(folders)); %#ok<NASGU>

% ------------------------------------------------------------------ build
cfg   = simulationConfig(options.Config);
scene = setupScene(cfg);
drawAxes(scene.ax, cfg);
earth = createEarth(scene.ax, cfg);
orbit = createOrbit(cfg, scene.ax);
sat   = createSatellite(scene.ax, cfg);

setappdata(scene.fig, 'SimControl', defaultControls());
set(scene.fig, 'KeyPressFcn', @onKeyPress);

writer = [];
if cfg.output.recordVideo
    writer = VideoWriter(cfg.output.videoFile, 'MPEG-4');
    writer.FrameRate = cfg.simulation.frameRate;
    open(writer);
    writerCleanup = onCleanup(@() close(writer)); %#ok<NASGU>
end

% -------------------------------------------------------------------- run
t           = cfg.simulation.startTime;
stepPerFrame = cfg.simulation.timeScale / cfg.simulation.frameRate;
framePeriod  = 1 / cfg.simulation.frameRate;
frame = 0;
state = satelliteState(orbit, t);

try
    while isgraphics(scene.fig) && frame < options.MaxFrames
        tick = tic;
        ctrl = getappdata(scene.fig, 'SimControl');
        if ctrl.quit
            break
        end
        if ctrl.reset
            t = cfg.simulation.startTime;
            clearpoints(scene.overlay.trail);
            ctrl.reset = false;
            setappdata(scene.fig, 'SimControl', ctrl);
        end

        state = satelliteState(orbit, t);
        updateScene(scene, earth, sat, state, ctrl, cfg);
        drawnow;

        if ~isempty(writer)
            writeVideo(writer, getframe(scene.fig));
        end

        if ~ctrl.paused
            t = t + stepPerFrame * ctrl.speed;
        end
        frame = frame + 1;
        pause(max(0, framePeriod - toc(tick)));
    end
catch err
    % Closing the window mid-frame invalidates handles; that is a normal exit.
    if isgraphics(scene.fig)
        rethrow(err);
    end
end

if isgraphics(scene.fig)
    ctrl = getappdata(scene.fig, 'SimControl');
    if ctrl.quit
        close(scene.fig);
    end
end

if nargout > 0
    result = struct('scene', scene, 'orbit', orbit, 'state', state, 'config', cfg);
end
end

% =====================================================================
function ctrl = defaultControls()
ctrl = struct('paused', false, 'speed', 1, 'reset', false, 'quit', false, ...
              'showTrail', true, 'showConstruction', true, 'showBasis', false);
end

function onKeyPress(src, evt)
ctrl = getappdata(src, 'SimControl');
switch evt.Key
    case 'space',     ctrl.paused = ~ctrl.paused;
    case 'uparrow',   ctrl.speed = min(ctrl.speed * 2, 64);
    case 'downarrow', ctrl.speed = max(ctrl.speed / 2, 1/16);
    case 't',         ctrl.showTrail = ~ctrl.showTrail;
    case 'c',         ctrl.showConstruction = ~ctrl.showConstruction;
    case 'b',         ctrl.showBasis = ~ctrl.showBasis;
    case 'r',         ctrl.reset = true;
    case {'q', 'escape'}, ctrl.quit = true;
end
setappdata(src, 'SimControl', ctrl);
end
