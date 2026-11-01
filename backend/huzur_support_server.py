#!/usr/bin/env python3
import json
import os
import re
import sqlite3
import threading
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

UUID_REGEX = re.compile(
    r"[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}"
)


def load_env_file(filepath: str) -> None:
    if not os.path.exists(filepath):
        return
    with open(filepath, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, v = line.split("=", 1)
            k = k.strip()
            v = v.strip().strip('"').strip("'")
            if k and k not in os.environ:
                os.environ[k] = v


load_env_file(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".env"))


def normalize_name_prefix(full_name: str) -> str:
    """
    Kullanıcı adının ilk kelimesinden Türkçe karakter duyarsız kısa kod öneki üretir:
    'Deniz' -> 'deniz'
    'Ali' -> 'ali'
    'Ege Deniz' -> 'ege'
    """
    cleaned = (full_name or "").strip()
    if not cleaned:
        return "misafir"
    first_word = cleaned.split()[0].lower()
    tr_map = {
        "ç": "c",
        "ğ": "g",
        "ı": "i",
        "i̇": "i",
        "ö": "o",
        "ş": "s",
        "ü": "u",
        "â": "a",
        "î": "i",
        "û": "u",
    }
    for k, v in tr_map.items():
        first_word = first_word.replace(k, v)
    prefix = re.sub(r"[^a-z0-9]", "", first_word)
    return prefix if prefix else "misafir"


class PushNotificationDispatcher:
    """
    Ege mesaj gönderdiğinde kayıtlı cihaz token'ına gerçek bildirim iletir.
    Başlık her zaman: 'Ege size yazdı'
    """

    def __init__(self) -> None:
        self.fcm_server_key = os.environ.get("FCM_SERVER_KEY", "").strip()
        self.service_account_json = os.environ.get(
            "FIREBASE_SERVICE_ACCOUNT_JSON", ""
        ).strip()
        self.sent_History: list[dict] = []

    def send_developer_reply_push(
        self,
        fcm_token: str | None,
        short_code: str,
        message_text: str,
    ) -> dict:
        payload = {
            "title": "Ege size yazdı",
            "body": message_text,
            "short_code": short_code,
            "type": "support_reply",
            "timestamp": datetime.now(timezone.utc).isoformat(),
        }
        self.sent_History.append({"token": fcm_token, **payload})

        if not fcm_token:
            return {"delivered": False, "reason": "no_fcm_token", "payload": payload}

        if self.fcm_server_key:
            try:
                req_body = json.dumps(
                    {
                        "to": fcm_token,
                        "priority": "high",
                        "notification": {
                            "title": "Ege size yazdı",
                            "body": message_text,
                            "sound": "default",
                        },
                        "data": payload,
                    }
                ).encode("utf-8")
                req = urllib.request.Request(
                    "https://fcm.googleapis.com/fcm/send",
                    data=req_body,
                    headers={
                        "Content-Type": "application/json",
                        "Authorization": f"key={self.fcm_server_key}",
                    },
                    method="POST",
                )
                with urllib.request.urlopen(req, timeout=8) as resp:
                    return {
                        "delivered": resp.status == 200,
                        "status": resp.status,
                        "payload": payload,
                    }
            except Exception as exc:
                return {"delivered": False, "reason": str(exc), "payload": payload}

        return {"delivered": True, "mode": "queued_for_client", "payload": payload}


