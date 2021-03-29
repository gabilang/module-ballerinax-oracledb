// Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied. See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/sql;
import ballerina/test;
import ballerina/io;

@test:BeforeGroups { value:["insert-object"] }
function beforeInsertObjectFunc() returns sql:Error? {
   string OID = "19A57209ECB73F91E03400400B40BB23";
   string OID2 = "19A57209ECB73F91E03400400B40BB25";

    Client oracledbClient = check new(user, password, host, port, database);
    sql:ExecutionResult result = check dropTableIfExists("TestObjectTypeTable");
    result = check dropTableIfExists("TestNestedObjectTypeTable");
    result = check dropTypeIfExists("OBJECT_TYPE");
    result = check dropTypeIfExists("NESTED_TYPE");
    result = check oracledbClient->execute(
        "CREATE OR REPLACE TYPE OBJECT_TYPE OID '"+ OID +"' AS OBJECT(" +
            "STRING_ATTR VARCHAR(20), "+
            "INT_ATTR NUMBER, "+
            "FLOAT_ATTR FLOAT, "+
            "DECIMAL_ATTR FLOAT " +
        ") "
    );
    result = check oracledbClient->execute("CREATE TABLE TestObjectTypeTable(" +
       "id NUMBER, "+
       "COL_OBJECT OBJECT_TYPE, " +
       "PRIMARY KEY(id) "+
       ")"
   );

    result = check oracledbClient->execute(
       "CREATE OR REPLACE TYPE NESTED_TYPE OID '"+ OID2 +"' AS OBJECT(" +
        "STRING_ATTR VARCHAR2(20), "+
        "OBJECT_ATTR OBJECT_TYPE, " +
        "MAP MEMBER FUNCTION GET_ATTR1 RETURN NUMBER "+
       ") "
   );
    result = check oracledbClient->execute("CREATE TABLE TestNestedObjectTypeTable(" +
       "id NUMBER, "+
       "COL_NESTED_OBJECT NESTED_TYPE, " +
       "PRIMARY KEY(id) "+
       ")"
   );

   check oracledbClient.close();
}

@test:Config {
   enable: true,
   groups:["execute","insert-object"]
}
function insertObjectTypeWithString() returns sql:Error? {
    Client oracledbClient = check new(user, password, host, port, database);

    string string_attr = "Hello world";
    int int_attr = 34;
    float float_attr = 34.23;
    decimal decimal_attr = 34.23;

    sql:ParameterizedQuery insertQuery = `INSERT INTO TestObjectTypeTable(id, COL_OBJECT) 
        VALUES(1, OBJECT_TYPE(${string_attr}, ${int_attr}, ${float_attr}, ${decimal_attr}))`;
    sql:ExecutionResult result = check oracledbClient->execute(insertQuery);

    test:assertExactEquals(result.affectedRowCount, 1, "Affected row count is different.");
    var insertId = result.lastInsertId;
    test:assertTrue(insertId is string, "Last Insert id should be string");

    check oracledbClient.close();
}

@test:Config {
   enable: true,
   groups:["execute","insert-object"],
   dependsOn: [insertObjectTypeWithString]
}
function insertObjectTypeWithCustomType() returns sql:Error? {
    Client oracledbClient = check new(user, password, host, port, database);

    string string_attr = "Hello world";
    int int_attr = 34;
    float float_attr = 34.23;
    decimal decimal_attr = 34.23;

    ObjectTypeValue objectType = new({typename: "object_type", 
        attributes: [ string_attr, int_attr, float_attr, decimal_attr]});

    sql:ParameterizedQuery insertQuery = `INSERT INTO TestObjectTypeTable(id, COL_OBJECT) VALUES(2, ${objectType})`;
    sql:ExecutionResult result = check oracledbClient->execute(insertQuery);

    test:assertExactEquals(result.affectedRowCount, 1, "Affected row count is different.");
    var insertId = result.lastInsertId;
    test:assertTrue(insertId is string, "Last Insert id should be string");

    check oracledbClient.close();
}

// @test:Config {
//    enable: true,
//    groups:["execute","insert-object"],
//    dependsOn: [insertObjectTypeWithCustomType]
// }
// function insertObjectTypeNull() returns sql:Error? {
//    Client oracledbClient = check new(user, password, host, port, database);

//    ObjectTypeValue objectType = new();

//    sql:ParameterizedQuery insertQuery = `INSERT INTO TestObjectTypeTable(id, COL_OBJECT) VALUES(3, ${objectType}))`;
//    sql:ExecutionResult|sql:Error result = oracledbClient->execute(insertQuery);

