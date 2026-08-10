import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/colors.dart';
import '../../../../data/models/requests/overtime_request_model.dart';
import '../bloc/action/overtime_action_bloc.dart';

class OvertimeFormScreen extends StatefulWidget {
  const OvertimeFormScreen({super.key});

  @override
  State<OvertimeFormScreen> createState() => _OvertimeFormScreenState();
}

class _OvertimeFormScreenState extends State<OvertimeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Pilih tanggal lembur')));
        return;
      }
      if (_startTime == null || _endTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih jam mulai dan selesai')),
        );
        return;
      }

      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      final startTimeStr =
          '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}';
      final endTimeStr =
          '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}';

      final request = OvertimeRequestModel(
        date: dateStr,
        startTime: startTimeStr,
        endTime: endTimeStr,
        reason: _reasonController.text,
      );

      context.read<OvertimeActionBloc>().add(CreateOvertime(request));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text(
          'Ajukan Lembur',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocListener<OvertimeActionBloc, OvertimeActionState>(
        listener: (context, state) {
          if (state is OvertimeActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.pop(context, true); // Return true to refresh list
          } else if (state is OvertimeActionFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.danger,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDateSelector(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildTimeSelector(true)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTimeSelector(false)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildReasonField(),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: BlocBuilder<OvertimeActionBloc, OvertimeActionState>(
                    builder: (context, state) {
                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: state is OvertimeActionLoading
                            ? null
                            : _submit,
                        child: state is OvertimeActionLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text('Kirim Pengajuan'),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(
              _selectedDate == null
                  ? 'Pilih Tanggal'
                  : DateFormat(
                      'EEEE, d MMM yyyy',
                      'id_ID',
                    ).format(_selectedDate!),
              style: TextStyle(
                color: _selectedDate == null ? Colors.grey : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector(bool isStart) {
    final time = isStart ? _startTime : _endTime;
    return InkWell(
      onTap: () => _selectTime(context, isStart),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(
              time == null
                  ? (isStart ? 'Mulai' : 'Selesai')
                  : time.format(context),
              style: TextStyle(
                color: time == null ? Colors.grey : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonField() {
    return TextFormField(
      controller: _reasonController,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: 'Alasan Lembur',
        alignLabelWithHint: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Alasan wajib diisi';
        }
        return null;
      },
    );
  }
}
