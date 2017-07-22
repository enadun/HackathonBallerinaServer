import ballerina.lang.jsons;
import ballerina.lang.system;

function main (string[] args) {
    system:println("Starting");
    json msg = {"response": {"message":"init"}};
    //string i1 = jsons:getString(msg, "$.response");
    system:println(jsons:toString(msg));
}
