import json
import os

import boto3
import pytest
from freezegun import freeze_time
from kubernetes.client.rest import ApiException

from tests.utils import dict_to_simple_namespace


@pytest.fixture()
def handler(monkeypatch):
    monkeypatch.setenv('AWS_REGION', 'eu-west-1')
    import drainer.handler as handler
    return handler


@pytest.fixture()
def mock_eks(mocker):
    return mocker.Mock(**{'describe_cluster.return_value': {'cluster': {
        'certificateAuthority': {
            'data': '84586abd904ef'
        },
        'endpoint': 'https://test-cluster.amazonaws.com'
    }}})


@pytest.fixture()
def mock_k8s_client_no_nodes(mocker):

    list_node_val = dict_to_simple_namespace({'items': []})

    mock_api = mocker.Mock(**{'list_node.return_value': list_node_val})

    class Configuration:

        def __init__(self):
            self.api_key = {}
            self.api_key_prefix = {}

    return mocker.Mock(**{'CoreV1Api.return_value': mock_api,
                          'Configuration.return_value': Configuration()})


@pytest.fixture()
def mock_k8s_client(mocker):
    list_pods_val = dict_to_simple_namespace({'items': [
        {'metadata': {
            'uid': 'aaa',
            'name': 'test_pod1',
            'namespace': 'test_ns',
            'annotations': None,
            'owner_references': None
        }
        }, {'metadata': {
            'uid': 'bbb',
            'name': 'test_pod2',
            'namespace': 'test_ns',
            'annotations': None,
            'owner_references': None
        }
        }
    ]})
    empty_list_pods_val = dict_to_simple_namespace({'items': []})

    list_node_val = dict_to_simple_namespace({'items': [{'metadata': {'name': 'test_node'}}]})

    mock_api = mocker.Mock(**{'list_pod_for_all_namespaces.side_effect': [list_pods_val, empty_list_pods_val],
                              'list_node.return_value': list_node_val,
                              'patch_node.return_value': mocker.Mock()}
                           )

    class Configuration:

        def __init__(self):
            self.api_key = {}
            self.api_key_prefix = {}

    return mocker.Mock(**{'CoreV1Api.return_value': mock_api,
                          'Configuration.return_value': Configuration()})


@pytest.fixture()
def mock_k8s_client_patch_exception(mocker):
    list_node_val = dict_to_simple_namespace({'items': [{'metadata': {'name': 'test_node'}}]})

    mock_api = mocker.Mock(**{'list_node.return_value': list_node_val,
                              'patch_node.side_effect': ApiException()})

    class Configuration:

        def __init__(self):
            self.api_key = {}
            self.api_key_prefix = {}

    return mocker.Mock(**{'CoreV1Api.return_value': mock_api,
                          'Configuration.return_value': Configuration()})


@pytest.fixture()
def mock_k8s_client_pods_exception(mocker):
    list_node_val = dict_to_simple_namespace({'items': [{'metadata': {'name': 'test_node'}}]})

    mock_api = mocker.Mock(**{'list_pod_for_all_namespaces.side_effect': ApiException(),
                              'list_node.return_value': list_node_val,
                              'patch_node.return_value': mocker.Mock()})

    class Configuration:

        def __init__(self):
            self.api_key = {}
            self.api_key_prefix = {}

    return mocker.Mock(**{'CoreV1Api.return_value': mock_api,
                          'Configuration.return_value': Configuration()})


@pytest.fixture()
def mock_ec2(mocker):
    describe_instances_resp = {
        'Reservations': [
            {'Instances': [
                {'PrivateDnsName': 'test_node'}
            ]}
        ]
    }

    return mocker.Mock(**{'describe_instances.return_value': describe_instances_resp})


@pytest.fixture()
def fake_eks_env():
    return {
        'kube_config_bucket': None,
        'kube_config_object': None,
        'cluster_name': 'test-cluster'
    }

