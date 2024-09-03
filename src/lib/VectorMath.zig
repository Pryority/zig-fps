const Vector3 = @cImport({
    @cInclude("raylib.h");
}).Vector3;

pub fn addVector3(a: Vector3, b: Vector3) Vector3 {
    return Vector3{
        .x = a.x + b.x,
        .y = a.y + b.y,
        .z = a.z + b.z,
    };
}

pub fn subtractVector3(a: Vector3, b: Vector3) Vector3 {
    return Vector3{
        .x = a.x - b.x,
        .y = a.y - b.y,
        .z = a.z - b.z,
    };
}
