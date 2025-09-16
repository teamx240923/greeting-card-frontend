import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../models/card.dart' as models;

class EnhancedCardWidget extends StatelessWidget {
  final models.Card card;
  final Function(String) onAction;

  const EnhancedCardWidget({
    super.key,
    required this.card,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Media content based on type
            _buildMediaContent(context),
            
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
            
            // Media type indicator
            Positioned(
              top: 20,
              left: 20,
              child: _buildMediaTypeIndicator(),
            ),
            
            // Duration indicator for video/audio
            if (card.duration != null)
              Positioned(
                top: 20,
                right: 20,
                child: _buildDurationIndicator(),
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
                  Row(
                    children: [
                      Text(
                        card.locale.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildMediaTypeChip(),
                    ],
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
                    icon: Icons.thumb_down_outlined,
                    activeIcon: Icons.thumb_down,
                    onTap: () => onAction('dislike'),
                    activeColor: Colors.grey[600],
                    inactiveColor: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  _ActionButton(
                    icon: Icons.bookmark_border,
                    activeIcon: Icons.bookmark,
                    onTap: () => onAction('save'),
                    activeColor: Colors.purple,
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
            
            // Play button for video/audio
            if (card.mediaType != models.MediaType.image)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    card.mediaType == models.MediaType.video 
                        ? Icons.play_arrow 
                        : Icons.volume_up,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaContent(BuildContext context) {
    switch (card.mediaType) {
      case models.MediaType.image:
        return CachedNetworkImage(
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
        );
      
      case models.MediaType.video:
        return Stack(
          children: [
            // Video thumbnail
            CachedNetworkImage(
              imageUrl: card.thumbUrl.isNotEmpty ? card.thumbUrl : card.imageUrl,
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
                    Icons.video_library,
                    color: Colors.grey,
                    size: 50,
                  ),
                ),
              ),
            ),
            // Video overlay
            Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ],
        );
      
      case models.MediaType.audio:
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF4A148C),
                const Color(0xFF1A237E),
                const Color(0xFF0D47A1),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.music_note,
                  size: 80,
                  color: Colors.white.withOpacity(0.8),
                ),
                const SizedBox(height: 16),
                Text(
                  'Audio Content',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (card.thumbUrl.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: card.thumbUrl,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey[300],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.album,
                          color: Colors.grey,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
    }
  }

  Widget _buildMediaTypeIndicator() {
    Color color;
    IconData icon;
    String text;
    
    switch (card.mediaType) {
      case models.MediaType.image:
        color = Colors.blue;
        icon = Icons.image;
        text = 'IMAGE';
        break;
      case models.MediaType.video:
        color = Colors.red;
        icon = Icons.videocam;
        text = 'VIDEO';
        break;
      case models.MediaType.audio:
        color = Colors.purple;
        icon = Icons.audiotrack;
        text = 'AUDIO';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaTypeChip() {
    Color color;
    IconData icon;
    
    switch (card.mediaType) {
      case models.MediaType.image:
        color = Colors.blue;
        icon = Icons.image;
        break;
      case models.MediaType.video:
        color = Colors.red;
        icon = Icons.videocam;
        break;
      case models.MediaType.audio:
        color = Colors.purple;
        icon = Icons.audiotrack;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            card.mediaType.name.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationIndicator() {
    if (card.duration == null) return const SizedBox.shrink();
    
    final minutes = card.duration!.inMinutes;
    final seconds = card.duration!.inSeconds % 60;
    final durationText = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        durationText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _shareCard() {
    Share.share(
      'Check out this ${card.mediaType.name} greeting card: ${card.occasion}',
      subject: 'Greeting Card - ${card.occasion}',
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
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
