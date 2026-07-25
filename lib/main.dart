import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'api_config.dart';
import 'login.dart';
import 'screens/setting_page.dart';
import 'widgets/image_slideshow.dart';
import 'product/bazar.dart';
import 'order/order.dart';

const Color brandColor = Color(0xFF0E8A4D);
const Color brandSeed = Color(0xFF38C172);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MyApp',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: brandColor,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: brandColor,
          elevation: 0,
          centerTitle: false,
        ),
        bottomAppBarTheme: const BottomAppBarThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: brandColor,
            foregroundColor: Colors.white,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: brandColor,
            side: const BorderSide(color: brandColor),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: brandColor.withOpacity(0.25)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: brandColor.withOpacity(0.25)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: brandColor, width: 1.4),
          ),
        ),
        useMaterial3: true,
        fontFamily: 'Vazir',
      ),
      home: const LoginPage(),
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
    );
  }
}

class AppStorage {
  final _storage = const FlutterSecureStorage();
  Future<void> write(String key, String value) async =>
      await _storage.write(key: key, value: value);
  Future<String?> read(String key) async => await _storage.read(key: key);
  Future<void> delete(String key) async => await _storage.delete(key: key);
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _pinController = TextEditingController();
  Uint8List? _tazkiraImageBytes;
  Uint8List? _profileImageBytes;
  String? _tazkiraImageName;
  String? _profileImageName;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _obscurePin = true;

