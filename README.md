Dagon Demo Application
======================
This is a test application that demonstrates features of [Dagon](https://github.com/gecko0307/dagon) game framework. You can use it as a basis to start your own project.

The demo shows how to create several scenes and run them with a simple menu. Every scene shows some part of Dagon's functionality, or how it can be extended.

[![Screenshot1](/screenshots/demo1.jpg)](/screenshots/demo1.jpg)
[![Screenshot2](/screenshots/demo2.jpg)](/screenshots/demo2.jpg)
[![Screenshot2](/screenshots/demo3.jpg)](/screenshots/demo3.jpg)

Prerequisites
-------------
To run the demo, a number of libraries should be installed, namely SDL2 and Freetype. If you don't have them installed system-wide (which is a common case on Windows), you can use the libraries provided [here](https://github.com/gecko0307/dagon/releases/tag/v0.0.2). Currently we provide libraries only for Windows and Linux. Download an archive for your system and place the `lib` folder in your project's working directory. Dagon will automatically detect and try to load them. If there are no local libraries in `lib` directory, it will use system ones.

License
-------
Copyright (c) 2016-2017 Timur Gafarov. Distributed under the Boost Software License, Version 1.0 (see accompanying file COPYING or at http://www.boost.org/LICENSE_1_0.txt).
