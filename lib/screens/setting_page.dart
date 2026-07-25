import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../main.dart';
import '../api_config.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _darkMode = false;
  bool _notifications = true;
  String _language = 'fa';
  final AppStorage _storage = AppStorage();
  Future<String?> _readToken() async {
    return await _storage.read('token');
  }
  Future<Map<String, dynamic>?> _fetchProfile() async {
    final token = await _readToken();
    if (token == null) return null;
    final res = await http.get(Uri.parse(api('/api/profile')), headers: {'Authorization': 'Bearer $token'});
    if (res.statusCode == 200) {
      final data = json.decode(res.body) as Map<String, dynamic>;
      return data['user'] as Map<String, dynamic>?;
    }
    return null;
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('تنظیمات'),
        backgroundColor: theme.colorScheme.primary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FutureBuilder<Map<String, dynamic>?>(
            future: _fetchProfile(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Card(
                  elevation: 2,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        SizedBox(width: 16),
                        CircularProgressIndicator(),
                        SizedBox(width: 16),
                        Text('در حال بارگذاری اطلاعات کاربر'),
                      ],
                    ),
                  ),
                );
              }
              final user = snapshot.data;
              return Card(
                elevation: 2,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.phone),
                      title: const Text('شماره تماس'),
                      subtitle: Text(user?['phone_number']?.toString() ?? ''),
                    ),
                    const Divider(height: 0),
                    ListTile(
                      leading: const Icon(Icons.schedule),
                      title: const Text('زمان باقی‌مانده'),
                      subtitle: Text(
                        (() {
                          final rem = user?['remaining_days'];
                          if (rem == null) return '';
                          final n = (rem is int) ? rem : int.tryParse(rem.toString()) ?? 0;
                          return '$n روز';
                        })(),
                      ),
                    ),
                    const Divider(height: 0),
                    ListTile(
                      leading: const Icon(Icons.lock),
                      title: const Text('رمز عبور'),
                      subtitle: const Text('******'),
                      trailing: IconButton(
                        icon: const Icon(Icons.visibility),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('نمایش رمز عبور'),
                              content: const Text('به دلایل امنیتی، رمز عبور ذخیره نمی‌شود و قابل نمایش نیست. می‌توانید رمز عبور خود را تغییر دهید.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('بستن')),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _showChangePasswordDialog();
                                  },
                                  child: const Text('تغییر رمز عبور'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 2,
            child: SwitchListTile(
              value: _darkMode,
              onChanged: (v) => setState(() => _darkMode = v),
              title: const Text('حالت شب'),
              subtitle: const Text('تغییر ظاهر به تم تیره'),
              secondary: const Icon(Icons.dark_mode),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 2,
            child: SwitchListTile(
              value: _notifications,
              onChanged: (v) => setState(() => _notifications = v),
              title: const Text('اعلان‌ها'),
              subtitle: const Text('فعال یا غیرفعال کردن اعلان‌ها'),
              secondary: const Icon(Icons.notifications_active),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.language),
              title: const Text('زبان'),
              subtitle: Text(_language == 'fa' ? 'فارسی' : 'English'),
              trailing: DropdownButton<String>(
                value: _language,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'fa', child: Text('فارسی')),
                  DropdownMenuItem(value: 'en', child: Text('English')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _language = v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setStateDialog) {
          return AlertDialog(
            title: const Text('تغییر رمز عبور'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: currentController,
                    obscureText: obscureCurrent,
                    decoration: InputDecoration(
                      labelText: 'رمز فعلی',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(obscureCurrent ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setStateDialog(() => obscureCurrent = !obscureCurrent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newController,
                    obscureText: obscureNew,
                    decoration: InputDecoration(
                      labelText: 'رمز جدید',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(obscureNew ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setStateDialog(() => obscureNew = !obscureNew),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmController,
                    obscureText: obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'تأیید رمز جدید',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(obscureConfirm ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setStateDialog(() => obscureConfirm = !obscureConfirm),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('لغو')),
              ElevatedButton(
                onPressed: () async {
                  final current = currentController.text.trim();
                  final newPass = newController.text.trim();
                  final confirm = confirmController.text.trim();
                  if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
                    _showSnack('لطفاً همه فیلدها را پر کنید');
                    return;
                  }
                  if (newPass.length < 6) {
                    _showSnack('رمز جدید باید حداقل ۶ کاراکتر باشد');
                    return;
                  }
                  if (newPass != confirm) {
                    _showSnack('رمز جدید و تأیید آن یکسان نیست');
                    return;
                  }
                  final ok = await _changePassword(current, newPass);
                  if (ok) {
                    if (mounted) {
                      Navigator.pop(ctx);
                      _showSnack('رمز عبور با موفقیت تغییر کرد');
                    }
                  }
                },
                child: const Text('ذخیره'),
              ),
            ],
          );
        });
      },
    );
  }

  Future<bool> _changePassword(String current, String newPass) async {
    try {
      final token = await _readToken();
      if (token == null) {
        _showSnack('ابتدا وارد شوید');
        return false;
      }
      final res = await http.post(
        Uri.parse(api('/api/password/change')),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: json.encode({'current_password': current, 'new_password': newPass}),
      );
      if (res.statusCode == 200) {
        return true;
      }
      final data = json.decode(res.body);
      _showSnack(data['message']?.toString() ?? 'خطا در تغییر رمز');
    } catch (e) {
      _showSnack('خطای اتصال: $e');
    }
    return false;
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
