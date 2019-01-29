﻿/*
Copyright (c) 2017-2018 Timur Gafarov

Boost Software License - Version 1.0 - August 17th, 2003
Permission is hereby granted, free of charge, to any person or organization
obtaining a copy of the software and accompanying documentation covered by
this license (the "Software") to use, reproduce, display, distribute,
execute, and transmit the Software, and to prepare derivative works of the
Software, and to permit third-parties to whom the Software is furnished to
do so, all subject to the following:

The copyright notices in the Software and this entire statement, including
the above license grant, this restriction and the following disclaimer,
must be included in all copies of the Software, in whole or in part, and
all derivative works of the Software, unless such copies or derivative
works are solely in the form of machine-executable object code generated by
a source language processor.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
*/

module main;

import std.stdio;
import std.math;
import std.random;
import std.algorithm;
import std.file;

import dagon;

import vehicle;

BVHTree!Triangle meshesToBVH(Mesh[] meshes)
{
    DynamicArray!Triangle tris;

    foreach(mesh; meshes)
    foreach(tri; mesh)
    {
        Triangle tri2 = tri;
        tri2.v[0] = tri.v[0];
        tri2.v[1] = tri.v[1];
        tri2.v[2] = tri.v[2];
        tri2.normal = tri.normal;
        tri2.barycenter = (tri2.v[0] + tri2.v[1] + tri2.v[2]) / 3;
        tris.append(tri2);
    }

    assert(tris.length);
    BVHTree!Triangle bvh = New!(BVHTree!Triangle)(tris, 4);
    tris.free();
    return bvh;
}

void collectEntityTrisRecursive(Entity e, ref DynamicArray!Triangle tris)
{
    if (e.solid && e.drawable)
    {
        e.update(0.0);
        Matrix4x4f normalMatrix = e.invAbsoluteTransformation.transposed;

        Mesh mesh = cast(Mesh)e.drawable;
        if (mesh is null)
        {
            Terrain t = cast(Terrain)e.drawable;
            if (t)
            {
                mesh = t.collisionMesh;
            }
        }

        if (mesh)
        {
            foreach(tri; mesh)
            {
                Vector3f v1 = tri.v[0];
                Vector3f v2 = tri.v[1];
                Vector3f v3 = tri.v[2];
                Vector3f n = tri.normal;

                v1 = v1 * e.absoluteTransformation;
                v2 = v2 * e.absoluteTransformation;
                v3 = v3 * e.absoluteTransformation;
                n = n * normalMatrix;

                Triangle tri2 = tri;
                tri2.v[0] = v1;
                tri2.v[1] = v2;
                tri2.v[2] = v3;
                tri2.normal = n;
                tri2.barycenter = (tri2.v[0] + tri2.v[1] + tri2.v[2]) / 3;
                tris.append(tri2);
            }
        }
    }

    foreach(c; e.children)
        collectEntityTrisRecursive(c, tris);
}

BVHTree!Triangle entitiesToBVH(Entity[] entities)
{
    DynamicArray!Triangle tris;

    foreach(e; entities)
        collectEntityTrisRecursive(e, tris);

    if (tris.length)
    {
        BVHTree!Triangle bvh = New!(BVHTree!Triangle)(tris, 4);
        tris.free();
        return bvh;
    }
    else
        return null;
}

class TestScene: Scene
{
    FontAsset aFontDroidSans14;

    TextureAsset aEnvmap;

    TextureAsset aTexGroundDiffuse;
    TextureAsset aTexGroundNormal;
    TextureAsset aTexGroundHeight;
    TextureAsset aTexGroundRoughness;

    TextureAsset aTexCrateDiffuse;

    TextureAsset aTexParticleSmoke;
    TextureAsset aTexParticleDust;
    TextureAsset aTexParticleDustNormal;

    TextureAsset aTexCarTyreDiffuse;
    TextureAsset aTexCarTyreNormal;

    TextureAsset aTexColorTable;
    TextureAsset aTexVignette;

    TextureAsset aTexDwarf;

    TextureAsset aHeightmap;

    TextureAsset aTexFootprint;

    OBJAsset aCrate;

    PackageAsset aCar;
    OBJAsset aCarDisk;
    OBJAsset aCarTyre;

    IQMAsset iqm;
    Entity eDwarf;
    Actor actor;

    PackageAsset aScene;

    ShapeSphere sSphere;

    LightSource sun;
    float sunPitch = -45.0f;
    float sunTurn = 10.0f;

    Material rayleighSkyMaterial;

    CubemapRenderTarget cubemapRenderTarget;
    Cubemap cubemap;

