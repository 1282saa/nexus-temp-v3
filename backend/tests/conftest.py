"""
pytest 설정 및 공통 fixtures
"""
import pytest
import os
import sys
from unittest.mock import Mock, patch
import boto3
from moto import mock_dynamodb, mock_bedrock

# 프로젝트 경로 추가
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

# 테스트 환경변수 설정
os.environ['ENVIRONMENT'] = 'test'
os.environ['SERVICE_NAME'] = 'nexus-test'
os.environ['STACK_SUFFIX'] = 'test'
os.environ['AWS_REGION'] = 'us-east-1'
os.environ['LOG_LEVEL'] = 'DEBUG'


@pytest.fixture(scope='session')
def aws_credentials():
    """AWS 자격증명 모킹"""
    os.environ['AWS_ACCESS_KEY_ID'] = 'testing'
    os.environ['AWS_SECRET_ACCESS_KEY'] = 'testing'
    os.environ['AWS_SECURITY_TOKEN'] = 'testing'
    os.environ['AWS_SESSION_TOKEN'] = 'testing'


@pytest.fixture
def dynamodb_client(aws_credentials):
    """DynamoDB 클라이언트 모킹"""
    with mock_dynamodb():
        yield boto3.client('dynamodb', region_name='us-east-1')


@pytest.fixture
def dynamodb_resource(aws_credentials):
    """DynamoDB 리소스 모킹"""
    with mock_dynamodb():
        yield boto3.resource('dynamodb', region_name='us-east-1')


@pytest.fixture
def conversations_table(dynamodb_resource):
    """Conversations 테이블 생성"""
    table = dynamodb_resource.create_table(
        TableName='nexus-test-conversations-test',
        KeySchema=[
            {'AttributeName': 'conversationId', 'KeyType': 'HASH'}
        ],
        AttributeDefinitions=[
            {'AttributeName': 'conversationId', 'AttributeType': 'S'},
            {'AttributeName': 'userId', 'AttributeType': 'S'},
            {'AttributeName': 'createdAt', 'AttributeType': 'S'}
        ],
        GlobalSecondaryIndexes=[
            {
                'IndexName': 'userId-createdAt-index',
                'KeySchema': [
                    {'AttributeName': 'userId', 'KeyType': 'HASH'},
                    {'AttributeName': 'createdAt', 'KeyType': 'RANGE'}
                ],
                'Projection': {'ProjectionType': 'ALL'},
                'ProvisionedThroughput': {
                    'ReadCapacityUnits': 5,
                    'WriteCapacityUnits': 5
                }
            }
        ],
        BillingMode='PAY_PER_REQUEST'
    )
    return table


@pytest.fixture
def prompts_table(dynamodb_resource):
    """Prompts 테이블 생성"""
    table = dynamodb_resource.create_table(
        TableName='nexus-test-prompts-test',
        KeySchema=[
            {'AttributeName': 'engineType', 'KeyType': 'HASH'},
            {'AttributeName': 'promptId', 'KeyType': 'RANGE'}
        ],
        AttributeDefinitions=[
            {'AttributeName': 'engineType', 'AttributeType': 'S'},
            {'AttributeName': 'promptId', 'AttributeType': 'S'}
        ],
        BillingMode='PAY_PER_REQUEST'
    )
    return table


@pytest.fixture
def api_gateway_event():
    """API Gateway 이벤트 모킹"""
    return {
        'version': '2.0',
        'routeKey': 'POST /conversations',
        'rawPath': '/conversations',
        'headers': {
            'content-type': 'application/json',
            'authorization': 'Bearer test-token'
        },
        'requestContext': {
            'http': {
                'method': 'POST',
                'path': '/conversations'
            },
            'requestId': 'test-request-id'
        },
        'body': '{"message": "test message"}',
        'isBase64Encoded': False
    }


@pytest.fixture
def websocket_event():
    """WebSocket 이벤트 모킹"""
    return {
        'requestContext': {
            'connectionId': 'test-connection-id',
            'eventType': 'MESSAGE',
            'routeKey': '$default'
        },
        'body': '{"action": "sendMessage", "message": "test", "engineType": "11"}'
    }


@pytest.fixture
def lambda_context():
    """Lambda 컨텍스트 모킹"""
    context = Mock()
    context.function_name = 'test-function'
    context.function_version = '1'
    context.invoked_function_arn = 'arn:aws:lambda:us-east-1:123456789012:function:test'
    context.memory_limit_in_mb = 512
    context.aws_request_id = 'test-request-id'
    context.log_group_name = '/aws/lambda/test-function'
    context.log_stream_name = 'test-stream'
    context.get_remaining_time_in_millis = Mock(return_value=30000)
    return context


@pytest.fixture
def bedrock_client_mock():
    """Bedrock 클라이언트 모킹"""
    with patch('boto3.client') as mock_client:
        client = Mock()
        client.invoke_model.return_value = {
            'body': Mock(read=Mock(return_value=b'{"content": [{"text": "AI response"}]}'))
        }
        client.invoke_model_with_response_stream.return_value = {
            'body': [
                {'chunk': {'bytes': b'{"delta": {"text": "streaming "}}'}},
                {'chunk': {'bytes': b'{"delta": {"text": "response"}}'}},
            ]
        }
        mock_client.return_value = client
        yield client


@pytest.fixture
def sample_conversation():
    """샘플 대화 데이터"""
    return {
        'conversationId': 'test-conv-123',
        'userId': 'test-user-123',
        'engineType': '11',
        'title': 'Test Conversation',
        'messages': [
            {
                'role': 'user',
                'content': 'Hello',
                'timestamp': '2024-01-01T00:00:00Z'
            },
            {
                'role': 'assistant',
                'content': 'Hi there!',
                'timestamp': '2024-01-01T00:00:01Z'
            }
        ],
        'createdAt': '2024-01-01T00:00:00Z',
        'updatedAt': '2024-01-01T00:00:01Z'
    }


@pytest.fixture
def sample_prompt():
    """샘플 프롬프트 데이터"""
    return {
        'engineType': '11',
        'promptId': '11',
        'instruction': 'You are a helpful assistant.',
        'description': 'General purpose assistant',
        'createdAt': '2024-01-01T00:00:00Z',
        'updatedAt': '2024-01-01T00:00:00Z'
    }