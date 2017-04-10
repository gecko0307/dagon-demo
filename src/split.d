module split;

import std.stdio;
import dagon;

import dlib.geometry;

struct EdgeSplitOutput
{
    Vector3f point;
    Vector3f normal;
    Vector2f texcoord;
    float proportion;
}

bool edgeSplitPlane(
    Plane divider, 
    Vector3f start, 
    Vector3f end, 
    Vector3f startN, 
    Vector3f endN, 
    Vector2f startUV, 
    Vector2f endUV,
    out EdgeSplitOutput output)
{
	Vector3f middle;
    if (!divider.intersectsLineSegment(start, end, middle))
        return false;

	float proportion = (start - middle).length / (start - end).length; 

	float tu = startUV.x + (endUV.x - startUV.x) * proportion;
	float tv = startUV.y + (endUV.y - startUV.y) * proportion;

    Vector3f n = lerp(startN, endN, proportion);

    output = EdgeSplitOutput(middle, n, Vector2f(tu, tv), proportion);
    return true;
}

struct TriSplitOutput
{
    Triangle q1;
    Triangle q2;
    Triangle e;
    bool quadOnBack;
}

bool triSplitPlane(Plane divider, Triangle tri, out TriSplitOutput output)
{
    Triangle q1;
    Triangle q2;
    Triangle e;

    EdgeSplitOutput edgeSplit1;
    EdgeSplitOutput edgeSplit2;
    EdgeSplitOutput edgeSplit3;

    bool s1 = edgeSplitPlane(divider, tri.v[0], tri.v[1], tri.n[0], tri.n[1], tri.t1[0], tri.t1[1], edgeSplit1);
    bool s2 = edgeSplitPlane(divider, tri.v[0], tri.v[2], tri.n[0], tri.n[2], tri.t1[0], tri.t1[2], edgeSplit2);
    bool s3 = edgeSplitPlane(divider, tri.v[1], tri.v[2], tri.n[1], tri.n[2], tri.t1[1], tri.t1[2], edgeSplit3);

    bool res = false;
    bool quadOnBack;

    if (s1 & s2)
    {
        q1.v[0] = tri.v[1];
        q1.v[1] = tri.v[2];
        q1.v[2] = edgeSplit1.point;

        q1.n[0] = tri.n[1];
        q1.n[1] = tri.n[2];
        q1.n[2] = edgeSplit1.normal;

        q1.t1[0] = tri.t1[1];
        q1.t1[1] = tri.t1[2];
        q1.t1[2] = edgeSplit1.texcoord;

        q2.v[0] = edgeSplit1.point;
        q2.v[1] = tri.v[2];
        q2.v[2] = edgeSplit2.point;

        q2.n[0] = edgeSplit1.normal;
        q2.n[1] = tri.n[2];
        q2.n[2] = edgeSplit2.normal;

        q2.t1[0] = edgeSplit1.texcoord;
        q2.t1[1] = tri.t1[2];
        q2.t1[2] = edgeSplit2.texcoord;

        e.v[0] = tri.v[0];
        e.v[1] = edgeSplit1.point;
        e.v[2] = edgeSplit2.point;

        e.n[0] = tri.n[0];
        e.n[1] = edgeSplit1.normal;
        e.n[2] = edgeSplit2.normal;

        e.t1[0] = tri.t1[0];
        e.t1[1] = edgeSplit1.texcoord;
        e.t1[2] = edgeSplit2.texcoord;

        quadOnBack = divider.distance(tri.v[0]) > 0;

        res = true;
    }
    else if (s1 & s3)
    {
        q1.v[0] = tri.v[0];
        q1.v[1] = edgeSplit1.point;
        q1.v[2] = tri.v[2];

        q1.n[0] = tri.n[0];
        q1.n[1] = edgeSplit1.normal;
        q1.n[2] = tri.n[2];

        q1.t1[0] = tri.t1[0];
        q1.t1[1] = edgeSplit1.texcoord;
        q1.t1[2] = tri.t1[2];

        q2.v[0] = edgeSplit1.point;
        q2.v[1] = edgeSplit3.point;
        q2.v[2] = tri.v[2];

        q2.n[0] = edgeSplit1.normal;
        q2.n[1] = edgeSplit3.normal;
        q2.n[2] = tri.n[2];

        q2.t1[0] = edgeSplit1.texcoord;
        q2.t1[1] = edgeSplit3.texcoord;
        q2.t1[2] = tri.t1[2];

        e.v[0] = tri.v[1];
        e.v[1] = edgeSplit3.point;
        e.v[2] = edgeSplit1.point;

        e.n[0] = tri.n[1];
        e.n[1] = edgeSplit3.normal;
        e.n[2] = edgeSplit1.normal;

        e.t1[0] = tri.t1[1];
        e.t1[1] = edgeSplit3.texcoord;
        e.t1[2] = edgeSplit1.texcoord;

        quadOnBack = divider.distance(tri.v[1]) > 0;

        res = true;
    }
    else if (s2 & s3)
    {
        q1.v[0] = tri.v[0];
        q1.v[1] = tri.v[1];
        q1.v[2] = edgeSplit3.point;

        q1.n[0] = tri.n[0];
        q1.n[1] = tri.n[1];
        q1.n[2] = edgeSplit3.normal;

        q1.t1[0] = tri.t1[0];
        q1.t1[1] = tri.t1[1];
        q1.t1[2] = edgeSplit3.texcoord;

        q2.v[0] = tri.v[0];
        q2.v[1] = edgeSplit3.point;
        q2.v[2] = edgeSplit2.point;

        q2.n[0] = tri.n[0];
        q2.n[1] = edgeSplit3.normal;
        q2.n[2] = edgeSplit2.normal;

        q2.t1[0] = tri.t1[0];
        q2.t1[1] = edgeSplit3.texcoord;
        q2.t1[2] = edgeSplit2.texcoord;

        e.v[0] = edgeSplit2.point;
        e.v[1] = edgeSplit3.point;
        e.v[2] = tri.v[2];

        e.n[0] = edgeSplit2.normal;
        e.n[1] = edgeSplit3.normal;
        e.n[2] = tri.n[2];

        e.t1[0] = edgeSplit2.texcoord;
        e.t1[1] = edgeSplit3.texcoord;
        e.t1[2] = tri.t1[2];

        quadOnBack = divider.distance(tri.v[2]) > 0;

        res = true;
    }

    output = TriSplitOutput(q1, q2, e, quadOnBack);
    return res;
}