    FirstPersonView fpview;
    CarView carView;
    bool carViewEnabled = false;

    Entity eSky;

    PhysicsWorld world;
    RigidBody bGround;
    float lightBallRadius = 0.5f;
    Geometry gLightBall;
    CharacterController character;
    VehicleController vehicle;

    BVHTree!Triangle bvh;
    bool haveBVH = false;

    Entity eCar;
    Entity[4] eWheels;
    Entity[4] eTyres;

    Emitter emitterLeft;
    Emitter emitterRight;

    Entity[20] footprints;

    string helpTextFirstPerson = "Press <LMB> to switch mouse look, WASD to move, spacebar to jump, <RMB> to create a light, arrow keys to rotate the sun, G to show/hide UI";
    string helpTextVehicle = "Press W/S to accelerate forward/backward, A/D to steer, E to get out of the car";

    TextLine helpText;
    TextLine infoText;
    TextLine messageText;

    Entity eMessage;

    Color4f[7] lightColors = [
        Color4f(1, 0.1, 0.1, 1),
        Color4f(1, 0.5, 0.1, 1),
        Color4f(1, 1, 0.1, 1),
        Color4f(0.1, 1, 0.1, 1),
        Color4f(0.1, 1, 0.5, 1),
        Color4f(0.1, 1, 1, 1),
        Color4f(0.1, 0.5, 1, 1)
    ];

    bool joystickButtonAPressed;
    bool joystickButtonBPressed;
    
    NuklearGUI gui;
    bool guiVisible = false;

    this(SceneManager smngr)
    {
        super(smngr);
    }

    override void onAssetsRequest()
    {
        aFontDroidSans14 = addFontAsset("data/font/DroidSans.ttf", 14);

        aEnvmap = addTextureAsset("data/hdri/the_sky_is_on_fire_1k.hdr");

        aTexGroundDiffuse = addTextureAsset("data/terrain/desert-albedo.png");
        aTexGroundNormal = addTextureAsset("data/terrain/desert-normal.png");
        aTexGroundHeight = addTextureAsset("data/terrain/desert-height.png");
        aTexGroundRoughness = addTextureAsset("data/terrain/desert-roughness.png");

        aTexCrateDiffuse = addTextureAsset("data/textures/crate.png");

        aTexParticleSmoke = addTextureAsset("data/textures/smoke.png");
        aTexParticleDust = addTextureAsset("data/textures/dust.png");
        aTexParticleDustNormal = addTextureAsset("data/textures/dust-normal.png");

        aCrate = addOBJAsset("data/obj/crate.obj");

        assetManager.mountDirectory("data/iqm");
        iqm = addIQMAsset("data/iqm/dwarf.iqm");

        aScene = addPackageAsset("data/village/village.asset");

        aCar = addPackageAsset("data/car/car.asset");
        aCarDisk = addOBJAsset("data/car/ac-cobra-disk.obj");
        aCarTyre = addOBJAsset("data/car/ac-cobra-tyre.obj");
        aTexCarTyreDiffuse = addTextureAsset("data/car/ac-cobra-wheel.png");
        aTexCarTyreNormal = addTextureAsset("data/car/ac-cobra-wheel-normal.png");

        aTexColorTable = addTextureAsset("data/colortables/filter1.png");
        aTexVignette = addTextureAsset("data/vignette.png");

        aTexDwarf = addTextureAsset("data/iqm/dwarf.jpg");

        aHeightmap = addTextureAsset("data/terrain/heightmap.png");

        aTexFootprint = addTextureAsset("data/textures/footprint.png");
    }

