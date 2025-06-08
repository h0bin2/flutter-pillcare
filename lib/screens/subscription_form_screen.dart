import 'package:flutter/material.dart';
import 'pharmacy_screen.dart';

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

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // addConsultationHistory 호출
      await addConsultationHistory(
        context,
        widget.pharmacy,
        _symptomController.text, // history
        'subscribe',
        pillName: _medicineController.text,
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              widget.pharmacy['name'] ?? '',
              style: TextStyle(fontFamily: 'NotoSansKR', fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 2),
            Text(
              '정기구독 신청서',
              style: TextStyle(fontFamily: 'NotoSansKR', fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black87),
            ),
          ],
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
                  labelText: '증상',
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