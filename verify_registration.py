from playwright.sync_api import sync_playwright
import os
import requests

BASE_URL = 'http://localhost:8080'
API_KEY = 'AIzaSyCL6JEyfEnyjXeJetEBDj5mkA9N3-LBeJg'
EMAIL = 'testverify1@tempmail.example'
PASSWORD = 'TestPass123!'

os.makedirs('test_screenshots', exist_ok=True)

def check_user(email, password):
    url = f'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={API_KEY}'
    r = requests.post(url, json={'email': email, 'password': password, 'returnSecureToken': True})
    print('Auth check:', r.status_code, r.text[:200])
    return r.status_code == 200

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    page = browser.new_page()

    page.goto(BASE_URL)
    page.wait_for_load_state('networkidle')
    page.wait_for_timeout(3500)

    placeholder = page.locator('flt-semantics-placeholder')
    placeholder.evaluate('el => el.dispatchEvent(new MouseEvent("click", {bubbles: true}))')
    page.wait_for_timeout(1200)

    page.get_by_text('Skip').first.click()
    page.wait_for_timeout(1000)

    page.get_by_text('Sign Up').first.click()
    page.wait_for_timeout(1000)

    def fill(label, value):
        page.locator(f'[aria-label="{label}"]').first.click()
        page.wait_for_timeout(300)
        page.locator(f'input[aria-label="{label}"]').first.fill(value)
        page.wait_for_timeout(200)

    def click_by_label(label, timeout=5000):
        locator = page.locator(f'flt-semantics[aria-label="{label}"], flt-semantics:has-text("{label}")').first
        locator.wait_for(timeout=timeout)
        locator.scroll_into_view_if_needed()
        locator.click()
        page.wait_for_timeout(200)

    fill('Email', EMAIL)
    fill('Password', PASSWORD)
    fill('Confirm password', PASSWORD)
    fill('Username', 'testverify1')
    fill('First name', 'Test')
    fill('Surname', 'Verify')
    fill('Age', '25')

    click_by_label('Select profession')
    page.wait_for_timeout(500)
    page.get_by_role('button', name='Founder').first.click()
    page.wait_for_timeout(300)

    page.locator('[aria-label="Flutter"]').first.click()
    page.wait_for_timeout(300)

    page.get_by_role('button', name='Sign Up').first.click()
    page.wait_for_timeout(4000)
    page.wait_for_load_state('networkidle')

    page.screenshot(path='test_screenshots/verify_register_after_submit.png', full_page=True)

    # Check if registration succeeded.
    ok = check_user(EMAIL, PASSWORD)
    print(f'Registration result: {"SUCCESS" if ok else "FAILED"}')

    browser.close()