    override void onAllocate()
    {
        super.onAllocate();

        environment.sunEnergy = 20.0f;

        sun = createLightSun(Quaternionf.identity, environment.sunColor, environment.sunEnergy);
        sun.shadow = true;
        mainSun = sun;

        cubemap = New!Cubemap(64, assetManager);
        cubemapRenderTarget = New!CubemapRenderTarget(cubemap.width, assetManager);
        //renderer.renderToCubemap(Vector3f(0, 5, 0), cubemap);
        //cubemap.fromEquirectangularMap(aEnvmap.image, 512);
        //environment.environmentMap = cubemap;

        // Camera and view
        auto eCamera = createEntity3D();
        eCamera.position = Vector3f(25.0f, 5.0f, 0.0f);
        fpview = New!FirstPersonView(eventManager, eCamera, assetManager);
        fpview.camera.turn = -90.0f;
        fpview.mouseSensibility = config.props.mouseSensibility.toFloat;
        view = fpview;

        // Post-processing settings
        renderer.hdr.tonemapper = Tonemapper.ACES;
        renderer.hdr.autoExposure = false;
        renderer.hdr.exposure = 0.3f;
        renderer.ssao.enabled = true;
        renderer.ssao.power = 10.0;
        renderer.motionBlur.enabled = true;
        renderer.motionBlur.shutterSpeed = 1.0 / 60.0;
        renderer.motionBlur.samples = 30;
        renderer.glow.enabled = true;
        renderer.glow.radius = 8;
        renderer.glow.brightness = 0.5;
        //renderer.glow.minLuminanceThreshold = 0.0;
        //renderer.glow.maxLuminanceThreshold = 20.0;
        //renderer.lensDistortion.enabled = true;
        //renderer.lensDistortion.dispersion = 0.2;
        renderer.antiAliasing.enabled = true;
        //renderer.lut.texture = aTexColorTable.texture;

        // Common materials
        auto matDefault = createMaterial();
        matDefault.roughness = 0.9f;
        matDefault.metallic = 0.0f;
        matDefault.culling = false;

        auto mGround = createMaterial();
        mGround.diffuse = aTexGroundDiffuse.texture;
        mGround.normal = aTexGroundNormal.texture;
        mGround.height = aTexGroundHeight.texture;
        mGround.roughness = aTexGroundRoughness.texture;
        mGround.parallax = ParallaxSimple;
        mGround.textureScale = Vector2f(25, 25);

        auto mCrate = createMaterial();
        mCrate.diffuse = aTexCrateDiffuse.texture;
        mCrate.roughness = 0.9f;
        mCrate.metallic = 0.0f;

        auto matChrome = createMaterial();
        matChrome.diffuse = Color4f(1.0f, 1.0f, 1.0f, 1.0f);
        matChrome.roughness = 0.4f;
        matChrome.metallic = 1.0f;

        auto matWheel = createMaterial();
        matWheel.diffuse = aTexCarTyreDiffuse.texture;
        matWheel.normal = aTexCarTyreNormal.texture;
        matWheel.roughness = 0.6f;
        matWheel.metallic = 0.0f;

        // Sky entity
        auto rRayleighShader = New!RayleighShader(assetManager);
        rayleighSkyMaterial = createMaterial(rRayleighShader);
        eSky = createSky(rayleighSkyMaterial);

        // Terrain
        auto eTerrain = createEntity3D();
        //eTerrain.scaling = Vector3f(0.5, 0.25, 0.5);
        auto heightmap = New!ImageHeightmap(aHeightmap.texture.image, 20, assetManager);
        auto terrain = New!Terrain(256, 80, heightmap, assetManager);
        Vector3f size = Vector3f(256, 0, 256) * eTerrain.scaling;
        eTerrain.drawable = terrain;
        //eTerrain.castShadow = false;
        eTerrain.position = Vector3f(-size.x * 0.5, 0, -size.z * 0.5);
        eTerrain.solid = true;
        eTerrain.material = mGround;
        eTerrain.dynamic = false;

        foreach(i; 0..footprints.length)
        {
            auto decal = createDecal();
            decal.position = Vector3f(5, 0, 0);
            decal.scaling = Vector3f(0.3, 2, 0.3);
            decal.drawable = aCrate.mesh;
            decal.material = createDecalMaterial();
            decal.material.diffuse = aTexFootprint.texture;
            decal.material.blending = Transparent;
            decal.material.depthWrite = false;
            decal.visible = false;
            footprints[i] = decal;
        }

        // Root entity from aScene
        Entity sceneEntity = addEntity3D(aScene.entity);

        // Physics world
        world = New!PhysicsWorld(assetManager);

        // BVH for castle model to handle collisions
        bvh = entitiesToBVH(_entities3D.data);
        haveBVH = true;
        if (bvh)
            world.bvhRoot = bvh.root;

        // Ground plane
        RigidBody bGround = world.addStaticBody(Vector3f(0.0f, 0.0f, 0.0f));
        auto gGround = New!GeomBox(world, Vector3f(100.0f, 1.0f, 100.0f));
        world.addShapeComponent(bGround, gGround, Vector3f(0.0f, -2.0f, 0.0f), 1.0f);
        //auto eGround = createEntity3D();
        //eGround.drawable = New!ShapePlane(200, 200, 100, assetManager);
        //eGround.material = mGround;
        //eGround.castShadow = false;

        // dmech geometries for dynamic objects
        gLightBall = New!GeomSphere(world, lightBallRadius);
        auto gSphere = New!GeomEllipsoid(world, Vector3f(0.9f, 1.0f, 0.9f));
        sSphere = New!ShapeSphere(1.0f, 24, 16, false, assetManager);

        // Character controller
        auto eCharacter = createEntity3D();
        eCharacter.position = fpview.camera.position;
        character = New!CharacterController(eCharacter, world, 80.0f, gSphere);
        auto gSensor = New!GeomBox(world, Vector3f(0.5f, 0.5f, 0.5f));
        character.createSensor(gSensor, Vector3f(0.0f, -0.75f, 0.0f));

        decalPositionPrev = eCharacter.position;

        // Crates
        auto gCrate = New!GeomBox(world, Vector3f(0.5f, 0.5f, 0.5f));

        foreach(i; 0..5)
        {
            auto eCrate = createEntity3D();
            eCrate.drawable = aCrate.mesh;
            eCrate.material = mCrate;
            eCrate.position = Vector3f(i * 0.1f, 3.0f + 3.0f * cast(float)i, -5.0f);
            eCrate.scaling = Vector3f(0.5f, 0.5f, 0.5f);
            auto bCrate = world.addDynamicBody(Vector3f(0, 0, 0), 0.0f);
            RigidBodyController rbc = New!RigidBodyController(eCrate, bCrate);
            eCrate.controller = rbc;
            world.addShapeComponent(bCrate, gCrate, Vector3f(0.0f, 0.0f, 0.0f), 30.0f);
        }

        // Car
        eCar = createEntity3D();
        eCar.drawable = aCar.entity;
        eCar.position = Vector3f(30.0f, 5.0f, 0.0f);
        eCar.layer = 2;

        auto gBox = New!GeomBox(world, Vector3f(1.3f, 0.65f, 2.8f));
        auto b = world.addDynamicBody(Vector3f(0, 0, 0), 0.0f);
        b.damping = 0.6f;
        vehicle = New!VehicleController(eCar, b, world);
        eCar.controller = vehicle;
        world.addShapeComponent(b, gBox, Vector3f(0.0f, 0.8f, 0.0f), 1500.0f);
        b.centerOfMass.y = -0.2f; // Artifically lowered center of mass
        b.centerOfMass.z = 0.25f;

        foreach(i, ref w; eWheels)
        {
            w = createEntity3D(eCar);
            w.drawable = aCarDisk.mesh;
            w.material = matChrome;

            eTyres[i] = createEntity3D(w);
            eTyres[i].drawable = aCarTyre.mesh;
            eTyres[i].material = matWheel;
        }

        carView = New!CarView(eventManager, vehicle, assetManager);
        carView.mouseSensibility = config.props.mouseSensibility.toFloat;
        carViewEnabled = false;

        // Smoke particle system with color changer and vortex
        auto mParticlesSmoke = createParticleMaterial();
        mParticlesSmoke.diffuse = aTexParticleSmoke.texture;
        mParticlesSmoke.normal = aTexParticleDustNormal.texture;
        //mParticlesSmoke.particleSphericalNormal = true;
        mParticlesSmoke.blending = Transparent;
        mParticlesSmoke.depthWrite = false;
        mParticlesSmoke.energy = 1.0f;

        Vector3f pos = Vector3f(0, 0, -10);
        auto chimney = aScene.entity("obChimney.entity");
        if (chimney)
            pos = chimney.absolutePosition;

        auto eParticlesTest = createEntity3D();
        auto emitterSmoke = New!Emitter(eParticlesTest, particleSystem, 50);
        emitterSmoke.material = mParticlesSmoke;
        emitterSmoke.startColor = Color4f(0.5, 0.5, 0.5, 1);
        emitterSmoke.endColor = Color4f(0, 0, 0, 0);
        emitterSmoke.initialDirectionRandomFactor = 0.2f;
        emitterSmoke.scaleStep = Vector2f(1, 1);
        emitterSmoke.minInitialSpeed = 5.0f;
        emitterSmoke.maxInitialSpeed = 10.0f;
        emitterSmoke.minSize = 0.5f;
        emitterSmoke.maxSize = 2.0f;
        eParticlesTest.position = pos;
        eParticlesTest.layer = 3;
        eParticlesTest.visible = true;

        auto eVortex = createEntity3D();
        eVortex.position = Vector3f(0, 0, -10);
        auto vortex = New!Vortex(eVortex, particleSystem, 1.0f, 1.0f);

        // Dust particle systems
        auto mParticlesDust = createParticleMaterial();
        mParticlesDust.diffuse = aTexParticleDust.texture;
        mParticlesDust.blending = Transparent;
        mParticlesDust.depthWrite = false;

        auto eParticlesRight = createEntity3D(eCar);
        emitterRight = New!Emitter(eParticlesRight, particleSystem, 20);
        eParticlesRight.position = Vector3f(-1.2f, 0, -2.8f);
        emitterRight.minLifetime = 0.1f;
        emitterRight.maxLifetime = 1.5f;
        emitterRight.minSize = 0.5f;
        emitterRight.maxSize = 1.0f;
        emitterRight.minInitialSpeed = 0.2f;
        emitterRight.maxInitialSpeed = 0.2f;
        emitterRight.scaleStep = Vector2f(1, 1);
        emitterRight.material = mParticlesDust;
        eParticlesRight.castShadow = false;
        eParticlesRight.layer = 3;
        eParticlesRight.visible = true;

        auto eParticlesLeft = createEntity3D(eCar);
        emitterLeft = New!Emitter(eParticlesLeft, particleSystem, 20);
        eParticlesLeft.position = Vector3f(1.2f, 0, -2.8f);
        emitterLeft.minLifetime = 0.1f;
        emitterLeft.maxLifetime = 1.5f;
        emitterLeft.minSize = 0.5f;
        emitterLeft.maxSize = 1.0f;
        emitterLeft.minInitialSpeed = 0.2f;
        emitterLeft.maxInitialSpeed = 0.2f;
        emitterLeft.scaleStep = Vector2f(1, 1);
        emitterLeft.material = mParticlesDust;
        eParticlesLeft.castShadow = false;
        eParticlesLeft.layer = 3;
        eParticlesLeft.visible = true;

        // Dwarf entity (animated model)
        /*
        actor = New!Actor(iqm.model, assetManager);
        eDwarf = createEntity3D();
        eDwarf.drawable = actor;
        auto matDwarf = createMaterial();
        matDwarf.diffuse = aTexDwarf.texture;
        matDwarf.roughness = 0.8f;
        eDwarf.material = matDwarf;
        eDwarf.position.x = 8.0f;
        eDwarf.position.y = 0.3f;
        eDwarf.scaling = Vector3f(0.04, 0.04, 0.04);
        eDwarf.defaultController.swapZY = true;
        */

        // HUD text
        helpText = New!TextLine(aFontDroidSans14.font, helpTextFirstPerson, assetManager);
        helpText.color = Color4f(1.0f, 1.0f, 1.0f, 0.7f);

        auto eText = createEntity2D();
        eText.drawable = helpText;
        eText.position = Vector3f(16.0f, 30.0f, 0.0f);

        infoText = New!TextLine(aFontDroidSans14.font, "0", assetManager);
        infoText.color = Color4f(1.0f, 1.0f, 1.0f, 0.7f);

        auto eText2 = createEntity2D();
        eText2.drawable = infoText;
        eText2.position = Vector3f(16.0f, 60.0f, 0.0f);

        messageText = New!TextLine(aFontDroidSans14.font,
            "Press <E> to get in the car",
            assetManager);
        messageText.color = Color4f(1.0f, 1.0f, 1.0f, 0.0f);

        auto eMessage = createEntity2D();
        eMessage.drawable = messageText;
        eMessage.position = Vector3f(eventManager.windowWidth * 0.5f - messageText.width * 0.5f, eventManager.windowHeight * 0.5f, 0.0f);
        
        gui = New!NuklearGUI(&eventManager, assetManager);
        auto eNuklear = createEntity2D();
        eNuklear.drawable = gui;
    }

