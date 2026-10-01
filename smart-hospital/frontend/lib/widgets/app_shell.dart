import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import 'app_logo.dart';

class AppShellNavItem {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final String? badge;

  const AppShellNavItem({
    required this.icon,
    this.selectedIcon,
    required this.label,
    this.badge,
  });
}

class AppShell extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<AppShellNavItem> items;
  final Widget body;
  final String title;
  final String? subtitle;
  final List<Widget>? actions;

  const AppShell({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.items,
    required this.body,
    required this.title,
    this.subtitle,
    this.actions,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
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
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;
    final auth = Provider.of<AuthProvider>(context);

    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            // Black Sidebar
            _buildSidebar(context, auth),
            // Main Content Area
            Expanded(
              child: Column(
                children: [
                  _buildDesktopTopBar(context, auth),
                  Expanded(
                    child: widget.body,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Mobile / Tablet View (< 900px)
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildMobileAppBar(context, auth),
      body: widget.body,
      bottomNavigationBar: _buildMobileBottomNav(context),
    );
  }

  Widget _buildSidebar(BuildContext context, AuthProvider auth) {
    return Container(
      width: 270,
      decoration: const BoxDecoration(
        color: AppColors.black,
        border: Border(
          right: BorderSide(color: Color(0xFF1E1E26), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header / Logo
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.xl,
            ),
            child: const AppLogo(
              size: 34,
              showText: true,
              isDark: true,
              subtitle: 'BED SYSTEM',
            ),
          ),
          const Divider(color: Color(0xFF1E1E26), height: 1),

          const SizedBox(height: AppSpacing.md),

          // Nav Section Label
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.xs,
            ),
            child: Text(
              'NAVIGATION',
              style: AppTypography.label(
                fontSize: 10,
                color: const Color(0xFF52525E),
                letterSpacing: 1.2,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          // Nav Items List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemCount: widget.items.length,
              separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.xs),
              itemBuilder: (context, index) {
                final item = widget.items[index];
                final isSelected = widget.selectedIndex == index;

                return _SidebarNavItem(
                  item: item,
                  isSelected: isSelected,
                  onTap: () => widget.onDestinationSelected(index),
                );
              },
            ),
          ),

          // Live System Status Card
          Container(
            margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: const Color(0xFF13131A),
              borderRadius: AppRadius.radiusMd,
              border: Border.all(color: const Color(0xFF22222D)),
            ),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, _) {
                    return Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.green.withValues(alpha: _pulseAnimation.value),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.green.withValues(alpha: 0.6),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'NETWORK ONLINE',
                        style: AppTypography.label(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.green,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Real-time telemetry active',
                        style: AppTypography.label(
                          fontSize: 10,
                          color: const Color(0xFF71717A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: Color(0xFF1E1E26), height: 1),

          // User Footer
          _buildUserFooter(context, auth),
        ],
      ),
    );
  }

  Widget _buildUserFooter(BuildContext context, AuthProvider auth) {
    final userName = auth.name ?? 'Staff User';
    final userRole = (auth.role ?? 'User').toUpperCase();
    final firstLetter = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: const Color(0xFF0E0E14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withValues(alpha: 0.15),
              borderRadius: AppRadius.radiusMd,
              border: Border.all(
                color: AppColors.primaryRed.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                firstLetter,
                style: AppTypography.headingSmall(color: AppColors.primaryRed),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  userName,
                  style: AppTypography.bodySmall(
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withValues(alpha: 0.15),
                    borderRadius: AppRadius.radiusPill,
                  ),
                  child: Text(
                    userRole,
                    style: AppTypography.label(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryRed,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 20),
            color: const Color(0xFF9CA3AF),
            hoverColor: AppColors.primaryRed.withValues(alpha: 0.15),
            tooltip: 'Sign Out',
            onPressed: () => auth.logout(),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTopBar(BuildContext context, AuthProvider auth) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: AppTypography.headingMedium(color: AppColors.ink),
                ),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.subtitle!,
                    style: AppTypography.bodySmall(color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),

          // Live "Updated just now" indicator
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs + 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: AppRadius.radiusPill,
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, _) {
                    return Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: AppColors.green.withValues(alpha: _pulseAnimation.value),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                ),
                const SizedBox(width: AppSpacing.xs + 2),
                Text(
                  'Updated just now',
                  style: AppTypography.label(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          if (widget.actions != null) ...[
            const SizedBox(width: AppSpacing.md),
            ...widget.actions!,
          ],
        ],
      ),
    );
  }

  PreferredSizeWidget _buildMobileAppBar(BuildContext context, AuthProvider auth) {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.ink,
      titleSpacing: AppSpacing.lg,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(color: AppColors.border, height: 1),
      ),
      title: Row(
        children: [
          const AppLogo(size: 28),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              widget.title,
              style: AppTypography.headingSmall(color: AppColors.ink),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        // Pulsing dot on mobile
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, _) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: _pulseAnimation.value),
                shape: BoxShape.circle,
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.logout_rounded, size: 20),
          tooltip: 'Sign Out',
          onPressed: () => auth.logout(),
        ),
        const SizedBox(width: AppSpacing.xs),
      ],
    );
  }

  Widget _buildMobileBottomNav(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: NavigationBar(
        selectedIndex: widget.selectedIndex,
        onDestinationSelected: widget.onDestinationSelected,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryRed.withValues(alpha: 0.12),
        elevation: 0,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: widget.items.map((item) {
          return NavigationDestination(
            icon: Icon(item.icon, color: AppColors.textSecondary, size: 22),
            selectedIcon: Icon(
              item.selectedIcon ?? item.icon,
              color: AppColors.primaryRed,
              size: 22,
            ),
            label: item.label,
          );
        }).toList(),
      ),
    );
  }
}

class _SidebarNavItem extends StatefulWidget {
  final AppShellNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;

    Color bgColor;
    if (isSelected) {
      bgColor = AppColors.primaryRed.withValues(alpha: 0.12);
    } else if (_isHovered) {
      bgColor = const Color(0xFF191922);
    } else {
      bgColor = Colors.transparent;
    }

    final textColor = isSelected
        ? AppColors.white
        : (_isHovered ? const Color(0xFFE5E7EB) : const Color(0xFF9CA3AF));
    final iconColor = isSelected ? AppColors.primaryRed : (_isHovered ? AppColors.white : const Color(0xFF9CA3AF));

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: AppRadius.radiusMd,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md - 1,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: AppRadius.radiusMd,
            border: isSelected
                ? Border.all(color: AppColors.primaryRed.withValues(alpha: 0.3), width: 1)
                : null,
          ),
          child: Row(
            children: [
              if (isSelected)
                Container(
                  width: 3.5,
                  height: 18,
                  margin: const EdgeInsets.only(right: AppSpacing.sm + 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed,
                    borderRadius: AppRadius.radiusPill,
                  ),
                ),
              Icon(
                isSelected ? (widget.item.selectedIcon ?? widget.item.icon) : widget.item.icon,
                color: iconColor,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  widget.item.label,
                  style: isSelected
                      ? AppTypography.headingSmall(color: textColor)
                      : AppTypography.bodyMedium(color: textColor, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.item.badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryRed : const Color(0xFF22222D),
                    borderRadius: AppRadius.radiusPill,
                  ),
                  child: Text(
                    widget.item.badge!,
                    style: AppTypography.label(
                      fontSize: 10,
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
