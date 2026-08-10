import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gaji_pro/core/constants/colors.dart';
import 'package:gaji_pro/data/models/responses/office_location_model.dart';
import 'package:gaji_pro/presentation/office_location/bloc/office_location/office_location_bloc.dart';
import 'package:gaji_pro/presentation/office_location/bloc/office_location/office_location_event.dart';
import 'package:gaji_pro/presentation/office_location/bloc/office_location/office_location_state.dart';

class OfficeLocationPickerScreen extends StatefulWidget {
  const OfficeLocationPickerScreen({super.key});

  @override
  State<OfficeLocationPickerScreen> createState() =>
      _OfficeLocationPickerScreenState();
}

class _OfficeLocationPickerScreenState
    extends State<OfficeLocationPickerScreen> {
  @override
  void initState() {
    super.initState();
    context.read<OfficeLocationBloc>().add(GetAssignedOffices());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: BlocBuilder<OfficeLocationBloc, OfficeLocationState>(
              builder: (context, state) {
                if (state is OfficeLocationLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is OfficeLocationError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.danger, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          state.message,
                          style: const TextStyle(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context
                              .read<OfficeLocationBloc>()
                              .add(GetAssignedOffices()),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }
                if (state is OfficeLocationLoaded) {
                  if (state.offices.isEmpty) {
                    return const Center(
                      child: Text('Tidak ada lokasi kantor yang ditugaskan'),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.offices.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildOfficeCard(state.offices[index]);
                    },
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              const Expanded(
                child: Text(
                  'Pilih Lokasi Kantor',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOfficeCard(OfficeLocationModel office) {
    return InkWell(
      onTap: () => Navigator.pop(context, office),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.business,
                  color: AppColors.primary600, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          office.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (office.isPrimary)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary600,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Utama',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (office.fullAddress.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      office.fullAddress,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'Radius: ${office.radius}m',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }
}
