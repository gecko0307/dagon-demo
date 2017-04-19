module particles;

import std.stdio;
import std.random;
import dagon;

struct Particle
{
    Vector4f color;
    Vector3f position;
    Vector3f velocity;
    Vector3f gravityVector;
    Vector2f scale;
    float lifetime;
    float time;
    bool move;
}

class ParticleSystem: Owner, Drawable
{
    Particle[] particles;

    Texture texture;
    View view;
    Matrix4x4f invViewMatRot;

    float gravityAcceleration = 9.8f;

    float minLifetime = 0.5f;
    float maxLifetime = 1.0f;

    float minSize = 0.25f;
    float maxSize = 1.0f;

    Vector3f initialDirection = Vector3f(0, 1, 0);
    float initialDirectionRandomFactor = 0.3f;
    float minInitialSpeed = 10.0f;
    float maxInitialSpeed = 20.0f;
    float airFrictionDamping = 0.98f;

    Color4f startColor = Color4f(0, 0.5f, 1, 1);
    Color4f endColor = Color4f(1, 1, 1, 0);

    bool haveParticlesToDraw;

    this(Texture t, View v, Owner o)
    {
        super(o);

        texture = t;
        view = v;

        particles = New!(Particle[])(300);
        foreach(ref p; particles)
        {
            resetParticle(p);
        }
    }

    ~this()
    {
        Delete(particles);
    }

    void update(double dt)
    {
        invViewMatRot = matrix3x3to4x4(matrix4x4to3x3(view.viewMatrix).transposed);

        haveParticlesToDraw = false;
        foreach(ref p; particles)
        if (p.time < p.lifetime)
        {
            p.time += dt;
            if (p.move)
            {
                p.velocity += p.gravityVector * gravityAcceleration * dt;
                p.velocity = p.velocity * airFrictionDamping;
                p.position += p.velocity * dt;
            }

            float t = p.time / p.lifetime;
            p.color = lerp(startColor, endColor, t);

            haveParticlesToDraw = true;
        }
        else
            resetParticle(p);
    }

    void resetParticle(ref Particle p)
    {
        p.position = Vector3f(0, 0, 0);
        Vector3f r = randomUnitVector3!float;
        float initialSpeed = uniform(minInitialSpeed, maxInitialSpeed);
        p.velocity = lerp(initialDirection, r, initialDirectionRandomFactor) * initialSpeed;
        p.lifetime = uniform(minLifetime, maxLifetime);
        p.gravityVector = Vector3f(0, -1, 0);
        float s = uniform(minSize, maxSize);
        p.scale = Vector2f(s, s);
        p.time = 0.0f;
        p.move = true;
    }

    pragma(inline) static void drawUnitBillboard()
    {
        glBegin(GL_QUADS);
        glTexCoord2f(0.0f, 0.0f); glVertex3f(-0.5f,  0.5f, 0.0f);
        glTexCoord2f(0.0f, 1.0f); glVertex3f(-0.5f, -0.5f, 0.0f);
        glTexCoord2f(1.0f, 1.0f); glVertex3f( 0.5f, -0.5f, 0.0f);
        glTexCoord2f(1.0f, 0.0f); glVertex3f( 0.5f,  0.5f, 0.0f);
        glEnd();
    }

    void render()
    {
        if (!haveParticlesToDraw)
            return;

        texture.bind();
        glPushAttrib(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_ENABLE_BIT);
        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE);
        glDepthMask(0);
        glDisable(GL_LIGHTING);
        foreach(ref p; particles)
        if (p.time < p.lifetime)
        {
            glPushMatrix();       
            glTranslatef(p.position.x, p.position.y, p.position.z);
            // Fast billboard rendering trick: compensate camera rotation
            glMultMatrixf(invViewMatRot.arrayof.ptr);
            glScalef(p.scale.x, p.scale.y, 1.0f);
            glColor4fv(p.color.arrayof.ptr);
            drawUnitBillboard();
            glPopMatrix();
        }
        glPopAttrib();
        texture.unbind();
    }
}

class ParticlesScene: BaseScene3D
{
    TextureAsset texAsset;

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

        auto psys = New!ParticleSystem(texAsset.texture, freeview, this);
        auto par = createEntity3D();
        par.drawable = psys;
    }

    override void onKeyDown(int key)
    {
        if (key == KEY_ESCAPE)
            sceneManager.loadAndSwitchToScene("Menu");
    }
}