class SupportDatabase:
    def __init__(self, db_path: str) -> None:
        self.db_path = db_path
        self._lock = threading.Lock()
        self._init_db()

    def _connect(self) -> sqlite3.Connection:
        conn = sqlite3.connect(self.db_path, timeout=15.0, isolation_level=None)
        conn.row_factory = sqlite3.Row
        conn.execute("PRAGMA journal_mode=WAL;")
        conn.execute("PRAGMA foreign_keys=ON;")
        return conn

    def _init_db(self) -> None:
        with self._lock:
            conn = self._connect()
            try:
                conn.execute(
                    """
                    CREATE TABLE IF NOT EXISTS support_sessions (
                        session_id TEXT PRIMARY KEY,
                        short_code TEXT UNIQUE NOT NULL,
                        base_prefix TEXT NOT NULL,
                        seq_num INTEGER NOT NULL,
                        user_name TEXT NOT NULL,
                        privacy_consent INTEGER NOT NULL CHECK(privacy_consent = 1),
                        privacy_consent_version TEXT NOT NULL,
                        privacy_consented_at TEXT NOT NULL,
                        fcm_token TEXT,
                        status TEXT NOT NULL DEFAULT 'active',
                        rating_stars INTEGER,
                        rating_comment TEXT,
                        created_at TEXT NOT NULL
                    );
                    """
                )
                conn.execute(
                    """
                    CREATE INDEX IF NOT EXISTS idx_support_prefix_seq
                    ON support_sessions(base_prefix, seq_num);
                    """
                )
                conn.execute(
                    """
                    CREATE TABLE IF NOT EXISTS support_messages (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        session_id TEXT NOT NULL,
                        sender TEXT NOT NULL,
                        sender_name TEXT NOT NULL,
                        text TEXT NOT NULL,
                        push_title TEXT,
                        created_at TEXT NOT NULL,
                        FOREIGN KEY(session_id) REFERENCES support_sessions(session_id)
                    );
                    """
                )
                conn.execute(
                    """
                    CREATE TABLE IF NOT EXISTS device_push_tokens (
                        token TEXT PRIMARY KEY,
                        platform TEXT NOT NULL,
                        session_id TEXT,
                        updated_at TEXT NOT NULL
                    );
                    """
                )
            finally:
                conn.close()

    def create_session(
        self,
        user_name: str,
        privacy_consent: object,
        privacy_consent_version: str,
        initial_message: str = "",
        fcm_token: str | None = None,
    ) -> dict:
        # 1. Zorunlu Gizlilik Doğrulaması (Varsayılan True Kesinlikle Yok)
        if privacy_consent is not True:
            raise ValueError(
                "Gizlilik onayı (privacy_consent=true) olmadan canlı destek oturumu oluşturulamaz."
            )
        clean_version = (privacy_consent_version or "").strip()
        if not clean_version:
            raise ValueError(
                "Gizlilik onay metni sürümü (privacy_consent_version) zorunludur."
            )
        clean_name = (user_name or "").strip()
        if not clean_name:
            raise ValueError("Kullanıcı adı (user_name) zorunludur.")

        prefix = normalize_name_prefix(clean_name)
        now_iso = datetime.now(timezone.utc).isoformat()
        session_uuid = str(uuid.uuid4())

        with self._lock:
            conn = self._connect()
            try:
                conn.execute("BEGIN IMMEDIATE;")
                row = conn.execute(
                    "SELECT COALESCE(MAX(seq_num), 0) AS max_seq FROM support_sessions WHERE base_prefix = ?",
                    (prefix,),
                ).fetchone()
                next_seq = int(row["max_seq"]) + 1
                short_code = f"{prefix}{next_seq}"

                conn.execute(
                    """
                    INSERT INTO support_sessions (
                        session_id, short_code, base_prefix, seq_num,
                        user_name, privacy_consent, privacy_consent_version,
                        privacy_consented_at, fcm_token, status, created_at
                    ) VALUES (?, ?, ?, ?, ?, 1, ?, ?, ?, 'active', ?)
                    """,
                    (
                        session_uuid,
                        short_code,
                        prefix,
                        next_seq,
                        clean_name,
                        clean_version,
                        now_iso,
                        fcm_token,
                        now_iso,
                    ),
                )

                conn.execute(
                    """
                    INSERT INTO support_messages (
                        session_id, sender, sender_name, text, created_at
                    ) VALUES (?, 'developer', 'Ege Deniz', ?, ?)
                    """,
                    (
                        session_uuid,
                        f"Merhaba {clean_name}, Huzur Canlı Destek hattına hoş geldiniz. Mesajınız bana ulaştı, en kısa sürede yanıtlayacağım.",
                        now_iso,
                    ),
                )

                clean_init = (initial_message or "").strip()
                if clean_init:
                    conn.execute(
                        """
                        INSERT INTO support_messages (
                            session_id, sender, sender_name, text, created_at
                        ) VALUES (?, 'user', ?, ?, ?)
                        """,
                        (session_uuid, clean_name, clean_init, now_iso),
                    )

                if fcm_token:
                    conn.execute(
                        """
                        INSERT INTO device_push_tokens (token, platform, session_id, updated_at)
                        VALUES (?, 'ios', ?, ?)
                        ON CONFLICT(token) DO UPDATE SET
                            session_id = excluded.session_id,
                            updated_at = excluded.updated_at
                        """,
                        (fcm_token, session_uuid, now_iso),
                    )

                conn.execute("COMMIT;")
            except Exception:
                conn.execute("ROLLBACK;")
                raise
            finally:
                conn.close()

        return self.get_session(session_uuid)

    def resolve_session_id(self, identifier: str) -> str | None:
        clean = (identifier or "").strip().lstrip("#")
        if not clean:
            return None
        conn = self._connect()
        try:
            row = conn.execute(
                """
                SELECT session_id FROM support_sessions
                WHERE LOWER(short_code) = LOWER(?) OR LOWER(session_id) = LOWER(?)
                LIMIT 1
                """,
                (clean, clean),
            ).fetchone()
            return str(row["session_id"]) if row else None
        finally:
            conn.close()

    def get_session(self, identifier: str) -> dict | None:
        real_id = self.resolve_session_id(identifier)
        if not real_id:
            return None
        conn = self._connect()
        try:
            s_row = conn.execute(
                "SELECT * FROM support_sessions WHERE session_id = ?",
                (real_id,),
            ).fetchone()
            if not s_row:
                return None
            m_rows = conn.execute(
                "SELECT * FROM support_messages WHERE session_id = ? ORDER BY id ASC",
                (real_id,),
            ).fetchall()

            return {
                "session_id": s_row["session_id"],
                "short_code": s_row["short_code"],
                "user_name": s_row["user_name"],
                "privacy_consent": bool(s_row["privacy_consent"] == 1),
                "privacy_consent_version": s_row["privacy_consent_version"],
                "privacy_consented_at": s_row["privacy_consented_at"],
                "fcm_token": s_row["fcm_token"],
                "status": s_row["status"],
                "rating_stars": s_row["rating_stars"],
                "rating_comment": s_row["rating_comment"],
                "created_at": s_row["created_at"],
                "messages": [
                    {
                        "id": str(r["id"]),
                        "sender": r["sender"],
                        "sender_name": r["sender_name"],
                        "text": r["text"],
                        "push_title": r["push_title"],
                        "created_at": r["created_at"],
                    }
                    for r in m_rows
                ],
            }
        finally:
            conn.close()

    def add_message(
        self,
        identifier: str,
        sender: str,
        text: str,
        sender_name: str | None = None,
    ) -> dict:
        real_id = self.resolve_session_id(identifier)
        if not real_id:
            raise KeyError(f"Oturum bulunamadı: {identifier}")
        clean_text = (text or "").strip()
        if not clean_text:
            raise ValueError("Mesaj metni boş olamaz.")

        session = self.get_session(real_id)
        assert session is not None
        is_dev = sender.lower() in ("developer", "admin", "ege", "support")
        normalized_sender = "developer" if is_dev else "user"
        resolved_name = (
            "Ege Deniz"
            if is_dev
            else (sender_name or session["user_name"] or "Kullanıcı")
        )
        push_title = "Ege size yazdı" if is_dev else None
        now_iso = datetime.now(timezone.utc).isoformat()

        with self._lock:
            conn = self._connect()
            try:
                cur = conn.execute(
                    """
                    INSERT INTO support_messages (
                        session_id, sender, sender_name, text, push_title, created_at
                    ) VALUES (?, ?, ?, ?, ?, ?)
                    """,
                    (
                        real_id,
                        normalized_sender,
                        resolved_name,
                        clean_text,
                        push_title,
                        now_iso,
                    ),
                )
                msg_id = str(cur.lastrowid)
            finally:
                conn.close()

        return {
            "id": msg_id,
            "session_id": real_id,
            "short_code": session["short_code"],
            "user_name": session["user_name"],
            "fcm_token": session["fcm_token"],
            "sender": normalized_sender,
            "sender_name": resolved_name,
            "text": clean_text,
            "push_title": push_title,
            "created_at": now_iso,
        }

    def close_session(self, identifier: str) -> dict:
        real_id = self.resolve_session_id(identifier)
        if not real_id:
            raise KeyError(f"Oturum bulunamadı: {identifier}")
        with self._lock:
            conn = self._connect()
            try:
                conn.execute(
                    "UPDATE support_sessions SET status = 'closed' WHERE session_id = ?",
                    (real_id,),
                )
            finally:
                conn.close()
        session = self.get_session(real_id)
        assert session is not None
        return session

    def save_rating(self, identifier: str, stars: int, comment: str) -> dict:
        real_id = self.resolve_session_id(identifier)
        if not real_id:
            raise KeyError(f"Oturum bulunamadı: {identifier}")
        clamped = max(1, min(5, int(stars)))
        clean_comment = (comment or "").strip()
        with self._lock:
            conn = self._connect()
            try:
                conn.execute(
                    """
                    UPDATE support_sessions
                    SET status = 'closed', rating_stars = ?, rating_comment = ?
                    WHERE session_id = ?
                    """,
                    (clamped, clean_comment, real_id),
                )
            finally:
                conn.close()
        session = self.get_session(real_id)
        assert session is not None
        return session

    def register_push_token(
        self,
        token: str,
        platform: str = "ios",
        session_identifier: str | None = None,
    ) -> dict:
        clean_token = (token or "").strip()
        if not clean_token:
            raise ValueError("FCM/APNs token boş olamaz.")
        real_session_id = (
            self.resolve_session_id(session_identifier)
            if session_identifier
            else None
        )
        now_iso = datetime.now(timezone.utc).isoformat()
        with self._lock:
            conn = self._connect()
            try:
                conn.execute(
                    """
                    INSERT INTO device_push_tokens (token, platform, session_id, updated_at)
                    VALUES (?, ?, ?, ?)
                    ON CONFLICT(token) DO UPDATE SET
                        platform = excluded.platform,
                        session_id = COALESCE(excluded.session_id, device_push_tokens.session_id),
                        updated_at = excluded.updated_at
                    """,
                    (clean_token, platform, real_session_id, now_iso),
                )
                if real_session_id:
                    conn.execute(
                        "UPDATE support_sessions SET fcm_token = ? WHERE session_id = ?",
                        (clean_token, real_session_id),
                    )
            finally:
                conn.close()
        return {
            "token": clean_token,
            "platform": platform,
            "session_id": real_session_id,
            "updated_at": now_iso,
        }


