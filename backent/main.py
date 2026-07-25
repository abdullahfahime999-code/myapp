from flask import Flask, request, jsonify, render_template, send_from_directory, session, redirect, url_for
from flask_cors import CORS
import mysql.connector
from mysql.connector import Error
import bcrypt
import re
import os
import uuid
from datetime import datetime, timedelta
from decimal import Decimal, InvalidOperation
import jwt
from functools import wraps
from zoneinfo import ZoneInfo
from werkzeug.utils import secure_filename


app = Flask(__name__)
app.secret_key = 'your-secret-key-here-change-this-in-production'  # ✅ اضافه کن
CORS(app)
MYSQL_HOST = os.getenv('MYSQL_HOST', 'Hazrat233.mysql.pythonanywhere-services.com')
MYSQL_PORT = int(os.getenv('MYSQL_PORT', '3306'))
MYSQL_USER = os.getenv('MYSQL_USER', 'Hazrat233')
MYSQL_PASSWORD = os.getenv('MYSQL_PASSWORD', 'afghan3333')
MYSQL_DB = os.getenv('MYSQL_DB', 'Hazrat233$students_db')
SECRET_KEY = os.getenv('SECRET_KEY', 'your-secret-key-here-change-this')
app.config['SECRET_KEY'] = SECRET_KEY
ALLOWED_CURRENCIES = {'افغانی', 'تومان', 'لیر ترکیه', 'دالر', 'یورو'}
UPLOAD_DIR = os.path.join(os.path.dirname(__file__), 'uploads')
USER_UPLOAD_DIR = os.path.join(UPLOAD_DIR, 'users')
TAZKIRA_UPLOAD_DIR = os.path.join(USER_UPLOAD_DIR, 'tazkira')
PROFILE_UPLOAD_DIR = os.path.join(USER_UPLOAD_DIR, 'profile')
os.makedirs(TAZKIRA_UPLOAD_DIR, exist_ok=True)
os.makedirs(PROFILE_UPLOAD_DIR, exist_ok=True)

ADMIN_USERNAME = 'admin'
ADMIN_PASSWORD = 'afghanistan'

@app.route('/', methods=['GET'])
def index():
    return jsonify({'status': 'ok'}), 200

@app.route('/uploads/<path:filename>', methods=['GET'])
def uploaded_file(filename):
    return send_from_directory(UPLOAD_DIR, filename)

# Database connection
def get_db_connection():
    try:
        db = mysql.connector.connect(
            host="Hazrat233.mysql.pythonanywhere-services.com",
            user="Hazrat233",
            password="afghan3333",
            database="Hazrat233$students_db",
            autocommit=True
        )
        return db
    except mysql.connector.Error as err:
        print(f"خطا در اتصال به دیتابیس: {err}")
        return None

# Token required decorator
def token_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = request.headers.get('Authorization')

        if not token:
            return jsonify({'message': 'توکن موجود نیست'}), 401

        try:
            token = token.split(' ')[1]  # Remove 'Bearer ' prefix
            data = jwt.decode(token, app.config['SECRET_KEY'], algorithms=['HS256'])
            current_user = data['user_id']
        except:
            return jsonify({'message': 'توکن نامعتبر است'}), 401

        return f(current_user, *args, **kwargs)

    return decorated

# Validation functions
def validate_phone(phone):
    pattern = r'^\+?\d{10,15}$'
    return re.match(pattern, phone) is not None
def normalize_phone(phone):
    return re.sub(r'[\s-]', '', phone)

def validate_password(password):
    return len(password) >= 6

def ensure_user_balance_column(cursor):
    try:
        cursor.execute(
            "SELECT COUNT(*) AS cnt FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = %s AND TABLE_NAME = %s AND COLUMN_NAME = %s",
            (MYSQL_DB, 'users', 'balance'),
        )
        info = cursor.fetchone()
        if not info or int(info.get('cnt', 0)) == 0:
            cursor.execute(
                "ALTER TABLE users ADD COLUMN balance DECIMAL(30,2) NOT NULL DEFAULT 0"
            )
    except Exception:
        pass
def format_money_value(value):
    if value is None:
        return '0'
    try:
        decimal_value = Decimal(str(value))
    except Exception:
        return str(value)
    text = format(decimal_value, 'f')
    if '.' in text:
        text = text.rstrip('0').rstrip('.')
    return text or '0'


def ensure_user_media_columns(cursor):
    try:
        columns = {
            'pin_code_hash': "ALTER TABLE users ADD COLUMN pin_code_hash VARCHAR(100)",
            'balance': "ALTER TABLE users ADD COLUMN balance DECIMAL(30,2) NOT NULL DEFAULT 0",
            'tazkira_image_path': "ALTER TABLE users ADD COLUMN tazkira_image_path VARCHAR(255) NULL",
            'profile_image_path': "ALTER TABLE users ADD COLUMN profile_image_path VARCHAR(255) NULL",
        }
        for column_name, alter_sql in columns.items():
            cursor.execute(
                "SELECT COUNT(*) AS cnt FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = %s AND TABLE_NAME = %s AND COLUMN_NAME = %s",
                (MYSQL_DB, 'users', column_name),
            )
            info = cursor.fetchone()
            if not info or int(info.get('cnt', 0)) == 0:
                cursor.execute(alter_sql)
    except Exception:
        pass


def save_user_image(uploaded_file, folder):
    if not uploaded_file or not uploaded_file.filename:
        return None
    filename = secure_filename(uploaded_file.filename)
    extension = os.path.splitext(filename)[1].lower()
    if extension not in {'.jpg', '.jpeg', '.png', '.webp'}:
        extension = '.jpg'
    unique_name = f"{uuid.uuid4().hex}{extension}"
    target_dir = TAZKIRA_UPLOAD_DIR if folder == 'tazkira' else PROFILE_UPLOAD_DIR
    os.makedirs(target_dir, exist_ok=True)
    relative_path = os.path.join('users', folder, unique_name)
    uploaded_file.save(os.path.join(UPLOAD_DIR, relative_path))
    return relative_path.replace('\\', '/')


def public_upload_url(relative_path):
    if not relative_path:
        return None
    normalized_path = relative_path.replace('\\', '/')
    return f"{request.url_root.rstrip('/')}/uploads/{normalized_path}"

# Health endpoint
@app.route('/api/health', methods=['GET'])
def health():
    db_host = MYSQL_HOST
    db_port = MYSQL_PORT
    db_name = MYSQL_DB
    status = {'database': {'host': db_host, 'port': db_port, 'name': db_name, 'connected': False}}
    connection = get_db_connection()
    try:
        if connection:
            cursor = connection.cursor()
            cursor.execute("SELECT 1")
            status['database']['connected'] = True
            return jsonify({'status': 'ok', **status}), 200
        else:
            return jsonify({'status': 'error', **status, 'message': 'اتصال به پایگاه‌داده ناموفق بود'}), 500
    except Exception as e:
        return jsonify({'status': 'error', **status, 'message': f'خطا: {str(e)}'}), 500
    finally:
        if 'cursor' in locals() and cursor:
            try:
                cursor.close()
            except:
                pass
        if 'connection' in locals() and connection:
            try:
                connection.close()
            except:
                pass

