"""
Register a throwaway admin-test user on the live AcquireBase web app.
After registration the script prints the user's email and username so the
session can promote them to admin in Firestore before testing admin actions.
"""
import os
import sys
import time
from datetime import datetime
from playwright.sync_api import sync_playwright

BASE_URL = 'https://saas-management-du664-58970.web.app'
PASSWORD = 'TestPass123!'
TIMESTAMP = datetime.now().strftime('%Y%m%d%H%M%S')
ADMIN_EMAIL = f'admintest_{TIMESTAMP}@tempmail.example'
ADMIN_USERNAME = f'admintest_{TIMESTAMP}'
ADMIN_USER = {
    'email': ADMIN_EMAIL,
    'username': ADMIN_USERNAME,
    'firstName': 'Admin',
    'lastName': 'Test',
    'age': '25',
}

SCREENSHOT_DIR = 'test_screenshots'


def enable_accessibility(page):
    placeholder = page.locator('flt-semantics-placeholder')
    try:
        placeholder.evaluate('el => el.dispatchEvent(new MouseEvent("click", {bubbles: true}))')
        time.sleep(0.8)
    except Exception:
        pass


def screenshot(page, name):
    path = os.path.join(SCREENSHOT_DIR, f'{name}.png')
    try:
        page.screenshot(path=path, full_page=True)
    except Exception as exc:
        print(f'  screenshot failed: {exc}', file=sys.stderr)
    return path


def wait_for_splash(page):
    time.sleep(3.5)


def handle_onboarding(page):
    try:
        page.get_by_text('Skip').first.click(timeout=3000)
        time.sleep(0.8)
    except Exception:
        pass


def fill_field(page, label, value):
    field = page.locator(f'[aria-label="{label}"]').first
    field.scroll_into_view_if_needed()
    field.click()
    time.sleep(0.3)
    inp = page.locator(f'input[aria-label="{label}"]').first
    inp.fill(value)
    time.sleep(0.2)


def click_by_text(page, text, timeout=5000):
    locator = page.locator(f'flt-semantics:has-text("{text}")').first
    locator.wait_for(timeout=timeout)
    locator.scroll_into_view_if_needed()
    locator.click()
    time.sleep(0.2)


def register_user(page, user):
    print(f"Registering {user['email']}...")

    page.get_by_text('Sign Up').first.click()
    time.sleep(1.0)
    screenshot(page, 'admin_register_form')

    fill_field(page, 'Email', user['email'])
    fill_field(page, 'Password', PASSWORD)
    fill_field(page, 'Confirm password', PASSWORD)
    fill_field(page, 'Username', user['username'])
    fill_field(page, 'First name', user['firstName'])
    fill_field(page, 'Surname', user['lastName'])
    fill_field(page, 'Age', user['age'])

    click_by_text(page, 'Select profession')
    time.sleep(0.6)
    for option in ['Founder', 'Student', 'Employee', 'Self-employed', 'Other']:
        try:
            opt = page.get_by_role('button', name=option)
            if opt.count() > 0:
                opt.first.click()
                time.sleep(0.3)
                break
        except Exception:
            continue

    page.locator('[aria-label="Flutter"]').first.click()
    time.sleep(0.3)

    screenshot(page, 'admin_register_filled')

    page.get_by_role('button', name='Sign Up').first.click()
    time.sleep(4.0)
    try:
        page.wait_for_load_state('networkidle', timeout=5000)
    except Exception:
        pass
    screenshot(page, 'admin_register_home')

    print(f"Registered {user['email']} successfully.")


def main():
    os.makedirs(SCREENSHOT_DIR, exist_ok=True)

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context()
        page = context.new_page()

        page.goto(BASE_URL)
        try:
            page.wait_for_load_state('networkidle', timeout=10000)
        except Exception:
            pass
        wait_for_splash(page)
        enable_accessibility(page)
        screenshot(page, 'admin_splash')

        handle_onboarding(page)
        screenshot(page, 'admin_login')

        register_user(page, ADMIN_USER)

        browser.close()

    print('\n--- ADMIN TEST USER CREATED ---')
    print(f"email: {ADMIN_EMAIL}")
    print(f"username: {ADMIN_USERNAME}")
    print(f"password: {PASSWORD}")
    print('Set role=admin on this user in Firestore, then run the admin-action test.')


if __name__ == '__main__':
    main()
