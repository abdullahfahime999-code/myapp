import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_config.dart';
import 'orderproduct.dart'; // ✅ import صفحه سفارش

class ShowProductPage extends StatefulWidget {
  final String operatorName;
  final String phoneNumber;

  const ShowProductPage({
    super.key,
    required this.operatorName,
    required this.phoneNumber,
  });

  @override
  State<ShowProductPage> createState() => _ShowProductPageState();
}

class _ShowProductPageState extends State<ShowProductPage> {
  List<dynamic> _packages = [];
  bool _isLoading = true;
  String? _error;

  String get _operatorImage {
    final images = {
      'افغان بیسیم': 'assets/images/operators/afghan_bisim.png',
      'روشن': 'assets/images/operators/roshan.png',
      'اتصالات': 'assets/images/operators/etisalat.png',
      'اتوما': 'assets/images/operators/atoma.png',
      'سلام': 'assets/images/operators/salam.png',
    };
    return images[widget.operatorName] ?? 'assets/images/operators/unknown.png';
  }

  String _getOperatorImage(String operatorName) {
    final images = {
      'افغان بیسیم': 'assets/images/operators/afghan_bisim.png',
      'روشن': 'assets/images/operators/roshan.png',
      'اتصالات': 'assets/images/operators/etisalat.png',
      'اتوما': 'assets/images/operators/atoma.png',
      'سلام': 'assets/images/operators/salam.png',
    };
    return images[operatorName] ?? 'assets/images/operators/unknown.png';
  }

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      String url = api('/api/packages/all');
      
      if (widget.operatorName.isNotEmpty && widget.operatorName != 'اپراتور نامشخص') {
        url += '?operator=${Uri.encodeComponent(widget.operatorName)}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final allPackages = data['packages'] ?? [];
          final filteredPackages = allPackages.where((p) {
            final name = p['name'] ?? '';
            return name == 'بسته انترنت افغانستان';
          }).toList();
          
          setState(() {
            _packages = filteredPackages;
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = data['message'] ?? 'خطا در دریافت بسته‌ها';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '📦 بسته‌های ${widget.operatorName}',
          style: const TextStyle(
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
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      _operatorImage,
                      width: 50,
                      height: 50,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.broken_image_rounded,
                            size: 30,
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📱 شماره: ${widget.phoneNumber}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '📡 اپراتور: ${widget.operatorName}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

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
                        Text('در حال بارگذاری بسته‌ها...'),
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
                              onPressed: _loadPackages,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0E8A4D),
                              ),
                              child: const Text('🔄 تلاش مجدد'),
                            ),
                          ],
                        ),
                      )
                    : _packages.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inbox_rounded,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'هیچ بسته‌ای یافت نشد',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadPackages,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: _packages.length,
                              itemBuilder: (context, index) {
                                final package = _packages[index];
                                return _PackageCard(
                                  package: package,
                                  operatorImage: _getOperatorImage(
                                    package['operator'] ?? ''
                                  ),
                                  operatorName: widget.operatorName,
                                  phoneNumber: widget.phoneNumber,
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
// 📌 کارت بسته با ناوبری به صفحه سفارش
// ============================================
class _PackageCard extends StatelessWidget {
  final Map<String, dynamic> package;
  final String operatorImage;
  final String operatorName;
  final String phoneNumber;

  const _PackageCard({
    required this.package,
    required this.operatorImage,
    required this.operatorName,
    required this.phoneNumber,
  });

  @override
  Widget build(BuildContext context) {
    final operatorColors = {
      'افغان بیسیم': const Color(0xFF1A8C3E),
      'روشن': const Color(0xFFE87B2D),
      'اتصالات': const Color(0xFFC41E24),
      'اتوما': const Color(0xFF00A651),
      'سلام': const Color(0xFF007BFF),
    };

    final String packageOperator = package['operator'] ?? 'نامشخص';
    final Color color = operatorColors[packageOperator] ?? Colors.grey;
    final double price = (package['price'] ?? 0).toDouble();
    final String name = package['name'] ?? 'بدون نام';
    final String description = package['description'] ?? '';

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 380;
    final isMediumScreen = screenWidth < 600;

    final double imageSize = isSmallScreen ? 40 : 50;
    final double fontSizeName = isSmallScreen ? 10 : (isMediumScreen ? 11 : 12);
    final double fontSizeDesc = isSmallScreen ? 11 : (isMediumScreen ? 12 : 13);
    final double fontSizePrice = isSmallScreen ? 12 : (isMediumScreen ? 13 : 14);
    final double paddingH = isSmallScreen ? 10 : (isMediumScreen ? 12 : 16);
    final double paddingV = isSmallScreen ? 8 : (isMediumScreen ? 10 : 12);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              spreadRadius: 0,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: Colors.grey.shade100,
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              // ✅ رفتن به صفحه تایید سفارش
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderProductPage(
                    package: package,
                    operatorName: operatorName,
                    phoneNumber: phoneNumber,
                  ),
                ),
              );
            },
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: paddingH,
                vertical: paddingV,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ✅ عکس اپراتور
                  Container(
                    width: imageSize,
                    height: imageSize,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        operatorImage,
                        width: imageSize,
                        height: imageSize,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Text(
                              packageOperator.isNotEmpty ? packageOperator[0] : '📡',
                              style: TextStyle(
                                fontSize: imageSize * 0.4,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // ✅ اطلاعات بسته
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ✅ نام بسته
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: fontSizeName,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        
                        // ✅ توضیحات
                        Text(
                          description.isNotEmpty
                              ? description
                              : 'بسته اینترنت',
                          style: TextStyle(
                            fontSize: fontSizeDesc,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          softWrap: true,
                        ),
                        const SizedBox(height: 6),
                        
                        // ✅ قیمت
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.toll_rounded,
                              size: fontSizePrice + 2,
                              color: const Color(0xFF0E8A4D),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${price.toStringAsFixed(0)} تومان',
                              style: TextStyle(
                                fontSize: fontSizePrice,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0E8A4D),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ✅ دکمه خرید
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Container(
                      margin: const EdgeInsets.only(left: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0E8A4D).withOpacity(0.06),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () {
                          // ✅ رفتن به صفحه تایید سفارش
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrderProductPage(
                                package: package,
                                operatorName: operatorName,
                                phoneNumber: phoneNumber,
                              ),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.shopping_cart_outlined,
                          color: const Color(0xFF0E8A4D),
                          size: isSmallScreen ? 18 : 22,
                        ),
                        padding: EdgeInsets.all(isSmallScreen ? 4 : 8),
                        constraints: BoxConstraints(
                          minWidth: isSmallScreen ? 28 : 40,
                          minHeight: isSmallScreen ? 28 : 40,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}