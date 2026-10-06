function updateScene(scene, earth, sat, state, ctrl, cfg)
%UPDATESCENE  Move every dynamic object to match the spacecraft state.
%
%   updateScene(scene, earth, sat, state, ctrl, cfg)
%
%   Per frame this
%     1. spins the Earth transform (sidereal rate) so the inertial coordinates
%        of the spacecraft stay unchanged while the planet rotates beneath it,
%     2. places and orients the spacecraft (nadir-pointing, arrays along the
%        orbit normal),
%     3. extends the trail and redraws the position vector r,
%     4. rebuilds the cylindrical and spherical construction from
%        coordinateSystem (rho, z, phi arc, theta arc, labels, local basis),
%     5. refreshes the numeric read-out panel.
%
%   CTRL carries the interactive toggles: showTrail, showConstruction,
%   showBasis.
%
%   See also: setupScene, coordinateSystem, satelliteState.

arguments
    scene (1,1) struct
    earth (1,1) struct
    sat   (1,1) struct
    state (1,1) struct
    ctrl  (1,1) struct
    cfg   (1,1) struct
end

ov = scene.overlay;
r  = state.position;

% 1. Earth rotation ------------------------------------------------------
if cfg.earth.rotate
    set(earth.transform, 'Matrix', makehgtform('zrotate', cfg.earth.rotationRate * state.time));
end

% 2. Spacecraft pose -----------------------------------------------------
zb = -r / norm(r);                                   % nadir
yb = state.angularMomentum / norm(state.angularMomentum);   % orbit normal
xb = cross(yb, zb);                                  % ~ velocity direction
pose = eye(4);
pose(1:3, 1:3) = [xb, yb, zb];
pose(1:3, 4)   = r;
set(sat.transform, 'Matrix', pose);

% 3. Trail and position vector -------------------------------------------
addpoints(ov.trail, r(1), r(2), r(3));
set(ov.trail, 'Visible', onOff(ctrl.showTrail));
set(ov.positionVector, 'UData', r(1), 'VData', r(2), 'WData', r(3));

% 4. Coordinate construction ---------------------------------------------
g = coordinateSystem(r, 'ArcRadiusFraction', cfg.display.arcRadiusFraction, ...
                        'ArcPoints', cfg.display.arcPoints);

set(ov.rhoLine, 'XData', g.rhoLine(1,:), 'YData', g.rhoLine(2,:), 'ZData', g.rhoLine(3,:));
set(ov.zLine,   'XData', g.zLine(1,:),   'YData', g.zLine(2,:),   'ZData', g.zLine(3,:));
set(ov.azimuthArc, 'XData', g.azimuthArc(1,:), 'YData', g.azimuthArc(2,:), 'ZData', g.azimuthArc(3,:));
set(ov.polarArc,   'XData', g.polarArc(1,:),   'YData', g.polarArc(2,:),   'ZData', g.polarArc(3,:));
set(ov.projection, 'XData', g.projection(1), 'YData', g.projection(2), 'ZData', g.projection(3));

moveLabel(ov.labelRho,   g.labelPosition.rho);
moveLabel(ov.labelZ,     g.labelPosition.z);
moveLabel(ov.labelR,     g.labelPosition.r);
moveLabel(ov.labelPhi,   g.labelPosition.phi);
moveLabel(ov.labelTheta, g.labelPosition.theta);

construction = [ov.rhoLine, ov.zLine, ov.azimuthArc, ov.polarArc, ov.projection, ...
                ov.labelRho, ov.labelZ, ov.labelPhi, ov.labelTheta];
set(construction, 'Visible', onOff(ctrl.showConstruction));

% Local spherical basis at the spacecraft (length scales with the scene)
len = 0.10 * scene.limit;
basis = {ov.basisR, g.basis.spherical.er; ...
         ov.basisTheta, g.basis.spherical.etheta; ...
         ov.basisPhi, g.basis.spherical.ephi};
for k = 1:size(basis, 1)
    h = basis{k, 1};
    v = len * basis{k, 2};
    set(h, 'XData', r(1), 'YData', r(2), 'ZData', r(3), ...
           'UData', v(1), 'VData', v(2), 'WData', v(3), ...
           'Visible', onOff(ctrl.showBasis));
end

% 5. Read-out panel ------------------------------------------------------
set(scene.infoPanel, 'String', infoLines(state));
end

% =====================================================================
function moveLabel(h, p)
set(h, 'Position', p(:).');
end

function s = onOff(flag)
if flag, s = 'on'; else, s = 'off'; end
end

function lines = infoLines(state)
%INFOLINES  Text for the live read-out; angles shown in degrees.
k  = 180 / pi;
cs = state.cartesian;
cy = state.cylindrical;
sp = state.spherical;
tt = state.time;

lines = { ...
    sprintf('t = %02d:%02d:%02d     orbit %d', floor(tt/3600), floor(mod(tt,3600)/60), floor(mod(tt,60)), state.orbitNumber), ...
    sprintf('true anomaly %7.2f deg', state.trueAnomaly * k), ...
    sprintf('altitude %10.1f km', state.altitude), ...
    sprintf('speed    %10.3f km/s', state.speed), ...
    ' ', ...
    'Cartesian', ...
    sprintf('  x = %10.1f km', cs.x), ...
    sprintf('  y = %10.1f km', cs.y), ...
    sprintf('  z = %10.1f km', cs.z), ...
    ' ', ...
    'Cylindrical', ...
    sprintf('  rho = %10.1f km    = sqrt(x^2+y^2)', cy.rho), ...
    sprintf('  phi = %10.2f deg   = atan2(y,x)', cy.phi * k), ...
    sprintf('  z   = %10.1f km', cy.z), ...
    ' ', ...
    'Spherical', ...
    sprintf('  r     = %10.1f km', sp.r), ...
    sprintf('  theta = %10.2f deg   polar, from +Z', sp.theta * k), ...
    sprintf('  phi   = %10.2f deg   azimuth, from +X', sp.phi * k), ...
    sprintf('  r sin(theta) = %10.1f km = rho', sp.r * sin(sp.theta)), ...
    sprintf('  r cos(theta) = %10.1f km = z',   sp.r * cos(sp.theta))};
end
