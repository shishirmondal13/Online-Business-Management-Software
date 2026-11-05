import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/app_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/employee.dart';
import '../providers/employee_provider.dart';

class AddEditEmployeeScreen extends ConsumerStatefulWidget {
  final Employee? employee;

  const AddEditEmployeeScreen({super.key, this.employee});

  @override
  ConsumerState<AddEditEmployeeScreen> createState() =>
      _AddEditEmployeeScreenState();
}

class _AddEditEmployeeScreenState extends ConsumerState<AddEditEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _designationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _salaryController = TextEditingController();
  DateTime _joiningDate = DateTime.now();
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.employee != null) {
      final e = widget.employee!;
      _nameController.text = e.name;
      _designationController.text = e.designation;
      _phoneController.text = e.phone;
      _emailController.text = e.email;
      _addressController.text = e.address;
      _salaryController.text = e.salary.toString();
      _joiningDate = e.joiningDate;
      _isActive = e.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _designationController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) throw Exception('User not logged in');

      final now = DateTime.now();
      final salary = double.tryParse(_salaryController.text) ?? 0;

      if (widget.employee != null) {
        // Update
        final updatedEmployee = widget.employee!.copyWith(
          name: _nameController.text.trim(),
          designation: _designationController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          address: _addressController.text.trim(),
          salary: salary,
          joiningDate: _joiningDate,
          isActive: _isActive,
          updatedAt: now,
        );
        await ref.read(employeeServiceProvider).updateEmployee(updatedEmployee);
      } else {
        // Add
        final newEmployee = Employee(
          id: const Uuid().v4(),
          userId: userId,
          createdAt: now,
          updatedAt: now,
          name: _nameController.text.trim(),
          designation: _designationController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          address: _addressController.text.trim(),
          salary: salary,
          joiningDate: _joiningDate,
          isActive: _isActive,
        );
        await ref.read(employeeServiceProvider).addEmployee(newEmployee);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.employee != null
                  ? 'Employee updated successfully'
                  : 'Employee added successfully',
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.employee != null ? 'Edit Employee' : 'Add Employee'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                controller: _nameController,
                label: 'Full Name',
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _designationController,
                label: 'Designation',
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _phoneController,
                label: 'Phone Number',
                keyboardType: TextInputType.phone,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _emailController,
                label: 'Email (Optional)',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _addressController,
                label: 'Address',
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              AppCurrencyField(
                controller: _salaryController,
                label: 'Monthly Salary',
              ),
              const SizedBox(height: 16),
              AppDateField(
                value: _joiningDate,
                label: 'Joining Date',
                onChanged: (d) => setState(() => _joiningDate = d),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Active Status'),
                subtitle: Text(
                  _isActive
                      ? 'Employee is currently active'
                      : 'Employee is inactive',
                ),
                value: _isActive,
                onChanged: (val) => setState(() => _isActive = val),
              ),
              const SizedBox(height: 24),
              AppButton(
                text: widget.employee != null
                    ? 'Update Employee'
                    : 'Add Employee',
                onPressed: _isLoading ? null : _handleSubmit,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
