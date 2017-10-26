Dagon Demo Application
======================
This is a test application that demonstrates features of [Dagon](https://github.com/gecko0307/dagon) game framework. 

The demo shows how to load static and animated meshes, assign materials and textures, create lights and a particle system, integrate a physics engine ([dmech](https://github.com/gecko0307/dmech) is this case), apply post-processing, render 2D text and much more. It includes a game-ready character controller that can jump, walk up the stairs and interact with ordinary rigid bodies. The demo can be used as a base for a first person shooter.

[![Screenshot1](/screenshots/main-thumb.jpg)](/screenshots/main.jpg)

Prerequisites
-------------
To run the demo, a number of libraries should be installed, namely SDL2 and Freetype. If you don't have them installed system-wide (which is a common case on Windows), you can use the libraries provided [here](https://github.com/gecko0307/dagon/releases/tag/v0.0.2). Currently we provide libraries only for Windows and Linux. Download an archive for your system and place the `lib` folder in your project's working directory. Dagon will automatically detect and try to load them. If there are no local libraries in `lib` directory, it will use system ones.

Binary releases of the demo already include all necessary libraries.

Building
--------
Just use Dub: 

`dub build`

Under Windows you can hide console using `win32` configuration: 

`dub build --config=win32`

Controls
--------
LMB enables mouse look, WASD keys are used to move and strafe, spacebar - to jump.

License
-------
Copyright (c) 2016-2017 Timur Gafarov. Distributed under the Boost Software License, Version 1.0 (see accompanying file COPYING or at http://www.boost.org/LICENSE_1_0.txt).
