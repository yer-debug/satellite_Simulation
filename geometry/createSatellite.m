function sat = createSatellite(ax, cfg)
%CREATESATELLITE  Simple spacecraft model (bus + two solar arrays) in a transform.
%
%   sat = createSatellite(ax, cfg) builds the model at the origin of its own
%   body frame and parents it to an hgtransform (sat.transform) that
%   updateScene moves and orients every frame.
%
%   Body frame: +Z_b points at the nadir (towards Earth), the solar arrays
%   extend along +/-Y_b (the orbit normal), and X_b = Y_b x Z_b is roughly
%   along the velocity. A marker at the origin keeps the spacecraft visible
%   from far away.
%
%   The drawn size is exaggerated (cfg.satellite.size, km); a real spacecraft
%   would be invisible at this scale.
%
%   See also: updateScene, createEarth.

arguments
    ax (1,1) matlab.graphics.axis.Axes
    cfg (1,1) struct
end

L  = cfg.satellite.size;
c  = cfg.colors;
tf = hgtransform('Parent', ax);

bus   = makeBox(tf, [0 0 0],  L*[0.50 0.50 0.60], c.satellite, c.background);
panelR = makeBox(tf, [0  0.85*L 0], L*[0.70 1.20 0.03], c.panel, c.background);
panelL = makeBox(tf, [0 -0.85*L 0], L*[0.70 1.20 0.03], c.panel, c.background);

marker = plot3(0, 0, 0, 'o', 'Parent', tf, 'MarkerSize', 6, ...
    'MarkerFaceColor', c.trail, 'MarkerEdgeColor', c.background, ...
    'HandleVisibility', 'off');

sat.transform = tf;
sat.parts     = [bus, panelR, panelL];
sat.marker    = marker;
sat.size      = L;
end

% =====================================================================
function h = makeBox(parent, center, dims, faceColor, edgeColor)
%MAKEBOX  Axis-aligned box as a single patch object.
d = dims(:).' / 2;
v = center(:).' + [-d(1) -d(2) -d(3);
                    d(1) -d(2) -d(3);
                    d(1)  d(2) -d(3);
                   -d(1)  d(2) -d(3);
                   -d(1) -d(2)  d(3);
                    d(1) -d(2)  d(3);
                    d(1)  d(2)  d(3);
                   -d(1)  d(2)  d(3)];
f = [1 2 3 4; 5 6 7 8; 1 2 6 5; 2 3 7 6; 3 4 8 7; 4 1 5 8];
h = patch('Parent', parent, 'Vertices', v, 'Faces', f, ...
    'FaceColor', faceColor, 'EdgeColor', edgeColor, 'LineWidth', 0.5, ...
    'FaceLighting', 'flat', 'HandleVisibility', 'off');
end
