import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/components/widgets.dart';

/// Forgot Password Screen with 8-point grid system
/// Spacing: 4, 8, 12, 16, 24, 32, 48 px
/// Font sizes: 12, 14, 16, 20, 24 px
/// Icon sizes: 20, 24, 40, 48 px
/// Container sizes: 80, 96 px
/// Border radius: 4, 8, 12, 16, 24 px
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      // Simulate API call
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isSuccess = true;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: const JagoAppBar(
        title: 'Lupa Password',
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _isSuccess ? _buildSuccessContent() : _buildFormContent(),
        ),
      ),
    );
  }

  Widget _buildFormContent() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          // Icon - 80px
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.primary50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_reset_rounded,
                color: AppColors.primary600,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Title
          const Center(
            child: Text(
              'Reset Password',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Masukkan email yang terdaftar. Kami akan mengirimkan link untuk reset password.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 48),
          // Email field
          JagoTextField(
            label: 'Email',
            hint: 'Masukkan email Anda',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email tidak boleh kosong';
              }
              if (!value.contains('@')) {
                return 'Email tidak valid';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),
          // Submit button
          JagoButton(
            text: 'Kirim Link Reset',
            onPressed: _handleSubmit,
            isLoading: _isLoading,
            leadingIcon: Icons.send_rounded,
          ),
          const SizedBox(height: 24),
          // Back to login
          Center(
            child: TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded, size: 20),
              label: const Text('Kembali ke Login'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Icon - 96px
        Container(
          width: 96,
          height: 96,
          decoration: const BoxDecoration(
            color: AppColors.successLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.success,
            size: 48,
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Email Terkirim!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Silakan cek email ${_emailController.text} untuk link reset password.',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Tidak menerima email? Cek folder spam atau',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textTertiary,
          ),
          textAlign: TextAlign.center,
        ),
        TextButton(
          onPressed: () {
            setState(() => _isSuccess = false);
          },
          child: const Text('Kirim ulang'),
        ),
        const SizedBox(height: 32),
        JagoButton(
          text: 'Kembali ke Login',
          onPressed: () => Navigator.pop(context),
          leadingIcon: Icons.arrow_back_rounded,
        ),
      ],
    );
  }
}
