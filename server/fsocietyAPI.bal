import ballerina.net.http;
import ballerina.lang.messages;
import ballerina.lang.time;
import ballerina.data.sql;
import ballerina.utils;
import ballerina.lang.datatables;

struct User {
    string username;
    string token;
    string timestamp;
}

map props = {"jdbcUrl":"jdbc:mysql://localhost:3306/ballerina_hackathon",
                    "username":"root", 
                    "password":"root"};

@http:configuration {basePath:"/fsociety/api/v1/"}
service<http> RestEndpoint{
    
    @http:POST{}
    @http:Path {value:"/users"}
    resource listUsers(message m){
        
        db_getAllUsers();
        
        json jsonMsg = messages:getJsonPayload(m);
        
        message response = {};
        
        json jSampleJSON = {users:[
            
                {name:"ruchira"},
                {name:"randana"}
            ],
            status:200,
            statusMessage:"OK"
        };
        
        messages:setJsonPayload(response, jSampleJSON);
        reply response;
        
    }
    
    @http:POST{}
    @http:Path {value:"/signIn"}
    resource signIn(message m){
        
        json jsonMessage = messages:getJsonPayload(m);
        message response = {};
        
        string username;
        username, _ = (string)jsonMessage["username"];
        
        json jSampleJSON = "";
        int status; 
        string uuidToken; 
        status, uuidToken = db_checkAndinsertUser(username);
        
        if(status == 0){
            jSampleJSON = {authToken:uuidToken,
                 status:200,
                 statusMessage:"OK"
            };
        }
        else{
            jSampleJSON = {authToken:uuidToken,
                     status:-1,
                     statusMessage:"Already exists"   
                
            }; 
        }
        
        messages:setJsonPayload(response, jSampleJSON);
        reply response;
        
    }
    
    
    @http:GET {}
    @http:Path {value:"/hello"}
    resource resourceName (message m) {
        
        message response = {};
        messages:setStringPayload(response, "Hello, World!");
        
        reply response;
    }
}

function db_checkAndinsertUser(string username) (int, string){
    
    sql:ClientConnector empDB = create sql:ClientConnector(props);
    sql:Parameter[] params = [];
    sql:Parameter pInUsername = {sqlType:"varchar", value:username};
    params = [pInUsername];
    
    datatable dt = sql:ClientConnector.select(empDB,"SELECT * from user WHERE username=?", params);
    boolean exists = false;
    
    while (datatables:hasNext(dt)) {
        
        any dataStruct = datatables:next(dt);
        var rs, _ = (User)dataStruct;
        
        if(rs != null){
            exists = true;
            break;
        }
        
    }
    
    
    sql:ClientConnector.close(empDB);
    
    if(exists == false){
        
        time:Time currentTime = time:currentTime();
        string uuid = utils:getRandomString();
        
        empDB = create sql:ClientConnector(props);
        params = [];
        sql:Parameter pUsername = {sqlType:"varchar", value:username};
        sql:Parameter pToken = {sqlType:"varchar", value:uuid};
        sql:Parameter pTimestamp = {sqlType:"timestamp", value:currentTime.time};
        
        params = [pUsername, pToken, pTimestamp];
        
        var ret = sql:ClientConnector.update(empDB,
                          "Insert into user (username, token, timestamp) "+
                          "values (?,?,?)",
                           params);
        
        sql:ClientConnector.close(empDB);
        return 0, uuid;
    }
    else{
        return -1, "";
    }
    
}

function db_getAllUsers(){
    
    sql:ClientConnector empDB = create sql:ClientConnector(props);
    sql:Parameter[] params = [];
    
    datatable dt = sql:ClientConnector.select(empDB,"SELECT username from user", params);
    
    json usernamesJson = [];
    int index=0;
    
    while (datatables:hasNext(dt)) {
        
        any dataStruct = datatables:next(dt);
        var rs, _ = (User)dataStruct;
        usernamesJson[index] = rs.username;
        index = index+1;
    }
    
    
    sql:ClientConnector.close(empDB);
}