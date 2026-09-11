import 'package:flutter/material.dart';
import '../services/vpn_service.dart';
import '../theme/app_theme.dart';

class PowerButton extends StatefulWidget {
  final ConnectionStatus status;
  final VoidCallback onTap;

  const PowerButton({
    Key? key,
    required this.status,
    required this.onTap,
  }) : super(key: key);

  @override
  State<PowerButton> createState() => _PowerButtonState();
}

class _PowerButtonState extends State<PowerButton> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color glowColor;
    Color buttonColor;
    IconData icon;

    switch (widget.status) {
      case ConnectionStatus.connected:
        glowColor = AppTheme.successGreen;
        buttonColor = AppTheme.successGreen;
        icon = Icons.shield_rounded;
        break;
      case ConnectionStatus.connecting:
        glowColor = AppTheme.warningOrange;
        buttonColor = AppTheme.warningOrange;
        icon = Icons.sync_rounded;
        break;
      case ConnectionStatus.disconnected:
      default:
        glowColor = AppTheme.primaryNeon;
        buttonColor = AppTheme.surface;
        icon = Icons.power_settings_new_rounded;
        break;
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final scale = widget.status == ConnectionStatus.connected ? _pulseAnimation.value : 1.0;
        return Transform.scale(
          scale: scale,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withOpacity(widget.status == ConnectionStatus.connected ? 0.35 : 0.15),
                    blurRadius: 35,
                    spreadRadius: 8,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: glowColor.withOpacity(0.8),
                  width: 3,
                ),
              ),
              child: Center(
                child: widget.status == ConnectionStatus.connecting
                    ? CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(glowColor),
                        strokeWidth: 3,
                      )
                    : Icon(
                        icon,
                        size: 72,
                        color: widget.status == ConnectionStatus.connected
                            ? AppTheme.successGreen
                            : AppTheme.primaryNeon,
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}