@pytest.fixture()
def fake_noneks_env():
    return {
        'kube_config_bucket': 'bucket',
        'kube_config_object': 'object',
        'cluster_name': 'test-cluster',
    }


@pytest.fixture()
def patched_handler(fs, monkeypatch, mocker, mock_eks, mock_ec2):
    monkeypatch.setenv('AWS_REGION', 'eu-west-1')

    # pyfakefs always initialises a temp dir, on Mac it is /var on Linux it is /tmp
    # https://github.com/jmcgeheeiv/pyfakefs/issues/329
    if not os.path.exists('/tmp'):
        fs.create_dir('/tmp')

    # boto3 won't work if it can't write to this directory
    boto_dir = os.path.abspath(os.path.join(os.path.dirname(boto3.__file__), ".."))
    fs.add_real_directory(boto_dir)

    import drainer.handler as handler

    monkeypatch.setattr(handler, 's3', mocker.Mock())
    monkeypatch.setattr(handler, 'asg', mocker.Mock())
    monkeypatch.setattr(handler, 'ec2', mock_ec2)
    monkeypatch.setattr(handler, 'eks', mock_eks)

    return handler


@pytest.fixture()
def patched_main_handler(mocker, mock_eks, mock_ec2, monkeypatch):
    monkeypatch.setenv('CLUSTER_NAME', 'test-cluster')
    monkeypatch.setenv('KUBE_CONFIG_BUCKET', 'bucket')
    monkeypatch.setenv('KUBE_CONFIG_OBJECT', 'object')

    import drainer.handler as handler

    monkeypatch.setattr(handler, '_lambda_handler', mocker.Mock())

    return handler


@pytest.fixture()
def mock_event(fs):
    event_json = os.path.join(os.path.dirname(__file__), 'fixtures/event.json')
    fs.add_real_file(event_json)
    with open(event_json, 'r') as event:
        return json.loads(event.read())


@freeze_time("2011-06-21 18:40:00")
def test_get_bearer_token(handler, monkeypatch):
    monkeypatch.setenv('AWS_ACCESS_KEY_ID', 'fake')
    monkeypatch.setenv('AWS_SECRET_ACCESS_KEY', 'fake')

    expected = 'k8s-aws-v1.aHR0cHM6Ly9zdHMuZXUtd2VzdC0xLmFtYXpvbmF3cy5jb20vP0' \
               'FjdGlvbj1HZXRDYWxsZXJJZGVudGl0eSZWZXJzaW9uPTIwMTEtMDYtMTUmWC1' \
               'BbXotQWxnb3JpdGhtPUFXUzQtSE1BQy1TSEEyNTYmWC1BbXotQ3JlZGVudGlh' \
               'bD1mYWtlJTJGMjAxMTA2MjElMkZldS13ZXN0LTElMkZzdHMlMkZhd3M0X3Jlc' \
               'XVlc3QmWC1BbXotRGF0ZT0yMDExMDYyMVQxODQwMDBaJlgtQW16LUV4cGlyZX' \
               'M9NjAmWC1BbXotU2lnbmVkSGVhZGVycz1ob3N0JTNCeC1rOHMtYXdzLWlkJlg' \
               'tQW16LVNpZ25hdHVyZT1mYWUxNDA5NDA2OGMzYWUzNmE1MTI3NzY3ZmIwMzE4' \
               'ZmE5ZjhjZmJjNzJmMTg2N2I2ZDY4MGY3OTc1Y2I5YTcw'

    actual = handler.get_bearer_token('test-cluster', 'eu-west-1')
    assert expected == actual


