function [r, theta, phi, declination] = cartesianToSpherical(x, y, z)
%CARTESIANTOSPHERICAL  Cartesian (x, y, z) -> spherical (r, theta, phi).
%
%   [r, theta, phi, declination] = cartesianToSpherical(x, y, z)
%
%   Convention (ISO 80000-2, "physics"):
%       r     = sqrt(x^2 + y^2 + z^2)   radial distance                [0, inf)
%       theta = atan2(rho, z)           polar angle measured from +Z     [0, pi]
%       phi   = atan2(y, x)             azimuth from +X, counter-clockwise [0, 2*pi)
%       declination = pi/2 - theta      angle above the XY plane      [-pi/2, pi/2]
%
%   Relations to cylindrical coordinates:
%       rho = r sin(theta),   z = r cos(theta),   phi is shared.
%
%   Inputs may be scalars or arrays of matching size; angles are radians.
%   At the origin theta and phi are defined as 0 (no NaNs are produced).
%
%   Inverse: x = r sin(theta) cos(phi), y = r sin(theta) sin(phi), z = r cos(theta).
%
%   See also: cartesianToCylindrical, coordinateSystem.

arguments
    x double {mustBeReal}
    y double {mustBeReal}
    z double {mustBeReal}
end

rho   = hypot(x, y);
r     = hypot(rho, z);
theta = atan2(rho, z);      % robust: no acos(z/r) rounding, no 0/0 at the origin
phi   = mod(atan2(y, x), 2*pi);
phi(phi >= 2*pi) = 0;
declination = pi/2 - theta;
end
