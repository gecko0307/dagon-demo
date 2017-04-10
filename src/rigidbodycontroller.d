module rigidbodycontroller;

import dagon;
import dmech.rigidbody;

class RigidBodyController: EntityController
{
    RigidBody rbody;

    this(Entity e, RigidBody b)
    {
        super(e);
        rbody = b;
        b.position = e.position;
        b.orientation = e.rotation;
    }

    override void update(double dt)
    {
        entity.position = rbody.position;
        entity.rotation = rbody.orientation; 
        entity.transformation = rbody.transformation;
        entity.invTransformation = entity.transformation.inverse;
    }
}

