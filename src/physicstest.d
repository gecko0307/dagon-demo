module physicstest;

import std.stdio;

import dagon;

import dmech.world;
import dmech.geometry;
import dmech.rigidbody;

import rigidbodycontroller;
import character;

class PhysicsScene: BaseScene3D
{ 
    FirstPersonView fpview;

    PhysicsWorld world;
    double physicsTimer;
    enum fixedTimeStep = 1.0 / 60.0;

    RigidBody bGround;
    Geometry gGround;

    Geometry gBox;

    GeomEllipsoid gSphere;
    GeomBox gSensor;
    CharacterController character;

    TextureAsset atex;
    TextureAsset atexGround;

    FontAsset afont;

    this(SceneManager smngr)
    {
        super(smngr);
    }

    override void onAssetsRequest()
    {
        atex = addTextureAsset("data/textures/crate.jpg");
        atexGround = addTextureAsset("data/textures/grass.png");
        afont = addFontAsset("data/font/DroidSans.ttf", 18);
    }

    override void onAllocate()
    {
        super.onAllocate();

        addPointLight(Vector3f(3, 3, 0), Color4f(1.0, 0.0, 0.0, 1.0));
        addPointLight(Vector3f(-3, 3, 0), Color4f(0.0, 1.0, 0.0, 1.0));
        addPointLight(Vector3f(0, 3, -3), Color4f(0.0, 0.0, 1.0, 1.0));
        addPointLight(Vector3f(-3, 3, -3), Color4f(1.0, 0.0, 1.0, 1.0));

        world = New!PhysicsWorld();
        
        RigidBody bGround = world.addStaticBody(Vector3f(0.0f, -1.0f, 0.0f));
        gGround = New!GeomBox(Vector3f(40.0f, 1.0f, 40.0f));
        world.addShapeComponent(bGround, gGround, Vector3f(0.0f, 0.0f, 0.0f), 1.0f);

        auto plane = New!ShapePlane(8, 8, this);
        auto p = createEntity3D();
        p.drawable = plane;
        auto mPlane = New!GenericMaterial(this);
        mPlane.diffuse = atexGround.texture;
        mPlane.roughness = 0.9f;
        p.material = mPlane;

        ShapeBox shapeBox = New!ShapeBox(1, 1, 1, this);
        gBox = New!GeomBox(Vector3f(1.0f, 1.0f, 1.0f));

        auto mat = New!GenericMaterial(this);
        mat.diffuse = atex.texture;
        mat.roughness = 0.2f;

        foreach(i; 0..20)
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

        fpview = New!FirstPersonView(eventManager, Vector3f(0.0f, 1.8f, 8.0f), this);
        view = fpview;

        gSphere = New!GeomEllipsoid(Vector3f(0.9f, 1.0f, 0.9f));
        gSensor = New!GeomBox(Vector3f(0.5f, 0.5f, 0.5f));
        character = New!CharacterController(world, fpview.camera.position, 80.0f, gSphere, this);
        character.createSensor(gSensor, Vector3f(0.0f, -0.75f, 0.0f));

        auto text = New!TextLine(afont.font, "Hello! Привет!", this);
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
    }

    override void onStart()
    {
        super.onStart();
        physicsTimer = 0.0;

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

    override void onUpdate(double dt)
    {
        physicsTimer += dt;
        if (physicsTimer >= fixedTimeStep)
        {
            controlCharacter(fixedTimeStep);

            physicsTimer -= fixedTimeStep;
            world.update(fixedTimeStep);

            fpview.camera.position = character.rbody.position;
        }

        super.onUpdate(dt);
    }
}