    override void onStart()
    {
        super.onStart();
        //actor.play();
    }

    override void onJoystickButtonDown(int button)
    {
        if (button == SDL_CONTROLLER_BUTTON_A)
            joystickButtonAPressed = true;
        else if (button == SDL_CONTROLLER_BUTTON_B)
            joystickButtonBPressed = true;
    }

    override void onJoystickButtonUp(int button)
    {
        if (button == SDL_CONTROLLER_BUTTON_A)
            joystickButtonAPressed = false;
        else if (button == SDL_CONTROLLER_BUTTON_B)
            joystickButtonBPressed = false;
    }

    override void onKeyDown(int key)
    {
        if (key == KEY_ESCAPE)
        {
            exitApplication();
        }
        else if (key == KEY_E)
        {
            if (carViewEnabled)
            {
                view = fpview;
                carView.active = false;
                fpview.active = true;
                carViewEnabled = false;
                character.rbody.active = true;
                character.rbody.position = vehicle.rbody.position + vehicle.rbody.orientation.rotate(Vector3f(1.0f, 0.0f, 0.0f).normalized) * 4.0f + Vector3f(0, 3, 0);
                helpText.text = helpTextFirstPerson;
            }
            else if (distance(fpview.cameraPosition, vehicle.rbody.position) <= 4.0f)
            {
                view = carView;
                fpview.active = false;
                carView.active = true;
                carViewEnabled = true;
                character.rbody.active = false;
                helpText.text = helpTextVehicle;
            }
        }
        else if (key == KEY_F1)
        {
            if (environment.skyMap is null)
            {
                environment.skyMap = aEnvmap.texture;
                eSky.material = defaultSkyMaterial;

                environment.environmentMap = null;
                renderer.renderToCubemap(Vector3f(0, 5, 0), cubemap, cubemapRenderTarget);
                environment.environmentMap = cubemap;
            }
            else
            {
                environment.skyMap = null;
                eSky.material = rayleighSkyMaterial;

                environment.environmentMap = null;
                renderer.renderToCubemap(Vector3f(0, 5, 0), cubemap, cubemapRenderTarget);
                environment.environmentMap = cubemap;
            }
        }
        else if (key == KEY_F12)
        {
            takeScreenshot();
        }
        else if (key == KEY_BACKSPACE && guiVisible)
        {
            gui.inputKeyDown(NK_KEY_BACKSPACE);
        }
    }

