from kubernetes.client.rest import ApiException
from mock import call

from drainer.k8s_utils import (abandon_lifecycle_action, cordon_node, node_exists, remove_all_pods)
from tests.utils import dict_to_simple_namespace


def test_node_exists(mocker):
    list_nodes_val = dict_to_simple_namespace({'items': [{'metadata': {'name': 'test_node'}}]})
    mock_api = mocker.Mock(**{'list_node.return_value': list_nodes_val})

    assert node_exists(mock_api, 'test_node') is True
    assert node_exists(mock_api, 'nope') is False


def test_abandon_lifecycle_action(mocker):
    asg_mock = mocker.Mock()
    abandon_lifecycle_action(asg_mock, 'asg', 'hook_name', 'instance_id')

    mock_args = {'LifecycleHookName': 'hook_name',
                 'AutoScalingGroupName': 'asg',
                 'LifecycleActionResult': 'ABANDON',
                 'InstanceId': 'instance_id'}

    asg_mock.complete_lifecycle_action.assert_called_with(**mock_args)


def test_cordon_node(mocker):
    api_mock = mocker.Mock()
    cordon_node(api_mock, 'test_node')

    mock_arg = {
        'apiVersion': 'v1',
        'kind': 'Node',
        'metadata': {
            'name': 'test_node'
        },
        'spec': {
            'unschedulable': True
        }
    }

    api_mock.patch_node.assert_called_with('test_node', mock_arg)


def test_remove_all_pods(mocker):
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

    mock_api = mocker.Mock(**{'list_pod_for_all_namespaces.side_effect': [list_pods_val, empty_list_pods_val]})

    remove_all_pods(mock_api, 'test_node')

    mock_api.list_pod_for_all_namespaces.assert_called_with(watch=False, include_uninitialized=True, field_selector='spec.nodeName=test_node')

    mock_arg = {
        'apiVersion': 'policy/v1beta1',
        'kind': 'Eviction',
        'deleteOptions': {},
        'metadata': {
            'name': 'test_pod1',
            'namespace': 'test_ns'
        }
    }

    mock_arg1 = {
        'apiVersion': 'policy/v1beta1',
        'kind': 'Eviction',
        'deleteOptions': {},
        'metadata': {
            'name': 'test_pod2',
            'namespace': 'test_ns'
        }
    }

    mock_api.create_namespaced_pod_eviction.assert_any_call('test_pod1-eviction', 'test_ns', mock_arg)
    mock_api.create_namespaced_pod_eviction.assert_any_call('test_pod2-eviction', 'test_ns', mock_arg1)


def test_remove_disruption_failure(mocker):
    list_pods_val = dict_to_simple_namespace({'items': [
        {'metadata': {
            'uid': 'aaa',
            'name': 'test_pod1',
            'namespace': 'test_ns',
            'annotations': None,
            'owner_references': None
        }
        }
    ]})
    empty_list_pods_val = dict_to_simple_namespace({'items': []})

    mock_api = mocker.Mock(**{'list_pod_for_all_namespaces.side_effect': [list_pods_val, empty_list_pods_val],
                              'create_namespaced_pod_eviction.side_effect': [ApiException(status=429), None]}
                           )

    remove_all_pods(mock_api, 'test_node', poll=1)

    mock_api.list_pod_for_all_namespaces.assert_called_with(watch=False, include_uninitialized=True, field_selector='spec.nodeName=test_node')

    mock_arg = {
        'apiVersion': 'policy/v1beta1',
        'kind': 'Eviction',
        'deleteOptions': {},
        'metadata': {
            'name': 'test_pod1',
            'namespace': 'test_ns'
        }
    }

    mock_api.create_namespaced_pod_eviction.assert_has_calls([
        call('test_pod1-eviction', 'test_ns', mock_arg),
        call('test_pod1-eviction', 'test_ns', mock_arg)]
    )


