import ballerina.lang.system;
import ballerina.lang.messages;
import ballerina.net.http;
import ballerina.net.ws;
import ballerina.lang.jsons;
@http:configuration {basePath:"/fsociety"}
@ws:WebSocketUpgradePath {value:"/chat-service"}
service<ws> fscietyChatServer {

    @ws:OnOpen {}
    resource onOpen(message m) {
        system:println("New client connected to the server.");
    }

    @ws:OnTextMessage {}
    resource onTextMessage(message m) {
        json jsonPayload = messages:getJsonPayload(m);
        system:println(jsonPayload);
        var messageType = jsons:getString(jsonPayload,"$.message-type");
        system:println(messageType);
        
        //ws:closeConnection(); // Close connection from server side
        if ("close" == messageType) {
            ws:closeConnection(); // Close connection from server side
        } else if ("init" == messageType) {
            json msg =  {"message":"init"};
            //system:println(result1);
            ws:pushText(jsons:toString(msg));
        }else if ("echo" == messageType) {
            ws:pushText(jsons:toString(jsonPayload));
        }
    }

    @ws:OnClose {}
    resource onClose(message m) {
        system:println("client left the server.");
    }
}
