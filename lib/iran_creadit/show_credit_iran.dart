import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api_config.dart';
import '../iran_creadit/order_credit_iran.dart';

class ShowCreditIranPage extends StatefulWidget {
  final String operatorName;
  final String phoneNumber;

  const ShowCreditIranPage({
    super.key,
    required this.operatorName,
    required this.phoneNumber,
  });

  @override
  State<ShowCreditIranPage> createState() => _ShowCreditIranPageState();
}

class _ShowCreditIranPageState extends State<ShowCreditIranPage> {
  final TextEditingController _amountController = TextEditingController();
  final storage = const FlutterSecureStorage();

  bool _isLoading = false;
  double _pricePerUnit = 0;
  int _selectedAmount = 0;
  double _totalPrice = 0;
  bool _hasPrice = false;
  String? _error;

  Future<void> _loadCreditPrice() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await storage.read(key: 'token');
      if (token == null) {
        setState(() {
          _error = 'لطفاً ابتدا وارد حساب خود شوید';
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse(api('/api/credits/iran')),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final credits = data['credits'] ?? [];
          if (credits.isNotEmpty) {
            final firstCredit = credits[0];
            setState(() {
              _pricePerUnit = (firstCredit['price'] ?? 0).toDouble();
              _hasPrice = true;
              _isLoading = false;
            });
          } else {
            setState(() {
              _error = 'هیچ قیمتی برای شارژ تعیین نشده است';
              _isLoading = false;
            });
          }
        } else {
          setState(() {
            _error = data['message'] ?? 'خطا در دریافت قیمت';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'خطا در ارتباط با سرور: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'خطا: $e';
        _isLoading = false;
      });
    }
  }

  void _calculatePrice(String value) {
    if (value.isEmpty) {
      setState(() {
        _selectedAmount = 0;
        _totalPrice = 0;
      });
      return;
    }

    final amount = int.tryParse(value);
    if (amount != null && amount > 0) {
      setState(() {
        _selectedAmount = amount;
        _totalPrice = amount * _pricePerUnit;
      });
    } else {
      setState(() {
        _selectedAmount = 0;
        _totalPrice = 0;
      });
    }
  }

  void _setQuickAmount(int amount) {
    _amountController.text = amount.toString();
    _calculatePrice(amount.toString());
  }

  @override
  void initState() {
    super.initState();
    _loadCreditPrice();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String _getOperatorImage(String operatorName) {
    final images = {
      'ایرانسل': 'assets/images/operators/iran_cell.png',
      'رایتل': 'assets/images/operators/rightel.png',
      'همراه اول': 'assets/images/operators/hamrahe_aval.png',
    };
    return images[operatorName] ?? 'assets/images/operators/unknown.png';
  }

  Color _getOperatorColor(String operatorName) {
    final colors = {
      'ایرانسل': const Color(0xFF6C2BD9),
      'رایتل': const Color(0xFFE91E63),
      'همراه اول': const Color(0xFF00BCD4),
    };
    return colors[operatorName] ?? Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final String operatorName = widget.operatorName;
    final String phoneNumber = widget.phoneNumber;
    final String operatorImage = _getOperatorImage(operatorName);
    final Color operatorColor = _getOperatorColor(operatorName);

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 380;
    final isMediumScreen = screenWidth < 600;

    final double fontSizeTitle = isSmallScreen ? 16 : 20;
    final double paddingMain = isSmallScreen ? 12 : 16;
    final double paddingCard = isSmallScreen ? 14 : 20;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '💰 خرید کریدیت ایران',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: fontSizeTitle,
          ),
        ),
        backgroundColor: const Color(0xFF0E8A4D),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(paddingMain),
          child: _isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: Color(0xFF0E8A4D),
                      ),
                      SizedBox(height: 16),
                      Text('در حال بارگذاری...'),
                    ],
                  ),
                )
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 60,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadCreditPrice,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0E8A4D),
                            ),
                            child: const Text('🔄 تلاش مجدد'),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ============================================
                          // 📌 اطلاعات کاربر
                          // ============================================
                          Container(
                            padding: EdgeInsets.all(paddingCard),
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
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: isSmallScreen ? 44 : 50,
                                  height: isSmallScreen ? 44 : 50,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.asset(
                                      operatorImage,
                                      width: isSmallScreen ? 44 : 50,
                                      height: isSmallScreen ? 44 : 50,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error,
                                          stackTrace) {
                                        return Container(
                                          color: Colors.grey[200],
                                          child: Icon(
                                            Icons.broken_image_rounded,
                                            size: isSmallScreen ? 24 : 30,
                                            color: Colors.grey,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '📱 $phoneNumber',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 14 : 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '📡 $operatorName',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 12 : 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ============================================
                          // 📌 عنوان بخش
                          // ============================================
                          Text(
                            'مقدار شارژ مورد نظر را وارد کنید',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // ============================================
                          // 📌 فیلد ورودی مقدار شارژ
                          // ============================================
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.08),
                                  blurRadius: 10,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: TextFormField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 18 : 22,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                hintText: 'مقدار را وارد کنید...',
                                hintStyle: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: isSmallScreen ? 16 : 18,
                                ),
                                prefixIcon: Icon(
                                  Icons.numbers_rounded,
                                  color: const Color(0xFF0E8A4D),
                                  size: isSmallScreen ? 24 : 28,
                                ),
                                suffixText: 'تومان',
                                suffixStyle: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: isSmallScreen ? 14 : 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 16 : 20,
                                  vertical: isSmallScreen ? 14 : 18,
                                ),
                              ),
                              onChanged: (value) {
                                _calculatePrice(value);
                              },
                            ),
                          ),

                          const SizedBox(height: 16),

                          // ============================================
                          // 📌 دکمه‌های سریع
                          // ============================================
                          Wrap(
                            spacing: isSmallScreen ? 6 : 8,
                            runSpacing: isSmallScreen ? 6 : 8,
                            children: [
                              _buildQuickButton(10, isSmallScreen),
                              _buildQuickButton(20, isSmallScreen),
                              _buildQuickButton(50, isSmallScreen),
                              _buildQuickButton(100, isSmallScreen),
                              _buildQuickButton(200, isSmallScreen),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // ============================================
                          // 📌 نمایش قیمت نهایی (مینیمال و حرفه‌ای)
                          // ============================================
                          if (_selectedAmount > 0)
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(paddingCard),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFF0E8A4D)
                                      .withOpacity(0.15),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'مقدار',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 13 : 14,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            '$_selectedAmount',
                                            style: TextStyle(
                                              fontSize:
                                                  isSmallScreen ? 18 : 20,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF1A1A1A),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'تومان',
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 12 : 13,
                                              color: Colors.grey[500],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Container(
                                    height: 1,
                                    color: Colors.grey[200],
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'قیمت کل',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 14 : 15,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            '${_totalPrice.toStringAsFixed(0)}',
                                            style: TextStyle(
                                              fontSize:
                                                  isSmallScreen ? 22 : 26,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFF0E8A4D),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'تومان',
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 13 : 15,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF0E8A4D),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 20),

                          // ============================================
                          // 📌 دکمه تایید و خرید
                          // ============================================
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _selectedAmount > 0
                                  ? () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              OrderCreditIranPage(
                                            operatorName: operatorName,
                                            phoneNumber: phoneNumber,
                                            amount: _selectedAmount,
                                            totalPrice: _totalPrice,
                                            pricePerUnit: _pricePerUnit,
                                          ),
                                        ),
                                      );
                                    }
                                  : null,
                              icon: const Icon(Icons.shopping_cart_rounded),
                              label: Text(
                                _selectedAmount > 0
                                    ? 'تایید و خرید (${_totalPrice.toStringAsFixed(0)} تومان)'
                                    : 'مقدار شارژ را وارد کنید',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _selectedAmount > 0
                                    ? const Color(0xFF0E8A4D)
                                    : Colors.grey[400],
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  vertical: isSmallScreen ? 14 : 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: _selectedAmount > 0 ? 4 : 0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey[600],
                            ),
                            child: const Text('بازگشت'),
                          ),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildQuickButton(int amount, bool isSmallScreen) {
    return SizedBox(
      width: isSmallScreen ? 52 : 60,
      height: isSmallScreen ? 40 : 46,
      child: OutlinedButton(
        onPressed: () => _setQuickAmount(amount),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF0E8A4D),
          side: BorderSide(
            color: _selectedAmount == amount
                ? const Color(0xFF0E8A4D)
                : Colors.grey[300]!,
            width: _selectedAmount == amount ? 2 : 1,
          ),
          backgroundColor: _selectedAmount == amount
              ? const Color(0xFF0E8A4D).withOpacity(0.1)
              : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          '$amount',
          style: TextStyle(
            fontSize: isSmallScreen ? 13 : 15,
            fontWeight: FontWeight.bold,
            color: _selectedAmount == amount
                ? const Color(0xFF0E8A4D)
                : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}