import 'package:flutter/material.dart';
import 'package:flutter_offline/flutter_offline.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/l10n/app_localizations.dart';

/// A wrapper widget that displays a full-screen overlay when the device is offline.
/// Wrap your app's main content with this widget to show offline status globally.
class OfflineWrapper extends StatelessWidget {
  final Widget child;

  const OfflineWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OfflineBuilder(
      connectivityBuilder: (
          BuildContext context,
          List<ConnectivityResult> connectivity,
          Widget child,
          ) {
        final bool isConnected = !connectivity.contains(ConnectivityResult.none);

        return Stack(
          children: [
            // Main app content - always visible
            child,

            // Offline overlay - shown on top when offline
            if (!isConnected)
              _OfflineOverlay(),
          ],
        );
      },
      child: child,
    );
  }
}

/// Full-screen overlay widget shown when offline
class _OfflineOverlay extends StatefulWidget {
  @override
  State<_OfflineOverlay> createState() => _OfflineOverlayState();
}

class _OfflineOverlayState extends State<_OfflineOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 400 || size.height < 600;
    final isVerySmallScreen = size.height < 500;

    // Define explicit colors to avoid theme interference
    const Color titleColor = Color(0xFF424242); // Grey 800
    const Color subtitleColor = Color(0xFF757575); // Grey 600
    const Color tipTextColor = Color(0xFF616161); // Grey 700
    const Color tipIconColor = Color(0xFF757575); // Grey 600
    const Color tipBackgroundColor = Color(0xFFF5F5F5); // Grey 100

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black.withOpacity(0.85),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 16 : 32,
                      vertical: 16,
                    ),
                    padding: EdgeInsets.all(isSmallScreen ? 20 : 32),
                    constraints: const BoxConstraints(maxWidth: 380),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Animated WiFi Icon
                        _AnimatedWifiIcon(
                          size: isVerySmallScreen ? 60 : (isSmallScreen ? 70 : 80),
                        ),
                        SizedBox(height: isSmallScreen ? 16 : 24),
                        // Title
                        Text(
                          l10n?.noConnection ?? 'No Internet Connection',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 18 : 22,
                            fontWeight: FontWeight.bold,
                            color: titleColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        // Subtitle
                        Text(
                          l10n?.checkInternetConnection ?? 'Please check your internet connection',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 13 : 14,
                            color: subtitleColor,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (!isVerySmallScreen) ...[
                          SizedBox(height: isSmallScreen ? 16 : 24),
                          // Connection tips
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: tipBackgroundColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                _ConnectionTip(
                                  icon: Icons.wifi,
                                  text: l10n?.checkWifi ?? 'Check Wi-Fi',
                                  compact: isSmallScreen,
                                  iconColor: tipIconColor,
                                  textColor: tipTextColor,
                                ),
                                const SizedBox(height: 8),
                                _ConnectionTip(
                                  icon: Icons.signal_cellular_alt,
                                  text: l10n?.checkMobileData ?? 'Check mobile data',
                                  compact: isSmallScreen,
                                  iconColor: tipIconColor,
                                  textColor: tipTextColor,
                                ),
                              ],
                            ),
                          ),
                        ],
                        SizedBox(height: isSmallScreen ? 16 : 24),
                        // Retry indicator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.mainColor),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                l10n?.waitingForConnection ?? 'Waiting for connection...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.mainColor,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated WiFi icon with pulsing effect
class _AnimatedWifiIcon extends StatefulWidget {
  final double size;

  const _AnimatedWifiIcon({this.size = 80});

  @override
  State<_AnimatedWifiIcon> createState() => _AnimatedWifiIconState();
}

class _AnimatedWifiIconState extends State<_AnimatedWifiIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
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
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.red.shade400,
              Colors.red.shade600,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(
          Icons.wifi_off_rounded,
          size: widget.size * 0.48,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Single connection tip row
class _ConnectionTip extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool compact;
  final Color iconColor;
  final Color textColor;

  const _ConnectionTip({
    required this.icon,
    required this.text,
    this.compact = false,
    this.iconColor = const Color(0xFF757575),
    this.textColor = const Color(0xFF616161),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: compact ? 16 : 18,
          color: iconColor,
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: compact ? 12 : 13,
              color: textColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}