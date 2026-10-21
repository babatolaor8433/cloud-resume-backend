import json
import boto3

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table("visitor-count")

def lambda_handler(event, context):
    response = table.update_item(
        Key={"Id_string": "resume"},
        UpdateExpression="ADD #c :inc",
        ExpressionAttributeNames={"#c": "Count"},
        ExpressionAttributeValues={":inc": 1},
        ReturnValues="UPDATED_NEW",
    )
    count = int(response["Attributes"]["Count"])
    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
        },
        "body": json.dumps({"count": count}),
    }