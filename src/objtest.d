module objtest;

import std.stdio;
import dagon;

class DummyOwner: Owner
{
    this(Owner o)
    {
        super(o);
    }
}

import dlib.filesystem.local;

class OBJScene: BaseScene3D
{
    OBJAsset obj;

    this(SceneManager smngr)
    {
        super(smngr);
    }

    override void onAssetsRequest()
    {
        obj = New!OBJAsset(assetManager);
        addAsset(obj, "data/obj/suzanne.obj");
    }

    override void onAllocate()
    {
        super.onAllocate();

        lightManager.addPointLight(Vector3f(-3, 2, 0), Color4f(1.0, 0.0, 0.0, 1.0));
        lightManager.addPointLight(Vector3f(3, 2, 0), Color4f(0.0, 1.0, 1.0, 1.0));
 
        auto freeview = New!Freeview(eventManager, assetManager);
        freeview.setZoom(6.0f);
        view = freeview;

        Entity e = New!Entity(eventManager, assetManager);
        auto lr = New!LightReceiver(e, lightManager);
        entities3D.append(e);

        e.drawable = obj.mesh;
        e.scaling = Vector3f(0.8f, 0.8f, 0.8f);

        auto mat = New!GenericMaterial(assetManager);
        mat.roughness = 0.9f;
        mat.shadeless = false;
        e.material = mat;
        
        environment.backgroundColor = Color4f(0.5f, 0.5f, 0.5f, 1.0f);
    }

    override void onKeyDown(int key)
    {
        if (key == KEY_ESCAPE)
            sceneManager.goToScene("Menu");
    }
}

