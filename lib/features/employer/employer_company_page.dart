import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class EmployerCompanyPage extends ConsumerStatefulWidget {
  const EmployerCompanyPage({super.key});

  @override
  ConsumerState<EmployerCompanyPage> createState() => _EmployerCompanyPageState();
}

class _EmployerCompanyPageState extends ConsumerState<EmployerCompanyPage> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _companyDescriptionController = TextEditingController();
  final _companyAddressController = TextEditingController();
  final _websiteController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  
  String _selectedIndustry = 'ເທກໂນໂລຢີສາລະສະໜ່ອງ';
  String _selectedCompanySize = '1-10 ຄົນ';
  
  @override
  void initState() {
    super.initState();
    _loadCompanyData();
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _companyDescriptionController.dispose();
    _companyAddressController.dispose();
    _websiteController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _loadCompanyData() {
    // Load existing company data (mock data)
    _companyNameController.text = 'ABC Technology Co., Ltd.';
    _companyDescriptionController.text = 'ບໍລິສັດຊັ້ນນໍາດ້ານເທກໂນໂລຢີ ມອງຫາຄົນເກ່ງຮ່ວມງານ';
    _companyAddressController.text = 'ວຽງຈັນ, ສປປ ລາວ';
    _websiteController.text = 'https://abc-tech.la';
    _phoneController.text = '020 12345678';
    _emailController.text = 'info@abc-tech.la';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ຂໍ້ມູນບໍລິສັດ'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        elevation: 2,
        actions: [
          TextButton(
            onPressed: _saveCompanyData,
            child: const Text(
              'ບັນທຶກ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Company Logo Section
              _buildLogoSection(),
              const SizedBox(height: 24),
              
              // Basic Information
              _buildBasicInfoSection(),
              const SizedBox(height: 24),
              
              // Contact Information
              _buildContactInfoSection(),
              const SizedBox(height: 24),
              
              // Company Details
              _buildCompanyDetailsSection(),
              const SizedBox(height: 32),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveCompanyData,
                  icon: const Icon(Icons.save),
                  label: const Text('ບັນທຶກຂໍ້ມູນ'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.business, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'ໂລໂກ້ບໍລິສັດ',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                    ),
                    child: Icon(
                      Icons.business,
                      size: 50,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ຟີເຈີອັບໂຫລດຮູບພາບຈະຖືກເພີ່ມໃນເວີຊັນຕໍ່ໄປ')),
                      );
                    },
                    icon: const Icon(Icons.upload),
                    label: const Text('ອັບໂຫລດໂລໂກ້'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'ຂໍ້ມູນພື້ນຖານ',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _companyNameController,
              decoration: const InputDecoration(
                labelText: 'ຊື່ບໍລິສັດ',
                hintText: 'ປ້ອນຊື່ບໍລິສັດ',
                prefixIcon: Icon(Icons.business_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'ກະລຸນາປ້ອນຊື່ບໍລິສັດ';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _companyDescriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'ລາຍລະອຽດບໍລິສັດ',
                hintText: 'ບັນຫາລາຍລະອຽດກ່ຽວກັບບໍລິສັດ',
                prefixIcon: Icon(Icons.description_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'ກະລຸນາປ້ອນລາຍລະອຽດບໍລິສັດ';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfoSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.contact_phone, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'ຂໍ້ມູນຕິດຕໍ່',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'ເບີໂທລະສັບ',
                hintText: '020 12345678',
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'ອີເມວ',
                hintText: 'company@example.com',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _websiteController,
              decoration: const InputDecoration(
                labelText: 'ເວັບໄຊ',
                hintText: 'https://company.com',
                prefixIcon: Icon(Icons.language_outlined),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _companyAddressController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'ທີ່ຢູ່',
                hintText: 'ປ້ອນທີ່ຢູ່ບໍລິສັດ',
                prefixIcon: Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyDetailsSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.category, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'ລາຍລະອຽດເພີ່ມເຕີມ',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedIndustry,
              decoration: const InputDecoration(
                labelText: 'ປະເພດອຸດສາຫະກໍາ',
                prefixIcon: Icon(Icons.business_center_outlined),
                border: OutlineInputBorder(),
              ),
              items: [
                'ເທກໂນໂລຢີສາລະສະໜ່ອງ',
                'ການເງິນ',
                'ການສຶກສາ',
                'ສາທາລະນະສຸກ',
                'ການຄ້າ',
                'ອຸດສາຫະກໍາ',
                'ບໍລິການ',
                'ອື່ນໆ',
              ].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedIndustry = newValue;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCompanySize,
              decoration: const InputDecoration(
                labelText: 'ຂະໜາດບໍລິສັດ',
                prefixIcon: Icon(Icons.people_outline),
                border: OutlineInputBorder(),
              ),
              items: [
                '1-10 ຄົນ',
                '11-50 ຄົນ',
                '51-200 ຄົນ',
                '201-500 ຄົນ',
                '501-1000 ຄົນ',
                '1000+ ຄົນ',
              ].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedCompanySize = newValue;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _saveCompanyData() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ບັນທຶກຂໍ້ມູນບໍລິສັດສໍາເລັດແລ້ວ'),
          backgroundColor: Colors.green,
        ),
      );
      
      // In a real app, you would save the data to a backend
      // For now, just show success message
    }
  }
}