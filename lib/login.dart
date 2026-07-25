import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'api_config.dart';
import 'main.dart';

const Color _brandColor = Color(0xFF0E8A4D);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  final storage = AppStorage();

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final response = await http.post(
          Uri.parse(api('/api/login')),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'phone_number': _phoneController.text.trim().replaceAll(
              RegExp(r'[\s-]'),
              '',
            ),
            'password': _passwordController.text.trim(),
          }),
        );
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          await storage.write('token', data['token']);
          await storage.write('user', json.encode(data['user']));
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => DashboardPage()),
            );
          }
        } else {
          final error = json.decode(response.body);
          _showErrorDialog(error['message'] ?? 'Login failed');
        }
      } catch (e) {
        _showErrorDialog('Connection error: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
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

  // ✅ تابع دریافت سایزهای ریسپانسیو
  Map<String, dynamic> _getResponsiveSizes(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    final isVerySmall = width < 360;
    final isSmall = width < 380;
    final isMedium = width < 500;
    final isTablet = width >= 600;
    
    final logoSize = isVerySmall ? 70 : (isSmall ? 80 : (isMedium ? 90 : 100));
    final fontSizeTitle = isVerySmall ? 18 : (isSmall ? 20 : (isMedium ? 24 : 28));
    final fontSizeSubtitle = isVerySmall ? 11 : (isSmall ? 12 : (isMedium ? 14 : 15));
    final paddingHorizontal = isVerySmall ? 12 : (isSmall ? 16 : (isMedium ? 20 : 24));
    final paddingVertical = isVerySmall ? 12 : (isSmall ? 16 : (isMedium ? 20 : 24));
    final cardPadding = isVerySmall ? 16 : (isSmall ? 20 : (isMedium ? 24 : 28));
    final buttonHeight = isVerySmall ? 44 : (isSmall ? 48 : (isMedium ? 52 : 54));
    final fontSizeButton = isVerySmall ? 14 : (isSmall ? 15 : (isMedium ? 16 : 18));
    final fontSizeSmall = isVerySmall ? 9 : (isSmall ? 10 : (isMedium ? 11 : 12));
    final fontSizeMedium = isVerySmall ? 11 : (isSmall ? 12 : (isMedium ? 13 : 14));
    final spacingLarge = isVerySmall ? 16 : (isSmall ? 20 : (isMedium ? 28 : 32));
    final spacingMedium = isVerySmall ? 12 : (isSmall ? 16 : (isMedium ? 20 : 24));
    final spacingSmall = isVerySmall ? 6 : (isSmall ? 8 : (isMedium ? 10 : 12));
    
    return {
      'isVerySmall': isVerySmall,
      'isSmall': isSmall,
      'isMedium': isMedium,
      'isTablet': isTablet,
      'logoSize': logoSize,
      'fontSizeTitle': fontSizeTitle,
      'fontSizeSubtitle': fontSizeSubtitle,
      'paddingHorizontal': paddingHorizontal,
      'paddingVertical': paddingVertical,
      'cardPadding': cardPadding,
      'buttonHeight': buttonHeight,
      'fontSizeButton': fontSizeButton,
      'fontSizeSmall': fontSizeSmall,
      'fontSizeMedium': fontSizeMedium,
      'spacingLarge': spacingLarge,
      'spacingMedium': spacingMedium,
      'spacingSmall': spacingSmall,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = _getResponsiveSizes(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'ورود',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: _brandColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: r['paddingHorizontal'],
              vertical: r['paddingVertical'],
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - kToolbarHeight - 60,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // لوگو
                  Container(
                    width: r['logoSize'],
                    height: r['logoSize'],
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _brandColor,
                          _brandColor.withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _brandColor.withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.eco_rounded,
                      color: Colors.white,
                      size: r['logoSize'] * 0.5,
                    ),
                  ),
                  SizedBox(height: r['spacingLarge']),

                  // متن خوش آمدید
                  Text(
                    'خوش آمدید',
                    style: TextStyle(
                      fontSize: r['fontSizeTitle'],
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'برای ادامه وارد حساب خود شوید',
                    style: TextStyle(
                      fontSize: r['fontSizeSubtitle'],
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: r['spacingMedium']),

                  // کارت فرم
                  Container(
                    padding: EdgeInsets.all(r['cardPadding']),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 30,
                          spreadRadius: 0,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: _brandColor.withOpacity(0.06),
                          blurRadius: 20,
                          spreadRadius: 0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // شماره موبایل
                          TextFormField(
                            controller: _phoneController,
                            decoration: InputDecoration(
                              labelText: 'شماره موبایل',
                              hintText: 'مثال: ۰۹۱۲۱۲۳۴۵۶۷',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: _brandColor,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              prefixIcon: Icon(
                                Icons.phone_outlined,
                                color: _brandColor.withOpacity(0.6),
                              ),
                              labelStyle: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                                fontSize: r['fontSizeMedium'],
                              ),
                              hintStyle: TextStyle(
                                fontSize: r['fontSizeSmall'],
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: r['isVerySmall'] ? 10 : (r['isSmall'] ? 12 : 14),
                              ),
                            ),
                            keyboardType: TextInputType.phone,
                            style: TextStyle(
                              fontSize: r['fontSizeMedium'],
                              fontWeight: FontWeight.w500,
                            ),
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
                          SizedBox(height: r['spacingSmall'] + 6),

                          // رمز عبور
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'رمز عبور',
                              hintText: 'حداقل ۶ کاراکتر',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: _brandColor,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              prefixIcon: Icon(
                                Icons.lock_outline_rounded,
                                color: _brandColor.withOpacity(0.6),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: _brandColor.withOpacity(0.6),
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                              labelStyle: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                                fontSize: r['fontSizeMedium'],
                              ),
                              hintStyle: TextStyle(
                                fontSize: r['fontSizeSmall'],
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: r['isVerySmall'] ? 10 : (r['isSmall'] ? 12 : 14),
                              ),
                            ),
                            obscureText: _obscurePassword,
                            style: TextStyle(
                              fontSize: r['fontSizeMedium'],
                              fontWeight: FontWeight.w500,
                            ),
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
                          const SizedBox(height: 8),

                          // فراموشی رمز
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                foregroundColor: _brandColor,
                              ),
                              child: Text(
                                'رمز عبور را فراموش کرده‌اید؟',
                                style: TextStyle(
                                  fontSize: r['fontSizeSmall'],
                                  fontWeight: FontWeight.w500,
                                  color: _brandColor.withOpacity(0.7),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: r['spacingSmall']),

                          // دکمه ورود
                          SizedBox(
                            height: r['buttonHeight'],
                            width: double.infinity,
                            child: _isLoading
                                ? Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          _brandColor,
                                          _brandColor.withOpacity(0.8),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Center(
                                      child: SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  )
                                : ElevatedButton(
                                    onPressed: _login,
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: Size(double.infinity, r['buttonHeight']),
                                      backgroundColor: _brandColor,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      textStyle: TextStyle(
                                        fontSize: r['fontSizeButton'],
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    child: const Text('ورود'),
                                  ),
                          ),
                          SizedBox(height: r['spacingSmall'] + 6),

                          // ثبت‌نام
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'حساب ندارید؟',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: r['fontSizeSmall'],
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const RegisterPage(),
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: _brandColor,
                                ),
                                child: Text(
                                  'ثبت‌نام کنید',
                                  style: TextStyle(
                                    fontSize: r['fontSizeSmall'],
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // شماره سازنده
                  SizedBox(height: r['spacingSmall'] + 6),
                  Column(
                    children: [
                      Container(
                        width: 40,
                        height: 1,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.code_rounded,
                            size: r['fontSizeSmall'] + 2,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'سازنده:',
                            style: TextStyle(
                              fontSize: r['fontSizeSmall'],
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {},
                            child: Text(
                              '۰۷۹۶۱۳۷۵۶۸',
                              style: TextStyle(
                                fontSize: r['fontSizeSmall'] + 1,
                                color: _brandColor,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'پشتیبانی و توسعه',
                        style: TextStyle(
                          fontSize: r['fontSizeSmall'] - 1,
                          color: Colors.grey[400],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: r['spacingSmall']),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}