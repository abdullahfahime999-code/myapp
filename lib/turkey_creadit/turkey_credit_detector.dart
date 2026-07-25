import 'package:flutter/material.dart';
import '../turkey_creadit/show_credit_turkey.dart';

class TurkeyCreditDetectorPage extends StatefulWidget {
  const TurkeyCreditDetectorPage({super.key});

  @override
  State<TurkeyCreditDetectorPage> createState() =>
      _TurkeyCreditDetectorPageState();
}

class _TurkeyCreditDetectorPageState extends State<TurkeyCreditDetectorPage> {
  final TextEditingController _phoneController = TextEditingController();
  String _operatorName = '';
  String _operatorImage = '';
  Color _operatorColor = Colors.grey;

  // اپراتورهای ترکیه
  final List<Map<String, dynamic>> _operators = [
    {
      'name': 'ترکسل',
      'image': 'assets/images/operators/turkcell.png',
      'prefixes': ['0505', '0530', '0531', '0532', '0533', '0534', '0535', '0536', '0537', '0538', '0539'],
      'color': Color(0xFFE0113A),
    },
    {
      'name': 'وودافون',
      'image': 'assets/images/operators/vodafone.png',
      'prefixes': ['0540', '0541', '0542', '0543', '0544', '0545', '0546', '0547', '0548', '0549'],
      'color': Color(0xFFE60000),
    },
    {
      'name': 'ترک تلکام',
      'image': 'assets/images/operators/turk_telekom.png',
      'prefixes': ['0550', '0551', '0552', '0553', '0554', '0555', '0556', '0557', '0558', '0559'],
      'color': Color(0xFF0066B3),
    },
  ];

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
          'خرید کریدیت ترکیه',
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
              '🇹🇷 خرید کریدیت ترکیه',
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
                  hintText: 'مثال: 05051234567',
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
                      builder: (context) => ShowCreditTurkeyPage(
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