    uint numScreenshots = 1;
    char[100] screenshotFilenameBuffer;
    void takeScreenshot()
    {
        string filename;
        do
        {
            uint n = sprintf(screenshotFilenameBuffer.ptr, "screenshot%03x.png", numScreenshots);
            filename = cast(string)screenshotFilenameBuffer[0..n];
            numScreenshots++;
        }
        while(exists(filename));

        sceneManager.application.saveScreenshot(filename);
    }

    override void onMouseButtonDown(int button)
    {
        if (guiVisible)
        {
            gui.inputButtonDown(button);
            // Don't execute rest of this callback if we click on gui element
            if (gui.itemIsAnyActive())
                return;
        }

        // Toggle mouse look / cursor lock
        if (button == MB_LEFT)
        {
            if (!carViewEnabled)
            {
                if (fpview.active)
                    fpview.active = false;
                else
                    fpview.active = true;
            }
            else
            {
                if (carView.active)
                    carView.active = false;
                else
                    carView.active = true;
            }
        }

        // Create a light ball
        if (button == MB_RIGHT && !carViewEnabled)
        {
            Vector3f pos = fpview.camera.position + fpview.camera.characterMatrix.forward * -2.0f + Vector3f(0, 1, 0);
            Color4f color = lightColors[uniform(0, lightColors.length)];
            createLightBall(pos, color, 20.0f, lightBallRadius, 5.0f);
        }
    }
    
