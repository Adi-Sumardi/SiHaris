import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:gaji_pro/presentation/leave/bloc/leave_list/leave_list_bloc.dart';
import 'package:gaji_pro/presentation/leave/bloc/leave_balance/leave_balance_bloc.dart';
import 'package:gaji_pro/presentation/leave/pages/leave_form_screen.dart';
import 'package:gaji_pro/presentation/leave/pages/leave_detail_screen.dart';
import 'package:gaji_pro/data/models/responses/leave_model.dart';
import 'package:gaji_pro/data/models/responses/leave_balance_model.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/components/jago_header_band.dart';

class LeaveListScreen extends StatefulWidget {
  const LeaveListScreen({super.key});

  @override
  State<LeaveListScreen> createState() => _LeaveListScreenState();
}

class _LeaveListScreenState extends State<LeaveListScreen> {
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    context.read<LeaveListBloc>().add(GetLeaveList());
    context.read<LeaveBalanceBloc>().add(GetLeaveBalance());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 200;
    if (_scrollController.position.pixels < threshold) return;

    final state = context.read<LeaveListBloc>().state;
    if (state is LeaveListLoaded && !state.hasReachedMax) {
      _currentPage++;
      context.read<LeaveListBloc>().add(GetLeaveList(page: _currentPage));
    }
  }

  void _refreshList() {
    _currentPage = 1;
    context.read<LeaveListBloc>().add(GetLeaveList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LeaveFormScreen()),
          );
          // Refresh list when coming back
          if (!mounted) return;
          if (context.mounted) {
            _refreshList();
            context.read<LeaveBalanceBloc>().add(GetLeaveBalance());
          }
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          _buildHeader(),
          const JagoHeaderBand(),
          // Balance grid + history are ONE scrollable region (not a fixed
          // header above an Expanded list) — with enough leave types
          // (e.g. after admin adds "Cuti Haji" on top of the existing
          // ones) a non-scrolling grid could push past the screen height
          // and overflow on smaller devices.
          Expanded(
            child: BlocBuilder<LeaveListBloc, LeaveListState>(
              builder: (context, state) {
                return CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverToBoxAdapter(child: _buildLeaveBalanceSection()),
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'RIWAYAT CUTI',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondary500,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    ..._buildHistorySlivers(state),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildHistorySlivers(LeaveListState state) {
    if (state is LeaveListLoading) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (state is LeaveListError) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(state.message),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _refreshList,
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      ];
    }
    if (state is LeaveListLoaded) {
      if (state.leaves.isEmpty) {
        return [
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text('Belum ada riwayat cuti')),
          ),
        ];
      }
      return [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          sliver: SliverList.builder(
            itemCount: state.leaves.length,
            itemBuilder: (context, index) {
              return _buildLeaveItem(state.leaves[index]);
            },
          ),
        ),
      ];
    }
    return const [SliverToBoxAdapter(child: SizedBox())];
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            const Expanded(
              child: Text(
                'Cuti & Izin',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 40), // Balance the back button
          ],
        ),
      ),
    );
  }

  /// Rincian saldo per jenis cuti — satu kartu per jenis cuti (mis. "Cuti
  /// Tahunan: 8 / 12 hari"), MENGGANTIKAN kartu ringkasan gabungan
  /// (Jatah/Sisa/Terpakai total semua jenis) yang sebelumnya ada di header
  /// biru. Grid 2 kolom yang wrap otomatis — jenis cuti baru yang
  /// ditambahkan admin (mis. "Cuti Haji") langsung dapat kartu sendiri di
  /// sini tanpa perlu perubahan kode, karena dibangun dari
  /// `state.balances` (respons API), bukan daftar tetap.
  Widget _buildLeaveBalanceSection() {
    return BlocBuilder<LeaveBalanceBloc, LeaveBalanceState>(
      builder: (context, state) {
        if (state is LeaveBalanceLoading || state is LeaveBalanceInitial) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (state is! LeaveBalanceLoaded || state.balances.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SALDO CUTI',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondary500,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.balances.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.75,
                ),
                itemBuilder: (context, index) {
                  return _buildLeaveTypeBalanceCard(state.balances[index]);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Color _leaveTypeColor(int leaveTypeId) {
    const palette = [
      AppColors.primary,
      AppColors.success,
      AppColors.warning,
      AppColors.info,
      AppColors.error,
    ];
    return palette[leaveTypeId % palette.length];
  }

  Widget _buildLeaveTypeBalanceCard(LeaveBalanceModel balance) {
    final color = _leaveTypeColor(balance.leaveTypeId);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  balance.leaveTypeName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text:
                      '${balance.remainingDays % 1 == 0 ? balance.remainingDays.toInt() : balance.remainingDays}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary900,
                  ),
                ),
                TextSpan(
                  text: ' / ${balance.entitledDays.toInt()} hari',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.secondary500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveItem(LeaveModel leave) {
    Color statusColor;
    switch (leave.status) {
      case 'approved':
        statusColor = AppColors.success;
        break;
      case 'pending':
        statusColor = AppColors.warning;
        break;
      case 'rejected':
        statusColor = AppColors.error;
        break;
      default:
        statusColor = AppColors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LeaveDetailScreen(leave: leave),
              ),
            );

            if (result == true && mounted) {
              _refreshList();
              context.read<LeaveBalanceBloc>().add(GetLeaveBalance());
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      leave.requestNumber,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        leave.statusLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.date_range,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            leave.leaveType.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_formatDate(leave.startDate)} - ${_formatDate(leave.endDate)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${leave.totalDays == leave.totalDays.toInt() ? leave.totalDays.toInt() : leave.totalDays} Hari',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (leave.reason != null && leave.reason!.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(),
                  ),
                  Text(
                    leave.reason!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('d MMM y', 'id_ID').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}
