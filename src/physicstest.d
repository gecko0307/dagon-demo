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

    this(SceneManager smngr)
    {
        super(smngr);
    }

    override void onAssetsRequest()
    {
        aFont = addFontAsset("data/font/DroidSans.ttf", 18);

        aTexCrate = addTextureAsset("data/textures/crate.jpg");
        aTexTiles = addTextureAsset("data/textures/tiles.jpg");

        aLevel = New!OBJAsset();
        addAsset(aLevel, "data/obj/level.obj");
    }

    override void onAllocate()
    {
        super.onAllocate();

        addPointLight(Vector3f(0, 5, 3), Color4f(0.0, 0.5, 1.0, 1.0));
        addPointLight(Vector3f(0, 5, -3), Color4f(0.0, 0.5, 1.0, 1.0));
        addPointLight(Vector3f(-6, 7, 0), Color4f(1.0, 0.5, 0.0, 1.0));

        world = New!PhysicsWorld();

        bvh = meshBVH(aLevel.mesh);
        world.bvhRoot = bvh.root;
        
        RigidBody bGround = world.addStaticBody(Vector3f(0.0f, -1.0f, 0.0f));
        gGround = New!GeomBox(Vector3f(40.0f, 1.0f, 40.0f));
        world.addShapeComponent(bGround, gGround, Vector3f(0.0f, 0.0f, 0.0f), 1.0f);

        auto level = createEntity3D();
        level.drawable = aLevel.mesh;
        auto mTiles = New!GenericMaterial(this);
        mTiles.diffuse = aTexTiles.texture;
        mTiles.roughness = 0.9f;
        level.material = mTiles;

        ShapeBox shapeBox = New!ShapeBox(1, 1, 1, this);
        gBox = New!GeomBox(Vector3f(1.0f, 1.0f, 1.0f));

        auto mat = New!GenericMaterial(this);
        mat.diffuse = aTexCrate.texture;
        mat.roughness = 0.2f;

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

        fpview = New!FirstPersonView(eventManager, Vector3f(10.0f, 1.8f, 0.0f), this);
        fpview.camera.turn = -90.0f;
        view = fpview;

        gSphere = New!GeomEllipsoid(Vector3f(0.9f, 1.0f, 0.9f));
        gSensor = New!GeomBox(Vector3f(0.5f, 0.5f, 0.5f));
        character = New!CharacterController(world, fpview.camera.position, 80.0f, gSphere, this);
        character.createSensor(gSensor, Vector3f(0.0f, -0.75f, 0.0f));

        auto text = New!TextLine(aFont.font, "Hello! Привет!", this);
        text.color = Color4f(1.0f, 1.0f, 1.0f, 1.0f);
        auto textE = createEntity2D();
        textE.drawable = text;
        textE.position = Vector3f(16.0f, 16.0f, 0.0f);
    }
    
    override void onRelease()
    {
        Delete(world);
        Delete(gGround);
        Delete(gBox);
        Delete(gSphere);
        Delete(gSensor);
        bvh.free();
    }

    override void onStart()
    {
        super.onStart();

        eventManager.showCursor(false);
        eventManager.setMouseToCenter();
    }

    override void onEnd()
    {
        super.onEnd();
        eventManager.showCursor(true);
    }

    override void onKeyDown(int key)
    {
        if (key == KEY_ESCAPE)
            sceneManager.loadAndSwitchToScene("Menu");
    }

    void controlCharacter(double dt)
    {
        character.rotation.y = fpview.camera.turn;
        Vector3f forward = fpview.camera.characterMatrix.forward;
        Vector3f right = fpview.camera.characterMatrix.right;
        float speed = 8.0f;
        if (eventManager.keyPressed[KEY_W]) character.move(forward, -speed);
        if (eventManager.keyPressed[KEY_S]) character.move(forward, speed);
        if (eventManager.keyPressed[KEY_A]) character.move(right, -speed);
        if (eventManager.keyPressed[KEY_D]) character.move(right, speed);
        if (eventManager.keyPressed[KEY_SPACE]) character.jump(2.0f);
        character.update();
    }

    override void onLogicsUpdate(double dt)
    {
        controlCharacter(dt);
        world.update(dt);
        fpview.camera.position = character.rbody.position;
    }
}

