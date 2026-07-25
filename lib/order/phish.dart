import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class PhishPage extends StatefulWidget {
  final Map<String, dynamic> order;
  final String currentTime;

  const PhishPage({
    super.key,
    required this.order,
    required this.currentTime,
  });

  @override
  State<PhishPage> createState() => _PhishPageState();
}

class _PhishPageState extends State<PhishPage> {
  String _userName = '';
  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    try {
      final userData = await storage.read(key: 'user');
      if (userData != null) {
        final user = json.decode(userData);
        final firstName = user['first_name'] ?? '';
        final lastName = user['last_name'] ?? '';
        setState(() {
          _userName = '$firstName $lastName'.trim();
        });
      }
    } catch (e) {
      setState(() {
        _userName = widget.order['user_name'] ?? widget.order['first_name'] ?? '';
      });
    }
  }

  String _formatPrice(double price) {
    final parts = price.toStringAsFixed(0).split('');
    String result = '';
    int count = 0;
    for (int i = parts.length - 1; i >= 0; i--) {
      result = parts[i] + result;
      count++;
      if (count % 3 == 0 && i != 0) {
        result = ',' + result;
      }
    }
    return result;
  }

  // ✅ دریافت category از دیتابیس
  String _getCategory() {
    return widget.order['category'] ?? '';
  }

  // ✅ تشخیص نوع بسته بر اساس category
  String _getPackageType() {
    final category = _getCategory();
    
    if (category == 'pubg') {
      return 'pubg';
    } else if (category == 'likee') {
      return 'likee';
    } else if (category == 'imo') {
      return 'imo';
    }
    return 'other';
  }

  // ✅ دریافت تصویر مناسب بر اساس category
  String _getPackageImage() {
    final category = _getCategory();
    
    switch (category) {
      case 'pubg':
        return 'assets/images/operators/pubg.png';
      case 'likee':
        return 'assets/images/operators/likee.png';
      case 'imo':
        return 'assets/images/operators/imo.png';
      default:
        return _getOperatorImage(widget.order['operator'] ?? '');
    }
  }

  // ✅ دریافت رنگ مناسب بر اساس category
  Color _getPackageColor() {
    final category = _getCategory();
    
    switch (category) {
      case 'pubg':
        return const Color(0xFFE65100);
      case 'likee':
        return const Color(0xFF0E8A4D);
      case 'imo':
        return const Color(0xFF1565C0);
      default:
        return _getOperatorColor(widget.order['operator'] ?? '');
    }
  }

  // ✅ دریافت نام نمایشی بر اساس category
  String _getPackageDisplayName() {
    final category = _getCategory();
    
    switch (category) {
      case 'pubg':
        return 'پابجی';
      case 'likee':
        return 'لایکی';
      case 'imo':
        return 'ایمو';
      default:
        return widget.order['operator'] ?? 'اپراتور نامشخص';
    }
  }

  // ✅ تشخیص اینکه بسته بازی هست یا نه
  bool _isGame() {
    final category = _getCategory();
    return category == 'pubg' || category == 'likee' || category == 'imo';
  }

  String _getOperatorImage(String operator) {
    final images = {
      // افغانستان
      'افغان بیسیم': 'assets/images/operators/afghan_bisim.png',
      'روشن': 'assets/images/operators/roshan.png',
      'اتصالات': 'assets/images/operators/etisalat.png',
      'اتوما': 'assets/images/operators/atoma.png',
      'سلام': 'assets/images/operators/salam.png',
      // ایران
      'ایرانسل': 'assets/images/operators/iran_cell.png',
      'رایتل': 'assets/images/operators/rightel.png',
      'همراه اول': 'assets/images/operators/hamrahe_aval.png',
      // ترکیه
      'ترکسل': 'assets/images/operators/turkcell.png',
      'وودافون': 'assets/images/operators/vodafone.png',
      'ترک تلکام': 'assets/images/operators/turk_telekom.png',
    };
    return images[operator] ?? 'assets/images/operators/unknown.png';
  }

  // ✅ دریافت مقدار نمایشی (ایدی یا شماره تماس)
  String _getDisplayValue() {
    final packageType = _getPackageType();
    final phoneNumber = widget.order['phone_number'] ?? '';
    final pubgId = widget.order['pubg_id'] ?? '';
    
    switch (packageType) {
      case 'pubg':
        return pubgId.isNotEmpty ? pubgId : '---';
      case 'likee':
      case 'imo':
        return phoneNumber.isNotEmpty ? phoneNumber : '---';
      default:
        return phoneNumber.isNotEmpty ? phoneNumber : '---';
    }
  }

  // ✅ دریافت لیبل مناسب
  String _getDisplayLabel() {
    final packageType = _getPackageType();
    
    switch (packageType) {
      case 'pubg':
        return '🆔 ایدی پابجی';
      case 'likee':
        return '🆔 ایدی لایکی';
      case 'imo':
        return '🆔 ایدی ایمو';
      default:
        return '📱 شماره تماس';
    }
  }

  // ✅ دریافت آیکون مناسب
  IconData _getDisplayIcon() {
    final packageType = _getPackageType();
    
    switch (packageType) {
      case 'pubg':
        return Icons.games_rounded;
      case 'likee':
        return Icons.thumb_up_rounded;
      case 'imo':
        return Icons.chat_rounded;
      default:
        return Icons.phone_android_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String status = widget.order['status'] ?? 'pending';
    final double price = (widget.order['price'] ?? 0).toDouble();
    final String packageName = widget.order['package_name'] ?? 'بدون نام';
    final String operator = widget.order['operator'] ?? '';
    final String description = widget.order['description'] ?? '';
    final String createdAtJalali = widget.order['created_at_jalali'] ?? '';
    final String createdAtTime = widget.order['created_at_time'] ?? '';
    final String rejectionReason = widget.order['rejection_reason'] ?? '';
    
    final Color statusColor = _getStatusColor(status);
    final String statusText = _getStatusText(status);
    final IconData statusIcon = _getStatusIcon(status);
    
    // ✅ دریافت اطلاعات بر اساس category
    final bool isGame = _isGame();
    final String packageImage = _getPackageImage();
    final Color packageColor = _getPackageColor();
    final String packageDisplayName = _getPackageDisplayName();

    // ✅ دریافت اطلاعات نمایشی
    final String displayValue = _getDisplayValue();
    final String displayLabel = _getDisplayLabel();
    final IconData displayIcon = _getDisplayIcon();

    const Color iconColor = Color(0xFF0E8A4D);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'فیش سفارش',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            fontFamily: 'Vazir',
          ),
        ),
        backgroundColor: const Color(0xFF0E8A4D),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200.withOpacity(0.08),
                      blurRadius: 16,
                      spreadRadius: 0,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.grey.shade100,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ============================================
                    // 📌 هدر فیش
                    // ============================================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.receipt_long_rounded,
                              size: 20,
                              color: iconColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'فیش سفارش',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: iconColor,
                                fontFamily: 'Vazir',
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: statusColor.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                statusIcon,
                                size: 12,
                                color: statusColor,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                statusText,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor,
                                  fontFamily: 'Vazir',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ============================================
                    // 📌 عکس بر اساس category
                    // ============================================
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isGame 
                                ? packageColor.withOpacity(0.10)
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isGame
                                  ? packageColor.withOpacity(0.20)
                                  : Colors.grey.shade200,
                              width: 1.5,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              packageImage,
                              width: 48,
                              height: 48,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade100,
                                  child: Center(
                                    child: isGame 
                                        ? const Text('🎮', style: TextStyle(fontSize: 24))
                                        : Text(
                                            operator.isNotEmpty ? operator[0] : '?',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: iconColor,
                                              fontFamily: 'Vazir',
                                            ),
                                          ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                packageName,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade900,
                                  fontFamily: 'Vazir',
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: packageColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    packageDisplayName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: packageColor,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Vazir',
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

                    // ============================================
                    // ✅ نام کاربر
                    // ============================================
                    if (_userName.isNotEmpty) ...[
                      _buildInfoRow(
                        Icons.person_rounded,
                        'نام کاربر',
                        _userName,
                        iconColor,
                      ),
                      const SizedBox(height: 8),
                      _buildDivider(),
                      const SizedBox(height: 8),
                    ],

                    // ============================================
                    // 📌 ایدی / شماره تماس (بر اساس نوع بسته)
                    // ============================================
                    _buildInfoRow(
                      displayIcon,
                      displayLabel,
                      displayValue,
                      iconColor,
                    ),
                    const SizedBox(height: 8),
                    _buildDivider(),
                    const SizedBox(height: 8),

                    // ============================================
                    // 📌 قیمت بسته
                    // ============================================
                    _buildInfoRow(
                      Icons.price_change_rounded,
                      'قیمت بسته',
                      '${_formatPrice(price)} تومان',
                      iconColor,
                    ),
                    const SizedBox(height: 8),
                    _buildDivider(),
                    const SizedBox(height: 8),

                    // ============================================
                    // 📌 مبلغ کم شده از حساب
                    // ============================================
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.remove_circle_rounded,
                                size: 16,
                                color: Colors.red.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'مبلغ کم شده از حساب',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Vazir',
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '- ${_formatPrice(price)} تومان',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                              fontFamily: 'Vazir',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDivider(),
                    const SizedBox(height: 8),

                    // ============================================
                    // 📌 علت رد (اگر سفارش رد شده باشد)
                    // ============================================
                    if (status == 'cancelled' && rejectionReason.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.comment_rounded,
                              size: 16,
                              color: Colors.red.shade700,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'علت رد سفارش',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Vazir',
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    rejectionReason,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red.shade700,
                                      fontFamily: 'Vazir',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildDivider(),
                      const SizedBox(height: 8),
                    ],

                    // ============================================
                    // 📌 توضیحات بسته
                    // ============================================
                    _buildDescriptionRow(
                      Icons.description_rounded,
                      'توضیحات',
                      description,
                      iconColor,
                    ),
                    const SizedBox(height: 8),
                    _buildDivider(),
                    const SizedBox(height: 8),

                    // ============================================
                    // 📌 تاریخ و ساعت
                    // ============================================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 14,
                              color: iconColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              createdAtJalali.isNotEmpty ? createdAtJalali : 'تاریخ ثبت نشده',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontFamily: 'Vazir',
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: iconColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              createdAtTime.isNotEmpty ? createdAtTime : widget.currentTime,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontFamily: 'Vazir',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildDivider(),
                    const SizedBox(height: 8),

                    // ============================================
                    // 📌 فوتر
                    // ============================================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.print_rounded,
                              size: 12,
                              color: iconColor.withOpacity(0.5),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'چاپ شده در',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade400,
                                fontFamily: 'Vazir',
                              ),
                            ),
                          ],
                        ),
                        Text(
                          widget.currentTime,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                            fontFamily: 'Vazir',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        'با تشکر از انتخاب شما',
                        style: TextStyle(
                          fontSize: 11,
                          color: iconColor.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Vazir',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ============================================
            // 📌 دکمه‌ها
            // ============================================
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('بازگشت'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: iconColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: iconColor),
                      textStyle: const TextStyle(
                        fontFamily: 'Vazir',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('فیش با موفقیت ارسال شد'),
                          backgroundColor: Color(0xFF0E8A4D),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text('اشتراک‌گذاری'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: iconColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontFamily: 'Vazir',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // 📌 ویجت‌های کمکی
  // ============================================
  
  Widget _buildInfoRow(IconData icon, String label, String value, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: iconColor,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Vazir',
                ),
              ),
            ],
          ),
          Text(
            value.isNotEmpty ? value : '---',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
              fontFamily: 'Vazir',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionRow(IconData icon, String label, String value, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: iconColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
              fontFamily: 'Vazir',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'بدون توضیحات',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
                fontFamily: 'Vazir',
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.grey.shade200,
      thickness: 0.8,
      height: 1,
    );
  }

  Color _getOperatorColor(String operator) {
    final colors = {
      // افغانستان
      'افغان بیسیم': const Color(0xFF1A8C3E),
      'روشن': const Color(0xFFE87B2D),
      'اتصالات': const Color(0xFFC41E24),
      'اتوما': const Color(0xFF00A651),
      'سلام': const Color(0xFF007BFF),
      // ایران
      'ایرانسل': const Color(0xFF6C2BD9),
      'رایتل': const Color(0xFFE91E63),
      'همراه اول': const Color(0xFF00BCD4),
      // ترکیه
      'ترکسل': const Color(0xFFE0113A),
      'وودافون': const Color(0xFFE60000),
      'ترک تلکام': const Color(0xFF0066B3),
    };
    return colors[operator] ?? Colors.grey;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'completed':
        return const Color(0xFF10B981);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'در انتظار تایید';
      case 'completed':
        return 'تکمیل شده';
      case 'cancelled':
        return 'لغو شده';
      default:
        return status;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty_rounded;
      case 'completed':
        return Icons.check_circle_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.info_rounded;
    }
  }
}