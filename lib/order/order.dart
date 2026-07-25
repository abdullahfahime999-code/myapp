import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api_config.dart';
import 'phish.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  List<dynamic> _allOrders = [];
  List<dynamic> _filteredOrders = [];
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'همه';
  final storage = const FlutterSecureStorage();

  final List<Map<String, dynamic>> _filters = [
    {'label': 'همه', 'color': Colors.grey, 'icon': Icons.apps_rounded},
    {'label': 'در انتظار', 'color': Color(0xFFF59E0B), 'icon': Icons.hourglass_empty_rounded},
    {'label': 'تکمیل شده', 'color': Color(0xFF10B981), 'icon': Icons.check_circle_rounded},
    {'label': 'لغو شده', 'color': Color(0xFFEF4444), 'icon': Icons.cancel_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
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
        Uri.parse(api('/api/orders')),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _allOrders = data['orders'] ?? [];
            _applyFilter();
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = data['message'] ?? 'خطا در دریافت سفارشات';
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

  void _applyFilter() {
    setState(() {
      if (_selectedFilter == 'همه') {
        _filteredOrders = List.from(_allOrders);
      } else if (_selectedFilter == 'در انتظار') {
        _filteredOrders = _allOrders.where((o) => o['status'] == 'pending').toList();
      } else if (_selectedFilter == 'تکمیل شده') {
        _filteredOrders = _allOrders.where((o) => o['status'] == 'completed').toList();
      } else if (_selectedFilter == 'لغو شده') {
        _filteredOrders = _allOrders.where((o) => o['status'] == 'cancelled').toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 380;
    final isMediumScreen = screenWidth < 500;

    final double filterPaddingH = isSmallScreen ? 8 : (isMediumScreen ? 10 : 14);
    final double filterPaddingV = isSmallScreen ? 5 : (isMediumScreen ? 6 : 8);
    final double filterFontSize = isSmallScreen ? 10 : (isMediumScreen ? 11 : 12);
    final double filterIconSize = isSmallScreen ? 12 : (isMediumScreen ? 14 : 16);
    final double filterDotSize = isSmallScreen ? 5 : (isMediumScreen ? 6 : 7);
    final double filterSpacing = isSmallScreen ? 3 : (isMediumScreen ? 4 : 6);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          ' سفارشات من',
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
      body: Column(
        children: [
          // فیلترها
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 4 : 8,
              vertical: isSmallScreen ? 4 : 6,
            ),
            color: Colors.grey[50],
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: _filters.map((filter) {
                  final isSelected = _selectedFilter == filter['label'];
                  final Color color = filter['color'];
                  final IconData icon = filter['icon'];
                  
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: filterSpacing),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedFilter = filter['label'];
                          _applyFilter();
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: EdgeInsets.symmetric(
                          horizontal: filterPaddingH,
                          vertical: filterPaddingV,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isSelected
                                ? [
                                    color.withOpacity(0.30),
                                    color.withOpacity(0.15),
                                    Colors.white.withOpacity(0.50),
                                  ]
                                : [
                                    Colors.white.withOpacity(0.50),
                                    Colors.white.withOpacity(0.20),
                                    Colors.white.withOpacity(0.10),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? color.withOpacity(0.50)
                                : Colors.grey.shade300.withOpacity(0.30),
                            width: isSelected ? 1.5 : 0.8,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withOpacity(0.25),
                                    blurRadius: 14,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 4),
                                  ),
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.40),
                                    blurRadius: 10,
                                    spreadRadius: -2,
                                    offset: const Offset(-2, -2),
                                  ),
                                ]
                              : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 6,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              icon,
                              size: filterIconSize,
                              color: isSelected ? color : Colors.grey[400],
                            ),
                            SizedBox(width: isSmallScreen ? 3 : 5),
                            Text(
                              filter['label'],
                              style: TextStyle(
                                fontSize: filterFontSize,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? color : Colors.grey[600],
                                letterSpacing: 0.2,
                              ),
                            ),
                            SizedBox(width: isSmallScreen ? 3 : 5),
                            Container(
                              width: filterDotSize,
                              height: filterDotSize,
                              decoration: BoxDecoration(
                                color: isSelected ? color : color.withOpacity(0.25),
                                shape: BoxShape.circle,
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: color.withOpacity(0.50),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // شمارش سفارشات
          if (!_isLoading && _error == null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_filteredOrders.length} سفارش',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_selectedFilter != 'همه')
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedFilter = 'همه';
                          _applyFilter();
                        });
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF0E8A4D),
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 30),
                      ),
                      child: const Text('نمایش همه'),
                    ),
                ],
              ),
            ),

          // لیست سفارشات
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: Color(0xFF0E8A4D),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'در حال بارگذاری سفارشات...',
                          style: TextStyle(color: Colors.grey),
                        ),
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
                              style: const TextStyle(color: Colors.red, fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadOrders,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0E8A4D),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('🔄 تلاش مجدد'),
                            ),
                          ],
                        ),
                      )
                    : _filteredOrders.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inbox_rounded,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _selectedFilter == 'همه'
                                      ? 'هیچ سفارشی یافت نشد'
                                      : 'هیچ سفارش $_selectedFilter یافت نشد',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _selectedFilter == 'همه'
                                      ? 'شما هنوز سفارشی ثبت نکرده‌اید'
                                      : 'سفارشی با این وضعیت وجود ندارد',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadOrders,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: _filteredOrders.length,
                              itemBuilder: (context, index) {
                                final order = _filteredOrders[index];
                                return _OrderCard(
                                  order: order,
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// 📌 کارت نمایش سفارش (بر اساس category)
// ============================================
class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;

  const _OrderCard({
    required this.order,
  });

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

  // ✅ دریافت category از دیتابیس
  String _getCategory() {
    return order['category'] ?? '';
  }

  // ✅ تشخیص اینکه بسته بازی هست یا نه
  bool _isGame() {
    final category = _getCategory();
    return category == 'pubg' || category == 'likee' || category == 'imo';
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
        return _getOperatorImage(order['operator'] ?? '');
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
        return _getOperatorColor(order['operator'] ?? '');
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
        return order['operator'] ?? 'نامشخص';
    }
  }

  Color _getOperatorColor(String operator) {
    final colors = {
      'افغان بیسیم': const Color(0xFF1A8C3E),
      'روشن': const Color(0xFFE87B2D),
      'اتصالات': const Color(0xFFC41E24),
      'اتوما': const Color(0xFF00A651),
      'سلام': const Color(0xFF007BFF),
      'ایرانسل': const Color(0xFF6C2BD9),
      'رایتل': const Color(0xFFE91E63),
      'همراه اول': const Color(0xFF00BCD4),
      'ترکسل': const Color(0xFFE0113A),
      'وودافون': const Color(0xFFE60000),
      'ترک تلکام': const Color(0xFF0066B3),
    };
    return colors[operator] ?? Colors.grey;
  }

  String _getOperatorImage(String operator) {
    final images = {
      'افغان بیسیم': 'assets/images/operators/afghan_bisim.png',
      'روشن': 'assets/images/operators/roshan.png',
      'اتصالات': 'assets/images/operators/etisalat.png',
      'اتوما': 'assets/images/operators/atoma.png',
      'سلام': 'assets/images/operators/salam.png',
      'ایرانسل': 'assets/images/operators/iran_cell.png',
      'رایتل': 'assets/images/operators/rightel.png',
      'همراه اول': 'assets/images/operators/hamrahe_aval.png',
      'ترکسل': 'assets/images/operators/turkcell.png',
      'وودافون': 'assets/images/operators/vodafone.png',
      'ترک تلکام': 'assets/images/operators/turk_telekom.png',
    };
    return images[operator] ?? 'assets/images/operators/unknown.png';
  }

  // ✅ دریافت لیبل مناسب برای نمایش (ایدی یا شماره تماس)
  String _getDisplayLabel() {
    final category = _getCategory();
    
    switch (category) {
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

  // ✅ دریافت مقدار نمایشی (ایدی یا شماره تماس)
  String _getDisplayValue() {
    final category = _getCategory();
    final phoneNumber = order['phone_number'] ?? '';
    final pubgId = order['pubg_id'] ?? '';
    
    switch (category) {
      case 'pubg':
        return pubgId.isNotEmpty ? pubgId : '---';
      case 'likee':
      case 'imo':
        return phoneNumber.isNotEmpty ? phoneNumber : '---';
      default:
        return phoneNumber.isNotEmpty ? phoneNumber : '---';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String status = order['status'] ?? 'pending';
    final Color statusColor = _getStatusColor(status);
    final String statusText = _getStatusText(status);
    final IconData statusIcon = _getStatusIcon(status);
    final double price = (order['price'] ?? 0).toDouble();
    final String packageName = order['package_name'] ?? 'بدون نام';
    
    // ✅ تشخیص بر اساس category
    final bool isGame = _isGame();
    final String packageImage = _getPackageImage();
    final Color packageColor = _getPackageColor();
    final String packageDisplayName = _getPackageDisplayName();
    
    // ✅ دریافت تاریخ و ساعت
    final String createdAtJalali = order['created_at_jalali'] ?? '';
    final String createdAtTime = order['created_at_time'] ?? '';
    final String createdAtFull = order['created_at_full'] ?? '';

    String displayDateTime = createdAtFull;
    if (displayDateTime.isEmpty && createdAtJalali.isNotEmpty) {
      displayDateTime = createdAtJalali;
      if (createdAtTime.isNotEmpty) {
        displayDateTime += ' - $createdAtTime';
      }
    }

    final String displayLabel = _getDisplayLabel();
    final String displayValue = _getDisplayValue();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PhishPage(
                order: order,
                currentTime: createdAtTime,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ عکس بر اساس category
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isGame 
                      ? packageColor.withOpacity(0.10)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isGame
                        ? packageColor.withOpacity(0.20)
                        : _getOperatorColor(order['operator'] ?? '').withOpacity(0.20),
                    width: 1.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    packageImage,
                    width: 56,
                    height: 56,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade100,
                        child: Center(
                          child: isGame 
                              ? const Text('🎮', style: TextStyle(fontSize: 28))
                              : Text(
                                  order['operator']?.isNotEmpty == true 
                                      ? order['operator']![0] 
                                      : '📡',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: _getOperatorColor(order['operator'] ?? ''),
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // اطلاعات سفارش
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            packageName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
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
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    
                    // ✅ نمایش نوع بسته (بر اساس category)
                    Row(
                      children: [
                        Icon(
                          isGame ? Icons.games_rounded : Icons.signal_cellular_alt_rounded,
                          size: 14,
                          color: packageColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          packageDisplayName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: packageColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.toll_rounded,
                          size: 14,
                          color: const Color(0xFF0E8A4D),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${price.toStringAsFixed(0)} تومان',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0E8A4D),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // ✅ نمایش ایدی یا شماره تماس (بر اساس category)
                    Row(
                      children: [
                        Icon(
                          isGame ? Icons.games_rounded : Icons.phone_android_rounded,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          displayValue,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(' + displayLabel.replaceAll('🆔 ', '').replaceAll('📱 ', '') + ')',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // ✅ تاریخ و ساعت
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            displayDateTime.isNotEmpty ? displayDateTime : 'زمان ثبت نشده',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}