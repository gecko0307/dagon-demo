module fptest;

import std.stdio;
import std.random;

import dagon;

import dmech.world;
import dmech.geometry;
import dmech.rigidbody;
import dmech.bvh;

import rigidbodycontroller;
import character;

BVHTree!Triangle meshBVH(Mesh mesh)
{
    DynamicArray!Triangle tris;

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

class FirstPersonScene: BaseScene3D
{ 
    OBJAsset aBuilding;
    TextureAsset aTexStoneDiffuse;
    TextureAsset aTexStoneNormal;
    TextureAsset aTexStoneHeight;
    TextureAsset aTexStone2Diffuse;
    TextureAsset aTexStone2Normal;
    TextureAsset aTexStone2Height;
    TextureAsset aTexCrateDiffuse;
    
    FirstPersonView fpview;
    
    Framebuffer fb;
    Framebuffer fbAA;
    PostFilterFXAA fxaa;
    PostFilterLensDistortion lens;
        
    Entity eShadowArea;
    ShadowArea sp1;
    ShadowArea sp2;
    ShadowArea sp3;
    ShadowMap sm1;
    ShadowMap sm2;
    ShadowMap sm3;    
    float r = -45.0f;
    float ry = 0.0f;
    
    ClusteredLightManager clm;
    BlinnPhongClusteredBackend bpcb;
    SkyBackend skyb;
    
    FontAsset aFont;

    Entity eSky;

    PhysicsWorld world;
    RigidBody bGround;
    Geometry gGround;
    Geometry gCrate;
    GeomEllipsoid gSphere;
    GeomBox gSensor;
    CharacterController character;
    BVHTree!Triangle bvh;
    bool initializedPhysics = false;

    this(SceneManager smngr)
    {
        super(smngr);
    }

    override void onAssetsRequest()
    {
        aFont = addFontAsset("data/font/DroidSans.ttf", 14);
        
        aBuilding = New!OBJAsset(assetManager);
        addAsset(aBuilding, "data/obj/level.obj");
        
        aTexStoneDiffuse = addTextureAsset("data/textures/stone-albedo.png");
        aTexStoneNormal = addTextureAsset("data/textures/stone-normal.png");
        aTexStoneHeight = addTextureAsset("data/textures/stone-height.png");
        
        aTexStone2Diffuse = addTextureAsset("data/textures/stone2-albedo.png");
        aTexStone2Normal = addTextureAsset("data/textures/stone2-normal.png");
        aTexStone2Height = addTextureAsset("data/textures/stone2-height.png");
        
        aTexCrateDiffuse = addTextureAsset("data/textures/crate.jpg");
    }

    override void onAllocate()
    {
        super.onAllocate();
        
        fpview = New!FirstPersonView(eventManager, Vector3f(10.0f, 1.8f, 0.0f), assetManager);
        fpview.camera.turn = -90.0f;
        view = fpview;
        
        fb = New!Framebuffer(eventManager.windowWidth, eventManager.windowHeight, assetManager);
        fbAA = New!Framebuffer(eventManager.windowWidth, eventManager.windowHeight, assetManager);
        fxaa = New!PostFilterFXAA(fb, assetManager);
        lens = New!PostFilterLensDistortion(fbAA, assetManager);
        
        environment.sunRotation = rotationQuaternion(Axis.x, degtorad(-45.0f));
        
        eShadowArea = createEntity3D();
        eShadowArea.position = Vector3f(0, 5, 3);
        eShadowArea.visible = false;
        sp1 = New!ShadowArea(eShadowArea, view, environment, 10, 10, -100, 100);
        sp2 = New!ShadowArea(eShadowArea, view, environment, 30, 30, -100, 100);
        sp3 = New!ShadowArea(eShadowArea, view, environment, 100, 100, -100, 100);
        sm1 = New!ShadowMap(1024, this, sp1, assetManager);
        sm2 = New!ShadowMap(1024, this, sp2, assetManager);
        sm3 = New!ShadowMap(1024, this, sp3, assetManager);
        
        clm = New!ClusteredLightManager(view, assetManager);
        bpcb = New!BlinnPhongClusteredBackend(clm, assetManager);
        bpcb.shadowMap1 = sm1;
        bpcb.shadowMap2 = sm2;
        bpcb.shadowMap3 = sm3;
        skyb = New!SkyBackend(assetManager);
        
        auto matSky = addMaterial(skyb);
        
        auto matStone = addMaterial(bpcb);
        matStone.diffuse = aTexStoneDiffuse.texture;
        matStone.normal = aTexStoneNormal.texture;
        matStone.height = aTexStoneHeight.texture;
        matStone.roughness = 0.2f;
        
        auto matCrate = addMaterial(bpcb);
        matCrate.diffuse = aTexCrateDiffuse.texture;
        matCrate.roughness = 0.9f;
        
        eSky = createEntity3D();
        eSky.material = matSky;
        eSky.drawable = New!ShapeSphere(100.0f, assetManager);
        eSky.scaling = Vector3f(-1.0f, -1.0f, -1.0f);
        
        auto matGround = addMaterial(bpcb);
        matGround.diffuse = aTexStone2Diffuse.texture;
        matGround.normal = aTexStone2Normal.texture;
        matGround.height = aTexStone2Height.texture;
        matGround.roughness = 0.8f;
        
        world = New!PhysicsWorld();

        bvh = meshBVH(aBuilding.mesh);
        world.bvhRoot = bvh.root;
        
        RigidBody bGround = world.addStaticBody(Vector3f(0.0f, 0.0f, 0.0f));
        gGround = New!GeomBox(Vector3f(100.0f, 0.8f, 100.0f));
        world.addShapeComponent(bGround, gGround, Vector3f(0.0f, 0.0f, 0.0f), 1.0f);
        auto eGround = createEntity3D();
        eGround.drawable = New!ShapePlane(200, 200, 100, assetManager);
        eGround.material = matGround;
        eGround.position.y = 0.8f;
        
        ShapeBox sCrate = New!ShapeBox(1, 1, 1, assetManager);
        gCrate = New!GeomBox(Vector3f(1.0f, 1.0f, 1.0f));

        foreach(i; 0..5)
        {
            auto eCrate = createEntity3D();
            eCrate.drawable = sCrate;
            eCrate.material = matCrate;
            eCrate.position = Vector3f(i * 0.1f, 3.0f + 3.0f * cast(float)i, -5.0f);
            auto bCrate = world.addDynamicBody(Vector3f(0, 0, 0), 0.0f);
            RigidBodyController rbc = New!RigidBodyController(eCrate, bCrate);
            eCrate.controller = rbc;
            world.addShapeComponent(bCrate, gCrate, Vector3f(0.0f, 0.0f, 0.0f), 10.0f);
        }
        
        gSphere = New!GeomEllipsoid(Vector3f(0.9f, 1.0f, 0.9f));
        gSensor = New!GeomBox(Vector3f(0.5f, 0.5f, 0.5f));
        character = New!CharacterController(world, fpview.camera.position, 80.0f, gSphere, assetManager);
        character.createSensor(gSensor, Vector3f(0.0f, -0.75f, 0.0f));

        Entity eBuilding = createEntity3D();
        eBuilding.material = matStone;
        eBuilding.drawable = aBuilding.mesh;
        
        auto text = New!TextLine(aFont.font, "Press <LMB> to switch mouse look, WASD to move, spacebar to jump, <RMB> to create a light, arrow keys to rotate the sun", assetManager);
        text.color = Color4f(1.0f, 1.0f, 1.0f, 1.0f);
        auto eText = createEntity2D();
        eText.drawable = text;
        eText.position = Vector3f(16.0f, eventManager.windowHeight - 30.0f, 0.0f);
        
        initializedPhysics = true;
    }
    
    GenericMaterial addMaterial(GenericMaterialBackend b = null)
    {
        auto m = New!GenericMaterial(assetManager);
        if (b)
            m.backend = b;
        return m;
    }
    
    override void onRelease()
    {
        super.onRelease();
        if (initializedPhysics)
        {
            Delete(world);
            Delete(gGround);
            Delete(gCrate);
            Delete(gSphere);
            Delete(gSensor);
            bvh.free();
            initializedPhysics = false;
        }
    }
    
    override void onStart()
    {
        super.onStart();
    }

    override void onEnd()
    {
        super.onEnd();
        fpview.active = false;
    }
    
    Color4f[9] lightColors = [
        Color4f(1, 1, 1, 1),
        Color4f(1, 0, 0, 1),
        Color4f(1, 0.5, 0, 1),
        Color4f(1, 1, 0, 1),
        Color4f(0, 1, 0, 1),
        Color4f(0, 1, 0.5, 1),
        Color4f(0, 1, 1, 1),
        Color4f(0, 0.5, 1, 1),
        Color4f(0, 0, 1, 1)
    ];

    override void onKeyDown(int key)
    {
        if (key == KEY_ESCAPE)
            sceneManager.goToScene("Menu");
    }
    
    override void onMouseButtonDown(int button)
    {
        if (button == MB_LEFT)
        {
            if (fpview.active)
                fpview.active = false;
            else
                fpview.active = true;
        }

        if (button == MB_RIGHT)
        {
            clm.addLight(fpview.camera.position, lightColors[uniform(0, 9)] * 2.0f, uniform(2.0f, 3.0f));
        }
    }
    
    void controlCharacter(double dt)
    {
        character.rotation.y = fpview.camera.turn;
        Vector3f forward = fpview.camera.characterMatrix.forward;
        Vector3f right = fpview.camera.characterMatrix.right; 
        float speed = 8.0f;
        Vector3f dir = Vector3f(0, 0, 0);
        if (eventManager.keyPressed[KEY_W]) dir += -forward;
        if (eventManager.keyPressed[KEY_S]) dir += forward;
        if (eventManager.keyPressed[KEY_A]) dir += -right;
        if (eventManager.keyPressed[KEY_D]) dir += right;
        character.move(dir.normalized, speed);
        if (eventManager.keyPressed[KEY_SPACE]) character.jump(2.0f);
        character.update();
    }
    
    override void onLogicsUpdate(double dt)
    {  
        controlCharacter(dt);
        world.update(dt);
        fpview.camera.position = character.rbody.position;
        eShadowArea.position = fpview.camera.position;
        
        if (eventManager.keyPressed[KEY_DOWN]) r += 30.0f * dt;
        if (eventManager.keyPressed[KEY_UP]) r -= 30.0f * dt;
        if (eventManager.keyPressed[KEY_LEFT]) ry += 30.0f * dt;
        if (eventManager.keyPressed[KEY_RIGHT]) ry -= 30.0f * dt;

        environment.sunRotation = rotationQuaternion(Axis.y, degtorad(ry)) * rotationQuaternion(Axis.x, degtorad(r));
        environment.update(dt);
        
        eSky.position = fpview.camera.position;
    }
    
    override void onRender()
    {
        eSky.visible = false;
        sm1.render(&rc3d);
        sm2.render(&rc3d);
        sm3.render(&rc3d);
        eSky.visible = true;

        fb.bind();        
        prepareRender();
        rc3d.apply();
        clm.update();
        renderEntities3D(&rc3d);
        fb.unbind();
        
        fbAA.bind();
        prepareRender();
        rc2d.apply();
        fxaa.render();
        fbAA.unbind();
        
        prepareRender();
        rc2d.apply();
        lens.render();
        renderEntities2D(&rc2d);
    }
}
