import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api_config.dart';
import '../order/order.dart'; // ✅ import صفحه سفارشات

class OrderCreditIranPage extends StatefulWidget {
  final String operatorName;
  final String phoneNumber;
  final int amount;
  final double totalPrice;
  final double pricePerUnit;

  const OrderCreditIranPage({
    super.key,
    required this.operatorName,
    required this.phoneNumber,
    required this.amount,
    required this.totalPrice,
    required this.pricePerUnit,
  });

  @override
  State<OrderCreditIranPage> createState() =>
      _OrderCreditIranPageState();
}

class _OrderCreditIranPageState
    extends State<OrderCreditIranPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _pinController = TextEditingController();
  bool _isLoading = false;
  bool _isPinLoading = false;
  bool _isPinDialogOpen = false;
  final storage = const FlutterSecureStorage();

  String _getOperatorImage(String operator) {
    final images = {
      'ایرانسل': 'assets/images/operators/iran_cell.png',
      'رایتل': 'assets/images/operators/rightel.png',
      'همراه اول': 'assets/images/operators/hamrahe_aval.png',
    };
    return images[operator] ?? 'assets/images/operators/unknown.png';
  }

  Color _getOperatorColor(String operator) {
    final colors = {
      'ایرانسل': const Color(0xFF6C2BD9),
      'رایتل': const Color(0xFFE91E63),
      'همراه اول': const Color(0xFF00BCD4),
    };
    return colors[operator] ?? Colors.grey;
  }

  void _showPinDialog() {
    if (_isPinDialogOpen) return;
    
    _pinController.clear();
    _isPinDialogOpen = true;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              Icons.lock_rounded,
              color: const Color(0xFF0E8A4D),
              size: 28,
            ),
            const SizedBox(width: 10),
            const Text(
              'تایید کد امنیتی',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0E8A4D),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'لطفاً کد امنیتی ۴ رقمی خود را وارد کنید',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
              decoration: InputDecoration(
                hintText: '_ _ _ _',
                hintStyle: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[400],
                  letterSpacing: 8,
                ),
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.grey[300]!,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF0E8A4D),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (value) {
                if (value.length == 4) {
                  // وقتی ۴ رقم وارد شد، دکمه فعال میشه
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _isPinDialogOpen = false;
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
            ),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: _isPinLoading
                ? null
                : () {
                    final pin = _pinController.text.trim();
                    if (pin.length != 4) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('❌ کد امنیتی باید ۴ رقم باشد'),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }
                    _verifyPin(pin);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0E8A4D),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _isPinLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('تایید'),
          ),
        ],
      ),
    ).then((_) {
      _isPinDialogOpen = false;
    });
  }

  Future<void> _verifyPin(String pin) async {
    if (_isPinLoading) return;
    
    setState(() {
      _isPinLoading = true;
    });

    try {
      final token = await storage.read(key: 'token');
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لطفاً ابتدا وارد حساب خود شوید'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          _isPinLoading = false;
        });
        return;
      }

      final response = await http.post(
        Uri.parse(api('/api/verify_pin')),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'pin_code': pin,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _isPinLoading = false;
        });
        _isPinDialogOpen = false;
        Navigator.pop(context);
        _submitOrder();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${data['message'] ?? 'کد امنیتی اشتباه است'}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _pinController.clear();
        setState(() {
          _isPinLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ خطا: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _isPinLoading = false;
      });
    }
  }

  Future<void> _submitOrder() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await storage.read(key: 'token');
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لطفاً ابتدا وارد حساب خود شوید'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final response = await http.post(
        Uri.parse(api('/api/orders/create_credit_iran')),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'phone_number': widget.phoneNumber,
          'operator': widget.operatorName,
          'amount': widget.amount,
          'price': widget.totalPrice,
          'price_per_unit': widget.pricePerUnit,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        final userData = await storage.read(key: 'user');
        if (userData != null) {
          final user = json.decode(userData);
          user['balance'] = data['new_balance'];
          await storage.write(key: 'user', value: json.encode(user));
        }

        _showSuccessDialog(data);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${data['message'] ?? 'خطا در ثبت سفارش'}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ خطا: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => Dialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                spreadRadius: 0,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF0E8A4D),
                      Color(0xFF16A34A),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0E8A4D).withOpacity(0.4),
                      blurRadius: 24,
                      spreadRadius: 0,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 56,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'سفارش کریدیت ایران با موفقیت ثبت شد',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0E8A4D),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.amount} تومان شارژ برای شماره ${widget.phoneNumber} ثبت شد',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey[200]!,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      Icons.phone_android_rounded,
                      'شماره تماس',
                      widget.phoneNumber,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.signal_cellular_alt_rounded,
                      'اپراتور',
                      widget.operatorName,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.numbers_rounded,
                      'مقدار شارژ',
                      '${widget.amount} تومان',
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.attach_money_rounded,
                      'مبلغ پرداختی',
                      '${widget.totalPrice.toStringAsFixed(0)} تومان',
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.wallet_rounded,
                      'موجودی جدید',
                      '${(data['new_balance'] ?? 0).toStringAsFixed(0)} تومان',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyOrdersPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0E8A4D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: const Text(
                    '📋 دیدن تراکنش‌ها',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
          textAlign: TextAlign.end,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final String operatorImage = _getOperatorImage(widget.operatorName);
    final Color operatorColor = _getOperatorColor(widget.operatorName);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'تایید سفارش کریدیت ایران',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF0E8A4D),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.receipt_long_rounded,
                    color: const Color(0xFF0E8A4D),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'جزئیات سفارش کریدیت ایران',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0E8A4D),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'لطفاً اطلاعات زیر را بررسی کنید و سپس تایید کنید',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.08),
                      blurRadius: 12,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: operatorColor.withOpacity(0.20),
                              width: 1.5,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.asset(
                              operatorImage,
                              width: 56,
                              height: 56,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade100,
                                  child: Center(
                                    child: Text(
                                      widget.operatorName.isNotEmpty
                                          ? widget.operatorName[0]
                                          : '?',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: operatorColor,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'خرید کریدیت ایران',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: operatorColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '🇮🇷 ${widget.operatorName}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: operatorColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildInfoRow(
                      Icons.phone_android_rounded,
                      'شماره تماس',
                      widget.phoneNumber,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.numbers_rounded,
                      'مقدار شارژ',
                      '${widget.amount} تومان',
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.attach_money_rounded,
                      'قیمت هر واحد',
                      '${widget.pricePerUnit.toStringAsFixed(0)} تومان',
                    ),
                    const SizedBox(height: 12),

                    const Divider(
                      color: Colors.grey,
                      thickness: 1,
                    ),
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '💰 مبلغ قابل پرداخت',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0E8A4D),
                          ),
                        ),
                        Text(
                          '${widget.totalPrice.toStringAsFixed(0)} تومان',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0E8A4D),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (_isLoading || _isPinDialogOpen)
                      ? null
                      : _showPinDialog,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_rounded),
                  label: Text(
                    _isLoading
                        ? 'در حال ثبت...'
                        : 'تایید و خرید کریدیت ایران (${widget.totalPrice.toStringAsFixed(0)} تومان)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isLoading
                        ? Colors.grey[400]
                        : const Color(0xFF0E8A4D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: _isLoading ? 0 : 4,
                    disabledBackgroundColor: Colors.grey[400],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                ),
                child: const Text('بازگشت'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}