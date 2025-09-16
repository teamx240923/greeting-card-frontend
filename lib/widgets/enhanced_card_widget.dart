import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import '../models/card.dart' as models;

class EnhancedCardWidget extends StatefulWidget {
  final models.Card card;
  final Function(String) onAction;

  const EnhancedCardWidget({
    super.key,
    required this.card,
    required this.onAction,
  });

  @override
  State<EnhancedCardWidget> createState() => _EnhancedCardWidgetState();
}

class _EnhancedCardWidgetState extends State<EnhancedCardWidget> {
  final GlobalKey _repaintBoundaryKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _repaintBoundaryKey,
      child: Container(
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
            if (widget.card.duration != null)
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
                    widget.card.occasion,
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
                        widget.card.locale.toUpperCase(),
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
                    onTap: () => widget.onAction('like'),
                    activeColor: Colors.red,
                    inactiveColor: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  _ActionButton(
                    icon: Icons.thumb_down_outlined,
                    activeIcon: Icons.thumb_down,
                    onTap: () => widget.onAction('dislike'),
                    activeColor: Colors.grey[600],
                    inactiveColor: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  _ActionButton(
                    icon: Icons.bookmark_border,
                    activeIcon: Icons.bookmark,
                    onTap: () => widget.onAction('save'),
                    activeColor: Colors.purple,
                    inactiveColor: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  _ActionButton(
                    icon: Icons.share,
                    onTap: () async {
                      widget.onAction('share');
                      await _shareCard(context);
                    },
                    activeColor: Colors.green,
                    inactiveColor: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  _ActionButton(
                    icon: Icons.skip_next,
                    onTap: () => widget.onAction('next'),
                    activeColor: Colors.blue,
                    inactiveColor: Colors.white,
                  ),
                ],
              ),
            ),
            
            // Play button for video/audio
            if (widget.card.mediaType != models.MediaType.image)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.card.mediaType == models.MediaType.video 
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
    ));
  }

  Widget _buildMediaContent(BuildContext context) {
    switch (widget.card.mediaType) {
      case models.MediaType.image:
        return CachedNetworkImage(
          imageUrl: widget.card.imageUrl,
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
              imageUrl: widget.card.thumbUrl.isNotEmpty ? widget.card.thumbUrl : widget.card.imageUrl,
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
                if (widget.card.thumbUrl.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: widget.card.thumbUrl,
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
    
    switch (widget.card.mediaType) {
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
    
    switch (widget.card.mediaType) {
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
            widget.card.mediaType.name.toUpperCase(),
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
    if (widget.card.duration == null) return const SizedBox.shrink();
    
    final minutes = widget.card.duration!.inMinutes;
    final seconds = widget.card.duration!.inSeconds % 60;
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

  Future<void> _shareCard(BuildContext context) async {
    try {
      // Show toast notification
      Fluttertoast.showToast(
        msg: "Preparing card for sharing...",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.black87,
        textColor: Colors.white,
        fontSize: 16.0,
      );

      // Take screenshot of the card
      final imageFile = await _takeScreenshot();
      
      if (imageFile != null) {
        // Share the screenshot
        await Share.shareXFiles(
          [XFile(imageFile.path)],
          text: 'Check out this ${widget.card.mediaType.name} greeting card: ${widget.card.occasion}',
          subject: 'Greeting Card - ${widget.card.occasion}',
        );
        
        // Clean up the temporary file after sharing
        await imageFile.delete();
        
        // Show success toast
        Fluttertoast.showToast(
          msg: "Card shared successfully!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } else {
        // Fallback to text sharing if screenshot fails
        await Share.share(
          'Check out this ${widget.card.mediaType.name} greeting card: ${widget.card.occasion}',
          subject: 'Greeting Card - ${widget.card.occasion}',
        );
        
        Fluttertoast.showToast(
          msg: "Shared as text message",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.orange,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    } catch (e) {
      print('Error sharing card: $e');
      
      // Show error toast
      Fluttertoast.showToast(
        msg: "Failed to share card",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      
      // Fallback to text sharing
      await Share.share(
        'Check out this ${widget.card.mediaType.name} greeting card: ${widget.card.occasion}',
        subject: 'Greeting Card - ${widget.card.occasion}',
      );
    }
  }

  Future<File?> _takeScreenshot() async {
    try {
      // Get the RenderRepaintBoundary
      final RenderRepaintBoundary boundary = 
          _repaintBoundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      
      // Capture the image
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) return null;

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final fileName = 'greeting_card_${widget.card.id}_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = '${tempDir.path}/$fileName';
      
      // Save the screenshot
      final file = File(filePath);
      await file.writeAsBytes(byteData.buffer.asUint8List());
      
      return file;
    } catch (e) {
      print('Error taking screenshot: $e');
      return null;
    }
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
