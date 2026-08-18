#!/usr/bin/env python3
"""Verify the Cloudinary unsigned upload preset accepts both images and raw files.

This does not test the Flutter UI, but it confirms the backend preset is configured
correctly for avatar/logo/screenshot (image) and project document (raw) uploads.
"""

import base64
import json
import sys
import urllib.error
import urllib.request
from urllib.parse import urlencode

CLOUD_NAME = 'pkplgkql'
UPLOAD_PRESET = 'acquirebase_unsigned'

# A valid 1x1 transparent PNG, base64-encoded.
TINY_PNG_B64 = (
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8'
    'z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=='
)


def build_multipart_body(fields):
    """Build a multipart/form-data body from a dict of plain fields and file tuples."""
    boundary = '----CloudinaryUploadTestBoundary'
    body = bytearray()

    for name, value in fields.items():
        if isinstance(value, tuple):
            filename, content_type, data = value
            body += f'--{boundary}\r\n'.encode()
            body += (
                f'Content-Disposition: form-data; name="{name}"; '
                f'filename="{filename}"\r\n'
            ).encode()
            body += f'Content-Type: {content_type}\r\n\r\n'.encode()
            if isinstance(data, str):
                body += data.encode()
            else:
                body += data
            body += b'\r\n'
        else:
            body += f'--{boundary}\r\n'.encode()
            body += (
                f'Content-Disposition: form-data; name="{name}"\r\n\r\n'
            ).encode()
            body += f'{value}\r\n'.encode()

    body += f'--{boundary}--\r\n'.encode()
    return bytes(body), boundary


def upload(resource_type, fields):
    url = f'https://api.cloudinary.com/v1_1/{CLOUD_NAME}/{resource_type}/upload'
    body, boundary = build_multipart_body(fields)
    headers = {
        'Content-Type': f'multipart/form-data; boundary={boundary}',
        'Content-Length': str(len(body)),
    }
    request = urllib.request.Request(url, data=body, headers=headers, method='POST')
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            return json.loads(response.read().decode())
    except urllib.error.HTTPError as e:
        error_body = e.read().decode()
        raise RuntimeError(f'HTTP {e.code}: {error_body}') from e


def test_image_upload():
    print('Testing image upload...')
    png_bytes = base64.b64decode(TINY_PNG_B64)
    result = upload(
        'image',
        {
            'upload_preset': UPLOAD_PRESET,
            'folder': 'acquirebase/test',
            'file': ('test_avatar.png', 'image/png', png_bytes),
        },
    )
    secure_url = result.get('secure_url')
    print(f'  Image upload OK: {secure_url}')
    return secure_url


def test_raw_upload():
    print('Testing raw/document upload...')
    document = 'This is a test project document from AcquireBase upload verification.'
    result = upload(
        'raw',
        {
            'upload_preset': UPLOAD_PRESET,
            'folder': 'acquirebase/test',
            'file': ('test_document.txt', 'text/plain', document),
        },
    )
    secure_url = result.get('secure_url')
    print(f'  Raw upload OK: {secure_url}')
    return secure_url


def main():
    print(f'Cloudinary upload verification for cloud: {CLOUD_NAME}')
    print()

    try:
        image_url = test_image_upload()
        raw_url = test_raw_upload()
    except Exception as e:
        print(f'Upload verification FAILED: {e}', file=sys.stderr)
        sys.exit(1)

    print()
    print('Both image and raw uploads succeeded.')
    print(f'  Image: {image_url}')
    print(f'  Raw:   {raw_url}')


if __name__ == '__main__':
    main()