    override void onMouseButtonUp(int button)
    {
        if (guiVisible)
        gui.inputButtonUp(button);
    }

    override void onTextInput(dchar unicode)
    {
        if (guiVisible)
            gui.inputUnicode(unicode);
    }

    override void onMouseWheel(int x, int y)
    {
        if (guiVisible)
            gui.inputScroll(x, y);
    }

    Entity createLightBall(Vector3f pos, Color4f color, float energy, float areaRadius, float volumeRadius)
    {
        auto light = createLightSphere(pos, color, energy * 5, volumeRadius, areaRadius);

        if (light)
        {
            auto mLightBall = createMaterial();
            mLightBall.diffuse = color;
            mLightBall.emission = color;
            mLightBall.energy = energy;

            auto eLightBall = createEntity3D();
            eLightBall.drawable = sSphere;
            eLightBall.scaling = Vector3f(areaRadius, areaRadius, areaRadius);
            eLightBall.castShadow = false;
            eLightBall.material = mLightBall;
            eLightBall.position = pos;

            auto bLightBall = world.addDynamicBody(Vector3f(0, 0, 0), 0.0f);
            RigidBodyController rbc = New!RigidBodyController(eLightBall, bLightBall);
            eLightBall.controller = rbc;
            world.addShapeComponent(bLightBall, gLightBall, Vector3f(0.0f, 0.0f, 0.0f), 10.0f);

            LightBehaviour lc = New!LightBehaviour(eLightBall, light);

            return eLightBall;
        }

        return null;
    }
    
    Color4f lightColor = Color4f(1f, 1f, 1f, 1f);
    
