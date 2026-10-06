function [rho, phi, zc] = cartesianToCylindrical(x, y, z)
%CARTESIANTOCYLINDRICAL  Cartesian (x, y, z) -> cylindrical (rho, phi, z).
%
%   [rho, phi, zc] = cartesianToCylindrical(x, y, z)
%
%       rho = sqrt(x^2 + y^2)      distance from the Z axis        [0, inf)
%       phi = atan2(y, x)          azimuth from +X, counter-clockwise [0, 2*pi)
%       zc  = z                    height above the XY plane
%
%   Inputs may be scalars or arrays of matching size; angles are radians.
%   On the Z axis (x = y = 0) phi is defined as 0.
%
%   Inverse: x = rho cos(phi), y = rho sin(phi), z = zc.
%
%   See also: cartesianToSpherical, coordinateSystem.

arguments
    x double {mustBeReal}
    y double {mustBeReal}
    z double {mustBeReal}
end

rho = hypot(x, y);
phi = mod(atan2(y, x), 2*pi);
phi(phi >= 2*pi) = 0;       % guard: mod() can round -1e-17 up to exactly 2*pi
zc  = z + zeros(size(rho));
end
