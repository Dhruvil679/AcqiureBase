"""
Verify that admin role/suspension updates work through Firestore security rules
without deployed Cloud Functions. This validates the same direct-Firestore path
that AdminFunctionsService falls back to on the Spark plan.
"""
import json
import sys
import time
import requests

API_KEY = 'AIzaSyCL6JEyfEnyjXeJetEBDj5mkA9N3-LBeJg'
PROJECT_ID = 'saas-management-du664'
TARGET_UID = '00rkFd6lYiX0xRBKFsncZKcra9t1'  # existing test user (trivedi)


def sign_up(email, password):
    url = f'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key={API_KEY}'
    r = requests.post(url, json={'email': email, 'password': password, 'returnSecureToken': True})
    r.raise_for_status()
    data = r.json()
    return data['localId'], data['idToken'], data['refreshToken']


def sign_in(email, password):
    url = f'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={API_KEY}'
    r = requests.post(url, json={'email': email, 'password': password, 'returnSecureToken': True})
    r.raise_for_status()
    return r.json()['idToken']


def firestore_update_field(uid, field, value, id_token):
    """Update a single field on users/{uid} using Firestore REST with auth token."""
    url = (
        f'https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents/users/{uid}'
        f'?updateMask.fieldPaths={field}'
    )
    body = {
        'fields': {
            field: _value_field(value),
        }
    }
    headers = {'Authorization': f'Bearer {id_token}', 'Content-Type': 'application/json'}
    r = requests.patch(url, headers=headers, json=body)
    if not r.ok:
        print(f'Firestore update failed: {r.status_code} {r.text}')
    r.raise_for_status()
    return r.json()


def _value_field(value):
    if isinstance(value, bool):
        return {'booleanValue': value}
    if isinstance(value, str):
        return {'stringValue': value}
    raise ValueError(f'Unsupported value type: {type(value)}')


def firestore_get_user(uid):
    url = f'https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents/users/{uid}'
    # No auth needed for read if public, but users are not public; use a service account? Use MCP instead.
    # We'll just return via REST without auth (will fail for non-public) and catch.
    r = requests.get(url)
    return r


def main():
    ts = int(time.time())
    email = f'admintest_{ts}@tempmail.example'
    password = 'TestPass123!'

    print(f'Creating admin test user {email}...')
    admin_uid, id_token, refresh = sign_up(email, password)
    print(f'Created admin candidate uid={admin_uid}')

    # Promote the candidate to admin using the Admin SDK path (this is what
    # would happen via Cloud Functions on Blaze, or via a trusted console/tool).
    print('Promoting candidate to admin via Firestore Admin path...')
    # The MCP tool call is performed by the assistant after this script prints
    # the uid. For now, we just print it and exit; a second script will run
    # after the role is set.
    print('\n--- SET THIS USER TO ADMIN ---')
    print(f'UID: {admin_uid}')
    print(f'Email: {email}')
    print(f'Password: {password}')
    print(f'Target user UID for testing: {TARGET_UID}')
    print('Run the next step after promoting the admin candidate in Firestore.')


if __name__ == '__main__':
    main()
