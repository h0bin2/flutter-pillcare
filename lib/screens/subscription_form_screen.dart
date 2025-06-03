import 'package:flutter/material.dart';

class SubscriptionFormScreen extends StatefulWidget {
  final Map<String, dynamic> pharmacy;
  const SubscriptionFormScreen({Key? key, required this.pharmacy}) : super(key: key);

  @override
  State<SubscriptionFormScreen> createState() => _SubscriptionFormScreenState();
}

class _SubscriptionFormScreenState extends State<SubscriptionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _medicineController = TextEditingController();
  final TextEditingController _symptomController = TextEditingController();

  @override
  void dispose() {
    _medicineController.dispose();
    _symptomController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // TODO: 신청서 제출 로직 구현
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('신청서가 제출되었습니다!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.pharmacy['name']} 정기구독 신청서',
          style: TextStyle(fontFamily: 'NotoSansKR', fontSize: 28, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _medicineController,
                decoration: InputDecoration(
                  labelText: '신청할 약 이름',
                  labelStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, fontFamily: 'NotoSansKR'),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty ? '약 이름을 입력하세요.' : null,
              ),
              SizedBox(height: 24),
              TextFormField(
                controller: _symptomController,
                decoration: InputDecoration(
                  labelText: '증상(선택)',
                  labelStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, fontFamily: 'NotoSansKR'),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFFB300),
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 18),
                  textStyle: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, fontFamily: 'NotoSansKR'),
                ),
                child: Text('신청하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 