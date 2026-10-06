function runChecks()
%RUNCHECKS  Numerical self-checks for SPACE_SIMULATION (no graphics needed).
%
%   Run from MATLAB:   >> cd tests; runChecks
%   Prints one line per check and errors on the first failure.
%
%   Covers: coordinate round trips and edge cases, Kepler propagation
%   (vis-viva energy, angular momentum, periodicity), the geometry returned
%   by coordinateSystem, and configuration validation.

root = fileparts(fileparts(mfilename('fullpath')));
folders = genpath(root);
addpath(folders);
cleanup = onCleanup(@() rmpath(folders)); %#ok<NASGU>

cfg = simulationConfig();

% ---------------------------------------------------- 1. coordinate transforms
rng(1);
P = 2e4 * (rand(3, 2000) - 0.5);
x = P(1,:); y = P(2,:); z = P(3,:);

[rho, phi, zc] = cartesianToCylindrical(x, y, z);
assertClose(rho .* cos(phi), x, 1e-9, 'cylindrical -> x');
assertClose(rho .* sin(phi), y, 1e-9, 'cylindrical -> y');
assertClose(zc, z, 0, 'cylindrical z');
assert(all(phi >= 0 & phi < 2*pi), 'cylindrical phi outside [0, 2*pi)');
report('cylindrical round trip');

[r, theta, phiS, decl] = cartesianToSpherical(x, y, z);
assertClose(r .* sin(theta) .* cos(phiS), x, 1e-9, 'spherical -> x');
assertClose(r .* sin(theta) .* sin(phiS), y, 1e-9, 'spherical -> y');
assertClose(r .* cos(theta), z, 1e-9, 'spherical -> z');
assertClose(r .* sin(theta), rho, 1e-9, 'rho = r sin(theta)');
assertClose(phiS, phi, 0, 'shared azimuth');
assertClose(decl, pi/2 - theta, 1e-15, 'declination');
assert(all(theta >= 0 & theta <= pi), 'theta outside [0, pi]');
report('spherical round trip and cylindrical relations');

[r0, t0, p0] = cartesianToSpherical(0, 0, 0);
assert(r0 == 0 && t0 == 0 && p0 == 0, 'origin must give (0, 0, 0)');
[~, tNorth] = cartesianToSpherical(0, 0, 5);
[~, tSouth] = cartesianToSpherical(0, 0, -5);
assertClose([tNorth tSouth], [0 pi], 1e-15, 'poles');
[~, ~, pNegX] = cartesianToSpherical(-3, 0, 0);
assertClose(pNegX, pi, 1e-15, 'negative X azimuth');
[~, pTiny] = cartesianToCylindrical(1, -1e-18, 0);
assert(pTiny >= 0 && pTiny < 2*pi, 'wrap guard for tiny negative y');
report('edge cases: origin, poles, -X axis, wrap guard');

% --------------------------------------------------------- 2. orbit propagation
orbit = createOrbit(cfg);
mu = cfg.earth.mu;
a  = cfg.orbit.semiMajorAxis;
hExpected = sqrt(mu * orbit.p);

for t = linspace(0, 2 * orbit.period, 41)
    s = satelliteState(orbit, t);
    rr = norm(s.position);
    assertClose(s.speed^2, mu * (2/rr - 1/a), 1e-9, 'vis-viva');
    assertClose(norm(s.angularMomentum), hExpected, 1e-9, 'angular momentum');
    assert(rr >= orbit.perigeeRadius - 1e-6 && rr <= orbit.apogeeRadius + 1e-6, ...
           'radius outside [perigee, apogee]');
    assert(s.altitude > 0, 'spacecraft below the surface');
end
report('vis-viva energy, angular momentum, radius bounds over two orbits');

s0 = satelliteState(orbit, 0);
s1 = satelliteState(orbit, orbit.period);
assertClose(s1.position, s0.position, 1e-6, 'periodicity (position)');
assertClose(s1.velocity, s0.velocity, 1e-9, 'periodicity (velocity)');
assertClose(s0.position, orbit.keyPoints.perigee, 1e-9, 't = 0 at perigee for nu0 = 0');
sApo = satelliteState(orbit, orbit.period / 2);
assertClose(sApo.position, orbit.keyPoints.apogee, 1e-6, 'half period at apogee');
assertClose(orbit.keyPoints.ascendingNode(3), 0, 1e-9, 'ascending node lies in the XY plane');
report('periodicity, perigee at t = 0, apogee at T/2, node in equatorial plane');

hiE = createOrbit(simulationConfig(struct('orbit', struct('eccentricity', 0.95, 'semiMajorAxis', 200000))));
sHi = satelliteState(hiE, 0.37 * hiE.period);
assertClose(sHi.speed^2, mu * (2/norm(sHi.position) - 1/200000), 1e-8, 'vis-viva at e = 0.95');
report('high-eccentricity Kepler solve (e = 0.95)');

% ----------------------------------------------------- 3. coordinate geometry
g = coordinateSystem(s0.position);
assertClose(g.rho, g.r * sin(g.theta), 1e-9, 'geom rho');
assertClose(g.z,   g.r * cos(g.theta), 1e-9, 'geom z');
assertClose(g.rhoLine(:,2), g.projection, 0, 'rhoLine end = projection');
assertClose(g.zLine(:,2), s0.position, 0, 'zLine end = position');
assertClose(vecnorm(g.polarArc), (0.30 * g.r) * ones(1, size(g.polarArc, 2)), 1e-9, 'polar arc radius');
assertClose(g.polarArc(:, end), 0.30 * s0.position, 1e-9, 'polar arc ends on r');
assertClose(g.azimuthArc(:, end), 0.30 * g.projection, 1e-9, 'azimuth arc ends on P''');

B = [g.basis.spherical.er, g.basis.spherical.etheta, g.basis.spherical.ephi];
assertClose(B' * B, eye(3), 1e-12, 'spherical basis orthonormal');
assertClose(det(B), 1, 1e-12, 'spherical basis right-handed');
assertClose(g.basis.spherical.er, s0.position / norm(s0.position), 1e-12, 'e_r along r');
Cb = [g.basis.cylindrical.erho, g.basis.cylindrical.ephi, g.basis.cylindrical.ez];
assertClose(Cb' * Cb, eye(3), 1e-12, 'cylindrical basis orthonormal');
assertClose(det(Cb), 1, 1e-12, 'cylindrical basis right-handed');
report('construction geometry and local bases');

% ------------------------------------------------------ 4. config validation
assertThrows(@() simulationConfig(struct('orbit', struct('eccentricity', 1.2))), 'SpaceSim:config:Eccentricity');
assertThrows(@() simulationConfig(struct('orbit', struct('semiMajorAxis', 7000, 'eccentricity', 0.2))), 'SpaceSim:config:Perigee');
assertThrows(@() simulationConfig(struct('orbit', struct('eccentrcity', 0.1))), 'SpaceSim:config:UnknownField');
report('configuration validation');

fprintf('\nAll checks passed.\n');
end

% =====================================================================
function assertClose(actual, expected, tol, label)
err = max(abs(actual(:) - expected(:)) ./ max(1, abs(expected(:))));
if err > tol
    error('Check failed (%s): relative error %.3g exceeds %.3g.', label, err, tol);
end
end

function assertThrows(fn, id)
try
    fn();
catch err
    if strcmp(err.identifier, id), return; end
    error('Expected error "%s" but got "%s".', id, err.identifier);
end
error('Expected error "%s" but nothing was thrown.', id);
end

function report(label)
fprintf('  ok  %s\n', label);
end