//    if (result is sql:ApplicationError) {
//       test:assertTrue(result.message().includes("Invalid parameter: null is passed as value for SQL type: object"));
//    } else {
//       test:assertFail("Database Error expected.");
//    }
//    check oracledbClient.close();
// }

// @test:Config {
//    enable: true,
//    groups:["execute","insert-object"],
//    dependsOn: [insertObjectTypeNull]
// }
// function insertObjectTypeWithNullArray() returns sql:Error? {
//    Client oracledbClient = check new(user, password, host, port, database);
//    ObjectTypeValue objectType = new({typename: "object_type", attributes: ()});

//    sql:ParameterizedQuery insertQuery = `INSERT INTO TestObjectTypeTable(id, COL_OBJECT) VALUES(4, ${objectType})`;
//    sql:ExecutionResult result = check oracledbClient->execute(insertQuery);

//    test:assertExactEquals(result.affectedRowCount, 1, "Affected row count is different.");
//    var insertId = result.lastInsertId;
//    test:assertTrue(insertId is string, "Last Insert id should be string");

//    check oracledbClient.close();
// }

// @test:Config {
//    enable: true,
//    groups:["execute","insert-object"],
//    dependsOn: [insertObjectTypeWithNullArray]
// }
// function insertObjectTypeWithEmptyArray() returns sql:Error? {
//     Client oracledbClient = check new(user, password, host, port, database);
//     ObjectTypeValue objectType = new({typename: "object_type", attributes: []});

//     sql:ParameterizedQuery insertQuery = `INSERT INTO TestObjectTypeTable(id, COL_OBJECT) VALUES(5, ${objectType})`;
//     sql:ExecutionResult|sql:Error result = oracledbClient->execute(insertQuery);

//     if (result is sql:DatabaseError) {
//         sql:DatabaseErrorDetail errorDetails = result.detail();
//         test:assertEquals(errorDetails.errorCode, 17049);
//         test:assertEquals(errorDetails.sqlState, "99999");
//     } else {
//         test:assertFail("Database Error expected.");
//     }
// }

// @test:Config {
//    enable: true,
//    groups:["execute","insert-object"],
//    dependsOn: [insertObjectTypeWithEmptyArray]
// }
// function insertObjectTypeWithInvalidTypes1() returns sql:Error? {
//     Client oracledbClient = check new(user, password, host, port, database);
//     string string_attr = "Hello world";
//     int int_attr = 34;
//     float float_attr = 34.23;
//     decimal decimal_attr = 34.23;

//     ObjectTypeValue objectType = new({typename: "object_type", 
//         attributes: [ float_attr, int_attr, string_attr, decimal_attr]});

//     sql:ParameterizedQuery insertQuery = `INSERT INTO TestObjectTypeTable(id, COL_OBJECT) VALUES(7, ${objectType})`;
//     sql:ExecutionResult|sql:Error result = oracledbClient->execute(insertQuery);
//     if (result is sql:ApplicationError) {
//         test:assertTrue(result.message().includes("The array contains elements of unmappable types."));
//     } else {
//         test:assertFail("Application Error expected.");
//     }
//     check oracledbClient.close();
// }

// @test:Config {
//    enable: true,
//    groups:["execute","insert-object"],
//    dependsOn: [insertObjectTypeWithInvalidTypes1]
// }
// function insertObjectTypeWithInvalidTypes2() returns sql:Error? {
//     Client oracledbClient = check new(user, password, host, port, database);
//     boolean invalid_attr = true;

//     ObjectTypeValue objectType = new({typename: "object_type", 
//         attributes: [invalid_attr]});

//     sql:ParameterizedQuery insertQuery = `INSERT INTO TestObjectTypeTable(id, COL_OBJECT) VALUES(8, ${objectType})`;
//     sql:ExecutionResult|sql:Error result = oracledbClient->execute(insertQuery);

//     if (result is sql:ApplicationError) {
//         test:assertTrue(result.message().includes("The array contains elements of unmappable types."));
//     } else {
//         test:assertFail("Application Error expected.");
//     }
//     check oracledbClient.close();
// }

// @test:Config {
//    enable: true,
//    groups:["execute","insert-object"],
//    dependsOn: [insertObjectTypeWithInvalidTypes2]
// }
// function insertObjectTypeWithInvalidTypes3() returns sql:Error? {
//     Client oracledbClient = check new(user, password, host, port, database);
//     map<string> invalid_attr = { key1: "value1", key2: "value2"};

//     ObjectTypeValue objectType = new({typename: "object_type", 
//         attributes: [invalid_attr]});

