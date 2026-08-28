import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/variables.dart';
import '../../../core/components/widgets.dart';
import '../bloc/login/login_bloc.dart';
import '../bloc/login/login_event.dart';
import '../bloc/login/login_state.dart';
import '../../home/pages/main_screen.dart';
import '../../../data/datasources/auth_remote_datasource.dart';
import 'otp_verification_screen.dart';
import 'register_screen.dart';

/// Login Screen with 8-point grid system
/// Spacing: 4, 8, 12, 16, 24, 32, 48 px
/// Font sizes: 12, 14, 16, 20, 24 px
/// Icon sizes: 16, 20, 24, 32 px
/// Container sizes: 24, 32, 48, 80 px
/// Border radius: 4, 8, 12, 16, 24, 32 px
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _usePasswordLogin = false;
  bool _isRequestingOtp = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRequestOtp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final input = _emailController.text.trim();

    setState(() {
      _isRequestingOtp = true;
    });

    final result = await AuthRemoteDatasource().requestOtp(input);

    setState(() {
      _isRequestingOtp = false;
    });

    result.fold(
      (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.danger),
        );
      },
      (data) {
        final destination = data['data']?['destination'] ?? input;
        final type = data['data']?['type'] ?? 'phone';

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpVerificationScreen(
              login: input,
              destination: destination,
              type: type,
            ),
          ),
        );
      },
    );
  }

  void _handlePasswordLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<LoginBloc>().add(
        LoginSubmitted(
          identifier: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginBloc, LoginState>(
      listener: (context, state) {
        if (state is LoginSuccess) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
        } else if (state is LoginError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    _buildHeader(),
                    _buildLoginForm(),
                    const Spacer(),
                    _buildPoweredBy(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 40,
        bottom: 40,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary600, AppColors.primary700],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Image.asset(
                  'assets/icons/app_icon.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Selamat Datang!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Masuk ke akun SiHaris Anda',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            JagoTextField(
              label: 'Nomor HP / Email / ID Karyawan',
              hint: 'Contoh: 08123456789 atau nama@email.com',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: _usePasswordLogin
                  ? TextInputAction.next
                  : TextInputAction.done,
              prefixIcon: Icons.phone_android_outlined,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nomor HP atau Email tidak boleh kosong';
                }
                return null;
              },
            ),
            if (_usePasswordLogin) ...[
              const SizedBox(height: 20),
              JagoTextField(
                label: 'Password',
                hint: 'Masukkan password Anda',
                controller: _passwordController,
                obscureText: true,
                textInputAction: TextInputAction.done,
                prefixIcon: Icons.lock_outlined,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password tidak boleh kosong';
                  }
                  if (value.length < 6) {
                    return 'Password minimal 6 karakter';
                  }
                  return null;
                },
                onSubmitted: (_) => _handlePasswordLogin(),
              ),
            ],

            const SizedBox(height: 24),

            if (!_usePasswordLogin) ...[
              JagoButton(
                text: 'Kirim Kode OTP (WA / Email)',
                onPressed: _handleRequestOtp,
                isLoading: _isRequestingOtp,
                leadingIcon: Icons.send_rounded,
              ),
            ] else ...[
              BlocBuilder<LoginBloc, LoginState>(
                builder: (context, state) {
                  return JagoButton(
                    text: 'Masuk dengan Password',
                    onPressed: _handlePasswordLogin,
                    isLoading: state is LoginLoading,
                    leadingIcon: Icons.login_rounded,
                  );
                },
              ),
            ],

            const SizedBox(height: 16),

            Center(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _usePasswordLogin = !_usePasswordLogin;
                  });
                },
                child: Text(
                  _usePasswordLogin
                      ? 'Atau Masuk dengan Kode OTP (WA/Email)'
                      : 'Atau Masuk dengan Password',
                  style: const TextStyle(
                    color: AppColors.primary600,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Center(
              child: GestureDetector(
                onTap: _contactAdminWhatsapp,
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    children: [
                      TextSpan(text: 'Belum punya akun? '),
                      TextSpan(
                        text: 'Kontak Admin',
                        style: TextStyle(
                          color: AppColors.primary600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _contactAdminWhatsapp() async {
    final uri = Uri.parse(Variables.adminWhatsappUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tidak dapat membuka WhatsApp. Silakan hubungi 081292702075.',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Widget _buildPoweredBy() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Powered by',
            style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 8),
          Image.asset('assets/images/yapi.png', height: 28),
        ],
      ),
    );
  }
}
