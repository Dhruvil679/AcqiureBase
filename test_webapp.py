"""
Playwright smoke test for the AcquireBase Flutter web build.

Flutter web renders to canvas, so normal selectors don't work. This script
loads the app, tries touch interactions to advance through onboarding,
captures screenshots, and checks the browser console for errors.
"""

import os
import sys
import time
from playwright.sync_api import sync_playwright

BASE_URL = 'http://localhost:8080'
SCREENSHOT_DIR = 'test_screenshots'


def wait_and_shot(page, filename, delay=1.5):
    """Wait a bit, then take a full-page screenshot."""
    time.sleep(delay)
    path = os.path.join(SCREENSHOT_DIR, filename)
    page.screenshot(path=path, full_page=True)
    print(f'  Screenshot: {path}')
    return path


def tap(page, x, y):
    """Tap at (x, y) using touch events, which Flutter web often handles better."""
    page.touchscreen.tap(x, y)


def main():
    os.makedirs(SCREENSHOT_DIR, exist_ok=True)
    errors = []

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(
            viewport={'width': 1280, 'height': 720},
            has_touch=True,
        )
        page = context.new_page()

        page.on('console', lambda msg: errors.append(msg.text) if msg.type == 'error' else None)
        page.on('pageerror', lambda exc: errors.append(str(exc)))

        print(f'Navigating to {BASE_URL}...')
        page.goto(BASE_URL)

        print('Waiting for onboarding...')
        wait_and_shot(page, '01_onboarding.png', delay=5.0)

        print('Tapping Next...')
        tap(page, 1180, 670)
        wait_and_shot(page, '02_after_tap1.png', delay=2.0)

        print('Tapping Next again...')
        tap(page, 1180, 670)
        wait_and_shot(page, '03_after_tap2.png', delay=2.0)

        print('Tapping Get Started...')
        tap(page, 1180, 670)
        wait_and_shot(page, '04_login.png', delay=2.5)

        print('Testing empty-form validation on login...')
        # Tap the Sign In button without entering credentials.
        page.touchscreen.tap(640, 540)
        wait_and_shot(page, '05_login_validation.png', delay=2.0)

        print('Testing reload (onboarding should now be skipped)...')
        page.reload()
        wait_and_shot(page, '06_after_reload.png', delay=5.0)

        browser.close()

    print('\nTest complete.')
    if errors:
        print(f'Console/page errors detected ({len(errors)}):')
        for err in errors[:20]:
            print(f'  - {err}')
        sys.exit(1)
    else:
        print('No console/page errors detected.')
        sys.exit(0)


if __name__ == '__main__':
    main()
