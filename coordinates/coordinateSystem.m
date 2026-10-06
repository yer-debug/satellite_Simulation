function geom = coordinateSystem(position, options)
%COORDINATESYSTEM  Geometry of the Cartesian / cylindrical / spherical construction.
%
%   geom = coordinateSystem(position) returns every point, line, arc and unit
%   vector needed to draw how one position P = [x; y; z] is described in the
%   three coordinate systems:
%
%       Cartesian    (x, y, z)        projections onto the three axes
%       Cylindrical  (rho, phi, z)    P' = [x; y; 0] is P dropped onto the XY plane
%       Spherical    (r, theta, phi)  theta is the angle from +Z down to P
%
%   Relationships made visible by the construction:
%       rho = r sin(theta)      z = r cos(theta)      phi is shared
%
%   Name-value options
%       ArcRadiusFraction  arc radius as a fraction of rho (phi) or r (theta), default 0.30
%       ArcPoints          samples per arc, default 48
%
%   Returned fields (all columns are 3x1, polylines are 3xN)
%       position, projection, rho, phi, z, r, theta, declination
%       rhoLine     origin -> P'          (cylindrical radius)
%       zLine       P' -> P               (cylindrical height)
%       azimuthArc  +X axis -> P' direction, in the XY plane
%       polarArc    +Z axis -> P direction, in the vertical plane through P
%       labelPosition  struct: rho, z, r, phi, theta anchor points for text
%       basis       struct with .spherical (er, etheta, ephi) and
%                   .cylindrical (erho, ephi, ez) unit vectors at P
%
%   See also: cartesianToCylindrical, cartesianToSpherical, updateScene.

arguments
    position (3,1) double {mustBeReal, mustBeFinite}
    options.ArcRadiusFraction (1,1) double {mustBePositive} = 0.30
    options.ArcPoints (1,1) double {mustBeInteger, mustBePositive} = 48
end

x = position(1);
y = position(2);
z = position(3);

[rho, phiC, zc]        = cartesianToCylindrical(x, y, z);
[r, theta, phi, decl]  = cartesianToSpherical(x, y, z);

n = options.ArcPoints;
f = options.ArcRadiusFraction;

geom.position    = position;
geom.projection  = [x; y; 0];
geom.rho         = rho;
geom.phi         = phi;
geom.z           = zc;
geom.r           = r;
geom.theta       = theta;
geom.declination = decl;

geom.rhoLine = [0, x; 0, y; 0, 0];
geom.zLine   = [x, x; y, y; 0, z];

% Azimuth arc: sweeps phi in the XY plane, starting on +X
beta = linspace(0, phi, n);
geom.azimuthArc = (f * rho) * [cos(beta); sin(beta); zeros(1, n)];

% Polar arc: sweeps theta in the vertical plane containing P, starting on +Z
alpha = linspace(0, theta, n);
geom.polarArc = (f * r) * [sin(alpha) * cos(phi); sin(alpha) * sin(phi); cos(alpha)];

% Text anchors, pushed slightly outside the arcs so labels do not overlap them
geom.labelPosition.rho   = 0.5 * [x; y; 0];
geom.labelPosition.z     = [x; y; z/2];
geom.labelPosition.r     = 0.5 * position;
geom.labelPosition.phi   = 1.35 * (f * rho) * [cos(phi/2); sin(phi/2); 0];
geom.labelPosition.theta = 1.35 * (f * r) * [sin(theta/2) * cos(phi); ...
                                             sin(theta/2) * sin(phi); ...
                                             cos(theta/2)];

% Local orthonormal bases at P
geom.basis.spherical.er     = [sin(theta)*cos(phi);  sin(theta)*sin(phi);  cos(theta)];
geom.basis.spherical.etheta = [cos(theta)*cos(phi);  cos(theta)*sin(phi); -sin(theta)];
geom.basis.spherical.ephi   = [-sin(phi); cos(phi); 0];
geom.basis.cylindrical.erho = [cos(phiC); sin(phiC); 0];
geom.basis.cylindrical.ephi = [-sin(phiC); cos(phiC); 0];
geom.basis.cylindrical.ez   = [0; 0; 1];
end
