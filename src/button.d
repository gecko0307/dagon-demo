module button;

import std.stdio;

import dagon;

class ButtonBehaiour: Behaviour
{
    uint width;
    uint height;
    Color4f color;
    bool mouseOver = false;
    TextLine label;
    void delegate() onClick;

    // Color animation
    Color4f backgroundPrevColor;
    Color4f backgroundTargetColor;
    Color4f labelPrevColor;
    Color4f labelTargetColor;
    float t = 0.0f;

    Color4f backgroundColorNormal = Color4f(0.9f, 0.9f, 0.9f, 1.0f);
    Color4f backgroundColorHover = Color4f(1.0f, 0.5f, 0.0f, 1.0f);
    Color4f labelColorNormal = Color4f(0.2f, 0.2f, 0.3f, 1.0f);
    Color4f labelColorHover = Color4f(1.0f, 1.0f, 1.0f, 1.0f);
    float fadeTime = 0.25f;

    this(uint w, uint h, Font font, string text, Entity e)
    {
        super(e);
        width = w;
        height = h;
        color = backgroundColorNormal;

        label = New!TextLine(font, text, this);
        label.color = labelColorNormal;

        backgroundPrevColor = backgroundColorNormal;
        backgroundTargetColor = backgroundColorNormal;
        labelPrevColor = labelColorNormal;
        labelTargetColor = labelColorNormal;

        onClick = &onClickDefault;
    }

    override void update(double dt)
    {
        if (mouseInRegion(
            cast(uint)entity.position.x, 
            cast(uint)entity.position.y,
            width, height))
        {
            if (!mouseOver)
            {
                mouseOver = true;
                onMouseEnter();
                t = 0.0f;
            }
        }
        else
        {
            if (mouseOver)
            {
                mouseOver = false;
                onMouseLeave();
                t = 0.0f;
            }
        }

        color = lerp(backgroundPrevColor, backgroundTargetColor, t);
        label.color = lerp(labelPrevColor, labelTargetColor, t);
        t += (1.0f / fadeTime) * dt;
        if (t >= 1.0f)
            t = 1.0f;
    }

    override void render(RenderingContext* rc)
    {
        glColor4fv(color.arrayof.ptr);
        glBegin(GL_QUADS);
        glTexCoord2f(0, 0); glVertex2f(0, 0);
        glTexCoord2f(1, 0); glVertex2f(width, 0);
        glTexCoord2f(1, 1); glVertex2f(width, height);
        glTexCoord2f(0, 1); glVertex2f(0, height);
        glEnd();
        glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
        glPushMatrix();
        float labelX = width * 0.5f - label.width * 0.5f;
        float labelY = height * 0.5f - label.height * 0.5f;
        glTranslatef(labelX, labelY, 0);
        label.render(rc);
        glPopMatrix();
    }

    void onMouseEnter()
    {
        backgroundPrevColor = color;
        labelPrevColor = label.color;
        backgroundTargetColor = backgroundColorHover;
        labelTargetColor = labelColorHover;
    }

    void onMouseLeave()
    {
        backgroundPrevColor = color;
        labelPrevColor = label.color;
        backgroundTargetColor = backgroundColorNormal;
        labelTargetColor = labelColorNormal;
    }

    void onClickDefault()
    {
    }

    override void onMouseButtonUp(int button)
    {
        if (button == MB_LEFT)
        {
            if (mouseOver)
            {
                if (onClick !is null)
                    onClick();
            }
        }
    }

    bool mouseInRegion(uint x, uint y, uint w, uint h)
    {
        return eventManager.mouseX > x &&
               eventManager.mouseY > y &&
               eventManager.mouseX < (x + w) &&
               eventManager.mouseY < (y + h);
    }
}