# Register endpoint
@app.route('/api/register', methods=['POST'])
def register():
    try:
        content_type = request.content_type or ''
        if 'multipart/form-data' in content_type:
            data = request.form.to_dict()
            tazkira_file = request.files.get('tazkira_image')
            profile_file = request.files.get('profile_image')
        else:
            data = request.get_json(silent=True) or {}
            tazkira_file = None
            profile_file = None

        required_fields = ('first_name', 'last_name', 'phone_number', 'password', 'pin_code')
        if not all(data.get(key) for key in required_fields):
            return jsonify({'message': '??????? ????? ???? ????????'}), 400

        first_name = data['first_name'].strip()
        last_name = data['last_name'].strip()
        phone_number = normalize_phone(data['phone_number'])
        password = data['password'].strip()
        pin_code = str(data.get('pin_code', '')).strip()

        if not validate_phone(phone_number):
            return jsonify({'message': '???? ????? ?????? ??????? ???'}), 400

        if not validate_password(password):
            return jsonify({'message': '??? ???? ???? ????? ? ??????? ????'}), 400
        if not re.match(r'^\d{4}$', pin_code):
            return jsonify({'message': '?? ??? ???? ? ??? ????'}), 400

        if 'multipart/form-data' not in content_type:
            return jsonify({'message': '???? ??????? ???? ??? ????? ? ??? ?????? ????? ???'}), 400
        if not tazkira_file or not profile_file:
            return jsonify({'message': '??? ????? ? ??? ?????? ?????? ???'}), 400

        salt = bcrypt.gensalt()
        password_hash = bcrypt.hashpw(password.encode('utf-8'), salt).decode('utf-8')
        pin_hash = bcrypt.hashpw(pin_code.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

        connection = get_db_connection()
        if not connection:
            return jsonify({'message': '????? ?? ??????????? ?????? ???'}), 500

        cursor = connection.cursor(dictionary=True)
        cursor.execute('SELECT id FROM users WHERE phone_number = %s', (phone_number,))
        existing_user = cursor.fetchone()

        if existing_user:
            return jsonify({'message': '????? ?????? ????? ??? ??? ???'}), 409

        try:
            ensure_user_media_columns(cursor)
        except Exception:
            pass

        tazkira_image_path = save_user_image(tazkira_file, 'tazkira')
        profile_image_path = save_user_image(profile_file, 'profile')

        insert_query = '''
        INSERT INTO users (phone_number, password_hash, first_name, last_name, pin_code_hash, tazkira_image_path, profile_image_path)
        VALUES (%s, %s, %s, %s, %s, %s, %s)
        '''
        cursor.execute(
            insert_query,
            (phone_number, password_hash, first_name, last_name, pin_hash, tazkira_image_path, profile_image_path),
        )
        connection.commit()

        return jsonify({
            'message': '????? ?? ?????? ??? ??',
            'user': {
                'id': cursor.lastrowid,
                'phone_number': phone_number,
                'first_name': first_name,
                'last_name': last_name,
                'balance': '0',
                'tazkira_image_url': public_upload_url(tazkira_image_path),
                'profile_image_url': public_upload_url(profile_image_path),
            }
        }), 201

    except Exception as e:
        return jsonify({'message': f'???: {str(e)}'}), 500
    finally:
        if 'cursor' in locals() and cursor:
            try:
                cursor.close()
            except:
                pass
        if 'connection' in locals() and connection:
            try:
                connection.close()
            except:
                pass

# Login endpoint
@app.route('/api/login', methods=['POST'])
def login():
    try:
        data = request.get_json()

        if not all(k in data for k in ('phone_number', 'password')):
            return jsonify({'message': 'شماره موبایل یا رمز عبور وارد نشده است'}), 400

        phone_number = normalize_phone(data['phone_number'])
        password = data['password'].strip()

        connection = get_db_connection()
        if not connection:
            return jsonify({'message': 'اتصال به پایگاه‌داده ناموفق بود'}), 500

        cursor = connection.cursor(dictionary=True)

        # Get user by email
        cursor.execute("SELECT * FROM users WHERE phone_number = %s", (phone_number,))
        user = cursor.fetchone()

        if not user:
            return jsonify({'message': 'شماره موبایل یا رمز عبور نامعتبر است'}), 401

        # Check password
        stored_hash = user['password_hash']
        if isinstance(stored_hash, bytes):
            stored_hash = stored_hash.decode('utf-8')
        if bcrypt.checkpw(password.encode('utf-8'), stored_hash.encode('utf-8')):
            # Generate token
            ensure_user_balance_column(cursor)
            token = jwt.encode({
                'user_id': user['id'],
                'exp': datetime.utcnow() + timedelta(hours=24)
            }, app.config['SECRET_KEY'], algorithm='HS256')
            balance_value = format_money_value(user.get('balance', 0))

            return jsonify({
                'message': 'ورود با موفقیت انجام شد',
                'token': token,
                'user': {
                    'id': user['id'],
                    'phone_number': user.get('phone_number'),
                    'first_name': user.get('first_name'),
                    'last_name': user.get('last_name'),
                    'balance': balance_value,
                    'tazkira_image_url': public_upload_url(user.get('tazkira_image_path')),
                    'profile_image_url': public_upload_url(user.get('profile_image_path')),
                }
            }), 200
        else:
            return jsonify({'message': 'شماره موبایل یا رمز عبور نامعتبر است'}), 401

    except Exception as e:
        return jsonify({'message': f'خطا: {str(e)}'}), 500
    finally:
        if 'cursor' in locals() and cursor:
            try:
                cursor.close()
            except:
                pass
        if 'connection' in locals() and connection:
            try:
                connection.close()
            except:
                pass

# Protected profile endpoint (example)
@app.route('/api/profile', methods=['GET'])
@token_required
def get_profile(current_user):
    try:
        connection = get_db_connection()
        if not connection:
            return jsonify({'message': 'اتصال به پایگاه‌داده ناموفق بود'}), 500

        cursor = connection.cursor(dictionary=True)
        try:
            cursor.execute("SELECT COUNT(*) AS cnt FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = %s AND TABLE_NAME = %s AND COLUMN_NAME = %s", (MYSQL_DB, 'users', 'expires_at'))
            info = cursor.fetchone()
            if not info or int(info.get('cnt', 0)) == 0:
                cursor.execute("ALTER TABLE users ADD COLUMN expires_at DATETIME NULL")
            ensure_user_balance_column(cursor)
        except Exception:
            pass
        cursor.execute("SELECT id, phone_number, first_name, last_name, created_at, expires_at, balance FROM users WHERE id = %s", (current_user,))
        user = cursor.fetchone()

        if user:
            exp = user.get('expires_at')
            if exp:
                if not isinstance(exp, datetime):
                    try:
                        exp = datetime.strptime(str(exp), "%Y-%m-%d %H:%M:%S")
                    except:
                        try:
                            exp = datetime.fromisoformat(str(exp))
                        except:
                            exp = None
                if exp:
                    now = datetime.utcnow()
                    delta = exp - now
                    secs = delta.total_seconds()
                    rem = int((secs + 86399) // 86400)
                    if rem < 0:
                        rem = 0
                    user['remaining_days'] = rem
                else:
                    user['remaining_days'] = None
            else:
                    user['remaining_days'] = None
            user['balance'] = format_money_value(user.get('balance', 0))
            user['tazkira_image_url'] = public_upload_url(user.get('tazkira_image_path'))
            user['profile_image_url'] = public_upload_url(user.get('profile_image_path'))
            return jsonify({'user': user}), 200
        else:
            return jsonify({'message': 'کاربر یافت نشد'}), 404

    except Exception as e:
        return jsonify({'message': f'خطا: {str(e)}'}), 500
    finally:
        if 'cursor' in locals() and cursor:
            try:
                cursor.close()
            except:
                pass
        if 'connection' in locals() and connection:
            try:
                connection.close()
            except:
                pass

@app.route('/api/dashboard', methods=['GET'])
@token_required
def dashboard(current_user):
    try:
        connection = get_db_connection()
        if not connection:
            return jsonify({'message': 'اتصال به پایگاه‌داده ناموفق بود'}), 500
        cursor = connection.cursor(dictionary=True)
        try:
            cursor.execute("SELECT COUNT(*) AS cnt FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = %s AND TABLE_NAME = %s AND COLUMN_NAME = %s", (MYSQL_DB, 'users', 'restricted'))
            info = cursor.fetchone()
            if not info or int(info.get('cnt', 0)) == 0:
                cursor.execute("ALTER TABLE users ADD COLUMN restricted TINYINT(1) NOT NULL DEFAULT 0")
            ensure_user_balance_column(cursor)
        except Exception:
            pass
        cursor.execute("SELECT first_name, last_name, phone_number, restricted, balance, profile_image_path FROM users WHERE id = %s", (current_user,))
        user = cursor.fetchone()
        if not user:
            return jsonify({'message': 'کاربر یافت نشد'}), 404
        name = f"{user.get('first_name','')} {user.get('last_name','')}".strip()
        blocked = bool(user.get('restricted', 0))
        resp = {
            'name': name,
            'phone_number': user.get('phone_number'),
            'blocked': blocked,
            'balance': format_money_value(user.get('balance', 0)),
            'profile_image_url': public_upload_url(user.get('profile_image_path')),
        }
        if blocked:
            resp['message'] = 'شما از طرف ادمین محدود شده‌اید. لطفاً برای رفع محدودیت با ادمین تماس بگیرید.'
        return jsonify(resp), 200
    except Exception as e:
        return jsonify({'message': f'خطا: {str(e)}'}), 500
    finally:
        if 'cursor' in locals() and cursor:
            try:
                cursor.close()
            except:
                pass
        if 'connection' in locals() and connection:
            try:
                connection.close()
            except:
                pass

# Update profile image
@app.route('/api/profile/image', methods=['POST'])
@token_required
def update_profile_image(current_user):
    try:
        if 'multipart/form-data' not in (request.content_type or ''):
            return jsonify({'message': 'لطفاً تصویر را ارسال کنید'}), 400
        profile_file = request.files.get('profile_image')
        if not profile_file or not profile_file.filename:
            return jsonify({'message': 'تصویر پروفایل الزامی است'}), 400
        os.makedirs(PROFILE_UPLOAD_DIR, exist_ok=True)
        new_path = save_user_image(profile_file, 'profile')
        if not new_path:
            return jsonify({'message': 'ذخیره تصویر ناموفق بود'}), 400
        connection = get_db_connection()
        if not connection:
            return jsonify({'message': 'اتصال به پایگاه‌داده ناموفق بود'}), 500
        cursor = connection.cursor()
        try:
            ensure_user_media_columns(cursor)
            cursor.execute(
                "UPDATE users SET profile_image_path = %s WHERE id = %s",
                (new_path, current_user),
            )
            connection.commit()
        finally:
            try:
                cursor.close()
            except:
                pass
            try:
                connection.close()
            except:
                pass
        return jsonify({
            'message': 'تصویر پروفایل با موفقیت به‌روزرسانی شد',
            'profile_image_url': public_upload_url(new_path),
        }), 200
    except Exception as e:
        return jsonify({'message': f'خطا: {str(e)}'}), 500

# Change password endpoint
@app.route('/api/password/change', methods=['POST'])
@token_required
def change_password(current_user):
    try:
        data = request.get_json()
        current_password = data.get('current_password', '').strip()
        new_password = data.get('new_password', '').strip()
        if not current_password or not new_password:
            return jsonify({'message': 'رمز فعلی و رمز جدید الزامی است'}), 400
        if len(new_password) < 6:
            return jsonify({'message': 'رمز جدید باید حداقل ۶ کاراکتر باشد'}), 400
        connection = get_db_connection()
        if not connection:
            return jsonify({'message': 'اتصال به پایگاه‌داده ناموفق بود'}), 500
        cursor = connection.cursor(dictionary=True)
        ensure_user_balance_column(cursor)
        cursor.execute("SELECT id, password_hash FROM users WHERE id = %s", (current_user,))
        user = cursor.fetchone()
        if not user:
            return jsonify({'message': 'کاربر یافت نشد'}), 404
        stored_hash = user['password_hash']
        if isinstance(stored_hash, bytes):
            stored_hash = stored_hash.decode('utf-8')
        if not bcrypt.checkpw(current_password.encode('utf-8'), stored_hash.encode('utf-8')):
            return jsonify({'message': 'رمز فعلی نادرست است'}), 401
        new_hash = bcrypt.hashpw(new_password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
        cursor.execute("UPDATE users SET password_hash = %s WHERE id = %s", (new_hash, current_user))
        connection.commit()
        return jsonify({'message': 'رمز عبور با موفقیت تغییر کرد'}), 200
    except Exception as e:
        return jsonify({'message': f'خطا: {str(e)}'}), 500
    finally:
        if 'cursor' in locals() and cursor:
            try:
                cursor.close()
            except:
                pass
        if 'connection' in locals() and connection:
            try:
                connection.close()
            except:
                pass

@app.route('/admin_user_control', methods=['GET'])
def admin_user_control():
    try:
        connection = get_db_connection()
        if not connection:
            return jsonify({'message': 'اتصال به پایگاه‌داده ناموفق بود'}), 500
        cursor = connection.cursor(dictionary=True)
        try:
            cursor.execute("SELECT COUNT(*) AS cnt FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = %s AND TABLE_NAME = %s AND COLUMN_NAME = %s", (MYSQL_DB, 'users', 'restricted'))
            info = cursor.fetchone()
            if not info or int(info.get('cnt', 0)) == 0:
                cursor.execute("ALTER TABLE users ADD COLUMN restricted TINYINT(1) NOT NULL DEFAULT 0")
            cursor.execute("SELECT COUNT(*) AS cnt FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = %s AND TABLE_NAME = %s AND COLUMN_NAME = %s", (MYSQL_DB, 'users', 'expires_at'))
            info2 = cursor.fetchone()
            if not info2 or int(info2.get('cnt', 0)) == 0:
                cursor.execute("ALTER TABLE users ADD COLUMN expires_at DATETIME NULL")
        except Exception:
            pass
        cursor.execute("SELECT id, phone_number, first_name, last_name, created_at, restricted, expires_at, profile_image_path, balance, tazkira_image_path FROM users ORDER BY created_at DESC")
        users = cursor.fetchall() or []
        def to_dt(x):
            if isinstance(x, datetime):
                return x
            try:
                return datetime.strptime(str(x), "%Y-%m-%d %H:%M:%S")
            except:
                try:
                    return datetime.fromisoformat(str(x))
                except:
                    return None
        def g2j(gy, gm, gd):
            g_d_m = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]
            gy2 = gy - 1600
            jy = 979
            if gy <= 1600:
                gy2 = gy - 621
                jy = 0
            days = 365 * gy2 + (gy2 + 3) // 4 - (gy2 + 99) // 100 + (gy2 + 399) // 400 - 80 + gd + g_d_m[gm - 1]
            jy += 33 * (days // 12053)
            days %= 12053
            jy += 4 * (days // 1461)
            days %= 1461
            if days > 365:
                jy += (days - 1) // 365
                days = (days - 1) % 365
            jm = 1 + (days < 186 and days // 31 or (days - 186) // 30)
            jd = 1 + (days < 186 and days % 31 or (days - 186) % 30)
            return jy + 1, jm, jd
        def fmt_jalali(dt):
            if not dt:
                return ""
            y, m, d = dt.year, dt.month, dt.day
            jy, jm, jd = g2j(y, m, d)
            return f"{jy:04d}/{jm:02d}/{jd:02d}"
        def fmt_tz(dt, zone):
            if not dt:
                return ""
            if dt.tzinfo is None:
                dt = dt.replace(tzinfo=ZoneInfo("UTC"))
            return dt.astimezone(ZoneInfo(zone)).strftime("%Y-%m-%d %H:%M")
        for u in users:
            dt = to_dt(u.get('created_at'))
            u['created_at_jalali'] = fmt_jalali(dt)
            u['time_kabul'] = fmt_tz(dt, "Asia/Kabul")
            u['time_tehran'] = fmt_tz(dt, "Asia/Tehran")
            exp = to_dt(u.get('expires_at'))
            if exp:
                now = datetime.utcnow()
                delta = exp - now
                secs = delta.total_seconds()
                rem = int((secs + 86399) // 86400)
                if rem < 0:
                    rem = 0
                u['remaining_days'] = rem
            else:
                u['remaining_days'] = None
            u['profile_image_url'] = public_upload_url(u.get('profile_image_path'))
            try:
                u['balance_toman'] = int(round(float(u.get('balance') or 0)))
            except Exception:
                u['balance_toman'] = 0
            u['tazkira_image_url'] = public_upload_url(u.get('tazkira_image_path'))
        return render_template('admin_user_control.html', users=users)
    except Exception as e:
        return jsonify({'message': f'خطا: {str(e)}'}), 500
    finally:
        if 'cursor' in locals() and cursor:
            try:
                cursor.close()
            except:
                pass
        if 'connection' in locals() and connection:
            try:
                connection.close()
            except:
                pass


@app.route('/admin_charger', methods=['GET'])
def admin_charger():
    try:
        connection = get_db_connection()
        if not connection:
            return jsonify({'message': 'اتصال به پایگاه‌داده ناموفق بود'}), 500
        cursor = connection.cursor(dictionary=True)
        try:
            ensure_user_balance_column(cursor)
        except Exception:
            pass
        cursor.execute("SELECT id, phone_number, first_name, last_name, created_at, balance FROM users ORDER BY created_at DESC")
        users = cursor.fetchall() or []
        for user in users:
            user['balance'] = format_money_value(user.get('balance', 0))
        return render_template('admin_charger.html', users=users)
    except Exception as e:
        return jsonify({'message': f'خطا: {str(e)}'}), 500
    finally:
        if 'cursor' in locals() and cursor:
            try:
                cursor.close()
            except:
                pass
        if 'connection' in locals() and connection:
            try:
                connection.close()
            except:
                pass

@app.route('/api/admin/user/restrict', methods=['POST'])
def admin_toggle_restrict():
    try:
        data = request.get_json() or {}
        user_id = data.get('user_id')
        restricted = data.get('restricted')
        if user_id is None or restricted is None:
            return jsonify({'message': 'پارامترهای لازم ارسال نشده‌اند'}), 400
        restricted_val = 1 if bool(restricted) else 0
        connection = get_db_connection()
        if not connection:
            return jsonify({'message': 'اتصال به پایگاه‌داده ناموفق بود'}), 500
        cursor = connection.cursor(dictionary=True)
        try:
            cursor.execute("SELECT COUNT(*) AS cnt FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = %s AND TABLE_NAME = %s AND COLUMN_NAME = %s", (MYSQL_DB, 'users', 'restricted'))
            info = cursor.fetchone()
            if not info or int(info.get('cnt', 0)) == 0:
                cursor.execute("ALTER TABLE users ADD COLUMN restricted TINYINT(1) NOT NULL DEFAULT 0")
        except Exception:
            pass
        cursor.execute("UPDATE users SET restricted = %s WHERE id = %s", (restricted_val, user_id))
        connection.commit()
        return jsonify({'message': 'وضعیت محدودیت به‌روزرسانی شد', 'user_id': user_id, 'restricted': bool(restricted_val)}), 200
    except Exception as e:
        return jsonify({'message': f'خطا: {str(e)}'}), 500
    finally:
        if 'cursor' in locals() and cursor:
            try:
                cursor.close()
            except:
                pass
        if 'connection' in locals() and connection:
            try:
                connection.close()
            except:
                pass

@app.route('/api/admin/user/delete', methods=['POST'])
def admin_delete_user():
    try:
        data = request.get_json() or {}
        user_id = data.get('user_id')
        if user_id is None:
            return jsonify({'message': 'شناسه کاربر ارسال نشده است'}), 400
        connection = get_db_connection()
        if not connection:
            return jsonify({'message': 'اتصال به پایگاه‌داده ناموفق بود'}), 500
        cursor = connection.cursor(dictionary=True)
        cursor.execute("DELETE FROM users WHERE id = %s", (user_id,))
        affected = cursor.rowcount
        connection.commit()
        if affected and affected > 0:
            return jsonify({'message': 'کاربر حذف شد', 'user_id': user_id}), 200
        else:
            return jsonify({'message': 'کاربر یافت نشد'}), 404
    except Exception as e:
        return jsonify({'message': f'خطا: {str(e)}'}), 500
    finally:
        if 'cursor' in locals() and cursor:
            try:
                cursor.close()
            except:
                pass
        if 'connection' in locals() and connection:
            try:
                connection.close()
            except:
                pass

@app.route('/api/admin/user/balance', methods=['POST'])
def admin_update_balance():
    try:
        data = request.get_json() or {}
        user_id = data.get('user_id')
        amount = data.get('amount')
        if user_id is None or amount is None:
            return jsonify({'message': 'پارامترهای لازم ارسال نشده‌اند'}), 400
        try:
            amount_f = float(amount)
        except Exception:
            return jsonify({'message': 'مقدار نامعتبر است'}), 400
        if amount_f < 0:
            return jsonify({'message': 'موجودی نمی‌تواند منفی باشد'}), 400
        connection = get_db_connection()
        if not connection:
            return jsonify({'message': 'اتصال به پایگاه‌داده ناموفق بود'}), 500
        cursor = connection.cursor(dictionary=True)
        try:
            cursor.execute("SELECT COUNT(*) AS cnt FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = %s AND TABLE_NAME = %s AND COLUMN_NAME = %s", (MYSQL_DB, 'users', 'balance'))
            info = cursor.fetchone()
            if not info or int(info.get('cnt', 0)) == 0:
                cursor.execute("ALTER TABLE users ADD COLUMN balance DECIMAL(18,2) NOT NULL DEFAULT 0")
        except Exception:
            pass
        cursor.execute("SELECT id FROM users WHERE id = %s", (user_id,))
        row = cursor.fetchone()
        if not row:
            return jsonify({'message': 'کاربر یافت نشد'}), 404
        new_balance = amount_f
        cursor.execute("UPDATE users SET balance = %s WHERE id = %s", (new_balance, user_id))
        connection.commit()
        try:
         # publish_event(user_id, 'balance_update', {'balance': new_balance})
         pass
        except Exception:
            pass
        return jsonify({
            'message': 'موجودی به‌روزرسانی شد',
            'user_id': user_id,
            'balance': new_balance,
        }), 200
    except Exception as e:
        return jsonify({'message': f'خطا: {str(e)}'}), 500
    finally:
        if 'cursor' in locals() and cursor:
            try:
                cursor.close()
            except:
                pass
        if 'connection' in locals() and connection:
            try:
                connection.close()
            except:
                pass

@app.route('/api/admin/user/set_days', methods=['POST'])
def admin_set_days():
    try:
        data = request.get_json() or {}
        user_id = data.get('user_id')
        days = data.get('days')
        if user_id is None or days is None:
            return jsonify({'message': 'پارامترهای لازم ارسال نشده‌اند'}), 400
        try:
            days_int = int(days)
        except:
            return jsonify({'message': 'مقدار روز نامعتبر است'}), 400
        if days_int < 0:
            return jsonify({'message': 'روز نمی‌تواند منفی باشد'}), 400
        connection = get_db_connection()
        if not connection:
            return jsonify({'message': 'اتصال به پایگاه‌داده ناموفق بود'}), 500
        cursor = connection.cursor(dictionary=True)
        try:
            cursor.execute("SELECT COUNT(*) AS cnt FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = %s AND TABLE_NAME = %s AND COLUMN_NAME = %s", (MYSQL_DB, 'users', 'expires_at'))
            info = cursor.fetchone()
            if not info or int(info.get('cnt', 0)) == 0:
                cursor.execute("ALTER TABLE users ADD COLUMN expires_at DATETIME NULL")
        except Exception:
            pass
        cursor.execute("UPDATE users SET expires_at = DATE_ADD(UTC_TIMESTAMP(), INTERVAL %s DAY) WHERE id = %s", (days_int, user_id))
        connection.commit()
        return jsonify({'message': 'زمان کاربر تنظیم شد', 'user_id': user_id, 'remaining_days': days_int}), 200
    except Exception as e:
        return jsonify({'message': f'خطا: {str(e)}'}), 500
    finally:
        if 'cursor' in locals() and cursor:
            try:
                cursor.close()
            except:
                pass
        if 'connection' in locals() and connection:
            try:
                connection.close()
            except:
                pass


@app.route('/api/admin/user/charge', methods=['POST'])
def admin_charge_user():
    try:
        data = request.get_json() or {}
        user_id = data.get('user_id')
        amount_raw = str(data.get('amount', '')).strip()
        if user_id is None or not amount_raw:
            return jsonify({'message': 'پارامترهای لازم ارسال نشده‌اند'}), 400
        try:
            amount = Decimal(amount_raw).quantize(Decimal('0.01'))
        except (InvalidOperation, ValueError):
            return jsonify({'message': 'مبلغ نامعتبر است'}), 400
        if amount <= 0:
            return jsonify({'message': 'مبلغ باید بزرگ‌تر از صفر باشد'}), 400
        connection = get_db_connection()
        if not connection:
            return jsonify({'message': 'اتصال به پایگاه‌داده ناموفق بود'}), 500
        cursor = connection.cursor(dictionary=True)
        ensure_user_balance_column(cursor)
        cursor.execute("SELECT id, balance FROM users WHERE id = %s", (user_id,))
        user = cursor.fetchone()
        if not user:
            return jsonify({'message': 'کاربر یافت نشد'}), 404
        cursor.execute(
            "UPDATE users SET balance = COALESCE(balance, 0) + %s WHERE id = %s",
            (amount, user_id),
        )
        connection.commit()
        cursor.execute("SELECT balance FROM users WHERE id = %s", (user_id,))
        updated = cursor.fetchone() or {}
        return jsonify({
            'message': 'موجودی با موفقیت شارژ شد',
            'user_id': user_id,
            'balance': format_money_value(updated.get('balance', 0)),
        }), 200
    except Exception as e:
        return jsonify({'message': f'خطا: {str(e)}'}), 500
    finally:
        if 'cursor' in locals() and cursor:
            try:
                cursor.close()
            except:
                pass
        if 'connection' in locals() and connection:
            try:
                connection.close()
            except:
                pass
#========================================================================
@app.route('/admin_product', methods=['GET', 'POST', 'PUT', 'DELETE'])
def admin_product():
    # ============================================
    # 🔒 بررسی لاگین بودن ادمین
    # ============================================
    if not session.get('admin_logged_in'):
        return redirect(url_for('admin_login'))

    try:
        connection = get_db_connection()
        if not connection:
            return jsonify({'message': 'اتصال به پایگاه‌داده ناموفق بود'}), 500

        cursor = connection.cursor(dictionary=True)

        # ============================================
        # 📌 ایجاد جدول products (با ستون operator)
        # ============================================
        try:
            cursor.execute(
                "SELECT COUNT(*) AS cnt FROM information_schema.TABLES "
                "WHERE TABLE_SCHEMA = %s AND TABLE_NAME = %s",
                (MYSQL_DB, 'products')
            )
            table_exists = cursor.fetchone()

            if not table_exists or int(table_exists.get('cnt', 0)) == 0:
                cursor.execute('''
                    CREATE TABLE products (
                        id INT AUTO_INCREMENT PRIMARY KEY,
                        name VARCHAR(255) NOT NULL,
                        description TEXT,
                        price DECIMAL(30,2) NOT NULL DEFAULT 0,
                        operator VARCHAR(50),
                        is_active TINYINT(1) DEFAULT 1,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
                    )
                ''')
                connection.commit()
                print("✅ جدول products ایجاد شد")

            # ============================================
            # 📌 بررسی و تغییر ستون product_type به operator
            # ============================================
            # بررسی وجود ستون product_type
            cursor.execute(
                "SELECT COUNT(*) AS cnt FROM information_schema.COLUMNS "
                "WHERE TABLE_SCHEMA = %s AND TABLE_NAME = %s AND COLUMN_NAME = %s",
                (MYSQL_DB, 'products', 'product_type')
            )
            has_product_type = cursor.fetchone()

            # بررسی وجود ستون operator
            cursor.execute(
                "SELECT COUNT(*) AS cnt FROM information_schema.COLUMNS "
                "WHERE TABLE_SCHEMA = %s AND TABLE_NAME = %s AND COLUMN_NAME = %s",
                (MYSQL_DB, 'products', 'operator')
            )
            has_operator = cursor.fetchone()

            # اگر product_type وجود دارد و operator وجود ندارد → تغییر نام بده
            if has_product_type and int(has_product_type.get('cnt', 0)) > 0:
                if not has_operator or int(has_operator.get('cnt', 0)) == 0:
                    cursor.execute("ALTER TABLE products CHANGE COLUMN product_type operator VARCHAR(50)")
                    connection.commit()
                    print("✅ ستون product_type به operator تغییر نام داد")

            # اگر هیچکدام وجود ندارد → ستون operator را اضافه کن
            elif not has_operator or int(has_operator.get('cnt', 0)) == 0:
                cursor.execute("ALTER TABLE products ADD COLUMN operator VARCHAR(50)")
                connection.commit()
                print("✅ ستون operator اضافه شد")

        except Exception as e:
            print(f"⚠️ خطا در ایجاد/بررسی جدول: {str(e)}")
            pass

        # ============================================
        # 📌 GET - دریافت محصولات
        # ============================================
        if request.method == 'GET':
            user_agent = request.headers.get('User-Agent', '')
            is_browser = 'Mozilla' in user_agent or 'Chrome' in user_agent or 'Safari' in user_agent
            is_api_request = request.headers.get('X-Requested-With') == 'XMLHttpRequest'

            if is_browser and not is_api_request and not request.args.get('id'):
                try:
                    cursor.execute("SELECT * FROM products ORDER BY id DESC")
                    products = cursor.fetchall() or []

                    for product in products:
                        if isinstance(product.get('price'), Decimal):
                            product['price'] = float(product['price'])

                    return render_template('admin_product.html', products=products)
                except Exception as e:
                    return jsonify({'message': f'خطا: {str(e)}'}), 500

            product_id = request.args.get('id')

            if product_id:
                cursor.execute("SELECT * FROM products WHERE id = %s", (product_id,))
                product = cursor.fetchone()

                if not product:
                    return jsonify({'message': 'محصول یافت نشد'}), 404

                if isinstance(product.get('price'), Decimal):
                    product['price'] = float(product['price'])

                return jsonify({'product': product}), 200

            else:
                cursor.execute("SELECT * FROM products ORDER BY id DESC")
                products = cursor.fetchall() or []

                for product in products:
                    if isinstance(product.get('price'), Decimal):
                        product['price'] = float(product['price'])

                return jsonify({
                    'products': products,
                    'count': len(products)
                }), 200

        # ============================================
        # 📌 POST - اضافه کردن محصول
        # ============================================
        elif request.method == 'POST':
            data = request.get_json(silent=True) or {}

            if not data.get('name') or data.get('price') is None:
                return jsonify({'message': 'نام و قیمت محصول الزامی است'}), 400

            name = data.get('name', '').strip()
            description = data.get('description', '').strip()
            operator = data.get('operator', '').strip()
            is_active = int(data.get('is_active', 1))

            try:
                price = float(data.get('price', 0))
                if price < 0:
                    return jsonify({'message': 'قیمت نمی‌تواند منفی باشد'}), 400
            except:
                return jsonify({'message': 'قیمت نامعتبر است'}), 400

            insert_query = '''
                INSERT INTO products (name, description, price, operator, is_active)
                VALUES (%s, %s, %s, %s, %s)
            '''
            cursor.execute(
                insert_query,
                (name, description, price, operator, is_active)
            )
            connection.commit()

            product_id = cursor.lastrowid

            return jsonify({
                'message': 'محصول با موفقیت اضافه شد',
                'product_id': product_id
            }), 201

        # ============================================
        # 📌 PUT - ویرایش محصول
        # ============================================
        elif request.method == 'PUT':
            data = request.get_json(silent=True) or {}
            product_id = data.get('id')

            if not product_id:
                return jsonify({'message': 'شناسه محصول الزامی است'}), 400

            cursor.execute("SELECT * FROM products WHERE id = %s", (product_id,))
            existing = cursor.fetchone()

            if not existing:
                return jsonify({'message': 'محصول یافت نشد'}), 404

            update_fields = []
            params = []

            if data.get('name'):
                update_fields.append("name = %s")
                params.append(data['name'].strip())

            if data.get('description') is not None:
                update_fields.append("description = %s")
                params.append(data['description'].strip())

            if data.get('price') is not None:
                try:
                    price = float(data['price'])
                    if price < 0:
                        return jsonify({'message': 'قیمت نمی‌تواند منفی باشد'}), 400
                    update_fields.append("price = %s")
                    params.append(price)
                except:
                    return jsonify({'message': 'قیمت نامعتبر است'}), 400

            if data.get('operator') is not None:
                update_fields.append("operator = %s")
                params.append(data['operator'].strip())

            if data.get('is_active') is not None:
                update_fields.append("is_active = %s")
                params.append(1 if bool(data['is_active']) else 0)

            if not update_fields:
                return jsonify({'message': 'هیچ فیلدی برای ویرایش ارسال نشده است'}), 400

            params.append(product_id)
            update_query = f"UPDATE products SET {', '.join(update_fields)} WHERE id = %s"
            cursor.execute(update_query, params)
            connection.commit()

            return jsonify({'message': 'محصول با موفقیت ویرایش شد'}), 200

        # ============================================
        # 📌 DELETE - حذف محصول
        # ============================================
        elif request.method == 'DELETE':
            data = request.get_json(silent=True) or {}
            product_id = data.get('id') or request.args.get('id')

            if not product_id:
                return jsonify({'message': 'شناسه محصول الزامی است'}), 400

            cursor.execute("SELECT * FROM products WHERE id = %s", (product_id,))
            existing = cursor.fetchone()

            if not existing:
                return jsonify({'message': 'محصول یافت نشد'}), 404

            cursor.execute("DELETE FROM products WHERE id = %s", (product_id,))
            connection.commit()

            return jsonify({'message': 'محصول با موفقیت حذف شد'}), 200

        else:
            return jsonify({'message': 'متد غیرمجاز'}), 405

    except Exception as e:
        print(f"❌ خطا در admin_product: {str(e)}")
        return jsonify({'message': f'خطا: {str(e)}'}), 500
    finally:
        if 'cursor' in locals() and cursor:
            try:
                cursor.close()
            except:
                pass
        if 'connection' in locals() and connection:
            try:
                connection.close()
            except:
                pass
#======================================================================================
@app.route('/admin_login', methods=['GET', 'POST'])
def admin_login():
    # اگر قبلاً لاگین کرده، به داشبورد برود
    if session.get('admin_logged_in'):
        return redirect(url_for('admin_dashboard'))

    if request.method == 'POST':
        username = request.form.get('username', '').strip()
        password = request.form.get('password', '').strip()

        if username == ADMIN_USERNAME and password == ADMIN_PASSWORD:
            session['admin_logged_in'] = True
            return redirect(url_for('admin_dashboard'))
        else:
            return render_template('admin_login.html', error='❌ نام کاربری یا رمز عبور اشتباه است')

    return render_template('admin_login.html', error=None)

@app.route('/admin_logout')
def admin_logout():
    session.pop('admin_logged_in', None)
    return redirect(url_for('admin_login'))

@app.route('/admin_dashboard', methods=['GET'])
def admin_dashboard():
    if not session.get('admin_logged_in'):
        return redirect(url_for('admin_login'))
    try:
        return render_template('admin_dashboard.html')
    except Exception as e:
        return f'خطا: {str(e)}', 500
#===============================================================================================
@app.route('/api/packages/all', methods=['GET'])
def get_all_packages():
    """
    دریافت همه بسته‌های فعال از جدول products
    Query Parameters: operator (اختیاری), category (اختیاری)
    """
    try:
        connection = get_db_connection()
        if not connection:
            return jsonify({'message': 'اتصال به پایگاه‌داده ناموفق بود'}), 500

        cursor = connection.cursor(dictionary=True)

        # دریافت پارامترها (اختیاری)
        operator = request.args.get('operator', '').strip()
        category = request.args.get('category', '').strip()

        # ساخت کوئری پایه
        query = """
            SELECT id, name, description, price, operator, is_active
            FROM products
            WHERE is_active = 1
        """
        params = []

        # فیلتر بر اساس اپراتور
        if operator:
            query += " AND operator = %s"
            params.append(operator)

        # فیلتر بر اساس دسته‌بندی (اگر ستون category دارید)
        if category:
            query += " AND category = %s"
            params.append(category)

        # مرتب‌سازی بر اساس قیمت
        query += " ORDER BY price ASC"

        cursor.execute(query, params)
        products = cursor.fetchall() or []

        # تبدیل Decimal به float
        for product in products:
            if isinstance(product.get('price'), Decimal):
                product['price'] = float(product['price'])

        return jsonify({
            'success': True,
            'packages': products,
            'count': len(products)
        }), 200

    except Exception as e:
        return jsonify({'message': f'خطا: {str(e)}'}), 500
    finally:
        if 'cursor' in locals() and cursor:
            try:
                cursor.close()
            except:
                pass
        if 'connection' in locals() and connection:
            try:
                connection.close()
            except:
                pass
# ============================================
# 📌 ایجاد جدول orders (اگر وجود نداشته باشد)
# ============================================
# در تابع ensure_orders_table() یا در یک تابع جداگانه
def ensure_orders_table():
    try:
        connection = get_db_connection()
        if not connection:
            return
        cursor = connection.cursor()

        # بررسی وجود جدول orders
        cursor.execute(
            "SELECT COUNT(*) AS cnt FROM information_schema.TABLES "
            "WHERE TABLE_SCHEMA = %s AND TABLE_NAME = %s",
            (MYSQL_DB, 'orders')
        )
        table_exists = cursor.fetchone()

        if not table_exists or int(table_exists.get('cnt', 0)) == 0:
            cursor.execute('''
                CREATE TABLE orders (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    user_id INT NOT NULL,
                    product_id INT NULL,
                    package_name VARCHAR(255) NOT NULL,
                    description TEXT NULL,
                    price DECIMAL(30,2) NOT NULL,
                    phone_number VARCHAR(50) NOT NULL,
                    operator VARCHAR(50),
                    user_name VARCHAR(255),
                    status ENUM('pending', 'completed', 'cancelled') DEFAULT 'pending',
                    rejection_reason TEXT NULL,
                    pubg_id VARCHAR(50) NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            ''')
            connection.commit()
            print("✅ جدول orders ایجاد شد")

        # ✅ بررسی وجود ستون description
        cursor.execute(
            "SELECT COUNT(*) AS cnt FROM information_schema.COLUMNS "
            "WHERE TABLE_SCHEMA = %s AND TABLE_NAME = %s AND COLUMN_NAME = %s",
            (MYSQL_DB, 'orders', 'description')
        )
        has_description = cursor.fetchone()

        if not has_description or int(has_description.get('cnt', 0)) == 0:
            cursor.execute("ALTER TABLE orders ADD COLUMN description TEXT NULL")
            connection.commit()
            print("✅ ستون description به جدول orders اضافه شد")

        # ✅ بررسی وجود ستون user_name
        cursor.execute(
            "SELECT COUNT(*) AS cnt FROM information_schema.COLUMNS "
            "WHERE TABLE_SCHEMA = %s AND TABLE_NAME = %s AND COLUMN_NAME = %s",
            (MYSQL_DB, 'orders', 'user_name')
        )
        has_user_name = cursor.fetchone()

        if not has_user_name or int(has_user_name.get('cnt', 0)) == 0:
            cursor.execute("ALTER TABLE orders ADD COLUMN user_name VARCHAR(255)")
            connection.commit()
            print("✅ ستون user_name به جدول orders اضافه شد")

        # ✅ بررسی وجود ستون rejection_reason
        cursor.execute(
            "SELECT COUNT(*) AS cnt FROM information_schema.COLUMNS "
            "WHERE TABLE_SCHEMA = %s AND TABLE_NAME = %s AND COLUMN_NAME = %s",
            (MYSQL_DB, 'orders', 'rejection_reason')
        )
        has_rejection_reason = cursor.fetchone()

        if not has_rejection_reason or int(has_rejection_reason.get('cnt', 0)) == 0:
            cursor.execute("ALTER TABLE orders ADD COLUMN rejection_reason TEXT NULL")
            connection.commit()
            print("✅ ستون rejection_reason به جدول orders اضافه شد")

        # ✅ بررسی وجود ستون pubg_id
        cursor.execute(
            "SELECT COUNT(*) AS cnt FROM information_schema.COLUMNS "
            "WHERE TABLE_SCHEMA = %s AND TABLE_NAME = %s AND COLUMN_NAME = %s",
            (MYSQL_DB, 'orders', 'pubg_id')
        )
        has_pubg_id = cursor.fetchone()

        if not has_pubg_id or int(has_pubg_id.get('cnt', 0)) == 0:
            cursor.execute("ALTER TABLE orders ADD COLUMN pubg_id VARCHAR(50) NULL")
            connection.commit()
            print("✅ ستون pubg_id به جدول orders اضافه شد")

        # ✅ بررسی وجود ستون operator
        cursor.execute(
            "SELECT COUNT(*) AS cnt FROM information_schema.COLUMNS "
            "WHERE TABLE_SCHEMA = %s AND TABLE_NAME = %s AND COLUMN_NAME = %s",
            (MYSQL_DB, 'orders', 'operator')
        )
        has_operator = cursor.fetchone()

        if not has_operator or int(has_operator.get('cnt', 0)) == 0:
            cursor.execute("ALTER TABLE orders ADD COLUMN operator VARCHAR(50)")
            connection.commit()
            print("✅ ستون operator به جدول orders اضافه شد")

        # ✅ بررسی وجود ستون product_id
        cursor.execute(
            "SELECT COUNT(*) AS cnt FROM information_schema.COLUMNS "
            "WHERE TABLE_SCHEMA = %s AND TABLE_NAME = %s AND COLUMN_NAME = %s",
            (MYSQL_DB, 'orders', 'product_id')
        )
        has_product_id = cursor.fetchone()

        if not has_product_id or int(has_product_id.get('cnt', 0)) == 0:
            cursor.execute("ALTER TABLE orders ADD COLUMN product_id INT NULL")
            connection.commit()
            print("✅ ستون product_id به جدول orders اضافه شد")

        # ✅ بررسی وجود ستون phone_number
        cursor.execute(
            "SELECT COUNT(*) AS cnt FROM information_schema.COLUMNS "
            "WHERE TABLE_SCHEMA = %s AND TABLE_NAME = %s AND COLUMN_NAME = %s",
            (MYSQL_DB, 'orders', 'phone_number')
        )
        has_phone_number = cursor.fetchone()

        if not has_phone_number or int(has_phone_number.get('cnt', 0)) == 0:
            cursor.execute("ALTER TABLE orders ADD COLUMN phone_number VARCHAR(50) NOT NULL DEFAULT ''")
            connection.commit()
            print("✅ ستون phone_number به جدول orders اضافه شد")

        cursor.close()
        connection.close()
    except Exception as e:
        print(f"⚠️ خطا در ایجاد/بررسی جدول orders: {str(e)}")

# ============================================
# 📌 ثبت سفارش جدید (وقتی کاربر بسته را انتخاب میکند)
# ============================================
@app.route('/api/orders/create', methods=['POST'])
@token_required
def create_order(current_user):
    try:
        data = request.get_json()

        if not data.get('product_id') or not data.get('package_name') or not data.get('price'):
            return jsonify({'message': 'اطلاعات محصول کامل نیست'}), 400

        product_id = data.get('product_id')
        package_name = data.get('package_name')
        price = float(data.get('price', 0))
        phone_number = data.get('phone_number', '')
        operator = data.get('operator', '')

        if price <= 0:
            return jsonify({'message': 'قیمت نامعتبر است'}), 400

        connection = get_db_connection()
        if not connection:
            return jsonify({'message': 'اتصال به پایگاه‌داده ناموفق بود'}), 500

        cursor = connection.cursor(dictionary=True)

        # ============================================
        # ✅ 1. دریافت اطلاعات کاربر (نام و موجودی)
        # ============================================
        cursor.execute(
            "SELECT id, first_name, last_name, balance FROM users WHERE id = %s",
            (current_user,)
        )
        user = cursor.fetchone()

        if not user:
            return jsonify({'message': 'کاربر یافت نشد'}), 404

        user_name = f"{user.get('first_name', '')} {user.get('last_name', '')}".strip()
        current_balance = float(user.get('balance', 0))

        # ============================================
        # ✅ 2. بررسی موجودی کافی
        # ============================================
        if current_balance < price:
            return jsonify({
                'success': False,
                'message': f'موجودی کافی نیست! موجودی شما: {current_balance:,.0f} تومان',
                'balance': current_balance
            }), 400

        # ============================================
        # ✅ 3. بررسی وجود محصول (هر دو جدول)
        # ============================================
        # ابتدا در جدول products (افغانستان) چک کن
        cursor.execute("SELECT id FROM products WHERE id = %s AND is_active = 1", (product_id,))
        product = cursor.fetchone()

        # اگر در products نبود، در products_iran (ایران) چک کن
        if not product:
            cursor.execute("SELECT id FROM products_iran WHERE id = %s AND is_active = 1", (product_id,))
            product = cursor.fetchone()

        # اگر در هیچکدام نبود، خطا بده
        if not product:
            return jsonify({'message': 'محصول یافت نشد'}), 404

        # ============================================
        # ✅ 4. ایجاد سفارش
        # ============================================
        insert_query = '''
            INSERT INTO orders (user_id, product_id, package_name, price, phone_number, operator, user_name)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
        '''
        cursor.execute(insert_query, (
            current_user,
            product_id,
            package_name,
            price,
            phone_number,
            operator,
            user_name
        ))
        order_id = cursor.lastrowid

        # ============================================
        # ✅ 5. کم کردن از موجودی کاربر
        # ============================================
        new_balance = current_balance - price
        cursor.execute(
            "UPDATE users SET balance = %s WHERE id = %s",
            (new_balance, current_user)
        )

        connection.commit()

        # ============================================
        # ✅ 6. برگرداندن پاسخ
        # ============================================
        return jsonify({
            'success': True,
            'message': 'سفارش با موفقیت ثبت شد',
            'order_id': order_id,
            'new_balance': new_balance,
            'deducted_amount': price
        }), 201

    except Exception as e:
        return jsonify({'message': f'خطا: {str(e)}'}), 500
    finally:
        if 'cursor' in locals() and cursor:
            try:
                cursor.close()
            except:
                pass
        if 'connection' in locals() and connection:
            try:
                connection.close()
            except:
                pass
# ============================================
# 📌 دریافت سفارشات کاربر
# ============================================
# ============================================
# 📌 دریافت سفارشات کاربر
# ============================================
# ============================================
# 📌 دریافت سفارشات کاربر
# ============================================
from datetime import datetime, timezone
from zoneinfo import ZoneInfo

@app.route('/api/orders', methods=['GET'])
@token_required
def get_user_orders(current_user):
    try:
        connection = get_db_connection()
        if not connection:
            return jsonify({'message': 'اتصال به پایگاه‌داده ناموفق بود'}), 500

        cursor = connection.cursor(dictionary=True)

        status_filter = request.args.get('status', '')

        # ✅ کوئری با حفظ credit_amount و price_per_unit
        query = """
            SELECT o.id, o.product_id, o.package_name, o.price, o.phone_number,
                   o.operator, o.status, o.created_at, o.rejection_reason,
                   o.credit_amount, o.price_per_unit, o.pubg_id, o.description as order_description,
                   COALESCE(p.name, p_iran.name) as product_name,
                   COALESCE(p.description, p_iran.description) as description
            FROM orders o
            LEFT JOIN products p ON o.product_id = p.id
            LEFT JOIN products_iran p_iran ON o.product_id = p_iran.id
            WHERE o.user_id = %s
        """
        params = [current_user]

        if status_filter:
            query += " AND o.status = %s"
            params.append(status_filter)

        query += " ORDER BY o.created_at DESC"

        cursor.execute(query, params)
        orders = cursor.fetchall() or []

        # ============================================
        # 📌 تابع تبدیل تاریخ به شمسی
        # ============================================
        def g2j(gy, gm, gd):
            g_d_m = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]
            gy2 = gy - 1600
            jy = 979

            if gy <= 1600:
                gy2 = gy - 621
                jy = 0

            days = 365 * gy2 + (gy2 + 3) // 4 - (gy2 + 99) // 100 + (gy2 + 399) // 400 - 80 + gd + g_d_m[gm - 1]
            jy += 33 * (days // 12053)
            days %= 12053
            jy += 4 * (days // 1461)
            days %= 1461

            if days > 365:
                jy += (days - 1) // 365
                days = (days - 1) % 365

            if days < 186:
                jm = 1 + days // 31
                jd = 1 + days % 31
            else:
                days -= 186
                jm = 7 + days // 30
                jd = 1 + days % 30

            return jy, jm, jd

        def fmt_jalali(dt):
            if not dt:
                return ""
            y, m, d = dt.year, dt.month, dt.day
            jy, jm, jd = g2j(y, m, d)
            return f"{jy:04d}/{jm:02d}/{jd:02d}"

        def fmt_iran_time(dt):
            if not dt:
                return ""
            if dt.tzinfo is None:
                dt = dt.replace(tzinfo=timezone.utc)
            iran_time = dt.astimezone(ZoneInfo("Asia/Tehran"))
            return iran_time.strftime("%H:%M")

        # ============================================
        # 📌 تبدیل تاریخ‌ها و تنظیم description
        # ============================================
        for order in orders:
            if isinstance(order.get('price'), Decimal):
                order['price'] = float(order['price'])

            product_id = order.get('product_id')
            package_name = order.get('package_name', '')
            credit_amount = order.get('credit_amount', 0)
            operator = order.get('operator', '')
            pubg_id = order.get('pubg_id', '')
            order_description = order.get('order_description', '')

            # ✅ تنظیم description برای انواع سفارش‌ها
            # 1. اگر product_id == 0 یا None باشد، یعنی سفارش کریدیت است
            if product_id == 0 or product_id is None:
                if credit_amount > 0:
                    # تشخیص نوع کریدیت بر اساس نام بسته
                    if 'ترکیه' in package_name or 'لیر' in package_name:
                        order['description'] = f"{credit_amount} لیر شارژ {operator}"
                    elif 'ایران' in package_name or 'تومان' in package_name:
                        order['description'] = f"{credit_amount} تومان شارژ {operator}"
                    elif 'پابجی' in package_name or 'یوسی' in package_name:
                        # ✅ یوسی پابجی (بدون credit_amount)
                        order['description'] = f"خرید یوسی پابجی برای ایدی {pubg_id or 'نامشخص'}"
                    else:
                        order['description'] = f"{credit_amount} افغانی شارژ {operator}"
                else:
                    order['description'] = 'شارژ'

            # 2. اگر order_description از خود جدول orders وجود داشته باشد (برای یوسی پابجی)
            elif order_description:
                order['description'] = order_description

            # 3. اگر description از جدول products یا products_iran وجود داشته باشد
            elif order.get('description'):
                order['description'] = order['description']

            # 4. اگر پابجی باشد و description نداشته باشد
            elif 'پابجی' in package_name or 'یوسی' in package_name:
                order['description'] = f"خرید یوسی پابجی برای ایدی {pubg_id or 'نامشخص'}"

            # 5. اگر هیچکدام نبود
            else:
                order['description'] = 'بدون توضیحات'

            # ✅ تنظیم package_name برای یوسی پابجی
            if 'پابجی' in package_name or 'یوسی' in package_name:
                if pubg_id:
                    order['package_name'] = package_name

            # ✅ تاریخ و ساعت
            if order.get('created_at'):
                dt = order['created_at']
                if isinstance(dt, datetime):
                    order['created_at_jalali'] = fmt_jalali(dt)
                    order['created_at_time'] = fmt_iran_time(dt)
                    order['created_at_full'] = f"{fmt_jalali(dt)} - {fmt_iran_time(dt)}"
                else:
                    order['created_at_jalali'] = str(dt)
                    order['created_at_time'] = ''
                    order['created_at_full'] = str(dt)

        return jsonify({
            'success': True,
            'orders': orders,
            'count': len(orders)
        }), 200

    except Exception as e:
        print(f"❌ خطا در get_user_orders: {str(e)}")
        return jsonify({'message': f'خطا: {str(e)}'}), 500
    finally:
        if 'cursor' in locals() and cursor:
            try:
                cursor.close()
            except:
                pass
        if 'connection' in locals() and connection:
            try:
                connection.close()
            except:
                pass
#====================================================================

# ============================================
@app.route('/admin_seller', methods=['GET', 'POST'])
def admin_seller():
    # ============================================
    # 🔒 بررسی لاگین بودن ادمین
    # ============================================
    if not session.get('admin_logged_in'):
        return redirect(url_for('admin_login'))

    try:
        connection = get_db_connection()
        if not connection:
            return jsonify({'message': 'اتصال به پایگاه‌داده ناموفق بود'}), 500

        cursor = connection.cursor(dictionary=True)

        # ============================================
        # 📌 POST - تایید یا رد سفارش
        # ============================================
        if request.method == 'POST':
            data = request.get_json() or {}
            order_id = data.get('order_id')
            action = data.get('action')  # 'confirm' یا 'reject'
            rejection_reason = data.get('rejection_reason', '').strip()  # ✅ علت رد

            if not order_id or not action:
                return jsonify({'message': 'پارامترهای لازم ارسال نشده‌اند'}), 400

            if action not in ['confirm', 'reject']:
                return jsonify({'message': 'عملکرد نامعتبر است'}), 400

            # دریافت اطلاعات سفارش
            cursor.execute("""
                SELECT id, user_id, price, status
                FROM orders
                WHERE id = %s
            """, (order_id,))
            order = cursor.fetchone()

            if not order:
                return jsonify({'message': 'سفارش یافت نشد'}), 404

            if order['status'] != 'pending':
                return jsonify({'message': 'این سفارش قبلاً بررسی شده است'}), 400

            if action == 'confirm':
                # ✅ تایید سفارش
                cursor.execute(
                    "UPDATE orders SET status = 'completed' WHERE id = %s",
                    (order_id,)
                )
                connection.commit()

                return jsonify({
                    'success': True,
                    'message': 'سفارش با موفقیت تایید شد',
                    'order_id': order_id,
                    'status': 'completed'
                }), 200

            elif action == 'reject':
                # ❌ رد سفارش - با علت
                user_id = order['user_id']
                price = float(order['price'])

                # برگشت موجودی به کاربر
                cursor.execute(
                    "UPDATE users SET balance = balance + %s WHERE id = %s",
                    (price, user_id)
                )

                # به‌روزرسانی وضعیت و ذخیره علت رد
                cursor.execute(
                    "UPDATE orders SET status = 'cancelled', rejection_reason = %s WHERE id = %s",
                    (rejection_reason, order_id)
                )

                connection.commit()

                return jsonify({
                    'success': True,
                    'message': 'سفارش رد شد و موجودی به کاربر برگشت داده شد',
                    'order_id': order_id,
                    'status': 'cancelled',
                    'refunded_amount': price
                }), 200

        # ============================================
        # 📌 GET - دریافت تمام سفارشات با موجودی کاربر
        # ============================================
        cursor.execute("""
            SELECT
                o.id,
                o.user_id,
                o.product_id,
                o.package_name,
                o.price,
                o.phone_number,
                o.operator,
                o.user_name,
                o.status,
                o.rejection_reason,
                o.created_at,
                u.first_name,
                u.last_name,
                u.phone_number as user_phone,
                u.balance as user_balance,
                p.name as product_name,
                p.description as product_description
            FROM orders o
            LEFT JOIN users u ON o.user_id = u.id
            LEFT JOIN products p ON o.product_id = p.id
            ORDER BY o.created_at DESC
        """)
        orders = cursor.fetchall() or []

        # ============================================
        # 📌 توابع تبدیل تاریخ به شمسی
        # ============================================
        def g2j(gy, gm, gd):
            g_d_m = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]
            gy2 = gy - 1600
            jy = 979

            if gy <= 1600:
                gy2 = gy - 621
                jy = 0

            days = 365 * gy2 + (gy2 + 3) // 4 - (gy2 + 99) // 100 + (gy2 + 399) // 400 - 80 + gd + g_d_m[gm - 1]
            jy += 33 * (days // 12053)
            days %= 12053
            jy += 4 * (days // 1461)
            days %= 1461

            if days > 365:
                jy += (days - 1) // 365
                days = (days - 1) % 365

            if days < 186:
                jm = 1 + days // 31
                jd = 1 + days % 31
            else:
                days -= 186
                jm = 7 + days // 30
                jd = 1 + days % 30

            return jy, jm, jd

        def fmt_jalali_date(dt):
            if not dt:
                return ""
            if isinstance(dt, str):
                try:
                    dt = datetime.fromisoformat(dt.replace('Z', '+00:00'))
                except:
                    return dt
            y, m, d = dt.year, dt.month, dt.day
            jy, jm, jd = g2j(y, m, d)
            return f"{jy:04d}/{jm:02d}/{jd:02d}"

        def fmt_time(dt):
            if not dt:
                return ""
            if isinstance(dt, str):
                try:
                    dt = datetime.fromisoformat(dt.replace('Z', '+00:00'))
                except:
                    return ""
            if dt.tzinfo is None:
                dt = dt.replace(tzinfo=timezone.utc)
            iran_time = dt.astimezone(ZoneInfo("Asia/Tehran"))
            return iran_time.strftime("%H:%M")

        # ============================================
        # 📌 تبدیل تاریخ‌ها برای هر سفارش
        # ============================================
        for order in orders:
            if isinstance(order.get('price'), Decimal):
                order['price'] = float(order['price'])

            # فرمت موجودی کاربر
            if order.get('user_balance') is not None:
                try:
                    order['user_balance_formatted'] = "{:,.0f}".format(float(order['user_balance']))
                except:
                    order['user_balance_formatted'] = str(order['user_balance'])
            else:
                order['user_balance_formatted'] = '0'

            if order.get('created_at'):
                dt = order['created_at']
                if isinstance(dt, datetime):
                    order['created_at_jalali'] = fmt_jalali_date(dt)
                    order['created_at_time'] = fmt_time(dt)
                else:
                    order['created_at_jalali'] = str(dt)
                    order['created_at_time'] = ''

            # وضعیت به فارسی
            status_map = {
                'pending': 'در انتظار تایید',
                'completed': 'تایید شده',
                'cancelled': 'رد شده'
            }
            order['status_persian'] = status_map.get(order.get('status'), 'نامشخص')

            # رنگ وضعیت
            status_color_map = {
                'pending': '#F59E0B',
                'completed': '#10B981',
                'cancelled': '#EF4444'
            }
            order['status_color'] = status_color_map.get(order.get('status'), '#6B7280')

        # ============================================
        # 📌 آمار سفارشات
        # ============================================
        cursor.execute("""
            SELECT
                COUNT(*) as total,
                SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) as pending,
                SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed,
                SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END) as cancelled
            FROM orders
        """)
        stats = cursor.fetchone() or {}

        cursor.close()
        connection.close()

        return render_template(
            'admin_seller.html',
            orders=orders,
            stats=stats
        )

    except Exception as e:
        print(f"❌ خطا در admin_seller: {str(e)}")
        return jsonify({'message': f'خطا: {str(e)}'}), 500
    finally:
        if 'cursor' in locals() and cursor:
            try:
                cursor.close()
            except:
                pass
        if 'connection' in locals() and connection:
            try:
                connection.close()
            except:
                pass
# ============================================
# 📌 مسیر ادمین برای مدیریت محصولات ایران
# ============================================
@app.route('/admin_product_iran', methods=['GET', 'POST', 'PUT', 'DELETE'])
def admin_product_iran():
    # ============================================
    # 🔒 بررسی لاگین بودن ادمین
    # ============================================
    if not session.get('admin_logged_in'):
        return redirect(url_for('admin_login'))

    try:
        connection = get_db_connection()
        if not connection:
            return jsonify({'message': 'اتصال به پایگاه‌داده ناموفق بود'}), 500

        cursor = connection.cursor(dictionary=True)

        # ============================================
        # 📌 ایجاد جدول products_iran (اگر وجود نداشته باشد)
        # ============================================
        try:
            cursor.execute(
                "SELECT COUNT(*) AS cnt FROM information_schema.TABLES "
                "WHERE TABLE_SCHEMA = %s AND TABLE_NAME = %s",
                (MYSQL_DB, 'products_iran')
            )
            table_exists = cursor.fetchone()

            if not table_exists or int(table_exists.get('cnt', 0)) == 0:
                cursor.execute('''
                    CREATE TABLE products_iran (
                        id INT AUTO_INCREMENT PRIMARY KEY,
                        name VARCHAR(255) NOT NULL,
                        description TEXT,
                        price DECIMAL(30,2) NOT NULL DEFAULT 0,
                        operator VARCHAR(50),
                        is_active TINYINT(1) DEFAULT 1,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
                    )
                ''')
                connection.commit()
                print("✅ جدول products_iran ایجاد شد")

        except Exception as e:
            print(f"⚠️ خطا در ایجاد/بررسی جدول products_iran: {str(e)}")
            pass

        # ============================================
        # 📌 GET - دریافت محصولات ایران
        # ============================================
        if request.method == 'GET':
            user_agent = request.headers.get('User-Agent', '')
            is_browser = 'Mozilla' in user_agent or 'Chrome' in user_agent or 'Safari' in user_agent
            is_api_request = request.headers.get('X-Requested-With') == 'XMLHttpRequest'

            if is_browser and not is_api_request and not request.args.get('id'):
                try:
                    cursor.execute("SELECT * FROM products_iran ORDER BY id DESC")
                    products = cursor.fetchall() or []

                    for product in products:
                        if isinstance(product.get('price'), Decimal):
                            product['price'] = float(product['price'])

                    return render_template('admin_product_iran.html', products=products)
                except Exception as e:
                    return jsonify({'message': f'خطا: {str(e)}'}), 500

            product_id = request.args.get('id')

            if product_id:
                cursor.execute("SELECT * FROM products_iran WHERE id = %s", (product_id,))
                product = cursor.fetchone()

                if not product:
                    return jsonify({'message': 'محصول یافت نشد'}), 404

                if isinstance(product.get('price'), Decimal):
                    product['price'] = float(product['price'])

                return jsonify({'product': product}), 200

            else:
                cursor.execute("SELECT * FROM products_iran ORDER BY id DESC")
                products = cursor.fetchall() or []

                for product in products:
                    if isinstance(product.get('price'), Decimal):
                        product['price'] = float(product['price'])

                return jsonify({
                    'products': products,
                    'count': len(products)
                }), 200

        # ============================================
        # 📌 POST - اضافه کردن محصول ایران
        # ============================================
        elif request.method == 'POST':
            data = request.get_json(silent=True) or {}

            if not data.get('name') or data.get('price') is None:
                return jsonify({'message': 'نام و قیمت محصول الزامی است'}), 400

            name = data.get('name', '').strip()
            description = data.get('description', '').strip()
            operator = data.get('operator', '').strip()
            is_active = int(data.get('is_active', 1))

            try:
                price = float(data.get('price', 0))
                if price < 0:
                    return jsonify({'message': 'قیمت نمی‌تواند منفی باشد'}), 400
            except:
                return jsonify({'message': 'قیمت نامعتبر است'}), 400

            insert_query = '''
                INSERT INTO products_iran (name, description, price, operator, is_active)
                VALUES (%s, %s, %s, %s, %s)
            '''
            cursor.execute(
                insert_query,
                (name, description, price, operator, is_active)
            )
            connection.commit()

            product_id = cursor.lastrowid

            return jsonify({
                'message': 'محصول با موفقیت اضافه شد',
                'product_id': product_id
            }), 201

        # ============================================
        # 📌 PUT - ویرایش محصول ایران
        # ============================================
        elif request.method == 'PUT':
            data = request.get_json(silent=True) or {}
            product_id = data.get('id')

            if not product_id:
                return jsonify({'message': 'شناسه محصول الزامی است'}), 400

            cursor.execute("SELECT * FROM products_iran WHERE id = %s", (product_id,))
            existing = cursor.fetchone()

            if not existing:
                return jsonify({'message': 'محصول یافت نشد'}), 404

            update_fields = []
            params = []

            if data.get('name'):
                update_fields.append("name = %s")
                params.append(data['name'].strip())

            if data.get('description') is not None:
                update_fields.append("description = %s")
                params.append(data['description'].strip())

            if data.get('price') is not None:
                try:
                    price = float(data['price'])
                    if price < 0:
                        return jsonify({'message': 'قیمت نمی‌تواند منفی باشد'}), 400
                    update_fields.append("price = %s")
                    params.append(price)
                except:
                    return jsonify({'message': 'قیمت نامعتبر است'}), 400

            if data.get('operator') is not None:
                update_fields.append("operator = %s")
                params.append(data['operator'].strip())

            if data.get('is_active') is not None:
                update_fields.append("is_active = %s")
                params.append(1 if bool(data['is_active']) else 0)

            if not update_fields:
                return jsonify({'message': 'هیچ فیلدی برای ویرایش ارسال نشده است'}), 400

            params.append(product_id)
            update_query = f"UPDATE products_iran SET {', '.join(update_fields)} WHERE id = %s"
            cursor.execute(update_query, params)
            connection.commit()

            return jsonify({'message': 'محصول با موفقیت ویرایش شد'}), 200

        # ============================================
        # 📌 DELETE - حذف محصول ایران
        # ============================================
        elif request.method == 'DELETE':
            data = request.get_json(silent=True) or {}
            product_id = data.get('id') or request.args.get('id')

            if not product_id:
                return jsonify({'message': 'شناسه محصول الزامی است'}), 400

            cursor.execute("SELECT * FROM products_iran WHERE id = %s", (product_id,))
            existing = cursor.fetchone()

            if not existing:
                return jsonify({'message': 'محصول یافت نشد'}), 404

            cursor.execute("DELETE FROM products_iran WHERE id = %s", (product_id,))
            connection.commit()

            return jsonify({'message': 'محصول با موفقیت حذف شد'}), 200

        else:
            return jsonify({'message': 'متد غیرمجاز'}), 405

    except Exception as e:
        print(f"❌ خطا در admin_product_iran: {str(e)}")
        return jsonify({'message': f'خطا: {str(e)}'}), 500
    finally:
        if 'cursor' in locals() and cursor:
            try:
                cursor.close()
            except:
                pass
        if 'connection' in locals() and connection:
            try:
                connection.close()
            except:
                pass
# ============================================
# 📌 دریافت بسته‌های ایران (برای کاربران)
# ============================================
@app.route('/api/packages/iran', methods=['GET'])
def get_iran_packages():
    """
    دریافت همه بسته‌های فعال ایران
    Query Parameters: operator (اختیاری)
    """
    try:
        connection = get_db_connection()
        if not connection:
            return jsonify({'message': 'اتصال به پایگاه‌داده ناموفق بود'}), 500

        cursor = connection.cursor(dictionary=True)

        operator = request.args.get('operator', '').strip()

        query = """
            SELECT id, name, description, price, operator, is_active
            FROM products_iran
            WHERE is_active = 1
        """
        params = []

        if operator:
            query += " AND operator = %s"
            params.append(operator)

        query += " ORDER BY price ASC"

        cursor.execute(query, params)
        products = cursor.fetchall() or []

        for product in products:
            if isinstance(product.get('price'), Decimal):
                product['price'] = float(product['price'])

        return jsonify({
            'success': True,
            'packages': products,
            'count': len(products)
        }), 200

    except Exception as e:
        return jsonify({'message': f'خطا: {str(e)}'}), 500
    finally:
        if 'cursor' in locals() and cursor:
            try:
                cursor.close()
            except:
                pass
        if 'connection' in locals() and connection:
            try:
                connection.close()
            except:
                pass
#======================================================
# ============================================
# 📌 مسیر ادمین برای مدیریت کریدیت افغانستان
# ============================================
@app.route('/admin_credit_afghanistan', methods=['GET', 'POST', 'PUT', 'DELETE'])
def admin_credit_afghanistan():
    # ============================================
    # 🔒 بررسی لاگین بودن ادمین
    # ============================================
    if not session.get('admin_logged_in'):
        return redirect(url_for('admin_login'))

    try:
        connection = get_db_connection()
        if not connection:
            return jsonify({'message': 'اتصال به پایگاه‌داده ناموفق بود'}), 500

        cursor = connection.cursor(dictionary=True)

        # ============================================
        # 📌 ایجاد جدول credits_afghanistan (اگر وجود نداشته باشد)
        # ============================================
        try:
            cursor.execute(
                "SELECT COUNT(*) AS cnt FROM information_schema.TABLES "
                "WHERE TABLE_SCHEMA = %s AND TABLE_NAME = %s",
                (MYSQL_DB, 'credits_afghanistan')
            )
            table_exists = cursor.fetchone()

            if not table_exists or int(table_exists.get('cnt', 0)) == 0:
                cursor.execute('''
                    CREATE TABLE credits_afghanistan (
                        id INT AUTO_INCREMENT PRIMARY KEY,
                        name VARCHAR(255) NOT NULL,
                        amount INT NOT NULL,
                        price DECIMAL(30,2) NOT NULL DEFAULT 0,
                        operator VARCHAR(50),
                        is_active TINYINT(1) DEFAULT 1,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
                    )
                ''')
                connection.commit()
                print("✅ جدول credits_afghanistan ایجاد شد")

        except Exception as e:
            print(f"⚠️ خطا در ایجاد/بررسی جدول credits_afghanistan: {str(e)}")
            pass

        # ============================================
        # 📌 GET - دریافت کریدیت‌ها
        # ============================================
        if request.method == 'GET':
            user_agent = request.headers.get('User-Agent', '')
            is_browser = 'Mozilla' in user_agent or 'Chrome' in user_agent or 'Safari' in user_agent
            is_api_request = request.headers.get('X-Requested-With') == 'XMLHttpRequest'

            if is_browser and not is_api_request and not request.args.get('id'):
                try:
                    cursor.execute("SELECT * FROM credits_afghanistan ORDER BY id DESC")
                    credits = cursor.fetchall() or []

                    for credit in credits:
                        if isinstance(credit.get('price'), Decimal):
                            credit['price'] = float(credit['price'])

                    return render_template('admin_credit_afghanistan.html', credits=credits)
                except Exception as e:
                    return jsonify({'message': f'خطا: {str(e)}'}), 500

            credit_id = request.args.get('id')

            if credit_id:
                cursor.execute("SELECT * FROM credits_afghanistan WHERE id = %s", (credit_id,))
                credit = cursor.fetchone()

                if not credit:
                    return jsonify({'message': 'کریدیت یافت نشد'}), 404

                if isinstance(credit.get('price'), Decimal):
                    credit['price'] = float(credit['price'])

                return jsonify({'credit': credit}), 200

            else:
                cursor.execute("SELECT * FROM credits_afghanistan ORDER BY id DESC")
                credits = cursor.fetchall() or []

                for credit in credits:
                    if isinstance(credit.get('price'), Decimal):
                        credit['price'] = float(credit['price'])

                return jsonify({
                    'credits': credits,
                    'count': len(credits)
                }), 200

        # ============================================
        # 📌 POST - اضافه کردن کریدیت
        # ============================================
        elif request.method == 'POST':
            data = request.get_json(silent=True) or {}

            if not data.get('name') or data.get('amount') is None or data.get('price') is None:
                return jsonify({'message': 'نام، مقدار و قیمت کریدیت الزامی است'}), 400

            name = data.get('name', '').strip()
            amount = int(data.get('amount', 0))
            price = float(data.get('price', 0))
            operator = data.get('operator', '').strip()
            is_active = int(data.get('is_active', 1))

            if amount <= 0:
                return jsonify({'message': 'مقدار شارژ باید بزرگتر از صفر باشد'}), 400
            if price <= 0:
                return jsonify({'message': 'قیمت باید بزرگتر از صفر باشد'}), 400

            insert_query = '''
                INSERT INTO credits_afghanistan (name, amount, price, operator, is_active)
                VALUES (%s, %s, %s, %s, %s)
            '''
            cursor.execute(
                insert_query,
                (name, amount, price, operator, is_active)
            )
            connection.commit()

            credit_id = cursor.lastrowid

            return jsonify({
                'message': 'کریدیت با موفقیت اضافه شد',
                'credit_id': credit_id
            }), 201

        # ============================================
        # 📌 PUT - ویرایش کریدیت
        # ============================================
        elif request.method == 'PUT':
            data = request.get_json(silent=True) or {}
            credit_id = data.get('id')

            if not credit_id:
                return jsonify({'message': 'شناسه کریدیت الزامی است'}), 400

            cursor.execute("SELECT * FROM credits_afghanistan WHERE id = %s", (credit_id,))
            existing = cursor.fetchone()

            if not existing:
                return jsonify({'message': 'کریدیت یافت نشد'}), 404

            update_fields = []
            params = []

            if data.get('name'):
                update_fields.append("name = %s")
                params.append(data['name'].strip())

            if data.get('amount') is not None:
                amount = int(data['amount'])
                if amount <= 0:
                    return jsonify({'message': 'مقدار شارژ باید بزرگتر از صفر باشد'}), 400
                update_fields.append("amount = %s")
                params.append(amount)

            if data.get('price') is not None:
                try:
                    price = float(data['price'])
                    if price < 0:
                        return jsonify({'message': 'قیمت نمی‌تواند منفی باشد'}), 400
                    update_fields.append("price = %s")
                    params.append(price)
                except:
                    return jsonify({'message': 'قیمت نامعتبر است'}), 400

            if data.get('operator') is not None:
                update_fields.append("operator = %s")
                params.append(data['operator'].strip())

            if data.get('is_active') is not None:
                update_fields.append("is_active = %s")
                params.append(1 if bool(data['is_active']) else 0)

            if not update_fields:
                return jsonify({'message': 'هیچ فیلدی برای ویرایش ارسال نشده است'}), 400

            params.append(credit_id)
            update_query = f"UPDATE credits_afghanistan SET {', '.join(update_fields)} WHERE id = %s"
            cursor.execute(update_query, params)
            connection.commit()

            return jsonify({'message': 'کریدیت با موفقیت ویرایش شد'}), 200

        # ============================================
        # 📌 DELETE - حذف کریدیت
        # ============================================
        elif request.method == 'DELETE':
            data = request.get_json(silent=True) or {}
            credit_id = data.get('id') or request.args.get('id')

            if not credit_id:
                return jsonify({'message': 'شناسه کریدیت الزامی است'}), 400

            cursor.execute("SELECT * FROM credits_afghanistan WHERE id = %s", (credit_id,))
            existing = cursor.fetchone()

            if not existing:
                return jsonify({'message': 'کریدیت یافت نشد'}), 404

            cursor.execute("DELETE FROM credits_afghanistan WHERE id = %s", (credit_id,))
            connection.commit()

            return jsonify({'message': 'کریدیت با موفقیت حذف شد'}), 200

        else:
            return jsonify({'message': 'متد غیرمجاز'}), 405

    except Exception as e:
        print(f"❌ خطا در admin_credit_afghanistan: {str(e)}")
        return jsonify({'message': f'خطا: {str(e)}'}), 500
    finally:
        if 'cursor' in locals() and cursor:
            try:
                cursor.close()
            except:
                pass
        if 'connection' in locals() and connection:
            try:
                connection.close()
            except:
                pass

# ============================================
# 📌 دریافت کریدیت‌های افغانستان (برای کاربران)
# ============================================
@app.route('/api/credits/afghanistan', methods=['GET'])
def get_credits_afghanistan():
    """
    دریافت همه کریدیت‌های فعال افغانستان
    Query Parameters: operator (اختیاری)
    """
    try:
        connection = get_db_connection()
        if not connection:
            return jsonify({'message': 'اتصال به پایگاه‌داده ناموفق بود'}), 500

        cursor = connection.cursor(dictionary=True)

        operator = request.args.get('operator', '').strip()

        query = """
            SELECT id, name, amount, price, operator, is_active
            FROM credits_afghanistan
            WHERE is_active = 1
        """
        params = []

        if operator:
            query += " AND operator = %s"
            params.append(operator)

        query += " ORDER BY amount ASC"

        cursor.execute(query, params)
        credits = cursor.fetchall() or []

        for credit in credits:
            if isinstance(credit.get('price'), Decimal):
                credit['price'] = float(credit['price'])

        return jsonify({
            'success': True,
            'credits': credits,
            'count': len(credits)
        }), 200

    except Exception as e:
        return jsonify({'message': f'خطا: {str(e)}'}), 500
    finally:
        if 'cursor' in locals() and cursor:
            try:
                cursor.close()
            except:
                pass
        if 'connection' in locals() and connection:
            try:
                connection.close()
            except:
                pass
#====================================================
# ============================================
# 📌 ثبت سفارش کریدیت
# ============================================
@app.route('/api/orders/create_credit', methods=['POST'])
@token_required
def create_credit_order(current_user):
    try:
        data = request.get_json()

        if not data.get('phone_number') or not data.get('operator') or not data.get('amount') or not data.get('price'):
            return jsonify({'message': 'اطلاعات کامل نیست'}), 400

        phone_number = data.get('phone_number')
        operator = data.get('operator')
        amount = int(data.get('amount', 0))
        price = float(data.get('price', 0))
        price_per_unit = float(data.get('price_per_unit', 0))

        if amount <= 0:
            return jsonify({'message': 'مقدار شارژ نامعتبر است'}), 400
        if price <= 0:
            return jsonify({'message': 'قیمت نامعتبر است'}), 400

        connection = get_db_connection()
        if not connection:
            return jsonify({'message': 'اتصال به پایگاه‌داده ناموفق بود'}), 500

        cursor = connection.cursor(dictionary=True)

        # ✅ 1. دریافت اطلاعات کاربر
        cursor.execute(
            "SELECT id, first_name, last_name, balance FROM users WHERE id = %s",
            (current_user,)
        )
        user = cursor.fetchone()

        if not user:
            return jsonify({'message': 'کاربر یافت نشد'}), 404

        user_name = f"{user.get('first_name', '')} {user.get('last_name', '')}".strip()
        if not user_name:
            user_name = 'کاربر'

        current_balance = float(user.get('balance', 0))

        # ✅ 2. بررسی موجودی
        if current_balance < price:
            return jsonify({
                'success': False,
                'message': f'موجودی کافی نیست! موجودی شما: {current_balance:,.0f} تومان',
                'balance': current_balance
            }), 400

        # ✅ 3. ایجاد سفارش کریدیت
        # ✅ اصلاح شده: "200 افغانی شارژ ایرانسل"
        package_name = f"{amount} افغانی شارژ {operator}"

        insert_query = '''
            INSERT INTO orders (
                user_id,
                product_id,
                package_name,
                price,
                phone_number,
                operator,
                user_name,
                credit_amount,
                price_per_unit
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
        '''
        cursor.execute(insert_query, (
            current_user,
            None,
            package_name,
            price,
            phone_number,
            operator,
            user_name,
            amount,
            price_per_unit
        ))
        order_id = cursor.lastrowid

        # ✅ 4. کم کردن از موجودی
        new_balance = current_balance - price
        cursor.execute(
            "UPDATE users SET balance = %s WHERE id = %s",
            (new_balance, current_user)
        )

        connection.commit()

        return jsonify({
            'success': True,
            'message': 'سفارش کریدیت با موفقیت ثبت شد',
            'order_id': order_id,
            'new_balance': new_balance,
            'deducted_amount': price,
            'amount': amount,
            'price_per_unit': price_per_unit
        }), 201

    except Exception as e:
        print(f"❌ خطا در create_credit_order: {str(e)}")
        return jsonify({'message': f'خطا: {str(e)}'}), 500
    finally:
        if 'cursor' in locals() and cursor:
            try:
                cursor.close()
            except:
                pass
        if 'connection' in locals() and connection:
            try:
                connection.close()
            except:
                pass
# ============================================
# 📌 مسیر ادمین برای مدیریت کریدیت ایران
# ============================================
@app.route('/admin_credit_iran', methods=['GET', 'POST', 'PUT', 'DELETE'])
def admin_credit_iran():
    # ============================================
    # 🔒 بررسی لاگین بودن ادمین
    # ============================================
    if not session.get('admin_logged_in'):
        return redirect(url_for('admin_login'))

    try:
        connection = get_db_connection()
        if not connection:
            return jsonify({'message': 'اتصال به پایگاه‌داده ناموفق بود'}), 500

        cursor = connection.cursor(dictionary=True)

        # ============================================
        # 📌 ایجاد جدول credits_iran (اگر وجود نداشته باشد)
        # ============================================
        try:
            cursor.execute(
                "SELECT COUNT(*) AS cnt FROM information_schema.TABLES "
                "WHERE TABLE_SCHEMA = %s AND TABLE_NAME = %s",
                (MYSQL_DB, 'credits_iran')
            )
            table_exists = cursor.fetchone()

            if not table_exists or int(table_exists.get('cnt', 0)) == 0:
                cursor.execute('''
                    CREATE TABLE credits_iran (
                        id INT AUTO_INCREMENT PRIMARY KEY,
                        name VARCHAR(255) NOT NULL,
                        amount INT NOT NULL,
                        price DECIMAL(30,2) NOT NULL DEFAULT 0,
                        operator VARCHAR(50),
                        is_active TINYINT(1) DEFAULT 1,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
                    )
                ''')
                connection.commit()
                print("✅ جدول credits_iran ایجاد شد")

        except Exception as e:
            print(f"⚠️ خطا در ایجاد/بررسی جدول credits_iran: {str(e)}")
            pass

        # ============================================
        # 📌 GET - دریافت کریدیت‌ها
        # ============================================
        if request.method == 'GET':
            user_agent = request.headers.get('User-Agent', '')
            is_browser = 'Mozilla' in user_agent or 'Chrome' in user_agent or 'Safari' in user_agent
            is_api_request = request.headers.get('X-Requested-With') == 'XMLHttpRequest'

            if is_browser and not is_api_request and not request.args.get('id'):
                try:
                    cursor.execute("SELECT * FROM credits_iran ORDER BY id DESC")
                    credits = cursor.fetchall() or []

                    for credit in credits:
                        if isinstance(credit.get('price'), Decimal):
                            credit['price'] = float(credit['price'])

                    return render_template('admin_credit_iran.html', credits=credits)
                except Exception as e:
                    return jsonify({'message': f'خطا: {str(e)}'}), 500

            credit_id = request.args.get('id')

            if credit_id:
                cursor.execute("SELECT * FROM credits_iran WHERE id = %s", (credit_id,))
                credit = cursor.fetchone()

                if not credit:
                    return jsonify({'message': 'کریدیت یافت نشد'}), 404

                if isinstance(credit.get('price'), Decimal):
                    credit['price'] = float(credit['price'])

                return jsonify({'credit': credit}), 200

            else:
                cursor.execute("SELECT * FROM credits_iran ORDER BY id DESC")
                credits = cursor.fetchall() or []

                for credit in credits:
                    if isinstance(credit.get('price'), Decimal):
                        credit['price'] = float(credit['price'])

                return jsonify({
                    'credits': credits,
                    'count': len(credits)
                }), 200

        # ============================================
        # 📌 POST - اضافه کردن کریدیت
        # ============================================
        elif request.method == 'POST':
            data = request.get_json(silent=True) or {}

            if not data.get('name') or data.get('amount') is None or data.get('price') is None:
                return jsonify({'message': 'نام، مقدار و قیمت کریدیت الزامی است'}), 400

            name = data.get('name', '').strip()
            amount = int(data.get('amount', 0))
            price = float(data.get('price', 0))
            operator = data.get('operator', '').strip()
            is_active = int(data.get('is_active', 1))

            if amount <= 0:
                return jsonify({'message': 'مقدار شارژ باید بزرگتر از صفر باشد'}), 400
            if price <= 0:
                return jsonify({'message': 'قیمت باید بزرگتر از صفر باشد'}), 400

            insert_query = '''
                INSERT INTO credits_iran (name, amount, price, operator, is_active)
                VALUES (%s, %s, %s, %s, %s)
            '''
            cursor.execute(
                insert_query,
                (name, amount, price, operator, is_active)
            )
            connection.commit()

            credit_id = cursor.lastrowid

            return jsonify({
                'message': 'کریدیت با موفقیت اضافه شد',
                'credit_id': credit_id
            }), 201

        # ============================================
        # 📌 PUT - ویرایش کریدیت
        # ============================================
        elif request.method == 'PUT':
            data = request.get_json(silent=True) or {}
            credit_id = data.get('id')

            if not credit_id:
                return jsonify({'message': 'شناسه کریدیت الزامی است'}), 400

            cursor.execute("SELECT * FROM credits_iran WHERE id = %s", (credit_id,))
            existing = cursor.fetchone()

            if not existing:
                return jsonify({'message': 'کریدیت یافت نشد'}), 404

            update_fields = []
            params = []

            if data.get('name'):
                update_fields.append("name = %s")
                params.append(data['name'].strip())

            if data.get('amount') is not None:
                amount = int(data['amount'])
                if amount <= 0:
                    return jsonify({'message': 'مقدار شارژ باید بزرگتر از صفر باشد'}), 400
                update_fields.append("amount = %s")
                params.append(amount)

            if data.get('price') is not None:
                try:
                    price = float(data['price'])
                    if price < 0:
                        return jsonify({'message': 'قیمت نمی‌تواند منفی باشد'}), 400
                    update_fields.append("price = %s")
                    params.append(price)
                except:
                    return jsonify({'message': 'قیمت نامعتبر است'}), 400

            if data.get('operator') is not None:
                update_fields.append("operator = %s")
                params.append(data['operator'].strip())

            if data.get('is_active') is not None:
                update_fields.append("is_active = %s")
                params.append(1 if bool(data['is_active']) else 0)

            if not update_fields:
                return jsonify({'message': 'هیچ فیلدی برای ویرایش ارسال نشده است'}), 400

            params.append(credit_id)
            update_query = f"UPDATE credits_iran SET {', '.join(update_fields)} WHERE id = %s"
            cursor.execute(update_query, params)
            connection.commit()

            return jsonify({'message': 'کریدیت با موفقیت ویرایش شد'}), 200

        # ============================================
        # 📌 DELETE - حذف کریدیت
        # ============================================
        elif request.method == 'DELETE':
            data = request.get_json(silent=True) or {}
            credit_id = data.get('id') or request.args.get('id')

            if not credit_id:
                return jsonify({'message': 'شناسه کریدیت الزامی است'}), 400

            cursor.execute("SELECT * FROM credits_iran WHERE id = %s", (credit_id,))
            existing = cursor.fetchone()

            if not existing:
                return jsonify({'message': 'کریدیت یافت نشد'}), 404

            cursor.execute("DELETE FROM credits_iran WHERE id = %s", (credit_id,))
            connection.commit()

            return jsonify({'message': 'کریدیت با موفقیت حذف شد'}), 200

        else:
            return jsonify({'message': 'متد غیرمجاز'}), 405

    except Exception as e:
        print(f"❌ خطا در admin_credit_iran: {str(e)}")
        return jsonify({'message': f'خطا: {str(e)}'}), 500
    finally:
        if 'cursor' in locals() and cursor:
            try:
                cursor.close()
            except:
                pass
        if 'connection' in locals() and connection:
            try:
                connection.close()
            except:
                pass


# ============================================
# 📌 دریافت کریدیت‌های ایران (برای کاربران)
# ============================================
@app.route('/api/credits/iran', methods=['GET'])
def get_credits_iran():
    """
    دریافت همه کریدیت‌های فعال ایران
    Query Parameters: operator (اختیاری)
    """
    try:
        connection = get_db_connection()
        if not connection:
            return jsonify({'message': 'اتصال به پایگاه‌داده ناموفق بود'}), 500

        cursor = connection.cursor(dictionary=True)

        operator = request.args.get('operator', '').strip()

        query = """
            SELECT id, name, amount, price, operator, is_active
            FROM credits_iran
            WHERE is_active = 1
        """
        params = []

        if operator:
            query += " AND operator = %s"
            params.append(operator)

        query += " ORDER BY amount ASC"

        cursor.execute(query, params)
        credits = cursor.fetchall() or []

        for credit in credits:
            if isinstance(credit.get('price'), Decimal):
                credit['price'] = float(credit['price'])

        return jsonify({
            'success': True,
            'credits': credits,
            'count': len(credits)
        }), 200

    except Exception as e:
        return jsonify({'message': f'خطا: {str(e)}'}), 500
    finally:
        if 'cursor' in locals() and cursor:
            try:
                cursor.close()
            except:
                pass
        if 'connection' in locals() and connection:
            try:
                connection.close()
            except:
                pass
# ============================================
# 📌 ثبت سفارش کریدیت ایران
# ============================================
@app.route('/api/orders/create_credit_iran', methods=['POST'])
@token_required
def create_credit_iran_order(current_user):
    try:
        data = request.get_json()

        if not data.get('phone_number') or not data.get('operator') or not data.get('amount') or not data.get('price'):
            return jsonify({'message': 'اطلاعات کامل نیست'}), 400

        phone_number = data.get('phone_number')
        operator = data.get('operator')
        amount = int(data.get('amount', 0))
        price = float(data.get('price', 0))
        price_per_unit = float(data.get('price_per_unit', 0))

        if amount <= 0:
            return jsonify({'message': 'مقدار شارژ نامعتبر است'}), 400
        if price <= 0:
            return jsonify({'message': 'قیمت نامعتبر است'}), 400

        connection = get_db_connection()
        if not connection:
            return jsonify({'message': 'اتصال به پایگاه‌داده ناموفق بود'}), 500

        cursor = connection.cursor(dictionary=True)

        # ✅ 1. دریافت اطلاعات کاربر
        cursor.execute(
            "SELECT id, first_name, last_name, balance FROM users WHERE id = %s",
            (current_user,)
        )
        user = cursor.fetchone()

        if not user:
            return jsonify({'message': 'کاربر یافت نشد'}), 404

        user_name = f"{user.get('first_name', '')} {user.get('last_name', '')}".strip()
        if not user_name:
            user_name = 'کاربر'

        current_balance = float(user.get('balance', 0))

        # ✅ 2. بررسی موجودی
        if current_balance < price:
            return jsonify({
                'success': False,
                'message': f'موجودی کافی نیست! موجودی شما: {current_balance:,.0f} تومان',
                'balance': current_balance
            }), 400

        # ✅ 3. ایجاد سفارش کریدیت ایران
        # ✅ اصلاح شده: "10 تومان شارژ ایرانسل"
        package_name = f"{amount} تومان شارژ {operator}"

        insert_query = '''
            INSERT INTO orders (
                user_id,
                product_id,
                package_name,
                price,
                phone_number,
                operator,
                user_name,
                credit_amount,
                price_per_unit
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
        '''
        cursor.execute(insert_query, (
            current_user,
            None,
            package_name,
            price,
            phone_number,
            operator,
            user_name,
            amount,
            price_per_unit
        ))
        order_id = cursor.lastrowid

        # ✅ 4. کم کردن از موجودی
        new_balance = current_balance - price
        cursor.execute(
            "UPDATE users SET balance = %s WHERE id = %s",
            (new_balance, current_user)
        )

        connection.commit()

        return jsonify({
            'success': True,
            'message': 'سفارش کریدیت ایران با موفقیت ثبت شد',
            'order_id': order_id,
            'new_balance': new_balance,
            'deducted_amount': price,
            'amount': amount,
            'price_per_unit': price_per_unit
        }), 201

    except Exception as e:
        return jsonify({'message': f'خطا: {str(e)}'}), 500
    finally:
        if 'cursor' in locals() and cursor:
            try:
                cursor.close()
            except:
                pass
        if 'connection' in locals() and connection:
            try:
                connection.close()
            except:
                pass
#=====================================================
# ============================================
# 📌 مسیر ادمین برای مدیریت کریدیت ترکیه
# ============================================
@app.route('/admin_credit_turkey', methods=['GET', 'POST', 'PUT', 'DELETE'])
def admin_credit_turkey():
    # ============================================
    # 🔒 بررسی لاگین بودن ادمین
    # ============================================
    if not session.get('admin_logged_in'):
        return redirect(url_for('admin_login'))

    try:
        connection = get_db_connection()
        if not connection:
            return jsonify({'message': 'اتصال به پایگاه‌داده ناموفق بود'}), 500

        cursor = connection.cursor(dictionary=True)

        # ============================================
        # 📌 ایجاد جدول credits_turkey (اگر وجود نداشته باشد)
        # ============================================
        try:
            cursor.execute(
                "SELECT COUNT(*) AS cnt FROM information_schema.TABLES "
                "WHERE TABLE_SCHEMA = %s AND TABLE_NAME = %s",
                (MYSQL_DB, 'credits_turkey')
            )
            table_exists = cursor.fetchone()

            if not table_exists or int(table_exists.get('cnt', 0)) == 0:
                cursor.execute('''
                    CREATE TABLE credits_turkey (
                        id INT AUTO_INCREMENT PRIMARY KEY,
                        name VARCHAR(255) NOT NULL,
                        amount INT NOT NULL,
                        price DECIMAL(30,2) NOT NULL DEFAULT 0,
                        operator VARCHAR(50),
                        is_active TINYINT(1) DEFAULT 1,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
                    )
                ''')
                connection.commit()
                print("✅ جدول credits_turkey ایجاد شد")

        except Exception as e:
            print(f"⚠️ خطا در ایجاد/بررسی جدول credits_turkey: {str(e)}")
            pass

        # ============================================
        # 📌 GET - دریافت کریدیت‌ها
        # ============================================
        if request.method == 'GET':
            user_agent = request.headers.get('User-Agent', '')
            is_browser = 'Mozilla' in user_agent or 'Chrome' in user_agent or 'Safari' in user_agent
            is_api_request = request.headers.get('X-Requested-With') == 'XMLHttpRequest'

            if is_browser and not is_api_request and not request.args.get('id'):
                try:
                    cursor.execute("SELECT * FROM credits_turkey ORDER BY id DESC")
                    credits = cursor.fetchall() or []

                    for credit in credits:
                        if isinstance(credit.get('price'), Decimal):
                            credit['price'] = float(credit['price'])

                    return render_template('admin_credit_turkey.html', credits=credits)
                except Exception as e:
                    return jsonify({'message': f'خطا: {str(e)}'}), 500

            credit_id = request.args.get('id')

            if credit_id:
                cursor.execute("SELECT * FROM credits_turkey WHERE id = %s", (credit_id,))
                credit = cursor.fetchone()

                if not credit:
                    return jsonify({'message': 'کریدیت یافت نشد'}), 404

                if isinstance(credit.get('price'), Decimal):
                    credit['price'] = float(credit['price'])

                return jsonify({'credit': credit}), 200

            else:
                cursor.execute("SELECT * FROM credits_turkey ORDER BY id DESC")
                credits = cursor.fetchall() or []

                for credit in credits:
                    if isinstance(credit.get('price'), Decimal):
                        credit['price'] = float(credit['price'])

                return jsonify({
                    'credits': credits,
                    'count': len(credits)
                }), 200

        # ============================================
        # 📌 POST - اضافه کردن کریدیت
        # ============================================
        elif request.method == 'POST':
            data = request.get_json(silent=True) or {}

            if not data.get('name') or data.get('amount') is None or data.get('price') is None:
                return jsonify({'message': 'نام، مقدار و قیمت کریدیت الزامی است'}), 400

            name = data.get('name', '').strip()
            amount = int(data.get('amount', 0))
            price = float(data.get('price', 0))
            operator = data.get('operator', '').strip()
            is_active = int(data.get('is_active', 1))

            if amount <= 0:
                return jsonify({'message': 'مقدار شارژ باید بزرگتر از صفر باشد'}), 400
            if price <= 0:
                return jsonify({'message': 'قیمت باید بزرگتر از صفر باشد'}), 400

            insert_query = '''
                INSERT INTO credits_turkey (name, amount, price, operator, is_active)
                VALUES (%s, %s, %s, %s, %s)
            '''
            cursor.execute(
                insert_query,
                (name, amount, price, operator, is_active)
            )
            connection.commit()

            credit_id = cursor.lastrowid

            return jsonify({
                'message': 'کریدیت با موفقیت اضافه شد',
                'credit_id': credit_id
            }), 201

        # ============================================
        # 📌 PUT - ویرایش کریدیت
        # ============================================
        elif request.method == 'PUT':
            data = request.get_json(silent=True) or {}
            credit_id = data.get('id')

            if not credit_id:
                return jsonify({'message': 'شناسه کریدیت الزامی است'}), 400

            cursor.execute("SELECT * FROM credits_turkey WHERE id = %s", (credit_id,))
            existing = cursor.fetchone()

            if not existing:
                return jsonify({'message': 'کریدیت یافت نشد'}), 404

            update_fields = []
            params = []

            if data.get('name'):
                update_fields.append("name = %s")
                params.append(data['name'].strip())

            if data.get('amount') is not None:
                amount = int(data['amount'])
                if amount <= 0:
                    return jsonify({'message': 'مقدار شارژ باید بزرگتر از صفر باشد'}), 400
                update_fields.append("amount = %s")
                params.append(amount)

            if data.get('price') is not None:
                try:
                    price = float(data['price'])
                    if price < 0:
                        return jsonify({'message': 'قیمت نمی‌تواند منفی باشد'}), 400
                    update_fields.append("price = %s")
                    params.append(price)
                except:
                    return jsonify({'message': 'قیمت نامعتبر است'}), 400

            if data.get('operator') is not None:
                update_fields.append("operator = %s")
                params.append(data['operator'].strip())

            if data.get('is_active') is not None:
                update_fields.append("is_active = %s")
                params.append(1 if bool(data['is_active']) else 0)

            if not update_fields:
                return jsonify({'message': 'هیچ فیلدی برای ویرایش ارسال نشده است'}), 400

            params.append(credit_id)
            update_query = f"UPDATE credits_turkey SET {', '.join(update_fields)} WHERE id = %s"
            cursor.execute(update_query, params)
            connection.commit()

            return jsonify({'message': 'کریدیت با موفقیت ویرایش شد'}), 200

        # ============================================
        # 📌 DELETE - حذف کریدیت
        # ============================================
        elif request.method == 'DELETE':
            data = request.get_json(silent=True) or {}
            credit_id = data.get('id') or request.args.get('id')

            if not credit_id:
                return jsonify({'message': 'شناسه کریدیت الزامی است'}), 400

            cursor.execute("SELECT * FROM credits_turkey WHERE id = %s", (credit_id,))
            existing = cursor.fetchone()

            if not existing:
                return jsonify({'message': 'کریدیت یافت نشد'}), 404

            cursor.execute("DELETE FROM credits_turkey WHERE id = %s", (credit_id,))
            connection.commit()

            return jsonify({'message': 'کریدیت با موفقیت حذف شد'}), 200

        else:
            return jsonify({'message': 'متد غیرمجاز'}), 405

    except Exception as e:
        print(f"❌ خطا در admin_credit_turkey: {str(e)}")
        return jsonify({'message': f'خطا: {str(e)}'}), 500
    finally:
        if 'cursor' in locals() and cursor:
            try:
                cursor.close()
            except:
                pass
        if 'connection' in locals() and connection:
            try:
                connection.close()
            except:
                pass


# ============================================
# 📌 دریافت کریدیت‌های ترکیه (برای کاربران)
# ============================================
@app.route('/api/credits/turkey', methods=['GET'])
def get_credits_turkey():
    """
    دریافت همه کریدیت‌های فعال ترکیه
    Query Parameters: operator (اختیاری)
    """
    try:
        connection = get_db_connection()
        if not connection:
            return jsonify({'message': 'اتصال به پایگاه‌داده ناموفق بود'}), 500

        cursor = connection.cursor(dictionary=True)

        operator = request.args.get('operator', '').strip()

        query = """
            SELECT id, name, amount, price, operator, is_active
            FROM credits_turkey
            WHERE is_active = 1
        """
        params = []

        if operator:
            query += " AND operator = %s"
            params.append(operator)

        query += " ORDER BY amount ASC"

        cursor.execute(query, params)
        credits = cursor.fetchall() or []

        for credit in credits:
            if isinstance(credit.get('price'), Decimal):
                credit['price'] = float(credit['price'])

        return jsonify({
            'success': True,
            'credits': credits,
            'count': len(credits)
        }), 200

    except Exception as e:
        return jsonify({'message': f'خطا: {str(e)}'}), 500
    finally:
        if 'cursor' in locals() and cursor:
            try:
                cursor.close()
            except:
                pass
        if 'connection' in locals() and connection:
            try:
                connection.close()
            except:
                pass


# ============================================
# 📌 ثبت سفارش کریدیت ترکیه
# ============================================
@app.route('/api/orders/create_credit_turkey', methods=['POST'])
@token_required
def create_credit_turkey_order(current_user):
    try:
        data = request.get_json()

        if not data.get('phone_number') or not data.get('operator') or not data.get('amount') or not data.get('price'):
            return jsonify({'message': 'اطلاعات کامل نیست'}), 400

        phone_number = data.get('phone_number')
        operator = data.get('operator')
        amount = int(data.get('amount', 0))
        price = float(data.get('price', 0))
        price_per_unit = float(data.get('price_per_unit', 0))

        if amount <= 0:
            return jsonify({'message': 'مقدار شارژ نامعتبر است'}), 400
        if price <= 0:
            return jsonify({'message': 'قیمت نامعتبر است'}), 400

        connection = get_db_connection()
        if not connection:
            return jsonify({'message': 'اتصال به پایگاه‌داده ناموفق بود'}), 500

        cursor = connection.cursor(dictionary=True)

        # ✅ 1. دریافت اطلاعات کاربر
        cursor.execute(
            "SELECT id, first_name, last_name, balance FROM users WHERE id = %s",
            (current_user,)
        )
        user = cursor.fetchone()

        if not user:
            return jsonify({'message': 'کاربر یافت نشد'}), 404

        user_name = f"{user.get('first_name', '')} {user.get('last_name', '')}".strip()
        if not user_name:
            user_name = 'کاربر'

        current_balance = float(user.get('balance', 0))

        # ✅ 2. بررسی موجودی
        if current_balance < price:
            return jsonify({
                'success': False,
                'message': f'موجودی کافی نیست! موجودی شما: {current_balance:,.0f} تومان',
                'balance': current_balance
            }), 400

        # ✅ 3. ایجاد سفارش کریدیت ترکیه
        package_name = f"{amount} لیر شارژ {operator}"

        insert_query = '''
            INSERT INTO orders (
                user_id,
                product_id,
                package_name,
                price,
                phone_number,
                operator,
                user_name,
                credit_amount,
                price_per_unit
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
        '''
        cursor.execute(insert_query, (
            current_user,
            None,
            package_name,
            price,
            phone_number,
            operator,
            user_name,
            amount,
            price_per_unit
        ))
        order_id = cursor.lastrowid

        # ✅ 4. کم کردن از موجودی
        new_balance = current_balance - price
        cursor.execute(
            "UPDATE users SET balance = %s WHERE id = %s",
            (new_balance, current_user)
        )

        connection.commit()

        return jsonify({
            'success': True,
            'message': 'سفارش کریدیت ترکیه با موفقیت ثبت شد',
            'order_id': order_id,
            'new_balance': new_balance,
            'deducted_amount': price,
            'amount': amount,
            'price_per_unit': price_per_unit
        }), 201

    except Exception as e:
        return jsonify({'message': f'خطا: {str(e)}'}), 500
    finally:
        if 'cursor' in locals() and cursor:
            try:
                cursor.close()
            except:
                pass
        if 'connection' in locals() and connection:
            try:
                connection.close()
            except:
                pass
#======================================================
@app.route('/api/verify_pin', methods=['POST'])
@token_required
def verify_pin(current_user):
    try:
        data = request.get_json()
        pin_code = data.get('pin_code', '').strip()

        if not pin_code or len(pin_code) != 4:
            return jsonify({
                'success': False,
                'message': 'کد امنیتی باید ۴ رقم باشد'
            }), 400

        if not pin_code.isdigit():
            return jsonify({
                'success': False,
                'message': 'کد امنیتی باید فقط شامل اعداد باشد'
            }), 400

        connection = get_db_connection()
        if not connection:
            return jsonify({'message': 'اتصال به پایگاه‌داده ناموفق بود'}), 500

        cursor = connection.cursor(dictionary=True)
        cursor.execute("SELECT pin_code_hash FROM users WHERE id = %s", (current_user,))
        user = cursor.fetchone()

        if not user:
            return jsonify({'success': False, 'message': 'کاربر یافت نشد'}), 404

        stored_hash = user['pin_code_hash']
        if isinstance(stored_hash, bytes):
            stored_hash = stored_hash.decode('utf-8')

        if bcrypt.checkpw(pin_code.encode('utf-8'), stored_hash.encode('utf-8')):
            return jsonify({'success': True, 'message': 'کد امنیتی صحیح است'}), 200
        else:
            return jsonify({'success': False, 'message': 'کد امنیتی اشتباه است'}), 400

    except Exception as e:
        return jsonify({'success': False, 'message': f'خطا: {str(e)}'}), 500
    finally:
        if 'cursor' in locals() and cursor:
            try:
                cursor.close()
            except:
                pass
        if 'connection' in locals() and connection:
            try:
                connection.close()
            except:
                pass
# ============================================
# 📌 مسیر ادمین برای مدیریت محصولات بازی
# ============================================
@app.route('/admin_product_games', methods=['GET', 'POST', 'PUT', 'DELETE'])
def admin_product_games():
    # ============================================
    # 🔒 بررسی لاگین بودن ادمین
    # ============================================
    if not session.get('admin_logged_in'):
        return redirect(url_for('admin_login'))

    try:
        connection = get_db_connection()
        if not connection:
            return jsonify({'message': 'اتصال به پایگاه‌داده ناموفق بود'}), 500

        cursor = connection.cursor(dictionary=True)

        # ============================================
        # 📌 ایجاد جدول products_games (اگر وجود نداشته باشد)
        # ============================================
        try:
            cursor.execute(
                "SELECT COUNT(*) AS cnt FROM information_schema.TABLES "
                "WHERE TABLE_SCHEMA = %s AND TABLE_NAME = %s",
                (MYSQL_DB, 'products_games')
            )
            table_exists = cursor.fetchone()

            if not table_exists or int(table_exists.get('cnt', 0)) == 0:
                cursor.execute('''
                    CREATE TABLE products_games (
                        id INT AUTO_INCREMENT PRIMARY KEY,
                        name VARCHAR(255) NOT NULL,
                        description TEXT,
                        price DECIMAL(30,2) NOT NULL DEFAULT 0,
                        category VARCHAR(50),
                        is_active TINYINT(1) DEFAULT 1,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
                    )
                ''')
                connection.commit()
                print("✅ جدول products_games ایجاد شد")

        except Exception as e:
            print(f"⚠️ خطا در ایجاد/بررسی جدول products_games: {str(e)}")
            pass

        # ============================================
        # 📌 GET - دریافت محصولات
        # ============================================
        if request.method == 'GET':
            user_agent = request.headers.get('User-Agent', '')
            is_browser = 'Mozilla' in user_agent or 'Chrome' in user_agent or 'Safari' in user_agent
            is_api_request = request.headers.get('X-Requested-With') == 'XMLHttpRequest'
            category_filter = request.args.get('category', '')

            if is_browser and not is_api_request and not request.args.get('id'):
                try:
                    query = "SELECT * FROM products_games"
                    params = []
                    if category_filter:
                        query += " WHERE category = %s"
                        params.append(category_filter)
                    query += " ORDER BY id DESC"

                    cursor.execute(query, params)
                    products = cursor.fetchall() or []

                    for product in products:
                        if isinstance(product.get('price'), Decimal):
                            product['price'] = float(product['price'])

                    return render_template('admin_product_games.html', products=products)
                except Exception as e:
                    return jsonify({'message': f'خطا: {str(e)}'}), 500

            product_id = request.args.get('id')

            if product_id:
                cursor.execute("SELECT * FROM products_games WHERE id = %s", (product_id,))
                product = cursor.fetchone()

                if not product:
                    return jsonify({'message': 'محصول یافت نشد'}), 404

                if isinstance(product.get('price'), Decimal):
                    product['price'] = float(product['price'])

                return jsonify({'product': product}), 200

            else:
                query = "SELECT * FROM products_games"
                params = []
                if category_filter:
                    query += " WHERE category = %s"
                    params.append(category_filter)
                query += " ORDER BY id DESC"

                cursor.execute(query, params)
                products = cursor.fetchall() or []

                for product in products:
                    if isinstance(product.get('price'), Decimal):
                        product['price'] = float(product['price'])

                return jsonify({
                    'products': products,
                    'count': len(products)
                }), 200

        # ============================================
        # 📌 POST - اضافه کردن محصول
        # ============================================
        elif request.method == 'POST':
            data = request.get_json(silent=True) or {}

            if not data.get('name') or data.get('price') is None or not data.get('category'):
                return jsonify({'message': 'نام، قیمت و دسته‌بندی محصول الزامی است'}), 400

            name = data.get('name', '').strip()
            description = data.get('description', '').strip()
            price = float(data.get('price', 0))
            category = data.get('category', '').strip()
            is_active = int(data.get('is_active', 1))

            if price < 0:
                return jsonify({'message': 'قیمت نمی‌تواند منفی باشد'}), 400

            insert_query = '''
                INSERT INTO products_games (name, description, price, category, is_active)
                VALUES (%s, %s, %s, %s, %s)
            '''
            cursor.execute(
                insert_query,
                (name, description, price, category, is_active)
            )
            connection.commit()

            product_id = cursor.lastrowid

            return jsonify({
                'message': 'محصول با موفقیت اضافه شد',
                'product_id': product_id
            }), 201

        # ============================================
        # 📌 PUT - ویرایش محصول
        # ============================================
        elif request.method == 'PUT':
            data = request.get_json(silent=True) or {}
            product_id = data.get('id')

            if not product_id:
                return jsonify({'message': 'شناسه محصول الزامی است'}), 400

            cursor.execute("SELECT * FROM products_games WHERE id = %s", (product_id,))
            existing = cursor.fetchone()

            if not existing:
                return jsonify({'message': 'محصول یافت نشد'}), 404

            update_fields = []
            params = []

            if data.get('name'):
                update_fields.append("name = %s")
                params.append(data['name'].strip())

            if data.get('description') is not None:
                update_fields.append("description = %s")
                params.append(data['description'].strip())

            if data.get('price') is not None:
                try:
                    price = float(data['price'])
                    if price < 0:
                        return jsonify({'message': 'قیمت نمی‌تواند منفی باشد'}), 400
                    update_fields.append("price = %s")
                    params.append(price)
                except:
                    return jsonify({'message': 'قیمت نامعتبر است'}), 400

            if data.get('category') is not None:
                update_fields.append("category = %s")
                params.append(data['category'].strip())

            if data.get('is_active') is not None:
                update_fields.append("is_active = %s")
                params.append(1 if bool(data['is_active']) else 0)

            if not update_fields:
                return jsonify({'message': 'هیچ فیلدی برای ویرایش ارسال نشده است'}), 400

            params.append(product_id)
            update_query = f"UPDATE products_games SET {', '.join(update_fields)} WHERE id = %s"
            cursor.execute(update_query, params)
            connection.commit()

            return jsonify({'message': 'محصول با موفقیت ویرایش شد'}), 200

        # ============================================
        # 📌 DELETE - حذف محصول
        # ============================================
        elif request.method == 'DELETE':
            data = request.get_json(silent=True) or {}
            product_id = data.get('id') or request.args.get('id')

            if not product_id:
                return jsonify({'message': 'شناسه محصول الزامی است'}), 400

            cursor.execute("SELECT * FROM products_games WHERE id = %s", (product_id,))
            existing = cursor.fetchone()

            if not existing:
                return jsonify({'message': 'محصول یافت نشد'}), 404

            cursor.execute("DELETE FROM products_games WHERE id = %s", (product_id,))
            connection.commit()

            return jsonify({'message': 'محصول با موفقیت حذف شد'}), 200

        else:
            return jsonify({'message': 'متد غیرمجاز'}), 405

    except Exception as e:
        print(f"❌ خطا در admin_product_games: {str(e)}")
        return jsonify({'message': f'خطا: {str(e)}'}), 500
    finally:
        if 'cursor' in locals() and cursor:
            try:
                cursor.close()
            except:
                pass
        if 'connection' in locals() and connection:
            try:
                connection.close()
            except:
                pass


# ============================================
# 📌 دریافت محصولات بازی (برای کاربران)
# ============================================
@app.route('/api/products/games', methods=['GET'])
def get_products_games():
    """
    دریافت محصولات بازی
    Query Parameters: category (imo, likee, pubg)
    """
    try:
        connection = get_db_connection()
        if not connection:
            return jsonify({'message': 'اتصال به پایگاه‌داده ناموفق بود'}), 500

        cursor = connection.cursor(dictionary=True)

        category = request.args.get('category', '').strip()

        query = """
            SELECT id, name, description, price, category, is_active
            FROM products_games
            WHERE is_active = 1
        """
        params = []

        if category:
            query += " AND category = %s"
            params.append(category)

        query += " ORDER BY price ASC"

        cursor.execute(query, params)
        products = cursor.fetchall() or []

        for product in products:
            if isinstance(product.get('price'), Decimal):
                product['price'] = float(product['price'])

        return jsonify({
            'success': True,
            'products': products,
            'count': len(products)
        }), 200

    except Exception as e:
        return jsonify({'message': f'خطا: {str(e)}'}), 500
    finally:
        if 'cursor' in locals() and cursor:
            try:
                cursor.close()
            except:
                pass
        if 'connection' in locals() and connection:
            try:
                connection.close()
            except:
                pass
# ============================================
# 📌 ثبت سفارش یوسی پابجی
# ========================================
# ============================================
# 📌 ثبت سفارش یوسی پابجی (بدون amount)
# ============================================
@app.route('/api/orders/create_pubg_credit', methods=['POST'])
@token_required
def create_pubg_credit_order(current_user):
    try:
        data = request.get_json(force=True, silent=True)

        if not data:
            data = request.form.to_dict()

        if not data:
            return jsonify({
                'success': False,
                'message': 'داده‌ای ارسال نشده است'
            }), 400

        print(f"📥 داده دریافتی: {data}")

        # ============================================
        # ✅ دریافت اطلاعات
        # ============================================
        pubg_id = str(data.get('pubg_id', '')).strip()
        package_name = str(data.get('package_name', '')).strip()

        try:
            price = float(data.get('price', 0))
        except (ValueError, TypeError):
            price = 0

        # ============================================
        # ✅ اعتبارسنجی - فقط pubg_id و price
        # ============================================
        if not pubg_id or len(pubg_id) < 4:
            return jsonify({
                'success': False,
                'message': 'ایدی پابجی نامعتبر است (حداقل ۴ کاراکتر)'
            }), 400

        if price <= 0:
            return jsonify({
                'success': False,
                'message': 'قیمت نامعتبر است'
            }), 400

        if not package_name:
            return jsonify({
                'success': False,
                'message': 'نام بسته ارسال نشده است'
            }), 400

        connection = get_db_connection()
        if not connection:
            return jsonify({
                'success': False,
                'message': 'اتصال به پایگاه‌داده ناموفق بود'
            }), 500

        cursor = connection.cursor(dictionary=True)

        # ✅ 1. دریافت اطلاعات کاربر
        cursor.execute(
            "SELECT id, first_name, last_name, balance FROM users WHERE id = %s",
            (current_user,)
        )
        user = cursor.fetchone()

        if not user:
            return jsonify({
                'success': False,
                'message': 'کاربر یافت نشد'
            }), 404

        user_name = f"{user.get('first_name', '')} {user.get('last_name', '')}".strip()
        if not user_name:
            user_name = 'کاربر'

        current_balance = float(user.get('balance', 0))

        # ✅ 2. بررسی موجودی کافی
        if current_balance < price:
            return jsonify({
                'success': False,
                'message': f'موجودی کافی نیست! موجودی شما: {current_balance:,.0f} تومان',
                'balance': current_balance
            }), 400

        # ✅ 3. ایجاد سفارش (بدون amount و credit_amount)
        description = f"خرید یوسی پابجی برای ایدی {pubg_id}"

        insert_query = '''
            INSERT INTO orders (
                user_id,
                package_name,
                description,
                price,
                phone_number,
                operator,
                user_name,
                pubg_id
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        '''
        cursor.execute(insert_query, (
            current_user,
            package_name,
            description,
            price,
            pubg_id,
            'پابجی',
            user_name,
            pubg_id
        ))
        order_id = cursor.lastrowid

        # ✅ 4. کم کردن از موجودی کاربر
        new_balance = current_balance - price
        cursor.execute(
            "UPDATE users SET balance = %s WHERE id = %s",
            (new_balance, current_user)
        )

        connection.commit()

        return jsonify({
            'success': True,
            'message': 'سفارش یوسی پابجی با موفقیت ثبت شد',
            'order_id': order_id,
            'new_balance': new_balance,
            'deducted_amount': price
        }), 201

    except Exception as e:
        print(f"❌ خطا در create_pubg_credit_order: {str(e)}")
        return jsonify({
            'success': False,
            'message': f'خطا: {str(e)}'
        }), 500
    finally:
        if 'cursor' in locals() and cursor:
            try:
                cursor.close()
            except:
                pass
        if 'connection' in locals() and connection:
            try:
                connection.close()
            except:
                pass
#=====================================================================
def to_dt(x):
    if isinstance(x, datetime):
        return x
    try:
        return datetime.strptime(str(x), "%Y-%m-%d %H:%M:%S")
    except:
        try:
            return datetime.fromisoformat(str(x))
        except:
            return None


def fmt_tz(dt, zone):
    if not dt:
        return ""
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=ZoneInfo("UTC"))
    return dt.astimezone(ZoneInfo(zone)).strftime("%Y-%m-%d %H:%M")






