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
    }

    override void onAssetsRequest()
    {
        assetManager.mountDirectory("data/iqm");
        iqm = New!IQMAsset(assetManager);
        addAsset(iqm, "data/iqm/mrfixit.iqm");
    }

    override void onAllocate()
    {
        super.onAllocate();

        addPointLight(Vector3f(0, 5, 2), Color4f(1.0, 0.0, 0.0, 1.0));
        addPointLight(Vector3f(0, 5, -2), Color4f(1.0, 1.0, 1.0, 1.0));
    
        freeview = New!Freeview(eventManager, assetManager);
        freeview.camera.setZoom(15.0f);
        view = freeview;

        actor = New!Actor(iqm.model, assetManager);
        mrfixit = createEntity3D();
        mrfixit.drawable = actor;

        auto mat = New!GenericMaterial(assetManager);
        mat.roughness = 0.2f;
        mat.shadeless = false;
        mrfixit.material = mat;

        auto plane = New!ShapePlane(8, 8, assetManager);
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
            sceneManager.goToScene("Menu");
    }
}

