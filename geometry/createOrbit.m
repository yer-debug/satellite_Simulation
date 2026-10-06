function orbit = createOrbit(cfg, ax)
%CREATEORBIT  Keplerian orbit model: path, key points and a propagator.
%
%   orbit = createOrbit(cfg) builds the orbit data (no graphics).
%   orbit = createOrbit(cfg, ax) additionally draws the orbital path and the
%   perigee / apogee / ascending-node markers into the axes AX.
%
%   Returned fields
%       elements    - a, e, i, raan, argPerigee, nu0 (radians, km)
%       p, period, meanMotion, perigeeRadius, apogeeRadius, earthRadius
%       rotation    - 3x3 matrix, perifocal (PQW) -> ECI
%       path        - 3xN positions of one full revolution [km]
%       keyPoints   - struct of 3x1 positions: perigee, apogee, ascendingNode
%       propagate   - handle: [r, v, nu] = orbit.propagate(t), t in seconds
%       graphics    - handles (empty struct when no axes were supplied)
%
%   Propagation is two-body (no perturbations): the mean anomaly advances
%   linearly in time and Kepler's equation is solved with Newton's method.
%
%   See also: satelliteState, simulationConfig.

arguments
    cfg (1,1) struct
    ax = []
end
if ~isempty(ax) && ~isgraphics(ax, 'axes')
    error('SpaceSim:createOrbit:BadAxes', 'Second argument must be an axes handle.');
end

d2r = pi / 180;
mu  = cfg.earth.mu;
a   = cfg.orbit.semiMajorAxis;
e   = cfg.orbit.eccentricity;
inc = cfg.orbit.inclinationDeg * d2r;
Om  = cfg.orbit.raanDeg        * d2r;
w   = cfg.orbit.argPerigeeDeg  * d2r;
nu0 = cfg.orbit.trueAnomalyDeg * d2r;

if e < 0 || e >= 1
    error('SpaceSim:createOrbit:Eccentricity', 'Only elliptical orbits (0 <= e < 1) are supported.');
end

p = a * (1 - e^2);          % semi-latus rectum
n = sqrt(mu / a^3);         % mean motion [rad/s]

% Perifocal (PQW) -> ECI rotation: Rz(raan) * Rx(inc) * Rz(argPerigee)
cO = cos(Om); sO = sin(Om);
ci = cos(inc); si = sin(inc);
cw = cos(w);  sw = sin(w);
R = [ cO*cw - sO*sw*ci,  -cO*sw - sO*cw*ci,   sO*si;
      sO*cw + cO*sw*ci,  -sO*sw + cO*cw*ci,  -cO*si;
      sw*si,              cw*si,              ci   ];

% Mean anomaly at t = 0 from the requested initial true anomaly
E0 = 2 * atan2(sqrt(1 - e) * sin(nu0/2), sqrt(1 + e) * cos(nu0/2));
M0 = E0 - e * sin(E0);

params = struct('mu', mu, 'e', e, 'p', p, 'n', n, 'M0', M0, 'R', R);

orbit.elements = struct('a', a, 'e', e, 'inclination', inc, 'raan', Om, ...
                        'argPerigee', w, 'nu0', nu0);
orbit.p             = p;
orbit.period        = 2*pi / n;
orbit.meanMotion    = n;
orbit.perigeeRadius = a * (1 - e);
orbit.apogeeRadius  = a * (1 + e);
orbit.earthRadius   = cfg.earth.radius;
orbit.rotation      = R;

% One full revolution, sampled uniformly in true anomaly
nu = linspace(0, 2*pi, cfg.orbit.pathPoints);
orbit.path = positionAtTrueAnomaly(params, nu);

orbit.keyPoints.perigee       = positionAtTrueAnomaly(params, 0);
orbit.keyPoints.apogee        = positionAtTrueAnomaly(params, pi);
orbit.keyPoints.ascendingNode = positionAtTrueAnomaly(params, mod(-w, 2*pi));

orbit.propagate = @(t) propagateKepler(params, t);
orbit.graphics  = struct();

if ~isempty(ax)
    c = cfg.colors;
    kp = orbit.keyPoints;
    orbit.graphics.path = plot3(ax, orbit.path(1,:), orbit.path(2,:), orbit.path(3,:), ...
        'Color', c.orbit, 'LineWidth', 1.2, 'HandleVisibility', 'off');

    names  = {'perigee', 'apogee', 'ascendingNode'};
    labels = {'Perigee', 'Apogee', 'Ascending node'};
    off    = 0.03 * orbit.apogeeRadius;
    for k = 1:numel(names)
        q = kp.(names{k});
        orbit.graphics.(names{k}) = plot3(ax, q(1), q(2), q(3), 'o', ...
            'MarkerSize', 5, 'MarkerFaceColor', c.orbit, 'MarkerEdgeColor', c.background);
        orbit.graphics.([names{k} 'Label']) = text(ax, q(1) + off, q(2) + off, q(3) + off, ...
            labels{k}, 'Color', c.textDim, 'FontSize', 10);
    end
end
end

% =====================================================================
function r = positionAtTrueAnomaly(P, nu)
%POSITIONATTRUEANOMALY  ECI position(s) for true anomaly NU (1xN or scalar).
rad = P.p ./ (1 + P.e * cos(nu));
pqw = [rad .* cos(nu); rad .* sin(nu); zeros(size(nu))];
r   = P.R * pqw;
end

function [rVec, vVec, nu] = propagateKepler(P, t)
%PROPAGATEKEPLER  Two-body state [km, km/s] at time T seconds after epoch.
M  = mod(P.M0 + P.n * t, 2*pi);
E  = solveKepler(M, P.e);
nu = 2 * atan2(sqrt(1 + P.e) * sin(E/2), sqrt(1 - P.e) * cos(E/2));
rad = P.p / (1 + P.e * cos(nu));
rVec = P.R * [rad * cos(nu); rad * sin(nu); 0];
vVec = P.R * (sqrt(P.mu / P.p) * [-sin(nu); P.e + cos(nu); 0]);
end

function E = solveKepler(M, e)
%SOLVEKEPLER  Newton iteration for E - e sin(E) = M.
if e < 0.8
    E = M;
else
    E = pi;
end
for iter = 1:50 %#ok<NASGU>
    dE = (E - e * sin(E) - M) / (1 - e * cos(E));
    E  = E - dE;
    if abs(dE) < 1e-13
        return
    end
end
warning('SpaceSim:createOrbit:KeplerNotConverged', ...
        'Kepler iteration did not converge (M = %.6f, e = %.4f).', M, e);
end
