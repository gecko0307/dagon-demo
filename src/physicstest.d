module physicstest;

import std.stdio;

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

class PhysicsScene: BaseScene3D
{ 
    FirstPersonView fpview;
    
    NonPBRBackend nonPBRBackend;
    Entity eShadowArea;
    ShadowArea sp1;
    ShadowArea sp2;
    ShadowArea sp3;
    ShadowMap sm1;
    ShadowMap sm2;
    ShadowMap sm3;

    PhysicsWorld world;

    RigidBody bGround;
    Geometry gGround;

    Geometry gBox;

    GeomEllipsoid gSphere;
    GeomBox gSensor;
    CharacterController character;

    TextureAsset aTexCrate;
    TextureAsset aTexTiles;
    OBJAsset aLevel;
    FontAsset aFont;

    BVHTree!Triangle bvh;

    bool initializedPhysics = false;

    this(SceneManager smngr)
    {
        super(smngr);
    }

    override void onAssetsRequest()
    {
        aFont = addFontAsset("data/font/DroidSans.ttf", 14);

        aTexCrate = addTextureAsset("data/textures/crate.jpg");
        aTexTiles = addTextureAsset("data/textures/tiles.jpg");

        aLevel = New!OBJAsset(assetManager);
        addAsset(aLevel, "data/obj/level.obj");
    }

    override void onAllocate()
    {
        super.onAllocate();
        
        fpview = New!FirstPersonView(eventManager, Vector3f(10.0f, 1.8f, 0.0f), assetManager);
        fpview.camera.turn = -90.0f;
        view = fpview;
        
        eShadowArea = createEntity3D();
        eShadowArea.position = Vector3f(0, 5, 3);
        eShadowArea.rotation = rotationQuaternion(Axis.x, degtorad(-45.0f));
        eShadowArea.visible = false;
        
        sp1 = New!ShadowArea(eShadowArea, view, 10, 10, -10, 10);
        sp2 = New!ShadowArea(eShadowArea, view, 30, 30, -30, 30);
        sp3 = New!ShadowArea(eShadowArea, view, 100, 100, -100, 100);
        sm1 = New!ShadowMap(1024, this, sp1, assetManager);
        sm2 = New!ShadowMap(1024, this, sp2, assetManager);
        sm3 = New!ShadowMap(1024, this, sp3, assetManager);
        
        nonPBRBackend = New!NonPBRBackend(assetManager);
        nonPBRBackend.shadowMap1 = sm1;
        nonPBRBackend.shadowMap2 = sm2;
        nonPBRBackend.shadowMap3 = sm3;

        addPointLight(Vector3f(0, 5, 3), Color4f(0.0, 0.5, 1.0, 1.0));
        addPointLight(Vector3f(0, 5, -3), Color4f(0.0, 0.5, 1.0, 1.0));
        addPointLight(Vector3f(-6, 7, 0), Color4f(1.0, 0.5, 0.0, 1.0));

        world = New!PhysicsWorld();

        bvh = meshBVH(aLevel.mesh);
        world.bvhRoot = bvh.root;
        
        RigidBody bGround = world.addStaticBody(Vector3f(0.0f, -1.5f, 0.0f));
        gGround = New!GeomBox(Vector3f(40.0f, 1.0f, 40.0f));
        world.addShapeComponent(bGround, gGround, Vector3f(0.0f, 0.0f, 0.0f), 1.0f);

        auto level = createEntity3D();
        level.drawable = aLevel.mesh;
        auto mTiles = addMaterial();
        mTiles.diffuse = aTexTiles.texture;
        mTiles.roughness = 0.1f;
        level.material = mTiles;
        
        auto plane = New!ShapePlane(40, 40, assetManager);
        auto p = createEntity3D();
        p.drawable = plane;
        p.material = mTiles;
        p.position.y = -0.5f;

        ShapeBox shapeBox = New!ShapeBox(1, 1, 1, assetManager);
        gBox = New!GeomBox(Vector3f(1.0f, 1.0f, 1.0f));

        auto mat = addMaterial();
        mat.diffuse = aTexCrate.texture;
        mat.roughness = 0.8f;

        foreach(i; 0..5)
        {
            auto boxE = createEntity3D();
            boxE.drawable = shapeBox;
            boxE.material = mat;
            boxE.position = Vector3f(i * 0.1f, 3.0f + 3.0f * cast(float)i, 0);
            auto bBox = world.addDynamicBody(Vector3f(0, 0, 0), 0.0f);
            RigidBodyController rbc = New!RigidBodyController(boxE, bBox);
            boxE.controller = rbc;
            world.addShapeComponent(bBox, gBox, Vector3f(0.0f, 0.0f, 0.0f), 10.0f);
        }

        gSphere = New!GeomEllipsoid(Vector3f(0.9f, 1.0f, 0.9f));
        gSensor = New!GeomBox(Vector3f(0.5f, 0.5f, 0.5f));
        character = New!CharacterController(world, fpview.camera.position, 80.0f, gSphere, assetManager);
        character.createSensor(gSensor, Vector3f(0.0f, -0.75f, 0.0f));

        auto text = New!TextLine(aFont.font, "Press <LMB> to look around, WASD to move, spacebar to jump", assetManager);
        text.color = Color4f(1.0f, 1.0f, 1.0f, 1.0f);
        auto textE = createEntity2D();
        textE.drawable = text;
        textE.position = Vector3f(16.0f, eventManager.windowHeight - 30.0f, 0.0f);

        initializedPhysics = true;
    }
    
    GenericMaterial addMaterial()
    {
        auto m = New!GenericMaterial(assetManager);
        m.backend = nonPBRBackend;
        return m;
    }
    
    override void onRelease()
    {
        super.onRelease();
        if (initializedPhysics)
        {
            Delete(world);
            Delete(gGround);
            Delete(gBox);
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
    }

    override void onKeyDown(int key)
    {
        if (key == KEY_ESCAPE)
            sceneManager.goToScene("Menu");
    }
    
    override void onMouseButtonDown(int button)
    {
        if (button == MB_LEFT)
        {
            fpview.active = true;
        }
    }
    
    override void onMouseButtonUp(int button)
    {
        if (button == MB_LEFT)
        {
            fpview.active = false;
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
    }
    
    override void onRender()
    {
        sm1.render(&rc3d);
        sm2.render(&rc3d);
        sm3.render(&rc3d);
        super.onRender();
    }
}


