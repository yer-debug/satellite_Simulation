function cfg = simulationConfig(overrides)
%SIMULATIONCONFIG  Central parameter set for SPACE_SIMULATION.
%
%   cfg = simulationConfig() returns the default configuration.
%
%   cfg = simulationConfig(overrides) merges a (nested) struct of overrides
%   into the defaults. Unknown field names raise an error, so a typo can
%   never silently fall back to a default:
%
%       cfg = simulationConfig(struct('orbit', struct('eccentricity', 0.1)));
%
%   Units: kilometres, seconds, radians - unless a field name ends in
%   "Deg" (degrees). Colours are RGB triplets in [0, 1].
%
%   Frame: Earth-centred inertial (ECI). +X points to the vernal equinox,
%   +Z to the celestial north pole, +Y completes the right-handed set.
%
%   See also: main, createOrbit, setupScene.

arguments
    overrides (1,1) struct = struct()
end

% ------------------------------------------------------------------ Earth
cfg.earth.radius           = 6378.137;      % km, WGS-84 equatorial radius
cfg.earth.mu               = 398600.4418;   % km^3/s^2, gravitational parameter
cfg.earth.rotationRate     = 7.2921159e-5;  % rad/s, sidereal rotation
cfg.earth.rotate           = true;          % spin Earth inside the inertial frame
cfg.earth.meshResolution   = 72;            % sphere faces per direction
cfg.earth.graticuleStepDeg = 30;            % latitude / longitude line spacing
cfg.earth.texturePath      = '';            % optional equirectangular image ('' = procedural)

% ------------------------------------------------------------------ Orbit
% Classical Keplerian elements of a deliberately eccentric, inclined orbit
% so that every angle in the construction is clearly visible.
cfg.orbit.semiMajorAxis  = 15000;   % km
cfg.orbit.eccentricity   = 0.35;    % 0 <= e < 1
cfg.orbit.inclinationDeg = 52;
cfg.orbit.raanDeg        = 40;      % right ascension of the ascending node
cfg.orbit.argPerigeeDeg  = 60;
cfg.orbit.trueAnomalyDeg = 0;       % at t = simulation.startTime
cfg.orbit.pathPoints     = 721;

% ------------------------------------------------------------- Simulation
cfg.simulation.frameRate  = 30;     % frames per second
cfg.simulation.timeScale  = 900;    % simulated seconds per real second
cfg.simulation.startTime  = 0;      % s

% ------------------------------------------------------------- Satellite
cfg.satellite.size        = 1100;   % km, drawn size (exaggerated for visibility)
cfg.satellite.trailPoints = 500;

% --------------------------------------------------------------- Display
cfg.display.axisLimitFactor    = 1.20;  % scene half-width = factor * apogee radius
cfg.display.viewAzimuthDeg     = 125;
cfg.display.viewElevationDeg   = 24;
cfg.display.showEquatorialPlane = true;
cfg.display.ringSpacing        = 10000; % km between range rings on the equatorial plane
cfg.display.arcRadiusFraction  = 0.30;  % angle arcs as a fraction of rho / r
cfg.display.arcPoints          = 48;
cfg.display.starCount          = 350;

% ---------------------------------------------------------------- Colours
cfg.colors.background = hexColor('#070B14');
cfg.colors.text       = hexColor('#D5DCE8');
cfg.colors.textDim    = hexColor('#7D889A');
cfg.colors.ocean      = hexColor('#1D4E7A');
cfg.colors.graticule  = hexColor('#7FA6C8');
cfg.colors.meridian   = hexColor('#E8C468');  % prime meridian: makes Earth's spin visible
cfg.colors.orbit      = hexColor('#8D99AB');
cfg.colors.trail      = hexColor('#F2F4F8');
cfg.colors.satellite  = hexColor('#C9D3E0');
cfg.colors.panel      = hexColor('#2F6BFF');
cfg.colors.axisX      = hexColor('#E5707A');  % X = red, Y = green, Z = blue
cfg.colors.axisY      = hexColor('#7BCB8B');
cfg.colors.axisZ      = hexColor('#6AA9F0');
cfg.colors.radius     = hexColor('#FFFFFF');  % position vector r
cfg.colors.rho        = hexColor('#4FD1B0');  % cylindrical radius rho
cfg.colors.zDrop      = hexColor('#B39DDB');  % height z
cfg.colors.phi        = hexColor('#4FC3F7');  % azimuth angle phi
cfg.colors.theta      = hexColor('#FFB74D');  % polar angle theta

% ---------------------------------------------------------------- Output
cfg.output.recordVideo = false;
cfg.output.videoFile   = 'space_simulation.mp4';

cfg = mergeStruct(cfg, overrides);
validateConfig(cfg);
end

% =====================================================================
function base = mergeStruct(base, over)
%MERGESTRUCT  Recursively merge OVER into BASE; unknown fields are errors.
names = fieldnames(over);
for k = 1:numel(names)
    f = names{k};
    if ~isfield(base, f)
        error('SpaceSim:config:UnknownField', ...
              'Unknown configuration field "%s".', f);
    end
    if isstruct(over.(f)) && isstruct(base.(f))
        base.(f) = mergeStruct(base.(f), over.(f));
    else
        base.(f) = over.(f);
    end
end
end

function validateConfig(cfg)
%VALIDATECONFIG  Reject physically or numerically impossible settings.
e  = cfg.orbit.eccentricity;
a  = cfg.orbit.semiMajorAxis;
Re = cfg.earth.radius;

if ~(isscalar(e) && e >= 0 && e < 1)
    error('SpaceSim:config:Eccentricity', ...
          'orbit.eccentricity must satisfy 0 <= e < 1 (elliptical orbits only).');
end
if ~(isscalar(a) && a > 0)
    error('SpaceSim:config:SemiMajorAxis', 'orbit.semiMajorAxis must be positive.');
end
if a * (1 - e) <= Re
    error('SpaceSim:config:Perigee', ...
          'Perigee radius %.1f km is not above the Earth radius %.1f km.', ...
          a * (1 - e), Re);
end
if cfg.simulation.frameRate <= 0 || cfg.simulation.timeScale <= 0
    error('SpaceSim:config:Timing', ...
          'simulation.frameRate and simulation.timeScale must be positive.');
end
if cfg.orbit.pathPoints < 16
    error('SpaceSim:config:PathPoints', 'orbit.pathPoints must be at least 16.');
end
end

function rgb = hexColor(hex)
%HEXCOLOR  '#RRGGBB' -> [r g b] in [0, 1].
rgb = sscanf(hex(2:7), '%2x').' / 255;
end
