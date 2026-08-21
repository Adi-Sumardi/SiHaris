import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/colors.dart';
import '../../../core/components/widgets.dart';
import '../../../core/widgets/delete_account_dialog.dart';
import '../../../data/datasources/auth_local_datasource.dart';
import '../../../data/models/responses/auth_response_model.dart';
import '../../auth/bloc/profile/profile_bloc.dart';
import '../../auth/bloc/profile/profile_event.dart';
import '../../auth/bloc/profile/profile_state.dart';
import '../../auth/pages/login_screen.dart';
import '../../home/pages/main_screen.dart';
import '../../tax_form/pages/tax_form_screen.dart';
import '../../auth/pages/change_password_screen.dart';
import '../../settings/pages/settings_screen.dart';
import '../../settings/pages/about_screen.dart';
import '../../settings/pages/faq_screen.dart';
import '../../face_enrollment/pages/face_enrollment_screen.dart';
import 'edit_profile_screen.dart';

/// Profile Screen - Dynamic from API
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(GetProfile());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoading || state is ProfileInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ProfileError) {
            return _buildError(context, state.message);
          }
          if (state is ProfileLoaded) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(context, state.user, state.company),
                  _buildProfileContent(context, state.user, state.company),
                ],
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () =>
                context.read<ProfileBloc>().add(GetProfile()),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserModel user, CompanyModel? company) {
    final employee = user.employee;
    final displayName = employee?.fullName.isNotEmpty == true
        ? employee!.fullName
        : user.name;
    final position = employee?.position ?? '';
    final companyName = company?.name ?? '';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary600, AppColors.primary700],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 20, color: Colors.white),
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const MainScreen()),
                        );
                      }
                    },
                  ),
                  const Text(
                    'Profil',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            size: 22, color: Colors.white),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditProfileScreen(user: user),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined,
                            size: 24, color: Colors.white),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SettingsScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Avatar
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: employee?.photo != null
                  ? ClipOval(
                      child: Image.network(
                        employee!.photo!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.person_rounded,
                          color: AppColors.primary600,
                          size: 40,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.person_rounded,
                      color: AppColors.primary600,
                      size: 40,
                    ),
            ),
            const SizedBox(height: 12),
            Text(
              displayName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            if (position.isNotEmpty)
              Text(
                position,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            if (companyName.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                companyName,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
            const SizedBox(height: 16),
            // Stats row
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              padding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildStatItem(
                      employee?.employeeId.isNotEmpty == true
                          ? employee!.employeeId
                          : '-',
                      'ID Karyawan'),
                  _buildDivider(),
                  _buildStatItem(
                      employee?.pin?.isNotEmpty == true
                          ? employee!.pin!
                          : '-',
                      'PIN Mesin'),
                  _buildDivider(),
                  _buildStatItem(
                    employee?.faceEnrolled == true ? 'Terdaftar' : 'Belum',
                    'Wajah',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 28,
      color: Colors.white.withValues(alpha: 0.3),
    );
  }

  Widget _buildProfileContent(BuildContext context, UserModel user, CompanyModel? company) {
    final employee = user.employee;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Informasi Pribadi'),
          const SizedBox(height: 12),
          _buildInfoCard([
            _buildInfoRow(Icons.email_outlined, 'Email', user.email),
            if (employee?.phone != null)
              _buildInfoRow(
                  Icons.phone_outlined, 'Telepon', employee!.phone!),
            if (employee?.nik != null && employee!.nik!.isNotEmpty)
              _buildInfoRow(
                  Icons.credit_card_outlined, 'NIK (No. KTP)', employee.nik!,
                  copyable: true),
          ]),
          const SizedBox(height: 20),
          _buildSectionTitle('Informasi Pekerjaan'),
          const SizedBox(height: 12),
          _buildInfoCard([
            if (company != null)
              _buildInfoRow(
                  Icons.apartment_outlined, 'Perusahaan', company.name),
            if (employee != null) ...[
              _buildInfoRow(
                  Icons.badge_outlined, 'ID Karyawan', employee.employeeId,
                  copyable: true),
              _buildInfoRow(
                  Icons.fingerprint_rounded,
                  'PIN Mesin Fingerprint',
                  employee.pin?.isNotEmpty == true ? employee.pin! : '-',
                  copyable: true),
              if (employee.department != null)
                _buildInfoRow(Icons.business_outlined, 'Departemen',
                    employee.department!),
              if (employee.position != null)
                _buildInfoRow(
                    Icons.work_outline, 'Jabatan', employee.position!),
              if (employee.employmentStatus != null)
                _buildInfoRow(Icons.verified_outlined, 'Status',
                    employee.employmentStatus!),
              if (employee.hireDate != null)
                _buildInfoRow(Icons.calendar_today_outlined, 'Bergabung',
                    employee.hireDate!,
                    isLast: true),
            ],
          ]),
          const SizedBox(height: 20),
          _buildSectionTitle('Keamanan & Biometrik'),
          const SizedBox(height: 12),
          _buildBiometricCard(context, employee),
          const SizedBox(height: 20),
          _buildSectionTitle('Dokumen Pajak'),
          const SizedBox(height: 12),
          _buildTaxDocumentCard(context),
          const SizedBox(height: 20),
          _buildSectionTitle('Pengaturan'),
          const SizedBox(height: 12),
          _buildMenuCard(context),
          const SizedBox(height: 24),
          _buildLogoutButton(context),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildBiometricCard(BuildContext context, EmployeeModel? employee) {
    final isEnrolled = employee?.faceEnrolled == true;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isEnrolled ? AppColors.successLight : AppColors.warningLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.face_retouching_natural_rounded,
                  color: isEnrolled ? AppColors.success : AppColors.warningDark,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pendaftaran Wajah',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isEnrolled
                          ? 'Wajah telah terdaftar untuk absensi'
                          : 'Daftarkan wajah untuk absensi mobile',
                      style: TextStyle(
                        fontSize: 11,
                        color: isEnrolled
                            ? AppColors.successDark
                            : AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isEnrolled ? AppColors.successLight : AppColors.warningLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isEnrolled ? AppColors.success : AppColors.warning,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isEnrolled ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                      size: 12,
                      color: isEnrolled ? AppColors.success : AppColors.warningDark,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isEnrolled ? 'Terdaftar' : 'Belum',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isEnrolled ? AppColors.successDark : AppColors.warningDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isEnrolled) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FaceEnrollmentScreen(),
                    ),
                  ).then((_) {
                    if (context.mounted) {
                      context.read<ProfileBloc>().add(GetProfile());
                    }
                  });
                },
                icon: const Icon(Icons.camera_alt_rounded, size: 18),
                label: const Text(
                  'Daftarkan Wajah Sekarang',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary600,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 14),
            InkWell(
              onTap: () => _showFaceReEnrollmentInfoDialog(context),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.secondary50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Perlu daftar ulang wajah? Hubungi Admin',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: AppColors.textTertiary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showFaceReEnrollmentInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.verified_user_rounded, color: AppColors.primary600),
            SizedBox(width: 10),
            Text(
              'Pendaftaran Wajah',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: const Text(
          'Wajah Anda sudah terdaftar dan terverifikasi untuk absensi.\n\nUntuk menjaga keamanan absensi, pendaftaran wajah hanya dapat dilakukan 1 kali. Jika ada kendala biometrik atau perubahan wajah, silakan ajukan permohonan reset ke Administrator HRD.\n\nSetelah Administrator menyetujui dan mereset data wajah Anda di sistem, tombol pendaftaran wajah akan otomatis aktif kembali.',
          style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mengerti', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    if (children.isEmpty) return const SizedBox();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {bool isLast = false, bool copyable = false}) {
    return Builder(
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : Border(
                    bottom: BorderSide(
                        color: AppColors.border.withValues(alpha: 0.5))),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary600, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              if (copyable && value != '-' && value.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.primary600),
                  tooltip: 'Salin $label',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$label berhasil disalin ($value)'),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaxDocumentCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          _buildMenuItem(Icons.receipt_long_outlined, 'Bukti Potong 1721-A1',
              onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TaxFormScreen()),
            );
          }, isLast: true),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          _buildMenuItem(Icons.lock_outline_rounded, 'Ubah Password',
              onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
            );
          }),
          _buildMenuItem(Icons.help_outline_rounded, 'Bantuan',
              onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FaqScreen()),
            );
          }),
          _buildMenuItem(
              Icons.delete_outline_rounded, 'Hapus Akun',
              onTap: () => DeleteAccountDialog.show(context)),
          _buildMenuItem(
              Icons.info_outline_rounded, 'Tentang Aplikasi',
              onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AboutScreen()),
            );
          },
              trailing: _buildTrailingText('v1.0.0'),
              isLast: true),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title,
      {VoidCallback? onTap, Widget? trailing, bool isLast = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                      color: AppColors.border.withValues(alpha: 0.5))),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.secondary50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.secondary600, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            trailing ??
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.secondary300, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTrailingText(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        JagoBottomSheet.showConfirmation(
          context: context,
          title: 'Keluar dari Aplikasi?',
          message: 'Anda yakin ingin keluar dari akun ini?',
          confirmText: 'Keluar',
          cancelText: 'Batal',
          isDanger: true,
          onConfirm: () {
            // Force logout: clear auth data then navigate to login
            final navigator = Navigator.of(context);
            AuthLocalDatasource().removeAuthData().then((_) {
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            });
          },
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: AppColors.danger, size: 20),
            SizedBox(width: 8),
            Text(
              'Keluar',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.danger,
              ),
            ),
          ],
        ),
      ),
    );
  }

  }
