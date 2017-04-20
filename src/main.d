module main;

import std.stdio;
import dagon;
import objtest;
import iqmtest;
import physicstest;
import particlestest;

import button;

class MenuScene: BaseScene3D
{
    FontAsset fontAsset;

    this(SceneManager smngr)
    {
        super(smngr);
        backgroundColor = Color4f(0.2f, 0.2f, 0.3f, 1.0f);
    }

    override void onAssetsRequest()
    {
        fontAsset = addFontAsset("data/font/DroidSans.ttf", 18);
    }

    override void onAllocate()
    {
        super.onAllocate();

        uint buttonWidth = 200;
        uint buttonHeight = 48;
        uint menuY = eventManager.windowHeight - buttonHeight - 150;

        auto button1 = createEntity2D();
        button1.position = Vector3f(eventManager.windowWidth * 0.5f - buttonWidth * 0.5f, menuY, 0.0f);
        auto button1Beh = New!ButtonBehaiour(buttonWidth, buttonHeight, fontAsset.font, "OBJ Test", button1);
        button1Beh.onClick = &onClickButton1;

        auto button2 = createEntity2D();
        button2.position = Vector3f(eventManager.windowWidth * 0.5f - buttonWidth * 0.5f, menuY - (buttonHeight + 8), 0.0f);
        auto button2Beh = New!ButtonBehaiour(buttonWidth, buttonHeight, fontAsset.font, "IQM Test", button2);
        button2Beh.onClick = &onClickButton2;

        auto button3 = createEntity2D();
        button3.position = Vector3f(eventManager.windowWidth * 0.5f - buttonWidth * 0.5f, menuY - (buttonHeight + 8) * 2, 0.0f);
        auto button3Beh = New!ButtonBehaiour(buttonWidth, buttonHeight, fontAsset.font, "Physics Test", button3);
        button3Beh.onClick = &onClickButton3;

        auto button4 = createEntity2D();
        button4.position = Vector3f(eventManager.windowWidth * 0.5f - buttonWidth * 0.5f, menuY - (buttonHeight + 8) * 3, 0.0f);
        auto button4Beh = New!ButtonBehaiour(buttonWidth, buttonHeight, fontAsset.font, "Particles Test", button4);
        button4Beh.onClick = &onClickButton4;

        auto buttonEx = createEntity2D();
        buttonEx.position = Vector3f(eventManager.windowWidth * 0.5f - buttonWidth * 0.5f, menuY - (buttonHeight + 8) * 4, 0.0f);
        auto buttonExBeh = New!ButtonBehaiour(buttonWidth, buttonHeight, fontAsset.font, "Exit", buttonEx);
        buttonExBeh.onClick = &onClickButtonExit;
    }

    void onClickButton1()
    {
        sceneManager.loadAndSwitchToScene("OBJScene", false);
    }

    void onClickButton2()
    {
        sceneManager.loadAndSwitchToScene("IQMScene", false);
    }

    void onClickButton3()
    {
        sceneManager.loadAndSwitchToScene("PhysicsScene", false);
    }

    void onClickButton4()
    {
        sceneManager.loadAndSwitchToScene("ParticlesScene", false);
    }

    void onClickButtonExit()
    {
        exitApplication();
    }

    override void onKeyDown(int key)
    {
        if (key == KEY_ESCAPE)
            exitApplication();
    }
}

class MyScene: BaseScene3D
{
    TextureAsset tex;

    this(SceneManager smngr)
    {
        super(smngr);
    }

    override void onAssetsRequest()
    {
        tex = addTextureAsset("data/textures/crate.jpg");
    }

    override void onAllocate()
    {
        super.onAllocate();

        addPointLight(Vector3f(-3, 3, 0), Color4f(1.0, 0.0, 0.0, 1.0));
        addPointLight(Vector3f( 3, 3, 0), Color4f(0.0, 1.0, 1.0, 1.0));

        auto freeview = New!Freeview(eventManager, this);
        freeview.setZoom(6.0f);
        view = freeview;

        ShapeBox shapeBox = New!ShapeBox(1, 1, 1, this);

        auto box = createEntity3D();
        box.drawable = shapeBox;

        auto mat = New!GenericMaterial(this);
        mat.diffuse = tex.texture;
        mat.roughness = 0.2f;
        box.material = mat;
    }

    override void onStart()
    {
        super.onStart();
    }

    override void onKeyDown(int key)
    {
        if (key == KEY_ESCAPE)
            sceneManager.loadAndSwitchToScene("Menu");
    }
}

class MyApplication: SceneApplication
{
    this(string[] args)
    {
        super(800, 600, "Dagon Demo", args);

        MenuScene menu = New!MenuScene(sceneManager);
        sceneManager.addScene(menu, "Menu");

        OBJScene objScene = New!OBJScene(sceneManager);
        sceneManager.addScene(objScene, "OBJScene");

        IQMScene iqmScene = New!IQMScene(sceneManager);
        sceneManager.addScene(iqmScene, "IQMScene");

        PhysicsScene physicsScene = New!PhysicsScene(sceneManager);
        sceneManager.addScene(physicsScene, "PhysicsScene");

        ParticlesScene parScene = New!ParticlesScene(sceneManager);
        sceneManager.addScene(parScene, "ParticlesScene");

        sceneManager.loadAndSwitchToScene("Menu");
    }
}

void main(string[] args)
{
    writeln("Allocated memory at start: ", allocatedMemory);
    MyApplication app = New!MyApplication(args);
    app.run();
    Delete(app);
    writeln("Allocated memory at end: ", allocatedMemory);
}

