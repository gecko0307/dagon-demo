module iqmtest;

import std.stdio;
import dagon;

class IQMScene: Scene
{
    LightManager lightManager;
    Environment env;

    RenderingContext rc3d; 
    Freeview freeview;

    DynamicArray!Entity entities;

    IQMAsset iqm;
    Entity mrfixit;
    Actor actor;

    this(SceneManager smngr)
    {
        super(smngr);
        assetManager.mountDirectory("data/iqm");
        assetManager.liveUpdate = false;
    }

    override void onAssetsRequest()
    {
        iqm = New!IQMAsset();
        addAsset(iqm, "data/iqm/mrfixit.iqm");
    }

    Entity createEntity3D()
    {
        Entity e = New!Entity(eventManager, this);
        auto lr = New!LightReceiver(e, lightManager);
        return e;
    }

    override void onAllocate()
    {
        lightManager = New!LightManager(this);
        lightManager.addPointLight(Vector3f(0, 5, 2), Color4f(1.0, 0.0, 0.0, 1.0));
        lightManager.addPointLight(Vector3f(0, 5, -2), Color4f(1.0, 1.0, 1.0, 1.0));
    
        freeview = New!Freeview(eventManager, this);
        freeview.camera.setZoom(15.0f);

        actor = New!Actor(iqm.model, this);
        mrfixit = createEntity3D();
        mrfixit.drawable = actor;
        entities.append(mrfixit);

        env = New!Environment(this);

        auto mat = New!GenericMaterial(this);
        mat.roughness = 0.2f;
        mat.shadeless = false;
        mrfixit.material = mat;

        auto plane = New!ShapePlane(8, 8, this);
        auto p = createEntity3D();
        p.drawable = plane;
        entities.append(p);
    }

    override void onRelease()
    {
        entities.free();
    }

    override void onStart()
    {
        writeln("Allocated memory after scene switch: ", allocatedMemory);

        rc3d.init(eventManager, env);
        rc3d.projectionMatrix = perspectiveMatrix(60.0f, eventManager.aspectRatio, 0.1f, 100.0f);

        actor.play();

        glEnable(GL_DEPTH_TEST);
        glEnable(GL_CULL_FACE);
    }

    override void onEnd()
    {
    }

    override void onKeyDown(int key)
    {
        if (key == KEY_ESCAPE)
            sceneManager.loadAndSwitchToScene("Menu");
    }

    override void onUpdate(double dt)
    {   
        freeview.update(dt);
        freeview.prepareRC(&rc3d);

        foreach(e; entities)
            e.update(dt);
    }

    override void onRender()
    {     
        glViewport(0, 0, eventManager.windowWidth, eventManager.windowHeight);
        glClearColor(0.5f, 0.5f, 0.5f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

        rc3d.apply();

        foreach(e; entities)
            e.render(&rc3d);
    } 
}

