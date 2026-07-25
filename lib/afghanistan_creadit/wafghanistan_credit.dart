import 'package:flutter/material.dart';
import '../afghanistan_creadit/show_credit_afghanistan.dart';

class AfghanCreditDetectorPage extends StatefulWidget {
  const AfghanCreditDetectorPage({super.key});

  @override
  State<AfghanCreditDetectorPage> createState() =>
      _AfghanCreditDetectorPageState();
}

class _AfghanCreditDetectorPageState extends State<AfghanCreditDetectorPage> {
  final TextEditingController _phoneController = TextEditingController();
  String _operatorName = '';
  String _operatorImage = '';
  Color _operatorColor = Colors.grey;

  // ============================================
  // 📌 لیست اپراتورها با عکس و پیش‌شماره
  // ============================================
  final List<Map<String, dynamic>> _operators = [
    {
      'name': 'افغان بیسیم',
      'image': 'assets/images/operators/afghan_bisim.png',
      'prefixes': ['070', '071'],
      'color': Color(0xFF1A8C3E),
    },
    {
      'name': 'روشن',
      'image': 'assets/images/operators/roshan.png',
      'prefixes': ['079', '072'],
      'color': Color(0xFFE87B2D),
    },
    {
      'name': 'اتصالات',
      'image': 'assets/images/operators/etisalat.png',
      'prefixes': ['078', '073'],
      'color': Color(0xFFC41E24),
    },
    {
      'name': 'اتوما',
      'image': 'assets/images/operators/atoma.png',
      'prefixes': ['077', '076'],
      'color': Color(0xFF00A651),
    },
    {
      'name': 'سلام',
      'image': 'assets/images/operators/salam.png',
      'prefixes': ['074'],
      'color': Color(0xFF007BFF),
    },
  ];

  // ============================================
  // 📌 تشخیص اپراتور بر اساس شماره
  // ============================================
  void detectOperator(String phoneNumber) {
    String cleaned = phoneNumber.replaceAll(RegExp(r'[\s\-]'), '');

    if (cleaned.isEmpty) {
      setState(() {
        _operatorName = '';
        _operatorImage = '';
        _operatorColor = Colors.grey;
      });
      return;
    }

    for (var op in _operators) {
      for (var prefix in op['prefixes']) {
        if (cleaned.startsWith(prefix)) {
          setState(() {
            _operatorName = op['name'];
            _operatorImage = op['image'];
            _operatorColor = op['color'];
          });
          return;
        }
      }
    }

    setState(() {
      _operatorName = 'اپراتور نامشخص';
      _operatorImage = 'assets/images/operators/unknown.png';
      _operatorColor = Colors.grey;
    });
  }

  // ============================================
  // 📌 بررسی اینکه آیا اپراتور انتخاب شده است
  // ============================================
  bool _isOperatorSelected(String operatorName) {
    return _operatorName == operatorName;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'خرید کریدیت افغانستان',
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📱 خرید کریدیت افغانستان',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0E8A4D),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'برای خرید کریدیت لطفاً شماره خود را دقیق وارد کنید',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),

            // ============================================
            // 📌 فیلد ورودی شماره
            // ============================================
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 15,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'مثال: 0701234567',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                  ),
                  prefixIcon: const Icon(
                    Icons.phone_android_rounded,
                    color: Color(0xFF0E8A4D),
                    size: 28,
                  ),
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
                onChanged: (value) {
                  detectOperator(value);
                },
              ),
            ),

            const SizedBox(height: 16),

            // ============================================
            // 📌 نمایش ۵ لوگوی اپراتور در یک ردیف
            // ============================================
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.08),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _operators.map((op) {
                  final isSelected = _isOperatorSelected(op['name']);
                  return _OperatorLogoItem(
                    imagePath: op['image'],
                    name: op['name'],
                    isSelected: isSelected,
                    color: op['color'],
                    onTap: () {
                      final prefix = op['prefixes'][0];
                      _phoneController.text = '$prefix' '1234567';
                      detectOperator(_phoneController.text);
                    },
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // ============================================
            // 📌 نمایش نتیجه با عکس
            // ============================================
            if (_operatorName.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _operatorColor.withOpacity(0.15),
                      _operatorColor.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _operatorColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          _operatorImage,
                          width: 80,
                          height: 80,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.broken_image_rounded,
                                size: 40,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _operatorName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _operatorColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'شماره شما متعلق به این اپراتور است',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey[200]!,
                  ),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.phone_android_rounded,
                      size: 60,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'شماره را وارد کنید',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'تا اپراتور شما تشخیص داده شود',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

            const Spacer(),

            // ============================================
            // 📌 دکمه تایید - رفتن به صفحه کریدیت
            // ============================================
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (_phoneController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('لطفاً شماره تماس خود را وارد کنید'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  if (_operatorName == 'اپراتور نامشخص' ||
                      _operatorName.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'شماره وارد شده معتبر نیست. لطفاً شماره صحیح را وارد کنید'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ShowCreditAfghanistanPage(
                        operatorName: _operatorName,
                        phoneNumber: _phoneController.text.trim(),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text(
                  'مشاهده کریدیت‌ها',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0E8A4D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// 📌 ویجت لوگوی هر اپراتور
// ============================================
class _OperatorLogoItem extends StatelessWidget {
  final String imagePath;
  final String name;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _OperatorLogoItem({
    required this.imagePath,
    required this.name,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isSelected ? color.withOpacity(0.15) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? color : Colors.grey[300]!,
                    width: isSelected ? 2.5 : 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    imagePath,
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Text(
                          name[0],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? color : Colors.grey[400],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (isSelected)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: TextStyle(
              fontSize: 9,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? color : Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}