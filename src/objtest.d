module objtest;

import std.stdio;
import dagon;

class OBJScene: BaseScene3D
{
    OBJAsset obj;

    this(SceneManager smngr)
    {
        super(smngr);
    }

    override void onAssetsRequest()
    {
        obj = New!OBJAsset();
        addAsset(obj, "data/obj/suzanne.obj");
    }

    override void onAllocate()
    {
        super.onAllocate();

        lightManager.addPointLight(Vector3f(-3, 2, 0), Color4f(1.0, 0.0, 0.0, 1.0));
        lightManager.addPointLight(Vector3f(3, 2, 0), Color4f(0.0, 1.0, 1.0, 1.0));
    
        auto freeview = New!Freeview(eventManager, this);
        freeview.setZoom(6.0f);
        view = freeview;

        auto suzanne = createEntity3D();
        suzanne.drawable = obj.mesh;
        suzanne.scaling = Vector3f(0.8f, 0.8f, 0.8f);

        auto mat = New!GenericMaterial(this);
        mat.roughness = 0.9f;
        mat.shadeless = false;
        suzanne.material = mat;
    }

    override void onKeyDown(int key)
    {
        if (key == KEY_ESCAPE)
            sceneManager.loadAndSwitchToScene("Menu");
    }
}