def test_create_kube_config(handler, fs, mock_eks):
    # pyfakefs always initialises a temp dir, on Mac it is /var on Linux it is /tmp
    # https://github.com/jmcgeheeiv/pyfakefs/issues/329
    if not os.path.exists('/tmp'):
        fs.create_dir('/tmp')

    kube_config_loc = os.path.join(os.path.dirname(__file__), 'fixtures/kube_config.yaml')
    fs.add_real_file(kube_config_loc)

    handler.create_kube_config(mock_eks, 'test-cluster')

    assert os.path.exists('/tmp/kubeconfig') is True

    with open('/tmp/kubeconfig', 'r') as actual,  open(kube_config_loc, 'r') as expected:
        assert actual.read() == expected.read()


@freeze_time("2014-04-09 01:30:00")
def test_handler_eks(mocker, monkeypatch, patched_handler, fake_eks_env, mock_k8s_client, mock_event):
    monkeypatch.setenv('AWS_ACCESS_KEY_ID', 'fake')
    monkeypatch.setenv('AWS_SECRET_ACCESS_KEY', 'fake')

    patched_handler._lambda_handler(fake_eks_env, mocker.Mock(), mock_k8s_client, mock_event)

    bearer_token = 'k8s-aws-v1.aHR0cHM6Ly9zdHMuZXUtd2VzdC0xLmFtYXpvbmF3cy5jb20vP' \
                   '0FjdGlvbj1HZXRDYWxsZXJJZGVudGl0eSZWZXJzaW9uPTIwMTEtMDYtMTUmW' \
                   'C1BbXotQWxnb3JpdGhtPUFXUzQtSE1BQy1TSEEyNTYmWC1BbXotQ3JlZGVud' \
                   'GlhbD1mYWtlJTJGMjAxNDA0MDklMkZldS13ZXN0LTElMkZzdHMlMkZhd3M0X' \
                   '3JlcXVlc3QmWC1BbXotRGF0ZT0yMDE0MDQwOVQwMTMwMDBaJlgtQW16LUV4c' \
                   'GlyZXM9NjAmWC1BbXotU2lnbmVkSGVhZGVycz1ob3N0JTNCeC1rOHMtYXdzL' \
                   'WlkJlgtQW16LVNpZ25hdHVyZT04OGY5OWViNjc1YjAwNDU4MTYxNDNhMmQ5Y' \
                   '2I3YjhhZjE2Y2QyNWZkN2I1Nzg5NDFlMjczNzNhNzU3NTRjM2Ex'

    assert mock_k8s_client.Configuration.return_value.api_key['authorization'] == bearer_token
    assert mock_k8s_client.Configuration.return_value.api_key_prefix['authorization'] == 'Bearer'

    mock_k8s_client.CoreV1Api.return_value.patch_node.assert_called_with('test_node', mocker.ANY)
    mock_k8s_client.CoreV1Api.return_value.list_pod_for_all_namespaces.assert_called_with(watch=False,
                                                                                          include_uninitialized=True,
                                                                                          field_selector='spec.nodeName=test_node')
    assert mock_k8s_client.CoreV1Api.return_value.create_namespaced_pod_eviction.call_count == 2

    patched_handler.asg.complete_lifecycle_action.assert_called_with(LifecycleHookName='k8s-drainer-LifecycleHook-DDXJNVV0KBG1',
                                                                     AutoScalingGroupName='k8s-worker-nodes-dev-NodeGroup-F49231EK31OA',
                                                                     LifecycleActionResult='CONTINUE',
                                                                     InstanceId='i-036e525e159f62a5d')