  Future<void> _pickImage({required bool isTazkira}) async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }
    final file = result.files.single;
    if (file.bytes == null) {
      _showErrorDialog('خواندن فایل انتخاب‌شده ممکن نیست');
      return;
    }
    setState(() {
      if (isTazkira) {
        _tazkiraImageBytes = file.bytes;
        _tazkiraImageName = file.name;
      } else {
        _profileImageBytes = file.bytes;
        _profileImageName = file.name;
      }
    });
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_tazkiraImageBytes == null || _profileImageBytes == null) {
      _showErrorDialog('لطفاً عکس تذکره و عکس پروفایل را انتخاب کنید');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(api('/api/register')),
      );
      request.fields.addAll({
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'phone_number': _phoneController.text.trim().replaceAll(
          RegExp(r'[\s-]'),
          '',
        ),
        'password': _passwordController.text.trim(),
        'pin_code': _pinController.text.trim(),
      });
      request.files.add(
        http.MultipartFile.fromBytes(
          'tazkira_image',
          _tazkiraImageBytes!,
          filename: _tazkiraImageName ?? 'tazkira.jpg',
        ),
      );
      request.files.add(
        http.MultipartFile.fromBytes(
          'profile_image',
          _profileImageBytes!,
          filename: _profileImageName ?? 'profile.jpg',
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 201) {
        _showSuccessDialog('ثبت‌نام با موفقیت انجام شد. لطفاً وارد شوید.');
      } else {
        final error = json.decode(response.body);
        _showErrorDialog(error['message'] ?? 'ثبت‌نام ناموفق بود');
      }
    } catch (e) {
      _showErrorDialog('خطای اتصال: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _imagePickerTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? brandColor
                : theme.colorScheme.primary.withOpacity(0.18),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: brandColor.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: brandColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.upload_file,
              color: selected ? Colors.green : brandColor,
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('موفق'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('باشه'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('خطا'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('باشه'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('ثبت‌نام'),
        backgroundColor: brandColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    brandColor.withOpacity(0.18),
                    theme.colorScheme.primary.withOpacity(0.06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(painter: DashboardPainter(color: brandColor)),
          ),
          Center(
            child: Card(
              elevation: 6,
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: brandColor.withOpacity(0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const Text(
                            'ایجاد حساب کاربری',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _firstNameController,
                            decoration: const InputDecoration(
                              labelText: 'نام',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'لطفاً نام را وارد کنید';
                              }
                              if (value.length < 2) {
                                return 'نام باید حداقل ۲ کاراکتر باشد';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _lastNameController,
                            decoration: const InputDecoration(
                              labelText: 'نام خانوادگی',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'لطفاً نام خانوادگی را وارد کنید';
                              }
                              if (value.length < 2) {
                                return 'نام خانوادگی باید حداقل ۲ کاراکتر باشد';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                              labelText: 'شماره موبایل',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.phone),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'لطفاً شماره موبایل را وارد کنید';
                              }
                              final v = value.replaceAll(RegExp(r'[\s-]'), '');
                              if (!RegExp(r'^\+?\d{10,15}$').hasMatch(v)) {
                                return 'شماره موبایل معتبر نیست';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _imagePickerTile(
                            title: 'عکس تذکره',
                            subtitle: _tazkiraImageName ?? 'فایل انتخاب نشده',
                            icon: Icons.badge_outlined,
                            selected: _tazkiraImageBytes != null,
                            onTap: () => _pickImage(isTazkira: true),
                          ),
                          const SizedBox(height: 12),
                          _imagePickerTile(
                            title: 'عکس پروفایل',
                            subtitle: _profileImageName ?? 'فایل انتخاب نشده',
                            icon: Icons.account_circle_outlined,
                            selected: _profileImageBytes != null,
                            onTap: () => _pickImage(isTazkira: false),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'رمز عبور',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                            obscureText: _obscurePassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'لطفاً رمز عبور را وارد کنید';
                              }
                              if (value.length < 6) {
                                return 'رمز عبور باید حداقل ۶ کاراکتر باشد';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmPasswordController,
                            decoration: InputDecoration(
                              labelText: 'تکرار رمز عبور',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () => setState(
                                  () => _obscureConfirmPassword =
                                      !_obscureConfirmPassword,
                                ),
                              ),
                            ),
                            obscureText: _obscureConfirmPassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'لطفاً تکرار رمز عبور را وارد کنید';
                              }
                              if (value != _passwordController.text) {
                                return 'رمزهای عبور مطابقت ندارند';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _pinController,
                            decoration: InputDecoration(
                              labelText: 'کد امنیتی ۴ رقمی',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.password),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePin
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () =>
                                    setState(() => _obscurePin = !_obscurePin),
                              ),
                            ),
                            obscureText: _obscurePin,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            maxLength: 4,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'لطفاً کد امنیتی را وارد کنید';
                              }
                              if (!RegExp(r'^\d{4}$').hasMatch(value)) {
                                return 'کد امنیتی باید ۴ رقم باشد';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          _isLoading
                              ? const CircularProgressIndicator()
                              : ElevatedButton(
                                  onPressed: _register,
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(
                                      double.infinity,
                                      50,
                                    ),
                                    backgroundColor: brandColor,
                                  ),
                                  child: const Text(
                                    'ثبت‌نام',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'حساب دارید؟ برگردید و وارد شوید',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  HomePage({super.key});
  final storage = AppStorage();
  Future<void> _logout(BuildContext context) async {
    await storage.delete('token');
    await storage.delete('user');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
    );
  }

  Future<Map<String, dynamic>> _getUserData() async {
    final userData = await storage.read('user');
    if (userData != null) return json.decode(userData) as Map<String, dynamic>;
    return {};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('خانه'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = snapshot.data ?? {};
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  child: Text(
                    (user['first_name']?.toString().isNotEmpty == true
                        ? user['first_name'][0].toString().toUpperCase()
                        : user['last_name']?.toString().isNotEmpty == true
                        ? user['last_name'][0].toString().toUpperCase()
                        : 'U'),
                    style: const TextStyle(fontSize: 40),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'خوش آمدید، ${(user['first_name'] ?? '')} ${(user['last_name'] ?? '')}'
                          .trim()
                          .isEmpty
                      ? 'خوش آمدید، کاربر!'
                      : 'خوش آمدید، ${(user['first_name'] ?? '')} ${(user['last_name'] ?? '')}!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'تلفن: ${user['phone_number'] ?? ''}',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 30),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.person),
                          title: const Text('نام'),
                          subtitle: Text(user['first_name'] ?? ''),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.person_outline),
                          title: const Text('نام خانوادگی'),
                          subtitle: Text(user['last_name'] ?? ''),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.phone),
                          title: const Text('تلفن'),
                          subtitle: Text(user['phone_number'] ?? ''),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// ✅ صفحه داشبورد (اصلاح شده با به‌روزرسانی موجودی)
// ============================================================
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final storage = AppStorage();
  Map<String, dynamic>? _user;
  String? _name;
  dynamic _balance = 0;
  int _purchaseTotal = 0;
  int _purchaseSuccess = 0;
  bool _loading = true;
  bool _blocked = false;
  String? _blockMessage;
  String? _profileImageUrl;
  bool _uploadingImage = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  String _toPersianNumber(String input) {
    if (input.isEmpty) return input;
    const eng = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const pers = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    return input.replaceAllMapped(RegExp(r'\d'), (match) {
      final index = eng.indexOf(match.group(0)!);
      return index != -1 ? pers[index] : match.group(0)!;
    });
  }

  String _fmtAmount(dynamic value) {
    final text = value == null ? '0' : value.toString();
    final number = double.tryParse(text) ?? 0;
    final formatted = (number - number.toInt()).abs() < 1e-9
        ? number.toInt().toString()
        : number.toStringAsFixed(2).replaceAll(RegExp(r'\.0+'), '');
    return _toPersianNumber(formatted);
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  Future<void> _load() async {
    final token = await storage.read('token');
    final userString = await storage.read('user');
    if (userString != null) {
      _user = json.decode(userString) as Map<String, dynamic>;
    }
    if (token != null) {
      try {
        final response = await http.get(
          Uri.parse(api('/api/dashboard')),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (response.statusCode == 200) {
          final data = json.decode(response.body) as Map<String, dynamic>;
          _name = data['name'] as String?;
          _balance = data['balance'];
          _purchaseTotal = _toInt(data['purchase_total']);
          _purchaseSuccess = _toInt(data['successful_purchases']);
          _blocked = data['blocked'] == true;
          _blockMessage = data['message'] as String?;
          final url = data['profile_image_url'];
          if (url is String && url.isNotEmpty) {
            _profileImageUrl = url;
          }
        } else if (response.statusCode == 401 || response.statusCode == 403) {
          await storage.delete('token');
          await storage.delete('user');
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => LoginPage()),
            );
            return;
          }
        }
      } catch (_) {}
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _logout() async {
    await storage.delete('token');
    await storage.delete('user');
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
    );
  }

  Future<void> _pickAndUploadProfileImage() async {
    if (_uploadingImage) return;
    final token = await storage.read('token');
    if (token == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('ابتدا دوباره وارد حساب خود شوید'),
          backgroundColor: Colors.red.shade600,
        ),
      );
      return;
    }
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;
    final filePath = file.path;
    if ((filePath == null || filePath.isEmpty) && bytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('خواندن فایل انتخاب‌شده ممکن نیست'),
          backgroundColor: Colors.red.shade600,
        ),
      );
      return;
    }
    setState(() => _uploadingImage = true);
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(api('/api/profile/image')),
      );
      request.headers['Authorization'] = 'Bearer $token';
      if (filePath != null && filePath.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'profile_image',
            filePath,
            filename: file.name,
          ),
        );
      } else if (bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'profile_image',
            bytes,
            filename: file.name,
          ),
        );
      }
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final newUrl = data['profile_image_url'] as String?;
        if (newUrl != null && newUrl.isNotEmpty) {
          if (mounted) {
            setState(() => _profileImageUrl = newUrl);
          }
          if (_user != null) {
            _user!['profile_image_url'] = newUrl;
            await storage.write('user', json.encode(_user));
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تصویر پروفایل با موفقیت تغییر کرد'),
              backgroundColor: Color(0xFF16A34A),
            ),
          );
        }
      } else {
        String message = 'خطا در آپلود تصویر';
        try {
          final data = json.decode(response.body);
          if (data is Map && data['message'] != null) {
            message = data['message'].toString();
          }
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا: $e'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  void _openFeature(String title, String subtitle, IconData icon) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FeaturePlaceholderPage(
          title: title,
          subtitle: subtitle,
          icon: icon,
        ),
      ),
    );
  }

  Widget _featureCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withOpacity(0.16)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 19),
                ),
                const SizedBox(height: 5),
                Text(
                  title,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width < 340 ? 10 : 11,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _purchaseSummaryCard() {
    return Card(
      elevation: 1,
      color: const Color(0xFFE6F9EC),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: const Color(0xFF16A34A).withOpacity(0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withOpacity(0.22),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.shopping_bag_rounded,
                    color: Color(0xFF15803D),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'خرید ها',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF14532D),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: 150,
                  child: _summaryMiniCard(
                    title: 'مجموع خرید ها',
                    value: '234 تومن',
                    icon: Icons.receipt_long_rounded,
                    color: const Color(0xFF15803D),
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: _summaryMiniCard(
                    title: 'خرید های موفق',
                    value: '23 بار',
                    icon: Icons.verified_rounded,
                    color: const Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryMiniCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 15),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstName = (_user?['first_name'] ?? '').toString();
    final lastName = (_user?['last_name'] ?? '').toString();
    final fullName = ('$firstName $lastName').trim();
    final displayName = _name ?? (fullName.isEmpty ? 'کاربر' : fullName);
    final balanceText = '${_fmtAmount(_balance)} تومن';

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('پروفایل'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('تنظیمات'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsPage()),
                  );
                },
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('خروج'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        title: const Text('داشبورد'),
        backgroundColor: brandColor,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_open, color: Colors.white),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                brandColor,
                brandColor.withOpacity(0.92),
                brandSeed,
              ],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            boxShadow: [
              BoxShadow(
                color: brandColor.withOpacity(0.45),
                blurRadius: 28,
                spreadRadius: -8,
                offset: const Offset(0, -4),
              ),
            ],
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Make it responsive based on available width
                    final isVerySmall = constraints.maxWidth < 320;
                    final isSmallScreen = constraints.maxWidth < 360 && !isVerySmall;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // خانه
                        Expanded(
                          child: _BottomNavItem(
                            icon: Icons.home_rounded,
                            label: 'خانه',
                            active: _selectedIndex == 0,
                            isSmall: isSmallScreen,
                            isVerySmall: isVerySmall,
                            onTap: () => setState(() => _selectedIndex = 0),
                          ),
                        ),
                        // بازار
                        Expanded(
                          child: _BottomNavItem(
                            icon: Icons.storefront_rounded,
                            label: 'بازار',
                            active: _selectedIndex == 1,
                            isSmall: isSmallScreen,
                            isVerySmall: isVerySmall,
                            onTap: () async {
                              setState(() => _selectedIndex = 1);
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const BazarPage(),
                                ),
                              );
                              _load(); // ✅ به‌روزرسانی موجودی بعد از برگشت
                            },
                          ),
                        ),
                        // حواله
                        Expanded(
                          child: _BottomNavItem(
                            icon: Icons.swap_horiz_rounded,
                            label: 'حواله',
                            active: _selectedIndex == 2,
                            isSmall: isSmallScreen,
                            isVerySmall: isVerySmall,
                            onTap: () {
                              setState(() => _selectedIndex = 2);
                              _openFeature(
                                'حواله',
                                'ارسال و پیگیری حواله‌ها در این بخش قرار می‌گیرد.',
                                Icons.swap_horiz_rounded,
                              );
                            },
                          ),
                        ),
                        // زیر شاخه
                        Expanded(
                          child: _BottomNavItem(
                            icon: Icons.account_tree_rounded,
                            label: 'زیر شاخه',
                            active: _selectedIndex == 3,
                            isSmall: isSmallScreen,
                            isVerySmall: isVerySmall,
                            onTap: () {
                              setState(() => _selectedIndex = 3);
                              _openFeature(
                                'زیر شاخه',
                                'مدیریت زیرشاخه‌ها در این بخش قرار می‌گیرد.',
                                Icons.account_tree_rounded,
                              );
                            },
                          ),
                        ),
                        // گزارشات (سفارشات)
                        Expanded(
                          child: _BottomNavItem(
                            icon: Icons.bar_chart_rounded,
                            label: 'گزارشات',
                            active: _selectedIndex == 4,
                            isSmall: isSmallScreen,
                            isVerySmall: isVerySmall,
                            onTap: () async {
                              setState(() => _selectedIndex = 4);
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MyOrdersPage(),
                                ),
                              );
                              _load(); // ✅ به‌روزرسانی موجودی بعد از برگشت
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            brandColor.withOpacity(0.12),
                            theme.colorScheme.primary.withOpacity(0.06),
                            brandColor.withOpacity(0.03),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _DashboardAuroraPainter(
                        color: brandColor,
                        seed: brandSeed,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 16,
                  right: 16,
                  child: Center(
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 600),
                        tween: Tween<double>(begin: 0, end: 1),
                        curve: Curves.easeOutBack,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, 30 * (1 - value)),
                            child: Opacity(
                              opacity: value,
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                brandColor,
                                brandColor.withOpacity(0.95),
                                brandSeed,
                              ],
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                            ),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: brandColor.withOpacity(0.55),
                                blurRadius: 35,
                                spreadRadius: -6,
                                offset: const Offset(0, 15),
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(22),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: _pickAndUploadProfileImage,
                                  child: TweenAnimationBuilder<double>(
                                    duration: const Duration(milliseconds: 400),
                                    tween: Tween<double>(begin: 0.8, end: 1),
                                    curve: Curves.easeOutBack,
                                    builder: (context, value, child) {
                                      return Transform.scale(
                                        scale: value,
                                        child: child,
                                      );
                                    },
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Container(
                                          width: 78,
                                          height: 78,
                                          padding: const EdgeInsets.all(3.5),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white.withOpacity(0.18),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.15),
                                                blurRadius: 12,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.white.withOpacity(0.30),
                                            ),
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Container(
                                                  margin: const EdgeInsets.all(3),
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        Colors.white.withOpacity(0.95),
                                                        Colors.white.withOpacity(0.80),
                                                      ],
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.bottomRight,
                                                    ),
                                                  ),
                                                  clipBehavior: Clip.antiAlias,
                                                  child: _profileImageUrl != null
                                                      ? Image.network(
                                                          _profileImageUrl!,
                                                          width: 72,
                                                          height: 72,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (context, error, stackTrace) {
                                                            return Container(
                                                              decoration: BoxDecoration(
                                                                shape: BoxShape.circle,
                                                                gradient: LinearGradient(
                                                                  colors: [
                                                                    const Color(0xFF059669),
                                                                    const Color(0xFF10B981),
                                                                  ],
                                                                  begin: Alignment.topLeft,
                                                                  end: Alignment.bottomRight,
                                                                ),
                                                              ),
                                                              child: const Center(
                                                                child: Icon(
                                                                  Icons.person_rounded,
                                                                  color: Colors.white,
                                                                  size: 36,
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                          loadingBuilder:
                                                              (
                                                                context,
                                                                child,
                                                                loadingProgress,
                                                              ) {
                                                                if (loadingProgress ==
                                                                    null) {
                                                                  return child;
                                                                }
                                                                return Container(
                                                                  decoration: BoxDecoration(
                                                                    shape: BoxShape.circle,
                                                                    gradient: LinearGradient(
                                                                      colors: [
                                                                        const Color(0xFF059669),
                                                                        const Color(0xFF10B981),
                                                                      ],
                                                                      begin: Alignment.topLeft,
                                                                      end: Alignment.bottomRight,
                                                                    ),
                                                                  ),
                                                                  child: const Center(
                                                                    child: SizedBox(
                                                                      width: 24,
                                                                      height: 24,
                                                                      child: CircularProgressIndicator(
                                                                        strokeWidth: 2.5,
                                                                        valueColor:
                                                                            AlwaysStoppedAnimation<
                                                                              Color
                                                                            >(
                                                                              Colors.white,
                                                                            ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                );
                                                              },
                                                        )
                                                      : Container(
                                                          decoration: BoxDecoration(
                                                            shape: BoxShape.circle,
                                                            gradient: LinearGradient(
                                                              colors: [
                                                                const Color(0xFF059669),
                                                                const Color(0xFF10B981),
                                                              ],
                                                              begin: Alignment.topLeft,
                                                              end: Alignment.bottomRight,
                                                            ),
                                                          ),
                                                          child: const Center(
                                                            child: Icon(
                                                              Icons.person_rounded,
                                                              color: Colors.white,
                                                              size: 36,
                                                            ),
                                                          ),
                                                        ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: -1,
                                          left: -1,
                                          child: Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.18),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: _uploadingImage
                                                ? const Padding(
                                                    padding: EdgeInsets.all(8),
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2.5,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(
                                                            Color(0xFF059669),
                                                          ),
                                                    ),
                                                  )
                                                : const Icon(
                                                    Icons.camera_alt_rounded,
                                                    size: 18,
                                                    color: Color(0xFF059669),
                                                  ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 18),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'خوش آمدید',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white.withOpacity(0.90),
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        displayName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          height: 1.05,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.32),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.52),
                                            width: 1.6,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.12),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: LayoutBuilder(
                                          builder: (context, balanceConstraints) {
                                            final balanceWidth = balanceConstraints.maxWidth;
                                            final iconSize = balanceWidth < 200 ? 18.0 : 22.0;
                                            final fontSize = balanceWidth < 200 ? 13.0 : (balanceWidth < 250 ? 15.0 : 17.0);
                                            return Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.account_balance_wallet_rounded,
                                                  color: Colors.white,
                                                  size: iconSize,
                                                ),
                                                SizedBox(width: balanceWidth < 200 ? 8 : 12),
                                                Flexible(
                                                  child: FittedBox(
                                                    fit: BoxFit.scaleDown,
                                                    alignment: Alignment.centerRight,
                                                    child: Text(
                                                      balanceText,
                                                      maxLines: 1,
                                                      softWrap: false,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: fontSize,
                                                        fontWeight: FontWeight.w900,
                                                        letterSpacing: balanceWidth < 200 ? 0.3 : 0.6,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 190,
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final cardHeight = width < 340
                              ? 88.0
                              : (width < 360 ? 96.0 : 100.0);
                          final spacing = width < 340 ? 4.0 : 6.0;
                          return ListView(
                            children: [
                              GridView.count(
                                crossAxisCount: 3,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisSpacing: spacing,
                                mainAxisSpacing: spacing,
                                mainAxisExtent: cardHeight,
                                children: [
                                  _featureCard(
                                    title: 'افزایش موجودی',
                                    icon: Icons.account_balance_wallet_rounded,
                                    color: brandColor,
                                    onTap: () => _openFeature(
                                      'افزایش موجودی',
                                      'شارژ حساب و مدیریت موجودی در این بخش قرار می‌گیرد.',
                                      Icons.account_balance_wallet_rounded,
                                    ),
                                  ),
                                  _featureCard(
                                    title: 'کارت به کارت',
                                    icon: Icons.credit_card_rounded,
                                    color: const Color(0xFF16A34A),
                                    onTap: () => _openFeature(
                                      'کارت به کارت',
                                      'انتقال وجه بین کارت‌ها در این بخش قرار می‌گیرد.',
                                      Icons.credit_card_rounded,
                                    ),
                                  ),
                                  _featureCard(
                                    title: 'پروفایل',
                                    icon: Icons.person_rounded,
                                    color: const Color(0xFF16A34A),
                                    onTap: () => _openFeature(
                                      'پروفایل',
                                      'اطلاعات و تنظیمات کاربر در این بخش قرار می‌گیرد.',
                                      Icons.person_rounded,
                                    ),
                                  ),
                                  _featureCard(
                                    title: 'نرخ ارز',
                                    icon: Icons.currency_exchange_rounded,
                                    color: Colors.orange,
                                    onTap: () => _openFeature(
                                      'نرخ ارز',
                                      'نمایش قیمت‌های به‌روز ارز در این بخش قرار می‌گیرد.',
                                      Icons.currency_exchange_rounded,
                                    ),
                                  ),
                                  _featureCard(
                                    title: 'سفارش ها',
                                    icon: Icons.receipt_long_rounded,
                                    color: Colors.teal,
                                    onTap: () => _openFeature(
                                      'سفارش ها',
                                      'پیگیری سفارش‌های شما در این بخش قرار می‌گیرد.',
                                      Icons.receipt_long_rounded,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _purchaseSummaryCard(),
                              const SizedBox(height: 10),
                              ImageSlideshow(
                                images: const [
                                  'https://images.unsplash.com/photo-1554224155-6726b3ff858f?w=1200&q=80',
                                  'https://images.unsplash.com/photo-1526304640581-d334cdbbf45e?w=1200&q=80',
                                  'https://images.unsplash.com/photo-1611974789855-9c2a0a7236a3?w=1200&q=80',
                                ],
                                height: 180,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
                if (_blocked)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.45),
                      child: Center(
                        child: Card(
                          elevation: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: Colors.red.withOpacity(0.4),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.block,
                                  color: Colors.red,
                                  size: 48,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'حساب شما محدود شده است',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _blockMessage ??
                                      'شما از طرف ادمین محدود شده‌اید. لطفاً برای رفع محدودیت با ادمین تماس بگیرید.',
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _logout,
                                  icon: const Icon(Icons.logout),
                                  label: const Text('خروج'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    minimumSize: const Size(180, 44),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

// ============================================================
// ✅ بقیه ویجت‌ها (بدون تغییر)
// ============================================================

class DashboardPainter extends CustomPainter {
  final Color color;
  DashboardPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final p = Paint()..isAntiAlias = true;
    final g1 = ui.Gradient.linear(Offset(0, 0), Offset(w, h * 0.3), [
      color.withOpacity(0.18),
      color.withOpacity(0.06),
    ]);
    p.shader = g1;
    final path1 = Path()
      ..moveTo(0, h * 0.20)
      ..quadraticBezierTo(w * 0.25, h * 0.12, w * 0.5, h * 0.18)
      ..quadraticBezierTo(w * 0.75, h * 0.24, w, h * 0.16)
      ..lineTo(w, 0)
      ..lineTo(0, 0)
      ..close();
    canvas.drawPath(path1, p);
    final g2 = ui.Gradient.linear(Offset(0, h), Offset(w, h * 0.7), [
      color.withOpacity(0.14),
      color.withOpacity(0.04),
    ]);
    p.shader = g2;
    final path2 = Path()
      ..moveTo(0, h)
      ..quadraticBezierTo(w * 0.25, h * 0.86, w * 0.5, h * 0.92)
      ..quadraticBezierTo(w * 0.75, h * 0.98, w, h * 0.88)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(path2, p);
    final pc = Paint()
      ..color = color.withOpacity(0.10)
      ..isAntiAlias = true;
    canvas.drawCircle(Offset(w - 80, 120), 80, pc);
    canvas.drawCircle(Offset(40, h - 120), 60, pc);
    final pd = Paint()
      ..color = color.withOpacity(0.06)
      ..isAntiAlias = true;
    final step = 30.0;
    for (double y = h * 0.25; y < h * 0.75; y += step) {
      for (double x = w * 0.15; x < w * 0.85; x += step) {
        canvas.drawCircle(Offset(x, y), 2, pd);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DashboardAuroraPainter extends CustomPainter {
  final Color color;
  final Color seed;
  _DashboardAuroraPainter({required this.color, required this.seed});
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final p = Paint()..isAntiAlias = true;
    final g1 = ui.Gradient.radial(Offset(w * 0.15, h * 0.15), h * 0.5, [
      seed.withOpacity(0.20),
      seed.withOpacity(0.0),
    ]);
    p.shader = g1;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), p);
    final g2 = ui.Gradient.radial(Offset(w * 0.85, h * 0.25), h * 0.45, [
      color.withOpacity(0.16),
      color.withOpacity(0.0),
    ]);
    p.shader = g2;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), p);
    final path = Path()
      ..moveTo(-20, h * 0.55)
      ..quadraticBezierTo(w * 0.25, h * 0.45, w * 0.5, h * 0.50)
      ..quadraticBezierTo(w * 0.75, h * 0.55, w + 20, h * 0.45)
      ..lineTo(w + 20, h * 0.70)
      ..lineTo(-20, h * 0.70)
      ..close();
    final g3 = ui.Gradient.linear(Offset(0, h * 0.45), Offset(0, h * 0.70), [
      seed.withOpacity(0.10),
      seed.withOpacity(0.02),
    ]);
    p.shader = g3;
    canvas.drawPath(path, p);
    final line = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color.withOpacity(0.08);
    for (double y = h * 0.25; y <= h * 0.75; y += 40) {
      final lp = Path()
        ..moveTo(w * 0.1, y)
        ..quadraticBezierTo(w * 0.5, y - 10, w * 0.9, y + 8);
      canvas.drawPath(lp, line);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

@immutable
class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final bool isSmall;
  final bool isVerySmall;
  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.isSmall = false,
    this.isVerySmall = false,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(isVerySmall ? 12 : (isSmall ? 14 : 18)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isVerySmall ? 12 : (isSmall ? 14 : 18)),
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            height: isVerySmall ? 42 : (isSmall ? 46 : 52),
            padding: EdgeInsets.symmetric(
              horizontal: isVerySmall ? 2 : (isSmall ? 4 : 8), 
              vertical: isVerySmall ? 2 : (isSmall ? 3 : 5)
            ),
            decoration: BoxDecoration(
              color: active ? Colors.white.withOpacity(0.30) : Colors.transparent,
              borderRadius: BorderRadius.circular(isVerySmall ? 12 : (isSmall ? 14 : 18)),
              border: active
                  ? Border.all(
                      color: Colors.white.withOpacity(0.45), 
                      width: isVerySmall ? 0.6 : (isSmall ? 0.8 : 1.0)
                    )
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: isVerySmall ? 16 : (isSmall ? 18 : 22),
                  color: active ? Colors.white : Colors.white.withOpacity(0.80),
                ),
                SizedBox(height: isVerySmall ? 1 : (isSmall ? 2 : 3)),
                Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isVerySmall ? 8 : (isSmall ? 9 : 10),
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

@immutable
class FeaturePlaceholderPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const FeaturePlaceholderPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        foregroundColor: brandColor,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              brandColor.withOpacity(0.12),
              theme.colorScheme.primary.withOpacity(0.05),
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Card(
            elevation: 6,
            margin: const EdgeInsets.all(24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: brandColor.withOpacity(0.18)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [brandColor, brandSeed.withOpacity(0.9)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Icon(icon, color: Colors.white, size: 36),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 22),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('بازگشت'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}