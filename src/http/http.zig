pub const HTTPMethod = enum {
    GET,
    POST,
    DELETE,
    PATCH,
};

pub const HTTPStatus = enum(u16) {
    // 200
    Ok = 200,
    Created = 201,
    Accepted = 202,
    NoContent = 204,
    PartialContent = 206,
    // 300
    NotModified = 304,
    // 400
    BadRequest = 400,
    UnAuthorized = 401,
    Forbidden = 403,
    NotFound = 404,
    // 500
    InternalServerError = 500,
    ServiceUnAvailable = 503,
};
