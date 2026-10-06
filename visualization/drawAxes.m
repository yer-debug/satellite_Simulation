function handles = drawAxes(ax, cfg)
%DRAWAXES  Draw and label the inertial X, Y and Z axes (plus equatorial plane and range rings).
%
%   handles = drawAxes(ax, cfg)
%
%   Axis colours follow the usual RGB = XYZ convention. The positive half of
%   each axis is a solid arrow; the negative half is a thin dotted line. The
%   translucent equatorial plane and its range rings give a sense of scale and
%   show where the azimuth angle phi is measured.
%
%   See also: setupScene, simulationConfig.

arguments
    ax (1,1) matlab.graphics.axis.Axes
    cfg (1,1) struct
end

c      = cfg.colors;
apogee = cfg.orbit.semiMajorAxis * (1 + cfg.orbit.eccentricity);
L      = 1.08 * apogee;                  % axis length

dirs   = eye(3);
cols   = {c.axisX, c.axisY, c.axisZ};
names  = {'X', 'Y', 'Z'};
labels = {'X  vernal equinox', 'Y', 'Z  north pole'};
handles = struct();

for k = 1:3
    d = dirs(:, k);
    handles.([names{k} 'Axis']) = quiver3(ax, 0, 0, 0, L*d(1), L*d(2), L*d(3), ...
        'Color', cols{k}, 'LineWidth', 1.6, 'AutoScale', 'off', ...
        'MaxHeadSize', 0.045, 'HandleVisibility', 'off');
    handles.([names{k} 'Negative']) = plot3(ax, [0 -L*d(1)], [0 -L*d(2)], [0 -L*d(3)], ':', ...
        'Color', 0.6 * cols{k} + 0.4 * c.background, 'LineWidth', 1.0, 'HandleVisibility', 'off');
    tip = 1.06 * L * d;
    handles.([names{k} 'Label']) = text(ax, tip(1), tip(2), tip(3), labels{k}, ...
        'Color', cols{k}, 'FontSize', 12, 'FontWeight', 'bold', ...
        'HorizontalAlignment', 'center');
end

if cfg.display.showEquatorialPlane
    ang = linspace(0, 2*pi, 241);
    handles.equatorialPlane = patch('Parent', ax, ...
        'XData', L*cos(ang), 'YData', L*sin(ang), 'ZData', zeros(size(ang)), ...
        'FaceColor', c.textDim, 'FaceAlpha', 0.06, ...
        'EdgeColor', c.textDim, 'EdgeAlpha', 0.35, 'LineWidth', 0.8, ...
        'FaceLighting', 'none', 'HandleVisibility', 'off');

    spacing = cfg.display.ringSpacing;
    k = 1;
    while k * spacing < L
        rr = k * spacing;
        handles.(sprintf('ring%d', k)) = plot3(ax, rr*cos(ang), rr*sin(ang), zeros(size(ang)), ...
            'Color', 0.45 * c.textDim + 0.55 * c.background, 'LineWidth', 0.6, 'HandleVisibility', 'off');
        handles.(sprintf('ringLabel%d', k)) = text(ax, 0, -rr, 0, ...
            sprintf('%s km', addThousands(rr)), 'Color', c.textDim, 'FontSize', 9, ...
            'HorizontalAlignment', 'left', 'VerticalAlignment', 'top');
        k = k + 1;
    end
end
end

function s = addThousands(v)
%ADDTHOUSANDS  10000 -> '10 000' (thin grouping, locale independent).
s = sprintf('%d', round(v));
n = numel(s);
for pos = n-3:-3:1
    s = [s(1:pos) ' ' s(pos+1:end)];
end
end