class SplittedMesh: Owner, Drawable
{
    uint displayList1;
    uint displayList2;

    DynamicArray!Triangle tris1;
    DynamicArray!Triangle tris2;

    this(Mesh m, Plane p, Owner owner)
    {
        super(owner);

        foreach(tri; m)
        {
            TriSplitOutput splitOut;
            if (triSplitPlane(p, tri, splitOut))
            {
                if (splitOut.quadOnBack)
                {
                    tris1.append(splitOut.q1);
                    tris1.append(splitOut.q2);
                    tris2.append(splitOut.e);
                }
                else
                {
                    tris2.append(splitOut.q1);
                    tris2.append(splitOut.q2);
                    tris1.append(splitOut.e);
                }
            }
            else
            {
                if (p.distance(tri.v[0]) > 0)
                    tris2.append(tri);
                else
                    tris1.append(tri);
            }
        }

        displayList1 = glGenLists(1);
        glNewList(displayList1, GL_COMPILE);
        glBegin(GL_TRIANGLES);
        foreach(ref tri; tris1)
        {
            drawTriangle(tri);
        }
        glEnd();
        glEndList();

        displayList2 = glGenLists(1);
        glNewList(displayList2, GL_COMPILE);
        glBegin(GL_TRIANGLES);
        foreach(ref tri; tris2)
        {
            drawTriangle(tri);
        }
        glEnd();
        glEndList();
    }

    protected void drawTriangle(ref Triangle tri)
    {
        glNormal3fv(tri.n[0].arrayof.ptr);
        glTexCoord2fv(tri.t1[0].arrayof.ptr);
        glVertex3fv(tri.v[0].arrayof.ptr);
            
        glNormal3fv(tri.n[1].arrayof.ptr);
        glTexCoord2fv(tri.t1[1].arrayof.ptr);
        glVertex3fv(tri.v[1].arrayof.ptr);

        glNormal3fv(tri.n[2].arrayof.ptr);
        glTexCoord2fv(tri.t1[2].arrayof.ptr);
        glVertex3fv(tri.v[2].arrayof.ptr);
    }

    void update(double dt)
    {
    }

    void render()
    {
        glDisable(GL_CULL_FACE);
        glColor4f(1, 0, 0, 1);
        glCallList(displayList1);
        glColor4f(0, 1, 0, 1);
        glCallList(displayList2);
    }

    ~this()
    {
        glDeleteLists(displayList1, 1);
        glDeleteLists(displayList2, 1);
        tris1.free();
        tris2.free();
    }
}

class SplitScene: BaseScene3D
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

        lightManager.addPointLight(Vector3f(0, 5, -3), Color4f(1.0, 0.0, 0.0, 1.0));
        lightManager.addPointLight(Vector3f(0, 5, 3), Color4f(0.0, 1.0, 1.0, 1.0));
    
        auto freeview = New!Freeview(eventManager, this);
        freeview.setZoom(6.0f);
        view = freeview;

        auto imrod = createEntity3D();
        Plane splitPlane = Plane(Vector3f(1, 0, 0), 0.5);
        imrod.drawable = New!SplittedMesh(obj.mesh, splitPlane, this);
        imrod.scaling = Vector3f(0.8f, 0.8f, 0.8f);
    }

    override void onKeyDown(int key)
    {
        if (key == KEY_ESCAPE)
            sceneManager.loadAndSwitchToScene("Menu");
    }
}

