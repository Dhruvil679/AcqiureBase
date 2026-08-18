"""
Sign in as the throwaway admin user and verify that direct Firestore updates to
role and isSuspended succeed through the security rules. This is the same path
AdminFunctionsService uses when Cloud Functions are unavailable.
"""
import json
import sys
import time
import requests

API_KEY = 'AIzaSyCL6JEyfEnyjXeJetEBDj5mkA9N3-LBeJg'
PROJECT_ID = 'saas-management-du664'
ADMIN_EMAIL = 'admintest_1786873925@tempmail.example'
PASSWORD = 'TestPass123!'
TARGET_UID = '00rkFd6lYiX0xRBKFsncZKcra9t1'


def sign_in(email, password):
    url = f'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={API_KEY}'
    r = requests.post(url, json={'email': email, 'password': password, 'returnSecureToken': True})
    r.raise_for_status()
    return r.json()['idToken']


def _value_field(value):
    if isinstance(value, bool):
        return {'booleanValue': value}
    if isinstance(value, str):
        return {'stringValue': value}
    raise ValueError(f'Unsupported value type: {type(value)}')


def update_user_field(uid, field, value, id_token):
    url = (
        f'https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents/users/{uid}'
        f'?updateMask.fieldPaths={field}'
    )
    body = {'fields': {field: _value_field(value)}}
    headers = {'Authorization': f'Bearer {id_token}', 'Content-Type': 'application/json'}
    r = requests.patch(url, headers=headers, json=body)
    if not r.ok:
        print(f'FAILED: {r.status_code} {r.text}')
        return False
    return True


def get_user_field(uid, field, id_token=None):
    url = (
        f'https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents/users/{uid}'
    )
    headers = {}
    if id_token:
        headers['Authorization'] = f'Bearer {id_token}'
    r = requests.get(url, headers=headers)
    if not r.ok:
        print(f'GET failed: {r.status_code} {r.text}')
        return None
    fields = r.json().get('fields', {})
    f = fields.get(field, {})
    return f.get('stringValue') if 'stringValue' in f else f.get('booleanValue')


def main():
    print('Signing in as admin test user...')
    id_token = sign_in(ADMIN_EMAIL, PASSWORD)
    print('Got ID token.')

    # 1. Promote target to admin.
    print('Promoting target to admin...')
    if not update_user_field(TARGET_UID, 'role', 'admin', id_token):
        sys.exit(1)
    time.sleep(1)
    role = get_user_field(TARGET_UID, 'role', id_token)
    print(f'  role after promote: {role}')
    assert role == 'admin', f'Expected admin, got {role}'

    # 2. Demote target back to user.
    print('Demoting target back to user...')
    if not update_user_field(TARGET_UID, 'role', 'user', id_token):
        sys.exit(1)
    time.sleep(1)
    role = get_user_field(TARGET_UID, 'role', id_token)
    print(f'  role after demote: {role}')
    assert role == 'user', f'Expected user, got {role}'

    # 3. Suspend target.
    print('Suspending target...')
    if not update_user_field(TARGET_UID, 'isSuspended', True, id_token):
        sys.exit(1)
    time.sleep(1)
    suspended = get_user_field(TARGET_UID, 'isSuspended', id_token)
    print(f'  isSuspended after suspend: {suspended}')
    assert suspended is True, f'Expected true, got {suspended}'

    # 4. Activate target.
    print('Activating target...')
    if not update_user_field(TARGET_UID, 'isSuspended', False, id_token):
        sys.exit(1)
    time.sleep(1)
    suspended = get_user_field(TARGET_UID, 'isSuspended', id_token)
    print(f'  isSuspended after activate: {suspended}')
    assert suspended is False, f'Expected false, got {suspended}'

    print('\nAll admin direct-Firestore actions succeeded.')


if __name__ == '__main__':
    main()
