module shadowtest;

import std.stdio;
import std.math;
import std.conv;
import dagon;

class ShadowScene: BaseScene3D
{
    OBJAsset obj;
    TextureAsset aTex;

    NonPBRBackend nonPBRBackend;
    Entity eShadowArea;
    ShadowArea sp;
    ShadowMap sm;

    float r = -45.0f;

    this(SceneManager smngr)
    {
        super(smngr);
    }

    override void onAssetsRequest()
    {
        obj = New!OBJAsset(assetManager);
        addAsset(obj, "data/obj/suzanne.obj");

        aTex = addTextureAsset("data/textures/tiles.jpg");
    }

    override void onAllocate()
    {
        super.onAllocate();

        auto freeview = New!Freeview(eventManager, assetManager);
        freeview.setZoom(6.0f);
        view = freeview;

        eShadowArea = createEntity3D();
        eShadowArea.position = Vector3f(0, 5, 3);
        eShadowArea.rotation = rotationQuaternion(Axis.x, degtorad(r));
        sp = New!ShadowArea(eShadowArea, view, 10, 10, -20, 100);

        sm = New!ShadowMap(1024, this, sp, assetManager);
        
        nonPBRBackend = New!NonPBRBackend(assetManager);
        nonPBRBackend.shadowMap1 = sm;

        lightManager.addPointLight(Vector3f(-3, 2, 0), Color4f(1.0, 0.0, 0.0, 1.0));
        lightManager.addPointLight(Vector3f(3, 2, 0), Color4f(0.0, 1.0, 1.0, 1.0));

        Entity e = createEntity3D();
        e.drawable = New!ShapeBox(1,1,1,assetManager); //obj.mesh;
        e.scaling = Vector3f(0.8f, 0.8f, 0.8f);
        e.position = Vector3f(0.0f, 0.75f, 0.0f);

        Entity e2 = createEntity3D();
        e2.drawable = e.drawable; //obj.mesh;
        e2.scaling = Vector3f(0.8f, 0.8f, 0.8f);
        e2.position = Vector3f(1.0f, 1.5f, 0.5f);

        auto plane = New!ShapePlane(8, 8, assetManager);
        auto p = createEntity3D();
        p.drawable = plane;
        
        auto mat = addMaterial();
        mat.roughness = 0.5f;
        mat.diffuse = aTex.texture;

        auto mat2 = addMaterial();
        mat2.roughness = 0.9f;
        mat2.diffuse = Color4f(1, 0, 0, 1);

        auto mat3 = addMaterial();
        mat3.roughness = 0.9f;
        mat3.diffuse = Color4f(0, 1, 0, 1);

        p.material = mat;
        e.material = mat2;
        e2.material = mat3;
    }

    GenericMaterial addMaterial()
    {
        auto m = New!GenericMaterial(assetManager);
        m.backend = nonPBRBackend;
        return m;
    }

    override void onLogicsUpdate(double dt)
    {
        //eShadowArea.rotation = rotationQuaternion(Axis.x, degtorad(r));
        //r += 90.0f * dt;
    }

    override void onRender()
    {
        eShadowArea.visible = false;
        sm.render(&rc3d);
        eShadowArea.visible = true;
        super.onRender();
    }

    override void onKeyDown(int key)
    {
        if (key == KEY_ESCAPE)
            sceneManager.goToScene("Menu");
    }
}

