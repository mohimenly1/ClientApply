import 'package:clientapply/models/city.dart';
import 'package:clientapply/models/shipmentrequest.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CreateShipmentPage extends StatefulWidget {
  @override
  _CreateShipmentPageState createState() => _CreateShipmentPageState();
}

class _CreateShipmentPageState extends State<CreateShipmentPage> {
  final _formKey = GlobalKey<FormState>();
  List<City> cities = [];
  City? selectedCity;

  final descriptionController = TextEditingController();
  final senderNameController = TextEditingController();
  final receiverNameController = TextEditingController();
  final receiverPhoneController = TextEditingController();

  final int customerId = 1;
  bool isLoadingCities = true;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    fetchCities();
  }

  Future<void> fetchCities() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:9090/api/cities'),
        headers: {'Accept-Charset': 'utf-8'},
      );
      if (response.statusCode == 200) {
        final utf8Body = utf8.decode(response.bodyBytes);
        final List jsonList = json.decode(utf8Body);
        setState(() {
          cities = jsonList.map((json) => City.fromJson(json)).toList();
          isLoadingCities = false;
        });
      } else {
        setState(() => isLoadingCities = false);
        _showErrorSnackbar('فشل تحميل المدن، يرجى المحاولة لاحقاً');
      }
    } catch (e) {
      setState(() => isLoadingCities = false);
      _showErrorSnackbar('حدث خطأ في الاتصال بالخادم');
    }
  }

  Future<void> submitShipment() async {
    if (!_formKey.currentState!.validate() || selectedCity == null) {
      _showErrorSnackbar('يرجى ملء جميع الحقول المطلوبة');
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final shipmentRequest = ShipmentRequest(
        description: descriptionController.text,
        senderName: senderNameController.text,
        receiverName: receiverNameController.text,
        receiverPhone: receiverPhoneController.text,
        cityId: selectedCity!.id,
        customerId: customerId,
      );

      final response = await http.post(
        Uri.parse('http://10.0.2.2:9090/api/shipments'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(shipmentRequest.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccessSnackbar('تم إنشاء الشحنة بنجاح!');
        _formKey.currentState!.reset();
        setState(() => selectedCity = null);
      } else {
        _showErrorSnackbar('فشل في إنشاء الشحنة: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackbar('حدث خطأ أثناء إرسال البيانات');
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'إنشاء شحنة جديدة',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue[800],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body:
          isLoadingCities
              ? _buildLoadingIndicator()
              : SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeaderSection(),
                      SizedBox(height: 20),
                      _buildInputField(
                        controller: descriptionController,
                        label: 'وصف الشحنة',
                        icon: Icons.description,
                        validator: (v) => v!.isEmpty ? 'يرجى إدخال وصف' : null,
                      ),
                      SizedBox(height: 15),
                      _buildInputField(
                        controller: senderNameController,
                        label: 'اسم المرسل',
                        icon: Icons.person_outline,
                        validator:
                            (v) => v!.isEmpty ? 'يرجى إدخال اسم المرسل' : null,
                      ),
                      SizedBox(height: 15),
                      _buildInputField(
                        controller: receiverNameController,
                        label: 'اسم المستلم',
                        icon: Icons.person,
                        validator:
                            (v) => v!.isEmpty ? 'يرجى إدخال اسم المستلم' : null,
                      ),
                      SizedBox(height: 15),
                      _buildInputField(
                        controller: receiverPhoneController,
                        label: 'هاتف المستلم',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        validator:
                            (v) => v!.isEmpty ? 'يرجى إدخال رقم الهاتف' : null,
                      ),
                      SizedBox(height: 20),
                      _buildCityDropdown(),
                      SizedBox(height: 30),
                      _buildSubmitButton(),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[800]!),
            strokeWidth: 5,
          ),
          SizedBox(height: 20),
          Text(
            'جاري تحميل بيانات المدن...',
            style: TextStyle(fontSize: 16, color: Colors.blue[800]),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      children: [
        Icon(Icons.local_shipping, size: 100, color: Colors.blue[800]),
        SizedBox(height: 10),
        Text(
          'املأ بيانات الشحنة',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.blue[900],
          ),
        ),
        SizedBox(height: 5),
        Text(
          'سنقوم بتوصيل شحنتك بأمان وسرعة',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue[700]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.blue, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      ),
      validator: validator,
    );
  }

  Widget _buildCityDropdown() {
    return DropdownButtonFormField<City>(
      value: selectedCity,
      items:
          cities
              .map(
                (city) => DropdownMenuItem(
                  value: city,
                  child: Row(
                    children: [
                      Icon(Icons.location_city, color: Colors.blue[700]),
                      SizedBox(width: 10),
                      Text(
                        '${city.name} (سعر التوصيل: ${city.deliveryCost} د.ل)',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
      onChanged: (val) => setState(() => selectedCity = val),
      decoration: InputDecoration(
        labelText: 'اختر المدينة',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 20),
      ),
      validator: (value) => value == null ? 'يرجى اختيار مدينة' : null,
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(10),
      icon: Icon(Icons.arrow_drop_down, color: Colors.blue[700]),
      isExpanded: true,
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: isSubmitting ? null : submitShipment,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 15),
        child:
            isSubmitting
                ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                : Text(
                  'إنشاء الشحنة',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
      ),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.blue[800],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 5,
        shadowColor: Colors.blue.withOpacity(0.3),
      ),
    );
  }
}