def test_remove_pending(mocker):
    list_pods_val = dict_to_simple_namespace({'items': [
        {'metadata': {
            'uid': 'aaa',
            'name': 'test_pod1',
            'namespace': 'test_ns',
            'annotations': None,
            'owner_references': None
        }
        }
    ]})
    empty_list_pods_val = dict_to_simple_namespace({'items': []})

    mock_api = mocker.Mock(**{'list_pod_for_all_namespaces.side_effect': [list_pods_val, list_pods_val, empty_list_pods_val]})

    remove_all_pods(mock_api, 'test_node', poll=1)

    mock_api.list_pod_for_all_namespaces.assert_has_calls([
        call(watch=False, include_uninitialized=True, field_selector='spec.nodeName=test_node'),
        call(watch=False, include_uninitialized=True, field_selector='spec.nodeName=test_node'),
        call(watch=False, include_uninitialized=True, field_selector='spec.nodeName=test_node')
    ])

    mock_arg = {
        'apiVersion': 'policy/v1beta1',
        'kind': 'Eviction',
        'deleteOptions': {},
        'metadata': {
            'name': 'test_pod1',
            'namespace': 'test_ns'
        }
    }

    mock_api.create_namespaced_pod_eviction.assert_any_call('test_pod1-eviction', 'test_ns', mock_arg)


def test_skip_daemonsets(mocker):
    list_pods_val = dict_to_simple_namespace({'items': [
        {'metadata': {
            'uid': 'aaa',
            'name': 'test_pod1',
            'namespace': 'test_ns',
            'annotations': None,
            'owner_references': [
                {
                    'controller': True,
                    'kind': 'DaemonSet'
                }
            ]
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
    unevictable_pods_val = dict_to_simple_namespace({'items': [
        {'metadata': {
            'uid': 'aaa',
            'name': 'test_pod1',
            'namespace': 'test_ns',
            'annotations': None,
            'owner_references': [
                {
                    'controller': True,
                    'kind': 'DaemonSet'
                }
            ]
        }
        }
    ]})
    mock_api = mocker.Mock(**{'list_pod_for_all_namespaces.side_effect': [list_pods_val, unevictable_pods_val]})

    remove_all_pods(mock_api, 'test_node')

    mock_api.list_pod_for_all_namespaces.assert_called_with(watch=False, include_uninitialized=True, field_selector='spec.nodeName=test_node')

    mock_arg1 = {
        'apiVersion': 'policy/v1beta1',
        'kind': 'Eviction',
        'deleteOptions': {},
        'metadata': {
            'name': 'test_pod2',
            'namespace': 'test_ns'
        }
    }

    mock_api.create_namespaced_pod_eviction.assert_any_call('test_pod2-eviction', 'test_ns', mock_arg1)

def test_skip_mirror_pods(mocker):
    list_pods_val = dict_to_simple_namespace({'items': [
        {'metadata': {
            'uid': 'aaa',
            'name': 'test_pod1',
            'namespace': 'test_ns',
            'annotations': {
                'kubernetes.io/config.mirror': 'mirror'
            },
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
    ]}, skip={".items.metadata.annotations": True})
    unevictable_pods_val = dict_to_simple_namespace({'items': [
        {'metadata': {
            'uid': 'aaa',
            'name': 'test_pod1',
            'namespace': 'test_ns',
            'annotations': {
                'kubernetes.io/config.mirror': 'mirror'
            },
            'owner_references': None
        }
        }
    ]}, skip={".items.metadata.annotations": True})
    mock_api = mocker.Mock(**{'list_pod_for_all_namespaces.side_effect': [list_pods_val, unevictable_pods_val]})

    remove_all_pods(mock_api, 'test_node')

    mock_api.list_pod_for_all_namespaces.assert_called_with(watch=False, include_uninitialized=True, field_selector='spec.nodeName=test_node')

    mock_arg1 = {
        'apiVersion': 'policy/v1beta1',
        'kind': 'Eviction',
        'deleteOptions': {},
        'metadata': {
            'name': 'test_pod2',
            'namespace': 'test_ns'
        }
    }

    mock_api.create_namespaced_pod_eviction.assert_any_call('test_pod2-eviction', 'test_ns', mock_arg1)
