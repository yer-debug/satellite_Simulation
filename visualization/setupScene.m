function scene = setupScene(cfg)
%SETUPSCENE  Create the figure, 3-D axes, lighting and the dynamic overlay objects.
%
%   scene = setupScene(cfg) returns a struct with
%       fig, ax        figure and axes handles
%       limit          half-width of the scene [km]
%       overlay        pre-allocated graphics that updateScene moves each frame:
%                      position vector, cylindrical / spherical construction,
%                      angle labels, local basis vectors, trail
%       infoPanel      text box showing the live coordinates
%       helpText       key reference along the bottom edge
%
%   Static content (axes, Earth, orbit, spacecraft) is added by drawAxes,
%   createEarth, createOrbit and createSatellite.
%
%   See also: drawAxes, updateScene, main.

arguments
    cfg (1,1) struct
end

c      = cfg.colors;
apogee = cfg.orbit.semiMajorAxis * (1 + cfg.orbit.eccentricity);
lim    = cfg.display.axisLimitFactor * apogee;

fig = figure('Name', 'SPACE_SIMULATION', 'NumberTitle', 'off', ...
    'Color', c.background, 'InvertHardcopy', 'off', ...
    'Units', 'normalized', 'OuterPosition', [0.04 0.05 0.92 0.90]);

ax = axes('Parent', fig, 'Position', [0 0.04 1 0.96], ...
    'Color', c.background, 'NextPlot', 'add', ...
    'XLim', [-lim lim], 'YLim', [-lim lim], 'ZLim', [-lim lim], ...
    'DataAspectRatio', [1 1 1], 'PlotBoxAspectRatio', [1 1 1], ...
    'Projection', 'perspective', 'Clipping', 'off');
view(ax, cfg.display.viewAzimuthDeg, cfg.display.viewElevationDeg);
axis(ax, 'vis3d');
axis(ax, 'off');
hold(ax, 'on');

scene.fig   = fig;
scene.ax    = ax;
scene.limit = lim;

% Sunlight: one directional light fixed in the inertial frame
scene.light = light('Parent', ax, 'Style', 'infinite', 'Position', [1 0.45 0.55], ...
                    'Color', [1.00 0.98 0.93]);

% Background stars on a sphere just inside the scene box (fixed seed -> same sky every run)
stream = RandStream('mt19937ar', 'Seed', 7);
s = randn(stream, 3, cfg.display.starCount);
s = 0.98 * lim * s ./ vecnorm(s);
scene.stars = plot3(ax, s(1,:), s(2,:), s(3,:), '.', ...
    'Color', c.textDim, 'MarkerSize', 3, 'HandleVisibility', 'off');

% ---------------------------------------------------------- dynamic overlay
ov = struct();
ov.trail = animatedline(ax, 'Color', c.trail, 'LineWidth', 1.4, ...
    'MaximumNumPoints', cfg.satellite.trailPoints, 'HandleVisibility', 'off');

ov.positionVector = quiver3(ax, 0, 0, 0, 1, 1, 1, ...
    'Color', c.radius, 'LineWidth', 2.2, 'AutoScale', 'off', ...
    'MaxHeadSize', 0.10, 'HandleVisibility', 'off');

ov.rhoLine = plot3(ax, NaN, NaN, NaN, '-',  'Color', c.rho,   'LineWidth', 2.0, 'HandleVisibility', 'off');
ov.zLine   = plot3(ax, NaN, NaN, NaN, '--', 'Color', c.zDrop, 'LineWidth', 1.6, 'HandleVisibility', 'off');
ov.azimuthArc = plot3(ax, NaN, NaN, NaN, '-', 'Color', c.phi,   'LineWidth', 2.4, 'HandleVisibility', 'off');
ov.polarArc   = plot3(ax, NaN, NaN, NaN, '-', 'Color', c.theta, 'LineWidth', 2.4, 'HandleVisibility', 'off');
ov.projection = plot3(ax, NaN, NaN, NaN, 'o', 'MarkerSize', 5, ...
    'MarkerFaceColor', c.rho, 'MarkerEdgeColor', c.background, 'HandleVisibility', 'off');

fs = 15;
ov.labelRho   = text(ax, 0, 0, 0, '\rho',   'Color', c.rho,    'FontSize', fs, 'Interpreter', 'tex', 'HorizontalAlignment', 'center');
ov.labelZ     = text(ax, 0, 0, 0, 'z',      'Color', c.zDrop,  'FontSize', fs, 'Interpreter', 'tex', 'HorizontalAlignment', 'center');
ov.labelR     = text(ax, 0, 0, 0, 'r',      'Color', c.radius, 'FontSize', fs, 'Interpreter', 'tex', 'HorizontalAlignment', 'center');
ov.labelPhi   = text(ax, 0, 0, 0, '\phi',   'Color', c.phi,    'FontSize', fs, 'Interpreter', 'tex', 'HorizontalAlignment', 'center');
ov.labelTheta = text(ax, 0, 0, 0, '\theta', 'Color', c.theta,  'FontSize', fs, 'Interpreter', 'tex', 'HorizontalAlignment', 'center');

% Local spherical basis (e_r, e_theta, e_phi) at the spacecraft
basisColors = {c.radius, c.theta, c.phi};
names = {'basisR', 'basisTheta', 'basisPhi'};
for k = 1:3
    ov.(names{k}) = quiver3(ax, 0, 0, 0, 1, 1, 1, 'Color', basisColors{k}, ...
        'LineWidth', 1.8, 'AutoScale', 'off', 'MaxHeadSize', 0.5, ...
        'Visible', 'off', 'HandleVisibility', 'off');
end
scene.overlay = ov;

% ------------------------------------------------------------- text panels
scene.infoPanel = uicontrol(fig, 'Style', 'text', 'Units', 'normalized', ...
    'Position', [0.012 0.50 0.27 0.48], 'String', '', ...
    'BackgroundColor', c.background, 'ForegroundColor', c.text, ...
    'HorizontalAlignment', 'left', 'FontName', 'FixedWidth', 'FontSize', 11);

scene.helpText = uicontrol(fig, 'Style', 'text', 'Units', 'normalized', ...
    'Position', [0 0 1 0.035], ...
    'String', 'space pause   up/down speed   t trail   c construction   b local basis   r restart   q quit   mouse drag rotates', ...
    'BackgroundColor', c.background, 'ForegroundColor', c.textDim, ...
    'HorizontalAlignment', 'center', 'FontSize', 10);
end
