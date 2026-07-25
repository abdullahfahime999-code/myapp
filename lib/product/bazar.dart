import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'wafghnistanin.dart';
import '../irproduct/wiranin.dart'; // ✅ اضافه کردن صفحه ایران
import '../afghanistan_creadit/wafghanistan_credit.dart'; // ✅ اضافه کردن صفحه کریدیت افغانستان
import '../iran_creadit/iran_credit_detector.dart'; // ✅ اضافه کردن صفحه کریدیت ایران
import '../turkey_creadit/turkey_credit_detector.dart'; // ✅ اضافه کردن صفحه کریدیت ترکیه
import '../pubg/pubg_detector.dart'; // ✅ اضافه کردن صفحه یوسی پابجی
import '../imo/imo_detector.dart'; // ✅ اضافه کردن صفحه الماس ایمو
import '../likee/likee_detector.dart'; // ✅ اضافه کردن صفحه الماس لایکی

class BazarPage extends StatelessWidget {
  const BazarPage({super.key});

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFF0E8A4D);
    const brandSeed = Color(0xFF38C172);

    final productCategories = [
      {'title': 'بسته های افغانستان', 'icon': 'afghanistan.svg', 'route': '/afghanistan'},
      {'title': 'کریدیت افغانستان', 'icon': 'afghanistan.svg', 'route': '/afghanistan_credit'},
      {'title': 'بسته های ایران', 'icon': 'iran.svg', 'route': '/iran'},
      {'title': 'کریدیت ایران', 'icon': 'iran.svg', 'route': '/iran_credit'},
      {'title': 'کریدیت ترکیه', 'icon': 'turkey.svg', 'route': '/turkey_credit'},
      {'title': 'یوسی پابجی', 'icon': 'pubg.svg', 'route': '/pubg'},
      {'title': 'الماس ایمو', 'icon': 'imo.svg', 'route': '/imo'},
      {'title': 'الماس لایکی', 'icon': 'likee.svg', 'route': '/likee'},
    ];

    final gameCategories = [
      {'title': 'الماس متیک فورج', 'icon': 'dimond-alt-fill.svg'},
      {'title': 'Party Star', 'icon': 'star-outline.svg'},
      {'title': 'Play Station', 'icon': 'playstation.svg'},
      {'title': 'سکه کالاف دیتوی', 'icon': 'call-of-duty.svg'},
      {'title': 'فری فایر', 'icon': 'free-fire.svg'},
      {'title': 'Popplive', 'icon': 'huya-live.svg'},
    ];

    final networkCategories = [
      {'title': 'بسته ارتباط', 'icon': 'irtbat.svg'},
      {'title': 'بسته برقرار', 'icon': 'barqara.svg'},
      {'title': 'بسته رخ', 'icon': 'rakh.svg'},
      {'title': 'بسته میزبان', 'icon': 'home.svg'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'بازار',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: brandColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [brandColor, brandSeed],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        color: Colors.grey[50],
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              
              // ========== بخش بسته‌ها ==========
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '📦 بسته‌ها',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: brandColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${productCategories.length} آیتم',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: brandColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Grid بسته‌ها
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: productCategories.length,
                  itemBuilder: (context, index) {
                    final product = productCategories[index];
                    return _ModernProductCard(
                      title: product['title'] as String,
                      iconPath: product['icon'] as String,
                      onTap: () {
                        // ============================================
                        // ✅ تشخیص مسیر بر اساس عنوان
                        // ============================================
                        if (product['title'] == 'بسته های افغانستان') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const OperatorDetectorPage(),
                            ),
                          );
                        } else if (product['title'] == 'کریدیت افغانستان') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AfghanCreditDetectorPage(),
                            ),
                          );
                        } else if (product['title'] == 'بسته های ایران') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const IranOperatorDetectorPage(),
                            ),
                          );
                        } else if (product['title'] == 'کریدیت ایران') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const IranCreditDetectorPage(),
                            ),
                          );
                        } else if (product['title'] == 'کریدیت ترکیه') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TurkeyCreditDetectorPage(),
                            ),
                          );
                        } else if (product['title'] == 'یوسی پابجی') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PubgDetectorPage(),
                            ),
                          );
                        } else if (product['title'] == 'الماس ایمو') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ImoDetectorPage(),
                            ),
                          );
                        } else if (product['title'] == 'الماس لایکی') {
                          // ✅ رفتن به صفحه الماس لایکی
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LikeeDetectorPage(),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${product['title']} انتخاب شد',
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor: brandColor,
                              duration: const Duration(milliseconds: 600),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 24),
              
              // ========== بخش بازی‌ها و سرگرمی‌ها ==========
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '🎮 بازی‌ها و سرگرمی‌ها',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: brandColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${gameCategories.length} آیتم',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: brandColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Grid بازی‌ها
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: gameCategories.length,
                  itemBuilder: (context, index) {
                    final game = gameCategories[index];
                    return _ModernProductCard(
                      title: game['title'] as String,
                      iconPath: game['icon'] as String,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${game['title']} انتخاب شد',
                              style: const TextStyle(color: Colors.white),
                            ),
                            backgroundColor: brandColor,
                            duration: const Duration(milliseconds: 600),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 24),
              
              // ========== بخش شبکه‌های بین‌المللی ==========
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '🌍 شبکه‌های بین‌المللی',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: brandColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${networkCategories.length} آیتم',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: brandColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Grid شبکه‌های بین‌المللی
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: networkCategories.length,
                  itemBuilder: (context, index) {
                    final network = networkCategories[index];
                    return _ModernProductCard(
                      title: network['title'] as String,
                      iconPath: network['icon'] as String,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${network['title']} انتخاب شد',
                              style: const TextStyle(color: Colors.white),
                            ),
                            backgroundColor: brandColor,
                            duration: const Duration(milliseconds: 600),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModernProductCard extends StatelessWidget {
  final String title;
  final String iconPath;
  final VoidCallback onTap;

  const _ModernProductCard({
    required this.title,
    required this.iconPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFF0E8A4D);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: brandColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: SvgPicture.asset(
                    'assets/svg/$iconPath',
                    width: 24,
                    height: 24,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF2D3436),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}