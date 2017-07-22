package server;

import ballerina.lang.system;
import ballerina.lang.messages;
import ballerina.net.http;
import ballerina.net.ws;
import ballerina.lang.jsons;
import ballerina.lang.time;
import ballerina.utils;
import ballerina.lang.arrays;

const string SALT = "jng0329 m9234jt9jt 23v0u4t235j25";

struct User {
    string name;
    string token;
    time:Time time;
}

@http:configuration {basePath:"/fsociety"}
@ws:WebSocketUpgradePath {value:"/chat-service"}
service<ws> fsocietyChatServer {

    User[] currentUsers = [];

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
            messageType = jsons:getString(jsonPayload,"$.message-type");
            json msg =  {"message":"init","user":"user","logged_in":""};
            ws:broadcastText(jsons:toString(msg));
        }else if ("echo" == messageType) {
            ws:pushText(jsons:toString(jsonPayload));
        }else if("chat"==messageType){
            //get username
            //string _username = jsons:getString(jsonPayload,"$.username");
            string _token = jsons:getString(jsonPayload,"$.token");
            system:println("Token:" +_token);

            User user = findUserByToken(currentUsers,_token);
            if(user!=null) {
                system:println("Valid User, broadcasting");
                var messageText = jsons:getString(jsonPayload, "$.message");
                json msg = {"username":user.name, "message":messageText, "message-type":messageType};
                system:println(msg);
                ws:broadcastText(jsons:toString(msg));
            }else{
                //Invalid token;
                ws:closeConnection();
            }

        }else if("signin"==messageType){
        //get username
            string _username = jsons:getString(jsonPayload,"$.username");
            system:println("signing in");
            string token = signIn(currentUsers,_username);
            system:println("token" + token);
            if(token!="") {
                json msg = { "status": "OK",
                               "token": token,"message-type":messageType
                           };
                ws:pushText(jsons:toString(msg));
                json newUser = {"username":_username,"message-type":"user-add"};
                ws:broadcastText(jsons:toString(newUser));
            }else{
                json msg =  { "status": "FAILED","message-type":messageType};
                ws:pushText(jsons:toString(msg));
            }
            json userList =  jsonUserList(currentUsers);
            json msg = {"message-type":"userlist","users":userList};
            ws:pushText(jsons:toString(msg));
        }
        else if("signout"==messageType){
        //get username
            string _username = jsons:getString(jsonPayload,"$.username");
            string token = signIn(currentUsers,_username);
            if(token!="") {
                json msg = { "status": "OK",
                               "token": token
                           };
                ws:pushText(jsons:toString(msg));
                json newUser = {"username":_username,"message-type":"user-add"};
                ws:broadcastText(jsons:toString(newUser));
            }else{
                json msg =  { "status": "FAILED"};
                ws:pushText(jsons:toString(msg));
            }

        }else if("userlist"==messageType){
        //get username

                json userList =  jsonUserList(currentUsers);
                json msg = {"message-type":"userlist","users":userList};
                ws:pushText(jsons:toString(msg));

        }
    }

    @ws:OnClose {}
    resource onClose(message m) {
        system:println("client left the server.");
    }
}

function jsonUserList(User[] currentUsers) (json){
    int i=0;
    json usersList =[];
    while(i<(currentUsers.length)) {
        json user;
        if (currentUsers[i] != null){
            user, _ = <json>currentUsers[i];
            jsons:addToArray(usersList, "$", user);
        }
        i=i+1;
    }
    return usersList;
}

function isValidUser(User[] currentUsers,string username,string token) (boolean){
    User user = findUserByName(currentUsers,username);
    return user.token==token;
}

function findUserByName (User[] currentUsers,string username) (User) {
    int i=0;
    while(i<(currentUsers.length)){
        if(currentUsers[i]!=null && currentUsers[i].name==username){
            return currentUsers[i];
        }
        i=i+1;
    }

    return null;
}

function findUserByToken (User[] currentUsers,string token) (User) {
    int i=0;
    while(i<(currentUsers.length)){
        if(currentUsers[i]!=null && currentUsers[i].token==token){
            return currentUsers[i];
        }
        i=i+1;
    }

    return null;
}

function signIn(User[] currentUsers,string username) (string) {
    system:println(currentUsers);
    User user = findUserByName(currentUsers,username);
    if (user == null) {
        system:println("No users");
        time:Time cTime = time:currentTime();
        string token = utils:getHash(username + cTime.time + SALT, "SHA256");
        system:println("Add user");
        currentUsers[((currentUsers.length)+1)] = {name:username,token:token,time:cTime};
        system:println("Added");
        return token;
    }else{
        return "";
    }
}

function createChatGroup(string user1,string user2) (string){
    string _id = groupUniqueID(user1,user2);
    ws:addConnectionToGroup(_id);
    return _id;
}

function checkUserIdentity(string token) (string username,int timeoutMilliseconds){
    return token,0;
}


function groupUniqueID(string user1,string user2) (string){
    string[] unordered = [user1,user2];
    string[] users = arrays:sort(unordered);
    return utils:getHash(users[0]+"-"+users[1]+SALT,"SHA256");
}