class TelegramSupportBridge:
    """
    Telegram bildirimlerinde uzun UUID yerine yalnızca kalıcı kısa kod (#deniz1, #ali1) kullanır.
    Yazma önizlemesi (typing preview) kesinlikle göndermez.
    /cevap <kisa_kod> <mesaj> ve /kapat <kisa_kod> komutlarını gerçek UUID oturumuna çözer.
    """

    def __init__(
        self,
        db: SupportDatabase,
        push_dispatcher: PushNotificationDispatcher,
    ) -> None:
        self.db = db
        self.push = push_dispatcher
        self.bot_token = os.environ.get("TELEGRAM_BOT_TOKEN", "").strip()
        self.admin_chat_id = os.environ.get("TELEGRAM_ADMIN_CHAT_ID", "").strip()
        self.outbox_log: list[str] = []

    @staticmethod
    def format_new_session_notification(
        short_code: str,
        user_name: str,
        initial_message: str,
    ) -> str:
        msg_part = initial_message.strip() if initial_message.strip() else "(Mesaj bekleniyor)"
        text = (
            f"Yeni Destek Oturumu [ #{short_code} ]\n"
            f"Kullanıcı: {user_name}\n"
            f"Mesaj: {msg_part}\n\n"
            f"Yanıtlamak için:\n"
            f"/cevap {short_code} Mesajınız\n"
            f"Oturumu kapatmak için:\n"
            f"/kapat {short_code}"
        )
        # Güvenlik: Bildirim metninde asla UUID bulunamaz
        assert not UUID_REGEX.search(text), "Telegram bildiriminde UUID sızıntısı!"
        return text

    @staticmethod
    def format_user_message_notification(
        short_code: str,
        user_name: str,
        message_text: str,
    ) -> str:
        text = (
            f"Yeni Mesaj [ #{short_code} ]\n"
            f"Kullanıcı: {user_name}\n"
            f"Mesaj: {message_text}\n\n"
            f"Yanıtla: /cevap {short_code} ..."
        )
        assert not UUID_REGEX.search(text), "Telegram bildiriminde UUID sızıntısı!"
        return text

    def send_admin_notification(self, text: str) -> bool:
        # UUID varsa kısa kodla maskele
        sanitized = UUID_REGEX.sub("[KISA-KOD]", text)
        self.outbox_log.append(sanitized)

        if not self.bot_token or not self.admin_chat_id:
            return False

        try:
            url = f"https://api.telegram.org/bot{self.bot_token}/sendMessage"
            payload = json.dumps(
                {
                    "chat_id": self.admin_chat_id,
                    "text": sanitized,
                }
            ).encode("utf-8")
            req = urllib.request.Request(
                url,
                data=payload,
                headers={"Content-Type": "application/json"},
                method="POST",
            )
            with urllib.request.urlopen(req, timeout=8) as resp:
                return resp.status == 200
        except Exception:
            return False

    def handle_telegram_command(self, raw_command_text: str) -> dict:
        """
        Desteklenen Telegram komutları:
        - /cevap deniz1 Merhaba Deniz...
        - /yanit deniz1 Merhaba Deniz...
        - /reply deniz1 Merhaba Deniz...
        - /kapat deniz1
        - /close deniz1
        """
        text = (raw_command_text or "").strip()
        if not text:
            return {"ok": False, "error": "Boş komut"}

        close_match = re.match(
            r"^/(?:kapat|close)\s+#?([a-zA-Z0-9\-]+)\s*$",
            text,
            flags=re.IGNORECASE,
        )
        if close_match:
            short_code = close_match.group(1).lower()
            session = self.db.close_session(short_code)
            ack = f"Oturum #{session['short_code']} ({session['user_name']}) kapatıldı."
            self.send_admin_notification(ack)
            return {
                "ok": True,
                "action": "close",
                "short_code": session["short_code"],
                "session_id": session["session_id"],
            }

        reply_match = re.match(
            r"^/(?:cevap|yanit|yanıt|reply)\s+#?([a-zA-Z0-9\-]+)\s+(.+)$",
            text,
            flags=re.IGNORECASE | re.DOTALL,
        )
        if not reply_match:
            # Alternatif kısa yazım: "deniz1: Merhaba"
            alt_match = re.match(
                r"^#?([a-zA-Z]+[0-9]+)\s*:\s*(.+)$",
                text,
                flags=re.IGNORECASE | re.DOTALL,
            )
            if alt_match:
                reply_match = alt_match

        if reply_match:
            code_arg = reply_match.group(1).lower()
            reply_body = reply_match.group(2).strip()
            msg_record = self.db.add_message(
                identifier=code_arg,
                sender="developer",
                text=reply_body,
                sender_name="Ege Deniz",
            )
            push_result = self.push.send_developer_reply_push(
                fcm_token=msg_record.get("fcm_token"),
                short_code=msg_record["short_code"],
                message_text=reply_body,
            )
            return {
                "ok": True,
                "action": "reply",
                "short_code": msg_record["short_code"],
                "session_id": msg_record["session_id"],
                "message": msg_record,
                "push": push_result,
            }

        return {"ok": False, "error": "Tanınmayan komut formatı"}