//     sql:ParameterizedQuery insertQuery = `INSERT INTO TestObjectTypeTable(id, COL_OBJECT) VALUES(9, ${objectType})`;
//     sql:ExecutionResult|sql:Error result = oracledbClient->execute(insertQuery);

//     if (result is sql:ApplicationError) {
//         test:assertTrue(result.message().includes("The array contains elements of unmappable types."));
//     } else {
//         test:assertFail("Application Error expected.");
//     }
//     check oracledbClient.close();
// }

// @test:Config {
//    enable: true,
//    groups:["execute","insert-object"],
//    dependsOn: [insertObjectTypeWithInvalidTypes3]
// }
// function insertObjectTypeWithStringArray() returns sql:Error? {
//     Client oracledbClient = check new(user, password, host, port, database);

//     string string_attr = "Hello world";
//     string int_attr = "34";
//     string float_attr = "34.23";
//     string decimal_attr = "34.23";

//     string[] attributes = [ string_attr, int_attr, float_attr, decimal_attr];

//     ObjectTypeValue objectType = new({typename: "object_type", attributes: attributes});

//     sql:ParameterizedQuery insertQuery = `INSERT INTO TestObjectTypeTable(id, COL_OBJECT) VALUES(10, ${objectType})`;
//     sql:ExecutionResult result = check oracledbClient->execute(insertQuery);

//     test:assertExactEquals(result.affectedRowCount, 1, "Affected row count is different.");
//     var insertId = result.lastInsertId;
//     test:assertTrue(insertId is string, "Last Insert id should be string");

//     check oracledbClient.close();
// }

@test:Config {
   enable: true,
   groups:["execute","insert-object"],
   dependsOn: [insertObjectTypeWithStringArray]
}
function insertObjectTypeWithNestedType() returns sql:Error? {
    Client oracledbClient = check new(user, password, host, port, database);

    string string_attr = "Hello world";
    int int_attr = 34;
    float float_attr = 34.23;
    decimal decimal_attr = 34.23;

    anydata[] attributes = [ string_attr,[string_attr, int_attr, float_attr, decimal_attr]];
    ObjectTypeValue objectType = new({typename: "nested_type", attributes: attributes});

    sql:ParameterizedQuery insertQuery = `INSERT INTO TestNestedObjectTypeTable(id, COL_NESTED_OBJECT) VALUES(11, ${objectType})`;
    sql:ExecutionResult result = check oracledbClient->execute(insertQuery);

    test:assertExactEquals(result.affectedRowCount, 1, "Affected row count is different.");
    var insertId = result.lastInsertId;
    test:assertTrue(insertId is string, "Last Insert id should be string");

    check oracledbClient.close();
}

type ObjectRecordType record {
    int id;
    ObjectType col_object;
};

// @test:Config {
//     groups: ["execute", "execute-params"],
//     dependsOn: [insertObjectTypeWithCustomType]
// }
// function selectObjectTypeWithoutParams() returns error? {
//     Client oracledbClient = check new (user, password, host, port, database);
//     stream<record{}, error> streamData = oracledbClient->query("SELECT col_object FROM TestObjectTypeTable WHERE id = 1");
//     record {|record {} value;|}? data = check streamData.next();
//     check streamData.close();
//     record {}? value = data?.value;
//     io:println(value);
//     check oracledbClient.close();
// }

@test:Config {
    groups: ["execute", "execute-params"],
    dependsOn: [insertObjectTypeWithCustomType]
}
function selectObjectType() returns error? {
    Client oracledbClient = check new (user, password, host, port, database);
    stream<record{}, error> streamResult = oracledbClient->query("SELECT col_object FROM TestObjectTypeTable WHERE id = 1", ObjectRecordType);
    stream<ObjectRecordType, sql:Error> streamData = <stream<ObjectRecordType, sql:Error>>streamResult;
    record {|ObjectRecordType value;|}? data = check streamData.next();
    check streamData.close();
    ObjectRecordType? value = data?.value;
    validateSelectObjectType(value);
    check oracledbClient.close();
}

isolated function validateSelectObjectType(ObjectRecordType? returnData) {
    if (returnData is ()) {
        test:assertFail("Returned data is nil");
    } else {
        io:println(returnData);
        test:assertEquals(returnData.length(), 4);

        // test:assertEquals(returnData["row_id"], 1);
        // test:assertEquals(returnData["text_type"], "very long text");
    }
}

// 1. select simple type - with custom record, w/o custom record
// 2. select complec type - with custom record, w/custom record