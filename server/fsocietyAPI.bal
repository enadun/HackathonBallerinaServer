package server;

import ballerina.net.http;
import ballerina.lang.messages;
import ballerina.lang.system;

@http:configuration {basePath:"/fsociety/api/v1/"}
service<http> RestEndpoint{
    
    @http:GET {}
    @http:Path {value:"/hello"}
    resource resourceName (message m) {
        
        message response = {};
        messages:setStringPayload(response, "Hello, World!");
        system:println(groupUniqueID("123","fsd"));
        reply response;
    }
}