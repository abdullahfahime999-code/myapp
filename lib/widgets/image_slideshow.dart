import 'package:flutter/material.dart';

class ImageSlideshow extends StatefulWidget {
  final List<String> images;
  final double height;
  const ImageSlideshow({super.key, required this.images, this.height = 180});
  @override
  State<ImageSlideshow> createState() => _ImageSlideshowState();
}

class _ImageSlideshowState extends State<ImageSlideshow> {
  late final PageController _controller;
  int _index = 0;
  bool _running = true;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _scheduleNext();
  }

  void _scheduleNext() {
    if (!mounted || !_running || widget.images.isEmpty) return;
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted || !_running || widget.images.isEmpty) return;
      final next = (_index + 1) % widget.images.length;
      if (_controller.hasClients) {
        _controller.animateToPage(
          next,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
      _scheduleNext();
    });
  }

  @override
  void dispose() {
    _running = false;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          SizedBox(
            height: widget.height,
            width: double.infinity,
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.images.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) => Image.network(
                widget.images[i],
                fit: BoxFit.cover,
                loadingBuilder: (c, child, p) => p == null
                    ? child
                    : Container(color: const Color(0xFFEAEAEA)),
                errorBuilder: (c, e, s) => Container(
                  color: const Color(0xFFEAEAEA),
                  alignment: Alignment.center,
                  child: const Icon(Icons.image_not_supported,
                      color: Colors.grey),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.images.length, (i) {
                final active = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active ? Colors.white : Colors.white70,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
