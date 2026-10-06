function state = satelliteState(orbit, t)
%SATELLITESTATE  Spacecraft position, velocity and coordinate data at time T.
%
%   state = satelliteState(orbit, t) propagates ORBIT (from createOrbit) to
%   time T [s] and expresses the position in all three coordinate systems.
%
%   Fields
%       time, orbitNumber, trueAnomaly [rad, 0..2*pi)
%       position (3x1 km), velocity (3x1 km/s), speed, angularMomentum (3x1)
%       altitude      - radius minus the mean Earth radius (spherical Earth)
%       cartesian     - x, y, z
%       cylindrical   - rho, phi, z
%       spherical     - r, theta (polar), phi (azimuth), declination
%
%   Coordinates are inertial (ECI), so they do not change when the drawn
%   Earth spins.
%
%   See also: createOrbit, coordinateSystem, updateScene.

arguments
    orbit (1,1) struct
    t (1,1) double {mustBeReal, mustBeFinite}
end

[r, v, nu] = orbit.propagate(t);

[rho, phiC, zc]          = cartesianToCylindrical(r(1), r(2), r(3));
[rs, theta, phiS, decl]  = cartesianToSpherical(r(1), r(2), r(3));

state.time            = t;
state.orbitNumber     = floor(t / orbit.period) + 1;
state.trueAnomaly     = mod(nu, 2*pi);
state.position        = r;
state.velocity        = v;
state.speed           = norm(v);
state.angularMomentum = cross(r, v);
state.altitude        = rs - orbit.earthRadius;

state.cartesian   = struct('x', r(1), 'y', r(2), 'z', r(3));
state.cylindrical = struct('rho', rho, 'phi', phiC, 'z', zc);
state.spherical   = struct('r', rs, 'theta', theta, 'phi', phiS, 'declination', decl);
end
