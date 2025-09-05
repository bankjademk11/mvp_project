import 'package:flutter/material.dart';

class PostJobPage extends StatefulWidget {
  const PostJobPage({super.key});

  @override
  State<PostJobPage> createState() => _PostJobPageState();
}

class _PostJobPageState extends State<PostJobPage> {
  final _title = TextEditingController();
  final _company = TextEditingController();
  final _province = TextEditingController();
  final _salaryMin = TextEditingController(text: '6000000');
  final _salaryMax = TextEditingController(text: '10000000');
  final _desc = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ປະກາດວຽກ (UI)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _title, decoration: const InputDecoration(labelText: 'ຕຳແໜ່ງ')),
          const SizedBox(height: 12),
          TextField(controller: _company, decoration: const InputDecoration(labelText: 'ບໍລິສັດ')),
          const SizedBox(height: 12),
          TextField(controller: _province, decoration: const InputDecoration(labelText: 'ແຂວງ')),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: TextField(controller: _salaryMin, decoration: const InputDecoration(labelText: 'ຂັ້ນຕ່ຳ (LAK)'))),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: _salaryMax, decoration: const InputDecoration(labelText: 'ຂັ້ນສູງ (LAK)'))),
            ],
          ),
          const SizedBox(height: 12),
          TextField(controller: _desc, maxLines: 6, decoration: const InputDecoration(labelText: 'ລາຍລະອຽດວຽກ')),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ບັນທຶກ (mock UI ເທົ່ານັ້ນ)')));
              Navigator.pop(context);
            },
            child: const Text('ບັນທຶກ'),
          ),
        ],
      ),
    );
  }
}