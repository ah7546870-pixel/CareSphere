import 'package:flutter/material.dart';

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isSecondary;
  final bool isDanger;
  final bool isLoading;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isSecondary = false,
    this.isDanger = false,
    this.isLoading = false,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Clean Light Theme Colors
    final gradient = widget.isDanger
        ? LinearGradient(colors: [theme.colorScheme.error, const Color(0xFFBE123C)])
        : widget.isSecondary
            ? const LinearGradient(colors: [Color(0xFFF1F5F9), Color(0xFFF1F5F9)])
            : LinearGradient(colors: [theme.primaryColor, const Color(0xFF14B8A6)]);
            
    final glowColor = widget.isDanger
        ? theme.colorScheme.error.withValues(alpha: 0.3)
        : widget.isSecondary
            ? Colors.transparent
            : theme.primaryColor.withValues(alpha: 0.25);

    final textColor = widget.isSecondary ? theme.colorScheme.onSurface : Colors.white;

    return GestureDetector(
      onTapDown: (_) => !widget.isLoading ? _controller.forward() : null,
      onTapUp: (_) {
        if (!widget.isLoading) {
          _controller.reverse();
          widget.onPressed();
        }
      },
      onTapCancel: () => !widget.isLoading ? _controller.reverse() : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(16),
              border: widget.isSecondary ? Border.all(color: theme.dividerColor) : null,
              boxShadow: widget.isSecondary
                  ? []
                  : [
                      BoxShadow(
                        color: glowColor,
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: Center(
              child: widget.isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: textColor),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, size: 20, color: textColor),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.text,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            fontFamily: 'Outfit',
                            letterSpacing: 0.5,
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