def test_handler_noneks(mocker, monkeypatch, patched_handler, fake_noneks_env, mock_k8s_client, mock_event):
    monkeypatch.setenv('AWS_ACCESS_KEY_ID', 'fake')
    monkeypatch.setenv('AWS_SECRET_ACCESS_KEY', 'fake')

    patched_handler._lambda_handler(fake_noneks_env, mocker.Mock(), mock_k8s_client, mock_event)

    patched_handler.s3.download_file.assert_called_with('bucket', 'object', '/tmp/kubeconfig')

    assert mock_k8s_client.Configuration.return_value.api_key.get('authorization') == None
    assert mock_k8s_client.Configuration.return_value.api_key_prefix.get('authorization') == None

    mock_k8s_client.CoreV1Api.return_value.patch_node.assert_called_with('test_node', mocker.ANY)
    mock_k8s_client.CoreV1Api.return_value.list_pod_for_all_namespaces.assert_called_with(watch=False,
                                                                                          include_uninitialized=True,
                                                                                          field_selector='spec.nodeName=test_node')
    assert mock_k8s_client.CoreV1Api.return_value.create_namespaced_pod_eviction.call_count == 2

    patched_handler.asg.complete_lifecycle_action.assert_called_with(LifecycleHookName='k8s-drainer-LifecycleHook-DDXJNVV0KBG1',
                                                                     AutoScalingGroupName='k8s-worker-nodes-dev-NodeGroup-F49231EK31OA',
                                                                     LifecycleActionResult='CONTINUE',
                                                                     InstanceId='i-036e525e159f62a5d')


def test_handler_no_nodes(mocker, monkeypatch, patched_handler, fake_eks_env, mock_k8s_client_no_nodes, mock_event):
    monkeypatch.setenv('AWS_ACCESS_KEY_ID', 'fake')
    monkeypatch.setenv('AWS_SECRET_ACCESS_KEY', 'fake')

    patched_handler._lambda_handler(fake_eks_env, mocker.Mock(), mock_k8s_client_no_nodes, mock_event)

    patched_handler.asg.complete_lifecycle_action.assert_called_with(LifecycleHookName='k8s-drainer-LifecycleHook-DDXJNVV0KBG1',
                                                                     AutoScalingGroupName='k8s-worker-nodes-dev-NodeGroup-F49231EK31OA',
                                                                     LifecycleActionResult='ABANDON',
                                                                     InstanceId='i-036e525e159f62a5d')


def test_handler_patch_exception(mocker, monkeypatch, patched_handler, fake_eks_env, mock_k8s_client_patch_exception, mock_event):
    monkeypatch.setenv('AWS_ACCESS_KEY_ID', 'fake')
    monkeypatch.setenv('AWS_SECRET_ACCESS_KEY', 'fake')

    patched_handler._lambda_handler(fake_eks_env, mocker.Mock(), mock_k8s_client_patch_exception, mock_event)

    patched_handler.asg.complete_lifecycle_action.assert_called_with(LifecycleHookName='k8s-drainer-LifecycleHook-DDXJNVV0KBG1',
                                                                     AutoScalingGroupName='k8s-worker-nodes-dev-NodeGroup-F49231EK31OA',
                                                                     LifecycleActionResult='ABANDON',
                                                                     InstanceId='i-036e525e159f62a5d')


def test_handler_pods_exception(mocker, monkeypatch, patched_handler, fake_eks_env, mock_k8s_client_pods_exception, mock_event):
    monkeypatch.setenv('AWS_ACCESS_KEY_ID', 'fake')
    monkeypatch.setenv('AWS_SECRET_ACCESS_KEY', 'fake')

    patched_handler._lambda_handler(fake_eks_env, mocker.Mock(), mock_k8s_client_pods_exception, mock_event)

    patched_handler.asg.complete_lifecycle_action.assert_called_with(LifecycleHookName='k8s-drainer-LifecycleHook-DDXJNVV0KBG1',
                                                                     AutoScalingGroupName='k8s-worker-nodes-dev-NodeGroup-F49231EK31OA',
                                                                     LifecycleActionResult='ABANDON',
                                                                     InstanceId='i-036e525e159f62a5d')


def test_main_handler(patched_main_handler, mock_event):
    patched_main_handler.lambda_handler(mock_event, {})
    k8s = patched_main_handler.k8s
    env = {
        'cluster_name': 'test-cluster',
        'kube_config_bucket': 'bucket',
        'kube_config_object': 'object'
    }

    patched_main_handler._lambda_handler.assert_called_with(env, k8s.config, k8s.client, mock_event)