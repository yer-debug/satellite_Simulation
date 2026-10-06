# SPACE_SIMULATION

A MATLAB 3-D visualisation of a spacecraft in orbit around Earth that links the
equations to the geometry: the **position vector**, its **angles**, and the same
point written in **Cartesian, cylindrical and spherical coordinates**.

```
Earth -> Orbit -> Position vector -> Angles -> Coordinate transformations -> 3-D view
```

## Run

Requires MATLAB R2019b or newer (no toolboxes).

```matlab
cd SPACE_SIMULATION
main                         % interactive, runs until you close the window
main('MaxFrames', 300)       % fixed length
main('Config', struct('orbit', struct('eccentricity', 0.1, 'inclinationDeg', 98)))
cd tests; runChecks          % numerical self-checks, no graphics
```

| Key | Action |
|-----|--------|
| space | pause / resume |
| up / down | double / halve the speed |
| t | show / hide the trail |
| c | show / hide the coordinate construction |
| b | show / hide the local basis vectors (e_r, e_theta, e_phi) |
| r | restart |
| q, Esc | quit |

Dragging with the mouse rotates the view (default 3-D axes interaction).

## What you see

| Object | Meaning |
|--------|---------|
| White arrow | position vector **r** from Earth's centre |
| Green line, rho | distance from the Z axis, `rho = sqrt(x^2 + y^2)` |
| Violet dashed line, z | height above the equatorial plane |
| Blue arc, phi | azimuth from +X, measured counter-clockwise in the XY plane |
| Amber arc, theta | polar angle from +Z down to **r** |
| X / Y / Z axes | red / green / blue; X = vernal equinox, Z = celestial north |
| Gold meridian on Earth | prime meridian; shows the planet spinning under a fixed (inertial) frame |

The panel at the top left prints the live values and the identities
`r sin(theta) = rho` and `r cos(theta) = z`.

## Conventions

* Frame: Earth-centred inertial (ECI), right-handed, units km, s, rad.
* Cylindrical `(rho, phi, z)`: `rho >= 0`, `phi in [0, 2*pi)`.
* Spherical `(r, theta, phi)` (ISO 80000-2): `theta in [0, pi]` is measured **from +Z**,
  `phi` is the same azimuth as in cylindrical coordinates. `declination = pi/2 - theta`.
* The coordinates are inertial, so they do not change when the drawn Earth spins.
  They are not geographic latitude/longitude.
* Orbit: two-body Keplerian propagation (Kepler's equation solved by Newton iteration).
  No drag, J2 or third-body effects. Altitude uses a spherical Earth of radius 6378.137 km.
* The spacecraft is drawn about 1100 km wide so it is visible; its size is not to scale.

## Structure

```
SPACE_SIMULATION/
├── main.m                        run loop, keyboard controls, optional video capture
├── config/simulationConfig.m     all parameters; merges and validates overrides
├── geometry/
│   ├── createEarth.m             sphere, graticule, prime meridian (spinning transform)
│   ├── createSatellite.m         bus + solar arrays, nadir-pointing transform
│   └── createOrbit.m             Keplerian elements -> path, key points, propagator
├── coordinates/
│   ├── cartesianToCylindrical.m  (x,y,z) -> (rho,phi,z)
│   ├── cartesianToSpherical.m    (x,y,z) -> (r,theta,phi,declination)
│   └── coordinateSystem.m        arcs, projections, labels, local bases for the drawing
├── visualization/
│   ├── setupScene.m              figure, axes, light, stars, dynamic overlay objects
│   ├── drawAxes.m                labelled X/Y/Z axes, equatorial plane, range rings
│   └── updateScene.m             per-frame update of every moving object and the read-out
├── data/satelliteState.m         position, velocity and all three coordinate sets at time t
└── tests/runChecks.m             numerical self-checks
```

## Customising

Everything lives in `config/simulationConfig.m`: orbital elements, time scale, colours,
view angle, trail length. To wrap a real Earth map around the sphere set
`earth.texturePath` to an equirectangular image. To record a video set
`output.recordVideo = true`.
# satellite_Simulation
# satellite_Simulation
