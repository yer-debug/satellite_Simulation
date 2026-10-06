function earth = createEarth(ax, cfg)
%CREATEEARTH  Earth sphere with latitude/longitude graticule, parented to a transform.
%
%   earth = createEarth(ax, cfg) draws Earth into the axes AX.
%
%   The sphere, graticule, equator and prime meridian share one hgtransform
%   (earth.transform), so updateScene can spin the whole planet by setting a
%   single matrix. The prime meridian is drawn in a contrasting colour so the
%   rotation is visible even without a texture.
%
%   If cfg.earth.texturePath points to an equirectangular image (e.g. a
%   blue-marble map) it is wrapped onto the sphere; otherwise a plain ocean
%   colour is used.
%
%   See also: updateScene, simulationConfig.

arguments
    ax (1,1) matlab.graphics.axis.Axes
    cfg (1,1) struct
end

R = cfg.earth.radius;
c = cfg.colors;

tf = hgtransform('Parent', ax);

[X, Y, Z] = sphere(cfg.earth.meshResolution);
sph = surface(R*X, R*Y, R*Z, 'Parent', tf, ...
    'EdgeColor', 'none', ...
    'FaceColor', c.ocean, ...
    'FaceLighting', 'gouraud', ...
    'AmbientStrength', 0.40, 'DiffuseStrength', 0.85, ...
    'SpecularStrength', 0.12, 'SpecularExponent', 18, ...
    'HandleVisibility', 'off');

texture = cfg.earth.texturePath;
if ~isempty(texture)
    if isfile(texture)
        img = imread(texture);
        set(sph, 'CData', flipud(img), 'FaceColor', 'texturemap');   % image row 1 = north
    else
        warning('SpaceSim:createEarth:TextureMissing', ...
                'Texture "%s" not found - using the procedural Earth.', texture);
    end
end

% Graticule (slightly above the surface to avoid z-fighting)
Rg   = R * 1.002;
step = cfg.earth.graticuleStepDeg;
lon  = linspace(0, 2*pi, 181);
lat  = linspace(-pi/2, pi/2, 91);
gx = []; gy = []; gz = [];

for latDeg = (-90 + step):step:(90 - step)
    if latDeg == 0, continue; end                 % equator is drawn separately
    la = latDeg * pi/180;
    gx = [gx, Rg*cos(la)*cos(lon), NaN]; %#ok<AGROW>
    gy = [gy, Rg*cos(la)*sin(lon), NaN]; %#ok<AGROW>
    gz = [gz, Rg*sin(la)*ones(size(lon)), NaN]; %#ok<AGROW>
end
for lonDeg = step:step:(360 - step)               % prime meridian (0 deg) is separate
    lo = lonDeg * pi/180;
    gx = [gx, Rg*cos(lat)*cos(lo), NaN]; %#ok<AGROW>
    gy = [gy, Rg*cos(lat)*sin(lo), NaN]; %#ok<AGROW>
    gz = [gz, Rg*sin(lat), NaN]; %#ok<AGROW>
end
faint = 0.45 * c.graticule + 0.55 * c.ocean;     % graticule blended into the ocean colour
earth.graticule = plot3(gx, gy, gz, 'Parent', tf, 'Color', faint, ...
    'LineWidth', 0.6, 'HandleVisibility', 'off');

earth.equator = plot3(Rg*cos(lon), Rg*sin(lon), zeros(size(lon)), 'Parent', tf, ...
    'Color', c.graticule, 'LineWidth', 1.4, 'HandleVisibility', 'off');
earth.primeMeridian = plot3(Rg*cos(lat), zeros(size(lat)), Rg*sin(lat), 'Parent', tf, ...
    'Color', c.meridian, 'LineWidth', 2.0, 'HandleVisibility', 'off');

earth.transform = tf;
earth.surface   = sph;
earth.radius    = R;
end
