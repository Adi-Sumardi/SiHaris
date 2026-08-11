import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/biometric_service.dart';
import '../../auth/bloc/logout/logout_bloc.dart';
import '../../auth/bloc/logout/logout_event.dart';
import '../../auth/bloc/logout/logout_state.dart';
import '../../auth/pages/login_screen.dart';
import 'about_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';
import '../../face_recognition/bloc/face_enroll/face_enroll_bloc.dart';
import '../../face_recognition/bloc/face_enroll/face_enroll_state.dart';
import '../../face_recognition/pages/face_enroll_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<LogoutBloc, LogoutState>(
      listener: (context, state) {
        if (state is LogoutSuccess) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Berhasil keluar'),
              backgroundColor: AppColors.success,
            ),
          );
        } else if (state is LogoutError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: AppBar(
          title: const Text(
            'Pengaturan',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: AppColors.textPrimary,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildSection([
                _buildListTile(
                  context,
                  icon: Icons.info_outline,
                  title: 'Tentang Aplikasi',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AboutScreen()),
                  ),
                ),
                _buildDivider(),
                _buildListTile(
                  context,
                  icon: Icons.privacy_tip_outlined,
                  title: 'Kebijakan Privasi',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PrivacyPolicyScreen(),
                    ),
                  ),
                ),
                _buildDivider(),
                _buildListTile(
                  context,
                  icon: Icons.description_outlined,
                  title: 'Syarat dan Ketentuan',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TermsOfServiceScreen(),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 24),
              _buildSection([
                _buildListTile(
                  context,
                  icon: Icons.logout,
                  title: 'Keluar',
                  textColor: AppColors.danger,
                  iconColor: AppColors.danger,
                  onTap: () => _showLogoutDialog(context),
                ),
              ]),
              const SizedBox(height: 24),
              _buildSection([
                _buildFaceRecognitionTile(context),
                _buildDivider(),
                const _BiometricToggleTile(),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(List<Widget> children) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(children: children),
        ),
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.primary, size: 24),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textColor ?? AppColors.textPrimary,
        ),
      ),
      trailing:
          trailing ??
          const Icon(
            Icons.chevron_right,
            color: AppColors.textTertiary,
            size: 20,
          ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: AppColors.divider,
    );
  }

  Widget _buildFaceRecognitionTile(BuildContext context) {
    return BlocBuilder<FaceEnrollBloc, FaceEnrollState>(
      builder: (context, state) {
        bool isEnrolled = false;
        if (state is FaceEnrollSuccess) {
          isEnrolled = state.response.enrolled;
        }

        return _buildListTile(
          context,
          icon: Icons.face,
          title: 'Face Recognition',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FaceEnrollScreen()),
            );
          },
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isEnrolled ? 'Terdaftar' : 'Belum terdaftar',
                style: TextStyle(
                  color: isEnrolled
                      ? AppColors.success
                      : AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              if (!isEnrolled)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Setup',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textTertiary,
                size: 20,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    // Capture the LogoutBloc before showing dialog
    final logoutBloc = context.read<LogoutBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: logoutBloc,
        child: BlocBuilder<LogoutBloc, LogoutState>(
          builder: (blocContext, state) {
            return AlertDialog(
              title: const Text('Keluar Aplikasi'),
              content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: state is LogoutLoading
                      ? null
                      : () {
                          // Close dialog first
                          Navigator.pop(dialogContext);
                          // Trigger logout using the captured bloc
                          logoutBloc.add(LogoutSubmitted());
                        },
                  child: state is LogoutLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Keluar',
                          style: TextStyle(color: AppColors.danger),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Toggle untuk mengaktifkan/menonaktifkan kunci biometrik (Face ID / sidik jari).
class _BiometricToggleTile extends StatefulWidget {
  const _BiometricToggleTile();

  @override
  State<_BiometricToggleTile> createState() => _BiometricToggleTileState();
}

class _BiometricToggleTileState extends State<_BiometricToggleTile> {
  final BiometricService _service = BiometricService.instance;
  bool _available = false;
  bool _enabled = false;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final available = await _service.isAvailable();
    final enabled = await _service.isEnabled();
    if (!mounted) return;
    setState(() {
      _available = available;
      _enabled = enabled;
      _loading = false;
    });
  }

  Future<void> _onChanged(bool value) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (value) {
        final ok = await _service.enable();
        if (!mounted) return;
        if (ok) {
          setState(() => _enabled = true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verifikasi biometrik gagal atau dibatalkan'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      } else {
        await _service.disable();
        if (!mounted) return;
        setState(() => _enabled = false);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = _loading
        ? 'Memeriksa perangkat...'
        : (_available
              ? 'Buka aplikasi dengan Face ID / sidik jari'
              : 'Tidak tersedia di perangkat ini');

    return ListTile(
      leading: const Icon(Icons.fingerprint, color: AppColors.primary, size: 24),
      title: const Text(
        'Kunci Biometrik',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      trailing: _loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Switch(
              value: _enabled,
              onChanged: (_available && !_busy) ? _onChanged : null,
              activeThumbColor: AppColors.primary,
            ),
    );
  }
}
