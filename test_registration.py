from playwright.sync_api import sync_playwright
import os

BASE_URL = 'http://localhost:8080'
PASSWORD = 'TestPass123!'
USERS = [
  {
    "email": "aarav.mehta@example.com",
    "firstname": "Aarav",
    "lastname": "Mehta",
    "username": "aarav_mehta",
    "password": "Test@Aarav01",
    "age": 24,
    "profession": "Founder",
    "skills": ["Python", "React"]
  },
  {
    "email": "riya.shah@example.com",
    "firstname": "Riya",
    "lastname": "Shah",
    "username": "riya_shah",
    "password": "Test@Riya02",
    "age": 21,
    "profession": "Student",
    "skills": ["Flutter", "JS"]
  },
  {
    "email": "dev.patel@example.com",
    "firstname": "Dev",
    "lastname": "Patel",
    "username": "dev_patel",
    "password": "Test@Dev03",
    "age": 27,
    "profession": "Self-employed",
    "skills": ["Python", "C / C++"]
  },
  {
    "email": "ananya.joshi@example.com",
    "firstname": "Ananya",
    "lastname": "Joshi",
    "username": "ananya_joshi",
    "password": "Test@Ananya04",
    "age": 23,
    "profession": "Student",
    "skills": ["React", "JS", "Flutter"]
  },
  {
    "email": "kunal.desai@example.com",
    "firstname": "Kunal",
    "lastname": "Desai",
    "username": "kunal_desai",
    "password": "Test@Kunal05",
    "age": 29,
    "profession": "Founder",
    "skills": ["Python", "React", "JS"]
  },
  {
    "email": "neha.trivedi@example.com",
    "firstname": "Neha",
    "lastname": "Trivedi",
    "username": "neha_trivedi",
    "password": "Test@Neha06",
    "age": 26,
    "profession": "Self-employed",
    "skills": ["Flutter", "Python"]
  },
  {
    "email": "yash.solanki@example.com",
    "firstname": "Yash",
    "lastname": "Solanki",
    "username": "yash_solanki",
    "password": "Test@Yash07",
    "age": 20,
    "profession": "Student",
    "skills": ["C / C++", "JS"]
  },
  {
    "email": "ishita.kapoor@example.com",
    "firstname": "Ishita",
    "lastname": "Kapoor",
    "username": "ishita_kapoor",
    "password": "Test@Ishita08",
    "age": 31,
    "profession": "Other",
    "skills": ["React", "Python"]
  },
  {
    "email": "harsh.pandya@example.com",
    "firstname": "Harsh",
    "lastname": "Pandya",
    "username": "harsh_pandya",
    "password": "Test@Harsh09",
    "age": 25,
    "profession": "Founder",
    "skills": ["Flutter", "React"]
  },
  {
    "email": "priya.nair@example.com",
    "firstname": "Priya",
    "lastname": "Nair",
    "username": "priya_nair",
    "password": "Test@Priya10",
    "age": 28,
    "profession": "Self-employed",
    "skills": ["JS", "Python", "C / C++"]
  },
  {
    "email": "aditya.rao@example.com",
    "firstname": "Aditya",
    "lastname": "Rao",
    "username": "aditya_rao",
    "password": "Test@Aditya11",
    "age": 26,
    "profession": "Founder",
    "skills": ["Python", "JS"]
  },
  {
    "email": "simran.agarwal@example.com",
    "firstname": "Simran",
    "lastname": "Agarwal",
    "username": "simran_agarwal",
    "password": "Test@Simran12",
    "age": 22,
    "profession": "Student",
    "skills": ["Flutter", "React"]
  },
  {
    "email": "manav.bhatt@example.com",
    "firstname": "Manav",
    "lastname": "Bhatt",
    "username": "manav_bhatt",
    "password": "Test@Manav13",
    "age": 30,
    "profession": "Self-employed",
    "skills": ["Python", "C / C++"]
  },
  {
    "email": "kavya.iyer@example.com",
    "firstname": "Kavya",
    "lastname": "Iyer",
    "username": "kavya_iyer",
    "password": "Test@Kavya14",
    "age": 24,
    "profession": "Student",
    "skills": ["JS", "React", "Flutter"]
  },
  {
    "email": "rohan.verma@example.com",
    "firstname": "Rohan",
    "lastname": "Verma",
    "username": "rohan_verma",
    "password": "Test@Rohan15",
    "age": 28,
    "profession": "Founder",
    "skills": ["React", "JS", "Python"]
  },
  {
    "email": "meera.singh@example.com",
    "firstname": "Meera",
    "lastname": "Singh",
    "username": "meera_singh",
    "password": "Test@Meera16",
    "age": 27,
    "profession": "Self-employed",
    "skills": ["Flutter", "Python"]
  },
  {
    "email": "dhruv.modi@example.com",
    "firstname": "Dhruv",
    "lastname": "Modi",
    "username": "dhruv_modi",
    "password": "Test@Dhruv17",
    "age": 21,
    "profession": "Student",
    "skills": ["C / C++", "Python"]
  },
  {
    "email": "tanvi.malhotra@example.com",
    "firstname": "Tanvi",
    "lastname": "Malhotra",
    "username": "tanvi_malhotra",
    "password": "Test@Tanvi18",
    "age": 25,
    "profession": "Other",
    "skills": ["React", "JS"]
  },
  {
    "email": "vivek.chauhan@example.com",
    "firstname": "Vivek",
    "lastname": "Chauhan",
    "username": "vivek_chauhan",
    "password": "Test@Vivek19",
    "age": 32,
    "profession": "Founder",
    "skills": ["Python", "Flutter", "React"]
  },
  {
    "email": "sneha.kulkarni@example.com",
    "firstname": "Sneha",
    "lastname": "Kulkarni",
    "username": "sneha_kulkarni",
    "password": "Test@Sneha20",
    "age": 23,
    "profession": "Self-employed",
    "skills": ["JS", "Flutter", "C / C++"]
  }
]



