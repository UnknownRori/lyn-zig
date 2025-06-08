const serverLib = @import("http/server.zig");
const requestLib = @import("http/request.zig");
const httpLib = @import("http/http.zig");

pub const Server = serverLib.Server;
pub const ServerConfig = serverLib.ServerConfig;
pub const Request = requestLib.Request;
pub const HTTPMethod = httpLib.HTTPMethod;

// Refrences for HTTP Request
// Host: localhost:8000
// User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:140.0) Gecko/20100101 Firefox/140.0
// Accept: */*
// Accept-Language: en,en-GB;q=0.8,ja;q=0.5,de;q=0.3
// Accept-Encoding: gzip, deflate, br, zstd
// DNT: 1
// Connection: keep-alive
// Cookie: phpMyAdmin=cb2bda84366332b27a9bfa73c805180f
// Sec-Fetch-Dest: empty
// Sec-Fetch-Mode: cors
// Sec-Fetch-Site: same-origin
