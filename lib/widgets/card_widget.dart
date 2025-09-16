import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../models/card.dart' as models;

class CardWidget extends StatelessWidget {
  final models.Card card;
  final Function(String) onAction;

  const CardWidget({
    super.key,
    required this.card,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFFE0E0E0),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          child: Stack(
          children: [
            // Card image
            CachedNetworkImage(
              imageUrl: card.imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              placeholder: (context, url) => Container(
                color: Colors.grey[300],
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(
                    Icons.error,
                    color: Colors.red,
                    size: 50,
                  ),
                ),
              ),
            ),
            // Gradient overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
            ),
            // Card info
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.occasion,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    card.locale.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Action buttons
            Positioned(
              right: 20,
              bottom: 20,
              child: Column(
                children: [
                  _ActionButton(
                    icon: Icons.favorite_border,
                    activeIcon: Icons.favorite,
                    onTap: () => onAction('like'),
                    activeColor: Colors.red,
                    inactiveColor: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  _ActionButton(
                    icon: Icons.share,
                    onTap: () {
                      onAction('share');
                      _shareCard();
                    },
                    activeColor: Colors.green,
                    inactiveColor: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  _ActionButton(
                    icon: Icons.skip_next,
                    onTap: () => onAction('next'),
                    activeColor: Colors.blue,
                    inactiveColor: Colors.white,
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

  void _shareCard() {
    Share.share(
      'Check out this amazing ${card.occasion} greeting card!',
      subject: 'Greeting Card',
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final IconData? activeIcon;
  final VoidCallback onTap;
  final Color? activeColor;
  final Color? inactiveColor;

  const _ActionButton({
    required this.icon,
    this.activeIcon,
    required this.onTap,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;
  bool _isActive = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _colorAnimation = ColorTween(
      begin: widget.inactiveColor ?? Colors.white,
      end: widget.activeColor ?? Colors.red,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap() {
    setState(() {
      _isActive = !_isActive;
    });
    
    if (_isActive) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
    
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _isActive && widget.activeIcon != null 
                    ? widget.activeIcon! 
                    : widget.icon,
                color: _colorAnimation.value,
                size: 24,
              ),
            ),
          );
        },
      ),
    );
  }
}
