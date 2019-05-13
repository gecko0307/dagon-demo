Dagon Demo Application
======================
This is a test application that demonstrates features of [Dagon](https://github.com/gecko0307/dagon) game framework. 

The demo shows how to load static and animated meshes, create terrain, skydome and particle systems, assign materials and textures, add lights, integrate a physics engine ([dmech](https://github.com/gecko0307/dmech) is this case), render 2D text, create UI and much more. It includes game-ready character controller and vehicle. The demo can be used as a base for a first person shooter or a racing game.

If you like Dagon, please support its development on [Patreon](https://www.patreon.com/gecko0307) or [Liberapay](https://liberapay.com/gecko0307). You can also make one-time donation via [PayPal](https://www.paypal.me/tgafarov). I appreciate any support. Thanks in advance!

[https://www.youtube.com/watch?v=UhQfMkObTEs](https://www.youtube.com/watch?v=UhQfMkObTEs)

[![Screenshot](https://3.bp.blogspot.com/-w5HvSblDmyY/XIPtUKuBX_I/AAAAAAAAD4A/_ff7Ck4u6f42VZK7FoCOc-B4Q6K2LS1nQCLcBGAs/s1600/005.jpg)](https://3.bp.blogspot.com/-w5HvSblDmyY/XIPtUKuBX_I/AAAAAAAAD4A/_ff7Ck4u6f42VZK7FoCOc-B4Q6K2LS1nQCLcBGAs/s1600/005.jpg)

Prerequisites
-------------
To run the demo, a number of libraries should be installed, namely SDL 2.0.8 and Freetype 2.8.1. We provide libraries for 32 and 64-bit Windows. They are automatically deployed when using DUB.

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

Press G to show UI widgets.

Press F1 to switch skydome/HDRI environment.

Press F12 to make a screenshot.

Press Escape or close the window to exit the application.

License
-------
Copyright (c) 2016-2019 Timur Gafarov. Distributed under the Boost Software License, Version 1.0 (see accompanying file COPYING or at http://www.boost.org/LICENSE_1_0.txt).
