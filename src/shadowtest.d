module shadowtest;

import std.stdio;
import std.math;
import std.conv;
import dagon;

class ShadowScene: BaseScene3D
{
    TextureAsset aTex;

    BlinnPhongBackend bpb;
    SkyBackend skyb;
    CascadedShadowMap shadowMap;

    this(SceneManager smngr)
    {
        super(smngr);
    }

    override void onAssetsRequest()
    {
        aTex = addTextureAsset("data/textures/tiles.jpg");
    }

    override void onAllocate()
    {
        super.onAllocate();

        auto freeview = New!Freeview(eventManager, assetManager);
        freeview.setZoom(6.0f);
        view = freeview;

        shadowMap = New!CascadedShadowMap(1024, this, assetManager);
        
        bpb = New!BlinnPhongBackend(assetManager);
        bpb.shadowMap = shadowMap;
        skyb = New!SkyBackend(assetManager);
        
        auto matSky = addMaterial(skyb);
        auto eSky = createEntity3D();
        eSky.material = matSky;
        eSky.drawable = New!ShapeSphere(100.0f, assetManager);
        eSky.scaling = Vector3f(-1.0f, -1.0f, -1.0f);

        lightManager.addPointLight(Vector3f(-3, 2, 0), Color4f(1.0, 0.0, 0.0, 1.0));
        lightManager.addPointLight(Vector3f(3, 2, 0), Color4f(0.0, 1.0, 1.0, 1.0));

        Entity e = createEntity3D();
        e.drawable = New!ShapeBox(1,1,1,assetManager);
        e.scaling = Vector3f(0.8f, 0.8f, 0.8f);
        e.position = Vector3f(0.0f, 0.75f, 0.0f);

        Entity e2 = createEntity3D();
        e2.drawable = e.drawable;
        e2.scaling = Vector3f(0.8f, 0.8f, 0.8f);
        e2.position = Vector3f(1.0f, 1.5f, 0.5f);

        auto plane = New!ShapePlane(8, 8, 4, assetManager);
        auto p = createEntity3D();
        p.drawable = plane;
        
        auto mat = addMaterial(bpb);
        mat.roughness = 0.5f;
        mat.diffuse = aTex.texture;

        auto mat2 = addMaterial(bpb);
        mat2.roughness = 0.9f;
        mat2.diffuse = Color4f(1, 0, 0, 1);

        auto mat3 = addMaterial(bpb);
        mat3.roughness = 0.9f;
        mat3.diffuse = Color4f(0, 1, 0, 1);

        p.material = mat;
        e.material = mat2;
        e2.material = mat3;
        
        environment.backgroundColor = Color4f(0.5f, 0.5f, 0.5f, 1.0f);
    }

    GenericMaterial addMaterial(GenericMaterialBackend backend)
    {
        auto m = New!GenericMaterial(assetManager);
        m.backend = backend;
        return m;
    }

    override void onLogicsUpdate(double dt)
    {        
        shadowMap.position = view.cameraPosition;
        shadowMap.update(dt);
    }

    override void onRender()
    {
        shadowMap.render(&rc3d);
        super.onRender();
    }

    override void onKeyDown(int key)
    {
        if (key == KEY_ESCAPE)
            sceneManager.goToScene("Menu");
    }
}

