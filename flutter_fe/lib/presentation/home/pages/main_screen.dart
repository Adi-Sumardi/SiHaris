import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/spacing.dart';
import 'home_screen.dart';
import '../../attendance/pages/attendance_history_screen.dart';
import '../../leave/pages/leave_list_screen.dart';
import '../../payslip/pages/payslip_screen.dart';
import '../../profile/pages/profile_screen.dart';
import '../../attendance/pages/attendance_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const AttendanceHistoryScreen(),
    const LeaveListScreen(),
    const PayslipScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _buildFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                0,
                Icons.home_outlined,
                Icons.home_rounded,
                'Beranda',
              ),
              _buildNavItem(
                1,
                Icons.history_outlined,
                Icons.history_rounded,
                'Riwayat',
              ),
              const SizedBox(width: 72), // Space for FAB
              _buildNavItem(
                3,
                Icons.receipt_long_outlined,
                Icons.receipt_long_rounded,
                'Slip Gaji',
              ),
              _buildNavItem(
                4,
                Icons.person_outline,
                Icons.person_rounded,
                'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: AppSpacing.borderRadiusMd,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppColors.primary600 : AppColors.secondary400,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: isSelected
                    ? AppColors.primary600
                    : AppColors.secondary400,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFab() {
    return Container(
      margin: const EdgeInsets.only(top: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary600.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: FloatingActionButton(
              heroTag: 'main_fab',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AttendanceScreen()),
              ),
              backgroundColor: AppColors.primary600,
              foregroundColor: AppColors.textOnPrimary,
              elevation: 0,
              child: SvgPicture.asset(
                'assets/images/attendance.svg',
                width: 28,
                height: 28,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Absensi',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.primary600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Alternative bottom navigation with more features
class JagoBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<JagoBottomNavItem> items;
  final bool showLabels;
  final Widget? centerButton;

  const JagoBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.showLabels = true,
    this.centerButton,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: AppSpacing.bottomNavHeight,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (int i = 0; i < items.length; i++) ...[
                if (centerButton != null && i == items.length ~/ 2)
                  const SizedBox(width: 56),
                _buildItem(i),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(int index) {
    final item = items[index];
    final isSelected = currentIndex == index;

    return InkWell(
      onTap: () => onTap(index),
      borderRadius: AppSpacing.borderRadiusMd,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? item.activeIcon : item.icon,
                  color: isSelected
                      ? AppColors.primary600
                      : AppColors.secondary400,
                  size: 24,
                ),
                if (item.badge != null && item.badge! > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        item.badge! > 9 ? '9+' : '${item.badge}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            if (showLabels) ...[
              const SizedBox(height: 4),
              Text(
                item.label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: isSelected
                      ? AppColors.primary600
                      : AppColors.secondary400,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class JagoBottomNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int? badge;

  const JagoBottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badge,
  });
}
