Dagon Demo Application
======================
This is a test application that demonstrates features of [Dagon](https://github.com/gecko0307/dagon) game framework. 

The demo shows how to load static and animated meshes, assign materials and textures, create lights, integrate a physics engine ([dmech](https://github.com/gecko0307/dmech) is this case), render 2D text and much more. It includes game-ready character controller and vehicle. The demo can be used as a base for a first person shooter or a racing game.

If you like Dagon, please support its development on [Patreon](https://www.patreon.com/gecko0307) or [Liberapay](https://liberapay.com/gecko0307). You can also make one-time donation via [PayPal](https://www.paypal.me/tgafarov). I appreciate any support. Thanks in advance!

Screenshots (may be not up to date):

[![Screenshot1](/screenshots/car-thumb.jpg)](/screenshots/car.jpg)
[![Screenshot2](/screenshots/characters-thumb.jpg)](/screenshots/characters.jpg)
[![Screenshot3](/screenshots/lights-thumb.jpg)](/screenshots/lights.jpg)

[https://www.youtube.com/watch?v=UhQfMkObTEs](https://www.youtube.com/watch?v=UhQfMkObTEs)

Prerequisites
-------------
To run the demo, a number of libraries should be installed, namely SDL2 and Freetype 2.8.1. We provide libraries for 64-bit Windows.

Building
--------
Just use Dub: 

`dub build`

Under Windows you can hide console using `win32` configuration: 

`dub build --config=win32`

To get the best performance, you can do an optimized build:

`dub build --build=release-nobounds`

We recommend using LDC compiler.

Controls
--------
LMB enables mouse look, WASD keys are used to move and strafe, spacebar - to jump.

Press E to get in the car, RMB to create a light ball. Press arrow keys rotate the sun (change daytime).

While in the car, press W/S to accelerate forward/backward, A/S to steer, E to get out. You can also use a joystick or a driving wheel.

Press Escape or close the window to exit the application.

License
-------
Copyright (c) 2016-2018 Timur Gafarov. Distributed under the Boost Software License, Version 1.0 (see accompanying file COPYING or at http://www.boost.org/LICENSE_1_0.txt).