def create_http_handler(
    db: SupportDatabase,
    tg_bridge: TelegramSupportBridge,
    push_dispatcher: PushNotificationDispatcher,
):
    class SupportRequestHandler(BaseHTTPRequestHandler):
        def _send_json(self, status_code: int, data: dict) -> None:
            body = json.dumps(data, ensure_ascii=False).encode("utf-8")
            self.send_response(status_code)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(body)

        def _read_json(self) -> dict:
            length = int(self.headers.get("Content-Length", "0"))
            if length <= 0:
                return {}
            raw = self.rfile.read(length).decode("utf-8")
            return json.loads(raw) if raw else {}

        def do_OPTIONS(self) -> None:
            self.send_response(204)
            self.send_header("Access-Control-Allow-Origin", "*")
            self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
            self.send_header("Access-Control-Allow-Headers", "Content-Type, Accept")
            self.end_headers()

        def do_GET(self) -> None:
            parsed = urllib.parse.urlparse(self.path)
            path = parsed.path.rstrip("/")

            if path == "/api/support/health":
                self._send_json(200, {"ok": True, "service": "huzur_support"})
                return

            m_get = re.match(r"^/api/support/sessions/([^/]+)$", path)
            if m_get:
                identifier = urllib.parse.unquote(m_get.group(1))
                session = db.get_session(identifier)
                if not session:
                    self._send_json(404, {"error": "Oturum bulunamadı."})
                    return
                self._send_json(200, session)
                return

            self._send_json(404, {"error": "Endpoint bulunamadı."})

        def do_POST(self) -> None:
            parsed = urllib.parse.urlparse(self.path)
            path = parsed.path.rstrip("/")

            try:
                payload = self._read_json()
            except Exception:
                self._send_json(400, {"error": "Geçersiz JSON gövdesi."})
                return

            # 1. Yeni Oturum Oluşturma (Zorunlu Gizlilik Onayı + Kalıcı Kısa Kod)
            if path == "/api/support/sessions":
                try:
                    session = db.create_session(
                        user_name=payload.get("user_name", ""),
                        privacy_consent=payload.get("privacy_consent", False),
                        privacy_consent_version=payload.get(
                            "privacy_consent_version", ""
                        ),
                        initial_message=payload.get("initial_message", ""),
                        fcm_token=payload.get("fcm_token"),
                    )
                    notif_text = tg_bridge.format_new_session_notification(
                        short_code=session["short_code"],
                        user_name=session["user_name"],
                        initial_message=payload.get("initial_message", ""),
                    )
                    tg_bridge.send_admin_notification(notif_text)
                    self._send_json(201, session)
                except ValueError as ve:
                    self._send_json(400, {"error": str(ve)})
                except Exception as exc:
                    self._send_json(500, {"error": str(exc)})
                return

            # 2. Oturuma Mesaj Gönderme (Kısa Kod veya UUID ile)
            m_msg = re.match(r"^/api/support/sessions/([^/]+)/messages$", path)
            if m_msg:
                identifier = urllib.parse.unquote(m_msg.group(1))
                try:
                    sender = payload.get("sender", "user")
                    text = payload.get("text", "")
                    sender_name = payload.get("sender_name")
                    msg_record = db.add_message(
                        identifier=identifier,
                        sender=sender,
                        text=text,
                        sender_name=sender_name,
                    )
                    if msg_record["sender"] == "user":
                        notif = tg_bridge.format_user_message_notification(
                            short_code=msg_record["short_code"],
                            user_name=msg_record["user_name"],
                            message_text=msg_record["text"],
                        )
                        tg_bridge.send_admin_notification(notif)
                    else:
                        push_dispatcher.send_developer_reply_push(
                            fcm_token=msg_record.get("fcm_token"),
                            short_code=msg_record["short_code"],
                            message_text=msg_record["text"],
                        )
                    self._send_json(201, msg_record)
                except KeyError as ke:
                    self._send_json(404, {"error": str(ke)})
                except ValueError as ve:
                    self._send_json(400, {"error": str(ve)})
                return

            # 3. Oturumu Kapatma
            m_close = re.match(r"^/api/support/sessions/([^/]+)/close$", path)
            if m_close:
                identifier = urllib.parse.unquote(m_close.group(1))
                try:
                    session = db.close_session(identifier)
                    self._send_json(200, session)
                except KeyError as ke:
                    self._send_json(404, {"error": str(ke)})
                return

            # 4. Değerlendirme Kaydetme
            m_rate = re.match(r"^/api/support/sessions/([^/]+)/rating$", path)
            if m_rate:
                identifier = urllib.parse.unquote(m_rate.group(1))
                try:
                    stars = int(payload.get("stars", 5))
                    comment = str(payload.get("comment", ""))
                    session = db.save_rating(identifier, stars, comment)
                    tg_bridge.send_admin_notification(
                        f"Değerlendirme [ #{session['short_code']} ]\n"
                        f"Kullanıcı: {session['user_name']}\n"
                        f"Puan: {stars}/5\n"
                        f"Yorum: {comment or '-'}"
                    )
                    self._send_json(200, session)
                except KeyError as ke:
                    self._send_json(404, {"error": str(ke)})
                return

            # 5. Telegram Webhook / Komut İşleyici
            if path == "/api/support/telegram/webhook":
                msg_obj = payload.get("message") or {}
                cmd_text = msg_obj.get("text") or payload.get("command") or ""
                try:
                    res = tg_bridge.handle_telegram_command(cmd_text)
                    self._send_json(200 if res.get("ok") else 400, res)
                except KeyError as ke:
                    self._send_json(404, {"ok": False, "error": str(ke)})
                return

            # 6. Cihaz Push Token Kayıt Endpoint'i
            if path == "/api/support/push/register":
                try:
                    rec = db.register_push_token(
                        token=payload.get("fcm_token", ""),
                        platform=payload.get("platform", "ios"),
                        session_identifier=payload.get("session_id"),
                    )
                    self._send_json(200, rec)
                except ValueError as ve:
                    self._send_json(400, {"error": str(ve)})
                return

            self._send_json(404, {"error": "Endpoint bulunamadı."})

        def log_message(self, format: str, *args) -> None:
            return

    return SupportRequestHandler


def run_server() -> None:
    port = int(os.environ.get("HUZUR_SUPPORT_PORT", "8080"))
    db_file = os.environ.get(
        "HUZUR_DB_PATH",
        os.path.join(os.path.dirname(os.path.abspath(__file__)), "huzur_support.db"),
    )
    db = SupportDatabase(db_file)
    push = PushNotificationDispatcher()
    tg = TelegramSupportBridge(db, push)
    handler_cls = create_http_handler(db, tg, push)
    server = ThreadingHTTPServer(("0.0.0.0", port), handler_cls)
    print(f"[HUZUR SUPPORT BACKEND] 0.0.0.0:{port} uzerinde aktif (DB: {db_file})")
    server.serve_forever()


if __name__ == "__main__":
    run_server()
