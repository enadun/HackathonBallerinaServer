import ballerina.net.http;
import ballerina.lang.messages;

@http:configuration {basePath:"/fsociety/api/v1/"}
service<http> RestEndpoint{
    
    @http:GET {}
    @http:Path {value:"/hello"}
    resource resourceName (message m) {
        
        message response = {};
        messages:setStringPayload(response, "Hello, World!");
        
        reply response;
    }
}