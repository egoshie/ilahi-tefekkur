#!/usr/bin/env python3
import concurrent.futures
import os
import tempfile
import unittest

from huzur_support_server import (
    PushNotificationDispatcher,
    SupportDatabase,
    TelegramSupportBridge,
    UUID_REGEX,
)


class Step3PrivacyAndTelegramTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp_dir = tempfile.TemporaryDirectory()
        self.db_path = os.path.join(self.tmp_dir.name, "test_support.db")
        self.db = SupportDatabase(self.db_path)
        self.push = PushNotificationDispatcher()
        self.tg = TelegramSupportBridge(self.db, self.push)

    def tearDown(self) -> None:
        self.tmp_dir.cleanup()

    def test_1_privacy_consent_strictly_required(self) -> None:
        # Onay False iken oturum açılamaz
        with self.assertRaises(ValueError):
            self.db.create_session(
                user_name="Deniz",
                privacy_consent=False,
                privacy_consent_version="2026.1",
            )

        # Onay None veya eksik iken oturum açılamaz
        with self.assertRaises(ValueError):
            self.db.create_session(
                user_name="Deniz",
                privacy_consent=None,
                privacy_consent_version="2026.1",
            )

        # Onay sürümü boş iken oturum açılamaz
        with self.assertRaises(ValueError):
            self.db.create_session(
                user_name="Deniz",
                privacy_consent=True,
                privacy_consent_version="",
            )

    def test_2_sequential_short_codes_and_persistence(self) -> None:
        s_deniz1 = self.db.create_session(
            user_name="Deniz",
            privacy_consent=True,
            privacy_consent_version="2026.1",
            initial_message="Merhaba",
        )
        self.assertEqual(s_deniz1["short_code"], "deniz1")
        self.assertTrue(s_deniz1["privacy_consent"])
        self.assertEqual(s_deniz1["privacy_consent_version"], "2026.1")

        s_deniz2 = self.db.create_session(
            user_name="Deniz",
            privacy_consent=True,
            privacy_consent_version="2026.1",
        )
        self.assertEqual(s_deniz2["short_code"], "deniz2")

        s_ali1 = self.db.create_session(
            user_name="Ali",
            privacy_consent=True,
            privacy_consent_version="2026.1",
        )
        self.assertEqual(s_ali1["short_code"], "ali1")

        s_ali2 = self.db.create_session(
            user_name="Ali",
            privacy_consent=True,
            privacy_consent_version="2026.1",
        )
        self.assertEqual(s_ali2["short_code"], "ali2")

        s_ege1 = self.db.create_session(
            user_name="Ege Deniz",
            privacy_consent=True,
            privacy_consent_version="2026.1",
        )
        self.assertEqual(s_ege1["short_code"], "ege1")

    def test_3_concurrent_sessions_never_collide(self) -> None:
        def create_concurrent(idx: int) -> str:
            s = self.db.create_session(
                user_name="Deniz",
                privacy_consent=True,
                privacy_consent_version="2026.1",
                initial_message=f"Eszamanli mesaj {idx}",
            )
            return s["short_code"]

        with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
            codes = list(pool.map(create_concurrent, range(10)))

        self.assertEqual(len(codes), 10)
        self.assertEqual(len(set(codes)), 10)
        expected = {f"deniz{i}" for i in range(1, 11)}
        self.assertEqual(set(codes), expected)

    def test_4_telegram_notifications_hide_uuid_and_commands_resolve_shortcode(self) -> None:
        session = self.db.create_session(
            user_name="Deniz",
            privacy_consent=True,
            privacy_consent_version="2026.1",
            initial_message="Kıble pusulası sorusu",
            fcm_token="test_ios_apns_fcm_token_123",
        )
        short_code = session["short_code"]
        real_uuid = session["session_id"]

        notif = self.tg.format_new_session_notification(
            short_code=short_code,
            user_name="Deniz",
            initial_message="Kıble pusulası sorusu",
        )
        self.assertIn("#deniz1", notif)
        self.assertNotIn(real_uuid, notif)
        self.assertIsNone(UUID_REGEX.search(notif))

        # Telegram üzerinden kısa kod ile cevap gönderme
        reply_res = self.tg.handle_telegram_command(
            "/cevap deniz1 Merhaba Deniz, pusulayı 8 çizerek kalibre edebilirsin."
        )
        self.assertTrue(reply_res["ok"])
        self.assertEqual(reply_res["session_id"], real_uuid)
        self.assertEqual(reply_res["message"]["sender"], "developer")
        self.assertEqual(reply_res["message"]["sender_name"], "Ege Deniz")
        self.assertEqual(reply_res["push"]["payload"]["title"], "Ege size yazdı")

        # Telegram üzerinden kısa kod ile oturum kapatma
        close_res = self.tg.handle_telegram_command("/kapat deniz1")
        self.assertTrue(close_res["ok"])
        updated = self.db.get_session("deniz1")
        self.assertEqual(updated["status"], "closed")


if __name__ == "__main__":
    unittest.main(verbosity=2)
