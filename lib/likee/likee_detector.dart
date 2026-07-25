import 'package:flutter/material.dart';
import '../likee/show_likee_credit.dart';

class LikeeDetectorPage extends StatefulWidget {
  const LikeeDetectorPage({super.key});

  @override
  State<LikeeDetectorPage> createState() => _LikeeDetectorPageState();
}

class _LikeeDetectorPageState extends State<LikeeDetectorPage> {
  final TextEditingController _likeeIdController = TextEditingController();
  String _selectedGame = '';
  String _gameImage = '';
  Color _gameColor = Colors.grey;

  // ✅ لیست گزینه‌های لایکی با عکس
  final List<Map<String, dynamic>> _games = [
    {
      'name': 'الماس لایکی',
      'image': 'assets/images/operators/likee.png',
      'color': const Color(0xFF0E8A4D),
    },
  ];

  void detectGame(String input) {
    if (input.isEmpty) {
      setState(() {
        _selectedGame = '';
        _gameImage = '';
        _gameColor = Colors.grey;
      });
      return;
    }

    // ✅ بررسی اینکه آیا ایدی وارد شده معتبر است (حداقل 4 کاراکتر)
    if (input.length >= 4) {
      setState(() {
        _selectedGame = 'الماس لایکی';
        _gameImage = 'assets/images/operators/likee.png';
        _gameColor = const Color(0xFF0E8A4D);
      });
    } else {
      setState(() {
        _selectedGame = '';
        _gameImage = '';
        _gameColor = Colors.grey;
      });
    }
  }

  bool _isGameSelected(String gameName) {
    return _selectedGame == gameName;
  }

  @override
  void dispose() {
    _likeeIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'خرید الماس لایکی',
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
              '💎 خرید الماس لایکی',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0E8A4D),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'لطفاً ایدی لایکی خود را وارد کنید',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),

            // ============================================
            // 📌 فیلد ورودی ایدی لایکی
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
                controller: _likeeIdController,
                keyboardType: TextInputType.text,
                maxLength: 30,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'ایدی لایکی خود را وارد کنید...',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                  ),
                  prefixIcon: const Icon(
                    Icons.thumb_up_rounded,
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
                  detectGame(value);
                },
              ),
            ),

            const SizedBox(height: 16),

            // ============================================
            // 📌 نمایش لوگو لایکی
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: _games.map((game) {
                  final isSelected = _isGameSelected(game['name']);
                  return _GameLogoItem(
                    imagePath: game['image'],
                    name: game['name'],
                    isSelected: isSelected,
                    color: game['color'],
                    onTap: () {
                      // ✅ با کلیک روی لوگو، یک ایدی نمونه وارد میشود
                      _likeeIdController.text = 'Likee_User_123';
                      detectGame(_likeeIdController.text);
                    },
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // ============================================
            // 📌 نمایش نتیجه با عکس
            // ============================================
            if (_selectedGame.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _gameColor.withOpacity(0.15),
                      _gameColor.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _gameColor.withOpacity(0.3),
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
                          _gameImage,
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
                      '💎 ${_selectedGame}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _gameColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ایدی شما: ${_likeeIdController.text}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '✅ ایدی شما معتبر است',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
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
                      Icons.thumb_up_rounded,
                      size: 60,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'ایدی لایکی را وارد کنید',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'تا بتوانید الماس خریداری کنید',
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
            // 📌 دکمه تایید - رفتن به صفحه خرید الماس لایکی
            // ============================================
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (_likeeIdController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('لطفاً ایدی لایکی خود را وارد کنید'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  if (_likeeIdController.text.trim().length < 4) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('ایدی لایکی باید حداقل ۴ کاراکتر باشد'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ShowLikeeCreditPage(
                        likeeId: _likeeIdController.text.trim(),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text(
                  'مشاهده الماس‌ها',
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
// 📌 ویجت لوگوی بازی
// ============================================
class _GameLogoItem extends StatelessWidget {
  final String imagePath;
  final String name;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _GameLogoItem({
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
                width: 70,
                height: 70,
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
                    width: 60,
                    height: 60,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Text(
                          name[0],
                          style: TextStyle(
                            fontSize: 24,
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