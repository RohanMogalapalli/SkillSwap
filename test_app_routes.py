import unittest
import time
from app.app import app
from app import db

class SkillSwapAppTests(unittest.TestCase):
    def setUp(self):
        self.client = app.test_client()
        app.config['TESTING'] = True

    def test_01_landing_page(self):
        response = self.client.get('/')
        self.assertEqual(response.status_code, 200)
        self.assertIn(b'SkillSwap', response.data)

    def test_02_login_page(self):
        response = self.client.get('/login')
        self.assertEqual(response.status_code, 200)
        self.assertIn(b'Mogalapalli Rohan', response.data)

    def test_03_quick_login_and_dashboard(self):
        # Quick login as Rohan (user_id 1)
        response = self.client.get('/quick-login/1', follow_redirects=True)
        self.assertEqual(response.status_code, 200)
        self.assertIn(b'Mogalapalli Rohan', response.data)
        self.assertIn(b'Skill Wallet', response.data)

    def test_04_skills_catalog(self):
        response = self.client.get('/skills')
        self.assertEqual(response.status_code, 200)
        self.assertIn(b'Python Programming', response.data)

    def test_05_sessions_list(self):
        with self.client.session_transaction() as sess:
            sess['user_id'] = 1
            sess['user_name'] = 'Mogalapalli Rohan'
            sess['role'] = 'STUDENT'
        response = self.client.get('/sessions')
        self.assertEqual(response.status_code, 200)
        self.assertIn(b'Peer Learning Sessions', response.data)

    def test_06_credits_ledger(self):
        with self.client.session_transaction() as sess:
            sess['user_id'] = 1
            sess['user_name'] = 'Mogalapalli Rohan'
            sess['role'] = 'STUDENT'
        response = self.client.get('/credits')
        self.assertEqual(response.status_code, 200)
        self.assertIn(b'Credit Audit Ledger', response.data)

    def test_07_certificates_and_verification(self):
        # Check certificates page
        with self.client.session_transaction() as sess:
            sess['user_id'] = 1 # Rohan has earned certificate
            sess['user_name'] = 'Mogalapalli Rohan'
            sess['role'] = 'STUDENT'
        response = self.client.get('/certificates')
        self.assertEqual(response.status_code, 200)
        self.assertIn(b'CERT-JAVA-2026-0002', response.data)

        # Check public verification endpoint
        response = self.client.get('/verify-certificate?code=CERT-JAVA-2026-0002')
        self.assertEqual(response.status_code, 200)
        self.assertIn(b'Authentic Campus Credential', response.data)

    def test_08_dbms_showcase(self):
        response = self.client.get('/dbms-showcase')
        self.assertEqual(response.status_code, 200)
        self.assertIn(b'Database Management Systems Concepts', response.data)
        self.assertIn(b'v_top_mentors', response.data)

    def test_09_complete_session_procedure(self):
        # Test executing complete_session on session 3 (scheduled between Rohan & Hemanth)
        ok, msg = db.call_complete_session(3)
        self.assertTrue(ok)
        print("PL/SQL complete_session test output:", msg)

    def test_10_college_email_restriction(self):
        # Invalid personal email must be rejected
        resp_invalid = self.client.post('/register', data={
            'name': 'Test User',
            'email': 'user@gmail.com',
            'password': 'password123',
            'department': 'CSE',
            'year': 2,
            'phone': '9999999999'
        }, follow_redirects=True)
        self.assertIn(b'Only official college emails', resp_invalid.data)

        # Valid college email with dynamic timestamp succeeds
        unique_email = f"student.{int(time.time())}@vitstudent.ac.in"
        resp_valid = self.client.post('/register', data={
            'name': 'VIT Student New',
            'email': unique_email,
            'password': 'password123',
            'department': 'CSE',
            'year': 2,
            'phone': '9999999998'
        }, follow_redirects=True)
        self.assertIn(b'Your account is active with 50 welcome Skill Credits', resp_valid.data)

if __name__ == '__main__':
    unittest.main()