    void updateUserInterface()
    { 
        if (!guiVisible) return;
        
        if (gui.begin("Sun", gui.Rect(20, 100, 230, 120), NK_WINDOW_BORDER | NK_WINDOW_MOVABLE | NK_WINDOW_TITLE))
        {
            gui.layoutRowDynamic(30, 1);    
            sunPitch = gui.property("Pitch:", -180f, sunPitch, 0f, 1f, 0.5f);
            sunTurn = gui.property("Turn:", -180f, sunTurn, 180f, 1f, 0.5f);
        }
        gui.end();

        if (gui.begin("Light creator", gui.Rect(20, 270, 230, 325), NK_WINDOW_BORDER | NK_WINDOW_MOVABLE | NK_WINDOW_TITLE))
        {
            gui.layoutRowDynamic(150, 1);
            lightColor = gui.colorPicker(lightColor, NK_RGB);

            gui.layoutRowDynamic(25, 1);
            lightColor.r = gui.property("#R:", 0f, lightColor.r, 1.0f, 0.01f, 0.005f);
            lightColor.g = gui.property("#G:", 0f, lightColor.g, 1.0f, 0.01f, 0.005f);
            lightColor.b = gui.property("#B:", 0f, lightColor.b, 1.0f, 0.01f, 0.005f);

            gui.layoutRowDynamic(25, 1);
            if (gui.buttonLabel("Create"))
            {
                if (!carViewEnabled)
                {
                    Vector3f pos = fpview.camera.position + fpview.camera.characterMatrix.forward * -2.0f + Vector3f(0, 1, 0);
                    createLightBall(pos, lightColor, 20.0f, lightBallRadius, 5.0f);
                }
            }
        }
        gui.end();

        if (gui.begin("Input and Texture", gui.Rect(1000, 100, 230, 200), NK_WINDOW_BORDER | NK_WINDOW_MOVABLE | NK_WINDOW_TITLE | NK_WINDOW_SCALABLE))
        {
            static int len = 4;
            static char[256] buffer = "test";
            gui.layoutRowDynamic(35, 1);
            gui.editString(NK_EDIT_SIMPLE, buffer.ptr, &len, 255, null);

            gui.layoutRowStatic(150, 150, 1);
            gui.image(aTexCrateDiffuse.texture.toNuklearImage);
            gui.layoutRowDynamic(35, 1);
        }
        gui.end();
    }

    // Character control
    void updateCharacter(double dt)
    {
        character.rotation.y = fpview.camera.turn;
        Vector3f forward = fpview.camera.characterMatrix.forward;
        Vector3f right = fpview.camera.characterMatrix.right;
        float speed = 6.0f;
        Vector3f dir = Vector3f(0, 0, 0);
        if (eventManager.keyPressed[KEY_W]) dir += -forward;
        if (eventManager.keyPressed[KEY_S]) dir += forward;
        if (eventManager.keyPressed[KEY_A]) dir += -right;
        if (eventManager.keyPressed[KEY_D]) dir += right;
        character.move(dir.normalized, speed);
        if (eventManager.keyPressed[KEY_SPACE]) character.jump(2.0f);
        character.logicalUpdate();
    }

    float walkDistance = 0.0f;
    Vector3f decalPositionPrev;
    size_t footprintIndex = 0;

    void updateVehicle(double dt)
    {
        float accelerate = 100.0f;

        if (eventManager.keyPressed[KEY_Z])
            vehicle.accelerateForward(accelerate);
        else if (eventManager.keyPressed[KEY_X])
            vehicle.accelerateBackward(accelerate);

        if (carViewEnabled)
        {
            if (eventManager.keyPressed[KEY_W] || joystickButtonBPressed)
                vehicle.accelerateForward(accelerate);
            else if (eventManager.keyPressed[KEY_S] || joystickButtonAPressed)
                vehicle.accelerateBackward(accelerate);
            else
                vehicle.brake = false;

            float steering = min(45.0f * abs(1.0f / max(vehicle.speed, 0.01f)), 5.0f);

            if (eventManager.keyPressed[KEY_A])
                vehicle.steer(-steering);
            else if (eventManager.keyPressed[KEY_D])
                vehicle.steer(steering);
            else if (eventManager.joystickAvailable)
            {
                float jAxis = eventManager.joystickAxis(SDL_CONTROLLER_AXIS_LEFTX);
                vehicle.setSteering(jAxis * 70.0f);
            }
            else
                vehicle.resetSteering();
        }

        if (vehicle.wheels[2].isDrifting) emitterLeft.emitting = true;
        else emitterLeft.emitting = false;
        if (vehicle.wheels[3].isDrifting) emitterRight.emitting = true;
        else emitterRight.emitting = false;

        vehicle.fixedStepUpdate(dt);

        foreach(i, ref w; eWheels)
        {
            auto vWheel = vehicle.wheels[i];
            w.position = vWheel.position;

            if (vehicle.wheels[i].dirCoef > 0.0f)
            {
                w.rotation = rotationQuaternion(Axis.y, degtorad(-vWheel.steeringAngle)) *
                             rotationQuaternion(Axis.x, degtorad(vWheel.roll));
            }
            else
            {
                w.rotation = rotationQuaternion(Axis.y, degtorad(-vWheel.steeringAngle + 180.0f)) *
                             rotationQuaternion(Axis.x, degtorad(-vWheel.roll));
            }
        }

        walkDistance += abs(dot(character.rbody.linearVelocity, character.rbody.transformation.forward)) * dt;
        if (walkDistance >= 1)
        {
            walkDistance = 0.0f;
            // TODO: check if character is on terrain
            showNewFootprint();
        }
    }

