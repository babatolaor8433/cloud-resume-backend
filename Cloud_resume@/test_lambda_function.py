import json
import os
from unittest.mock import MagicMock

os.environ.setdefault("AWS_DEFAULT_REGION", "us-east-1")

import Lambda_function


def test_handler_returns_incremented_count(monkeypatch):
    mock_table = MagicMock()
    mock_table.update_item.return_value = {"Attributes": {"Count": 5}}
    monkeypatch.setattr(Lambda_function, "table", mock_table)

    result = Lambda_function.lambda_handler({}, None)

    assert result["statusCode"] == 200
    assert json.loads(result["body"]) == {"count": 5}
    mock_table.update_item.assert_called_once_with(
        Key={"Id_string": "resume"},
        UpdateExpression="ADD #c :inc",
        ExpressionAttributeNames={"#c": "Count"},
        ExpressionAttributeValues={":inc": 1},
        ReturnValues="UPDATED_NEW",
    )
