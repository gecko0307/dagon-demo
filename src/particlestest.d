module particlestest;

import std.stdio;
import std.math;
import dagon;

import particles;

class ParticlesScene: BaseScene3D
{
    TextureAsset texAsset;
    Entity particles;

    this(SceneManager smngr)
    {
        super(smngr);
        backgroundColor = Color4f(0, 0, 0, 1);
    }

    override void onAssetsRequest()
    {
        texAsset = addTextureAsset("data/textures/particle.png");
    }

    override void onAllocate()
    {
        super.onAllocate();

        lightManager.addPointLight(Vector3f(-3, 2, 0), Color4f(1.0, 0.0, 0.0, 1.0));
        lightManager.addPointLight(Vector3f(3, 2, 0), Color4f(0.0, 1.0, 1.0, 1.0));
    
        auto freeview = New!Freeview(eventManager, this);
        freeview.setZoom(6.0f);
        view = freeview;

        particles = createEntity3D();
        auto psys = New!ParticleSystem(particles, 400, texAsset.texture, freeview);

        auto eVortex = createEntity3D();
        eVortex.position = Vector3f(3, 0, 0);
        eVortex.rotation = rotationQuaternion(0, degtorad(-90.0f));
        auto ff1 = New!Vortex(eVortex, psys, 100, 10);

        auto eBlackHole = createEntity3D();
        eBlackHole.position = Vector3f(-5, 0, 0);
        auto ff2 = New!BlackHole(eBlackHole, psys, 100);

        auto eColorChanger = createEntity3D();
        eColorChanger.position = Vector3f(3, 3, 0);
        auto ff3 = New!ColorChanger(eColorChanger, psys, Color4f(0.5f, 0.0, 1, 1), 2, 0);
    }

    override void onUpdate(double dt)
    {
        super.onUpdate(dt);
        if (eventManager.keyPressed[KEY_LEFT]) particles.position.x -= 5.0f * dt;
        if (eventManager.keyPressed[KEY_RIGHT]) particles.position.x += 5.0f * dt;
        if (eventManager.keyPressed[KEY_DOWN]) particles.position.y -= 5.0f * dt;
        if (eventManager.keyPressed[KEY_UP]) particles.position.y += 5.0f * dt;
    }

    override void onKeyDown(int key)
    {
        if (key == KEY_ESCAPE)
            sceneManager.loadAndSwitchToScene("Menu");
    }
}