    void showNewFootprint()
    {
        auto decal = footprints[footprintIndex];

        Vector3f sideOffset;
        if (footprintIndex % 2)
            sideOffset = fpview.invViewMatrix.right * 0.2f;
        else
            sideOffset = -fpview.invViewMatrix.right * 0.2f;

        decal.position = character.rbody.position - fpview.invViewMatrix.forward * 0.5f + sideOffset;

        decal.rotation = rotationQuaternion!float(Axis.y, -degtorad(fpview.camera.turn));
        decal.visible = true;

        footprintIndex++;
        if (footprintIndex == footprints.length)
            footprintIndex = 0;
    }

    char[100] lightsText;

    bool sunChanged = true;

    override void onKeyUp(int key)
    {
        if (key == KEY_DOWN || key == KEY_UP ||
            key == KEY_LEFT || key == KEY_RIGHT)
            sunChanged = true;
            
        if (key == KEY_G)
            guiVisible = !guiVisible;
        if (key == KEY_BACKSPACE && guiVisible)
            gui.inputKeyUp(NK_KEY_BACKSPACE);
    }

    override void onLogicsUpdate(double dt)
    {
        updateUserInterface();
        
        // Update our character, vehicle and physics
        if (!carViewEnabled)
            updateCharacter(dt);
        updateVehicle(dt);
        world.update(dt);

        // Place camera to character controller position
        fpview.camera.position = character.rbody.position;

        // Sun control
        if (eventManager.keyPressed[KEY_DOWN]) sunPitch += 30.0f * dt;
        if (eventManager.keyPressed[KEY_UP]) sunPitch -= 30.0f * dt;
        if (eventManager.keyPressed[KEY_LEFT]) sunTurn += 30.0f * dt;
        if (eventManager.keyPressed[KEY_RIGHT]) sunTurn -= 30.0f * dt;

        environment.sunRotation =
            rotationQuaternion(Axis.y, degtorad(sunTurn)) *
            rotationQuaternion(Axis.x, degtorad(sunPitch));

        if (sunChanged)
        {
            environment.environmentMap = null;
            renderer.renderToCubemap(Vector3f(0, 5, 0), cubemap, cubemapRenderTarget);
            environment.environmentMap = cubemap;
            sunChanged = false;
        }


        // Update infoText with some debug info
        float speed = vehicle.speed * 3.6f;
        uint n = sprintf(lightsText.ptr, "FPS: %u", eventManager.fps);
        string s = cast(string)lightsText[0..n];
        infoText.setText(s);

        if (!carViewEnabled && distance(fpview.cameraPosition, vehicle.rbody.position) <= 4.0f)
        {
            if (messageText.color.a < 1.0f)
                messageText.color.a += 4.0f * dt;
        }
        else
        {
            if (messageText.color.a > 0.0f)
                messageText.color.a -= 4.0f * dt;
        }
    }

    override void onRelease()
    {
        super.onRelease();

        // If we have created BVH, we should release it
        if (haveBVH)
        {
            if (bvh)
                bvh.free();
            haveBVH = false;
        }
    }
}

class MyApplication: SceneApplication
{
    this(string[] args)
    {
        super("Dagon demo", args);
        TestScene test = New!TestScene(sceneManager);
        sceneManager.addScene(test, "TestScene");
        sceneManager.goToScene("TestScene");
    }
}

void main(string[] args)
{
    writeln("Allocated memory at start: ", allocatedMemory);
    MyApplication app = New!MyApplication(args);
    app.run();
    Delete(app);
    writeln("Allocated memory at end: ", allocatedMemory);
}