def enable_accessibility(page):
    placeholder = page.locator('flt-semantics-placeholder')
    placeholder.evaluate('el => el.dispatchEvent(new MouseEvent("click", {bubbles: true}))')
    page.wait_for_timeout(1200)


def screenshot(page, name):
    page.screenshot(path=f'test_screenshots/{name}.png', full_page=True)


def wait_for_splash(page):
    page.wait_for_timeout(3500)


def handle_onboarding(page):
    page.get_by_text('Skip').first.click()
    page.wait_for_timeout(1000)


def fill_field(page, label, value):
    field = page.locator(f'[aria-label="{label}"]').first
    field.scroll_into_view_if_needed()
    field.click()
    page.wait_for_timeout(300)
    inp = page.locator(f'input[aria-label="{label}"]').first
    inp.fill(value)
    page.wait_for_timeout(200)


def click_by_label(page, label, timeout=5000):
    """Click the first flt-semantics node whose aria-label or text matches."""
    locator = page.locator(f'flt-semantics[aria-label="{label}"], flt-semantics:has-text("{label}")').first
    locator.wait_for(timeout=timeout)
    locator.scroll_into_view_if_needed()
    locator.click()
    page.wait_for_timeout(200)


def register_user(page, user, index):
    print(f"Registering {user['email']}...")

    # From login, go to register.
    page.get_by_text('Sign Up').first.click()
    page.wait_for_timeout(1000)
    screenshot(page, f'{index}_register_form')

    fill_field(page, 'Email', user['email'])
    fill_field(page, 'Password', PASSWORD)
    fill_field(page, 'Confirm password', PASSWORD)
    fill_field(page, 'Username', user['username'])
    fill_field(page, 'First name', user['firstName'])
    fill_field(page, 'Surname', user['lastName'])
    fill_field(page, 'Age', user['age'])

    # Select profession.
    click_by_label(page, 'Select profession')
    page.wait_for_timeout(600)
    # Try common profession options.
    for option in ['Founder', 'Student', 'Employee', 'Self-employed', 'Other']:
        try:
            opt = page.get_by_role('button', name=option)
            if opt.count() > 0:
                opt.first.click()
                page.wait_for_timeout(300)
                break
        except Exception:
            continue

    # Select Flutter skill.
    page.locator('[aria-label="Flutter"]').first.click()
    page.wait_for_timeout(300)

    screenshot(page, f'{index}_register_filled')

    # Submit.
    page.get_by_role('button', name='Sign Up').first.click()

    # Wait for navigation to home.
    page.wait_for_timeout(4000)
    page.wait_for_load_state('networkidle')
    screenshot(page, f'{index}_home_after_register')

    print(f"Registered {user['email']} successfully.")


def logout(page, index):
    print(f"Logging out {index}...")
    # Bottom nav tabs: Explore, Saved, Dashboard, Profile.
    # Try clicking the last tab (Profile).
    tabs = page.locator('flt-semantics[role="button"]').all()
    if len(tabs) >= 4:
        tabs[-1].click()
        page.wait_for_timeout(1000)

    try:
        logout_btn = page.locator('[aria-label="Log out"], [aria-label="Logout"]').first
        if logout_btn.count() > 0:
            logout_btn.click()
            page.wait_for_timeout(1500)
            print(f"Logged out {index}.")
            return
    except Exception:
        pass

    print(f"Could not log out {index}; will close browser and start fresh.")


def main():
    os.makedirs('test_screenshots', exist_ok=True)

    with sync_playwright() as p:
        for i, user in enumerate(USERS, start=1):
            browser = p.chromium.launch(headless=True)
            context = browser.new_context()
            page = context.new_page()

            page.goto(BASE_URL)
            page.wait_for_load_state('networkidle')
            wait_for_splash(page)
            enable_accessibility(page)
            screenshot(page, f'{i}_splash')

            handle_onboarding(page)
            screenshot(page, f'{i}_login')

            register_user(page, user, i)
            logout(page, i)

            browser.close()


if __name__ == '__main__':
    main()
