module iqmtest;

import std.stdio;
import dagon;

class IQMScene: BaseScene3D
{
    Freeview freeview;

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

    override void onAllocate()
    {
        super.onAllocate();

        addPointLight(Vector3f(0, 5, 2), Color4f(1.0, 0.0, 0.0, 1.0));
        addPointLight(Vector3f(0, 5, -2), Color4f(1.0, 1.0, 1.0, 1.0));
    
        freeview = New!Freeview(eventManager, this);
        freeview.camera.setZoom(15.0f);
        view = freeview;

        actor = New!Actor(iqm.model, this);
        mrfixit = createEntity3D();
        mrfixit.drawable = actor;

        auto mat = New!GenericMaterial(this);
        mat.roughness = 0.2f;
        mat.shadeless = false;
        mrfixit.material = mat;

        auto plane = New!ShapePlane(8, 8, this);
        auto p = createEntity3D();
        p.drawable = plane;
    }

    override void onStart()
    {
        super.onStart();
        actor.play();
    }

    override void onKeyDown(int key)
    {
        if (key == KEY_ESCAPE)
            sceneManager.loadAndSwitchToScene("Menu");
    }
}

