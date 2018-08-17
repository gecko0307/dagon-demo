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

import dagon;

import rigidbodycontroller;
import character;
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
        Matrix4x4f normalMatrix = e.invAbsoluteTransformation.transposed;
    
        Mesh mesh = cast(Mesh)e.drawable;
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

    TextureAsset aTexImrodDiffuse;
    TextureAsset aTexImrodNormal;
    
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

    OBJAsset aImrod;
    OBJAsset aCrate;
    
    PackageAsset aCar;
    OBJAsset aCarDisk;
    OBJAsset aCarTyre;
    
    IQMAsset iqm;
    
    Entity eMrfixit;
    Actor actor;
    
    PackageAsset aScene;
    
    ShapeSphere sSphere;

    ShadelessBackend shadelessMatBackend;
    ParticleBackend particleMatBackend;
    
    float sunPitch = -45.0f;
    float sunTurn = 10.0f;
    
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
    
    ParticleSystem psysLeft;
    ParticleSystem psysRight;

    string helpTextFirstPerson = "Press <LMB> to switch mouse look, WASD to move, spacebar to jump, <RMB> to create a light, arrow keys to rotate the sun";
    string helpTextVehicle = "Press W/S to accelerate forward/backward, A/D to steer, E to get out of the car";
    
    TextLine helpText;
    TextLine infoText;
    TextLine messageText;
    
    Entity eMessage;
  
    Color4f[8] lightColors = [
        Color4f(1, 1, 1, 1),
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
    
    GenericMaterialBackend matBackend;

    this(SceneManager smngr)
    {
        super(smngr);
    }

    override void onAssetsRequest()
    {
        aFontDroidSans14 = addFontAsset("data/font/DroidSans.ttf", 14);
        
        aEnvmap = addTextureAsset("data/hdri/the_sky_is_on_fire_1k.hdr");
    
        aTexImrodDiffuse = addTextureAsset("data/textures/imrod-diffuse.png");
        aTexImrodNormal = addTextureAsset("data/textures/imrod-normal.png");
        
        aTexGroundDiffuse = addTextureAsset("data/textures/ground-albedo.png");
        aTexGroundNormal = addTextureAsset("data/textures/ground-normal.png");
        aTexGroundHeight = addTextureAsset("data/textures/ground-height.png");
        aTexGroundRoughness = addTextureAsset("data/textures/ground-roughness.png");
        
        aTexCrateDiffuse = addTextureAsset("data/textures/crate.png");
        
        aTexParticleSmoke = addTextureAsset("data/textures/smoke.png");
        aTexParticleDust = addTextureAsset("data/textures/dust.png");
        aTexParticleDustNormal = addTextureAsset("data/textures/dust-normal.png");
        
        aImrod = addOBJAsset("data/obj/imrod.obj");
        
        aCrate = addOBJAsset("data/obj/crate.obj");
        
        assetManager.mountDirectory("data/iqm");
        iqm = addIQMAsset("data/iqm/mrfixit.iqm");
        
        aScene = addPackageAsset("data/village/village.asset");
        
        aCar = addPackageAsset("data/car/car.asset");
        aCarDisk = addOBJAsset("data/car/ac-cobra-disk.obj");
        aCarTyre = addOBJAsset("data/car/ac-cobra-tyre.obj");
        aTexCarTyreDiffuse = addTextureAsset("data/car/ac-cobra-wheel.png");
        aTexCarTyreNormal = addTextureAsset("data/car/ac-cobra-wheel-normal.png");
        
        aTexColorTable = addTextureAsset("data/colortables/colortable4.png");
        aTexVignette = addTextureAsset("data/vignette.png");
    }

    override void onAllocate()
    {
        super.onAllocate();
        
        // Environment settings
        environment.useSkyColors = true;
        environment.atmosphericFog = true;
        environment.fogStart = 0.0f;
        environment.fogEnd = 10000.0f;
        //environment.environmentMap = aEnvmap.texture;
        //environment.environmentMap.useLinearFiltering = false;
        
        shadowMap.shadowBrightness = 0.1f;
        
        // Camera and view
        auto eCamera = createEntity3D();
        eCamera.position = Vector3f(25.0f, 5.0f, 0.0f);
        fpview = New!FirstPersonView(eventManager, eCamera, assetManager);
        fpview.camera.turn = -90.0f;
        view = fpview;
        
        // Post-processing settings
        hdr.autoExposure = false;
        ssao.enabled = true;
        motionBlur.enabled = true;
        glow.enabled = true;
        glow.brightness = 0.6;
        glow.radius = 5;
        lut.texture = aTexColorTable.texture;
        vignette.texture = aTexVignette.texture;
        lensDistortion.enabled = true;
        lensDistortion.dispersion = 0.1;
        antiAliasing.enabled = true;
        
        // Material backends
        shadelessMatBackend = New!ShadelessBackend(assetManager);
        particleMatBackend = New!ParticleBackend(gbuffer, assetManager);
        
        // Common materials
        auto matDefault = createMaterial();
        matDefault.roughness = 0.9f;
        matDefault.metallic = 0.0f;
        matDefault.culling = false;
        
        auto matImrod = createMaterial();
        matImrod.diffuse = aTexImrodDiffuse.texture;
        matImrod.normal = aTexImrodNormal.texture;
        matImrod.roughness = 0.2f;
        matImrod.metallic = 0.0f;

        auto mGround = createMaterial();
        mGround.diffuse = aTexGroundDiffuse.texture;
        mGround.normal = aTexGroundNormal.texture;
        mGround.height = aTexGroundHeight.texture;
        mGround.roughness = aTexGroundRoughness.texture;
        mGround.parallax = ParallaxSimple;
        
        auto mCrate = createMaterial();
        mCrate.diffuse = aTexCrateDiffuse.texture;
        mCrate.roughness = 0.9f;
        mCrate.metallic = 0.0f;
        
        auto matChrome = createMaterial();
        matChrome.diffuse = Color4f(1.0f, 1.0f, 1.0f, 1.0f);
        matChrome.roughness = 0.1f;
        matChrome.metallic = 1.0f;

        auto matWheel = createMaterial();
        matWheel.diffuse = aTexCarTyreDiffuse.texture;
        matWheel.normal = aTexCarTyreNormal.texture;
        matWheel.roughness = 0.6f;
        matWheel.metallic = 0.0f;
        
        // Sky entity
        eSky = createSky();
        
        // Imrod entity
        /*
        Entity eImrod = createEntity3D();
        eImrod.material = matImrod;
        eImrod.drawable = aImrod.mesh;
        eImrod.position.x = -2.0f;
        eImrod.scaling = Vector3f(0.5, 0.5, 0.5);
        */
        
        // Mr Fixit entity (animated model)
        actor = New!Actor(iqm.model, assetManager);
        eMrfixit = createEntity3D();
        eMrfixit.drawable = actor;
        eMrfixit.material = matDefault;
        eMrfixit.position.x = 8.0f;
        eMrfixit.rotation = rotationQuaternion(Axis.y, degtorad(-90.0f));
        eMrfixit.scaling = Vector3f(0.25, 0.25, 0.25);
        eMrfixit.defaultController.swapZY = true;
        
        // Root entity from aScene
        Entity sceneEntity = addEntity3D(aScene.entity);
        
        // Physics world 
        world = New!PhysicsWorld(assetManager);

        // BVH for castle model to handle collisions
        bvh = entitiesToBVH(entities3D.data);
        haveBVH = true;
        if (bvh)
            world.bvhRoot = bvh.root;
        
        // Ground plane
        RigidBody bGround = world.addStaticBody(Vector3f(0.0f, 0.0f, 0.0f));
        auto gGround = New!GeomBox(world, Vector3f(100.0f, 1.0f, 100.0f));
        world.addShapeComponent(bGround, gGround, Vector3f(0.0f, -1.0f, 0.0f), 1.0f);
        auto eGround = createEntity3D();
        eGround.drawable = New!ShapePlane(200, 200, 100, assetManager);
        eGround.material = mGround;
        eGround.castShadow = false;

        // dmech geometries for dynamic objects
        gLightBall = New!GeomSphere(world, lightBallRadius);
        auto gSphere = New!GeomEllipsoid(world, Vector3f(0.9f, 1.0f, 0.9f));
        sSphere = New!ShapeSphere(1.0f, 24, 16, false, assetManager);
        
        // Character controller
        character = New!CharacterController(world, fpview.camera.position, 80.0f, gSphere, assetManager);
        auto gSensor = New!GeomBox(world, Vector3f(0.5f, 0.5f, 0.5f));
        character.createSensor(gSensor, Vector3f(0.0f, -0.75f, 0.0f));

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
        
        auto gBox = New!GeomBox(world, Vector3f(1.3f, 0.6f, 2.8f));
        auto b = world.addDynamicBody(Vector3f(0, 0, 0), 0.0f);
        b.damping = 0.6f;
        vehicle = New!VehicleController(eCar, b, world);
        eCar.controller = vehicle;
        world.addShapeComponent(b, gBox, Vector3f(0.0f, 0.8f, 0.0f), 1200.0f);
        b.centerOfMass.y = 0.1f; // Artifically lowered center of mass
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
        carViewEnabled = false;
        
        // Smoke particle system with color changer and vortex
        auto mParticlesSmoke = createMaterial(particleMatBackend);
        mParticlesSmoke.diffuse = aTexParticleSmoke.texture;
        mParticlesSmoke.normal = aTexParticleDustNormal.texture;
        //mParticlesSmoke.particleSphericalNormal = true;
        mParticlesSmoke.blending = Transparent;
        mParticlesSmoke.depthWrite = false;
        mParticlesSmoke.energy = 1.0f;
        //mParticlesSmoke.shadeless = true;
        
        Vector3f pos = Vector3f(0, 0, -10);
        auto chimney = aScene.entity("obChimney.entity");
        if (chimney)
            pos = chimney.absolutePosition;
            
        auto eParticlesTest = createEntity3D();
        auto psys = New!ParticleSystem(eParticlesTest, 50);
        psys.material = mParticlesSmoke;
        psys.startColor = Color4f(0.5, 0.5, 0.5, 1);
        psys.endColor = Color4f(0, 0, 0, 0);
        psys.initialDirectionRandomFactor = 0.2f;
        psys.scaleStep = Vector2f(1, 1);
        psys.minInitialSpeed = 5.0f;
        psys.maxInitialSpeed = 10.0f;
        psys.minSize = 0.5f;
        psys.maxSize = 2.0f;
        eParticlesTest.position = pos;
        eParticlesTest.layer = 3;
        eParticlesTest.visible = true;
        
        auto eVortex = createEntity3D();
        eVortex.position = Vector3f(0, 0, -10);
        auto vortex = New!Vortex(eVortex, psys, 1.0f, 1.0f);
        
        // Dust particle systems
        auto mParticlesDust = createMaterial(particleMatBackend);
        mParticlesDust.diffuse = aTexParticleDust.texture;
        mParticlesDust.blending = Transparent;
        mParticlesDust.depthWrite = false;
        
        auto eParticlesRight = createEntity3D(eCar);
        psysRight = New!ParticleSystem(eParticlesRight, 20);
        eParticlesRight.position = Vector3f(-1.2f, 0, -2.8f);
        psysRight.minLifetime = 0.1f;
        psysRight.maxLifetime = 1.5f;
        psysRight.minSize = 0.5f;
        psysRight.maxSize = 1.0f;
        psysRight.minInitialSpeed = 0.2f;
        psysRight.maxInitialSpeed = 0.2f;
        psysRight.scaleStep = Vector2f(1, 1);
        psysRight.material = mParticlesDust;
        eParticlesRight.layer = 3;
        eParticlesRight.visible = true;

        auto eParticlesLeft = createEntity3D(eCar);
        psysLeft = New!ParticleSystem(eParticlesLeft, 20);
        eParticlesLeft.position = Vector3f(1.2f, 0, -2.8f);
        psysLeft.minLifetime = 0.1f;
        psysLeft.maxLifetime = 1.5f;
        psysLeft.minSize = 0.5f;
        psysLeft.maxSize = 1.0f;
        psysLeft.minInitialSpeed = 0.2f;
        psysLeft.maxInitialSpeed = 0.2f;
        psysLeft.scaleStep = Vector2f(1, 1);
        psysLeft.material = mParticlesDust;
        eParticlesLeft.layer = 3;
        eParticlesLeft.visible = true;

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
    }
    
    override void onStart()
    {
        super.onStart();
        actor.play();
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
            SDL_SetRelativeMouseMode(SDL_FALSE);
            exitApplication();
        }
        else if (key == KEY_E)
        {
            if (carViewEnabled)
            {
                view = fpview;
                carViewEnabled = false;
                character.rbody.active = true;
                character.rbody.position = vehicle.rbody.position + vehicle.rbody.orientation.rotate(Vector3f(1.0f, 0.0f, 0.0f).normalized) * 4.0f + Vector3f(0, 3, 0);
                helpText.text = helpTextFirstPerson;
            }
            else if (distance(fpview.cameraPosition, vehicle.rbody.position) <= 4.0f)
            {
                view = carView;
                carViewEnabled = true;
                character.rbody.active = false;
                helpText.text = helpTextVehicle;
            }
        }
        else if (key == KEY_F1)
        {
            if (environment.environmentMap is null)
                environment.environmentMap = aEnvmap.texture;
            else
                environment.environmentMap = null;
        }
    }
    
    override void onMouseButtonDown(int button)
    {
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
            createLightBall(pos, color, 10.0f, lightBallRadius, 5.0f);
        }
    }
    
    Entity createLightBall(Vector3f pos, Color4f color, float energy, float areaRadius, float volumeRadius)
    {
        auto light = createLight(pos, color, energy, volumeRadius, areaRadius);
            
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
        character.update();
    }

    void updateVehicle(double dt)
    {
        float accelerate = 1000.0f;
    
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
        
        if (vehicle.wheels[2].isDrifting) psysLeft.emitting = true;
        else psysLeft.emitting = false;
        if (vehicle.wheels[3].isDrifting) psysRight.emitting = true;
        else psysRight.emitting = false;
        
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
    }
    
    char[100] lightsText;
    
    override void onLogicsUpdate(double dt)
    {
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

        // Update infoText with some debug info
        float speed = vehicle.speed * 3.6f;
        uint n = sprintf(lightsText.ptr, 
            "FPS: %u | visible lights: %u | total lights: %u | max visible lights: %u | speed: %f km/h", 
            eventManager.fps, 
            lightManager.currentlyVisibleLights, 
            lightManager.lightSources.length, 
            lightManager.maxNumLights,
            speed);
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
        super(1280, 720, false, "Dagon demo", args);

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
