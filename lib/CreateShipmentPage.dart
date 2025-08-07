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

  Future<void> submitShipment(String paymentMethod) async {
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
        final shipmentData = json.decode(response.body);
        final shipmentId = shipmentData['id'];

        final paymentResponse = await http.post(
          Uri.parse('http://10.0.2.2:9090/api/payments'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'amount': selectedCity!.deliveryCost,
            'shipmentId': shipmentId,
            'method': paymentMethod,
            'status': 'PAID',
          }),
        );

        if (paymentResponse.statusCode == 200 ||
            paymentResponse.statusCode == 201) {
          _showSuccessSnackbar('تم إنشاء الشحنة والدفع بنجاح!');
          _formKey.currentState!.reset();
          setState(() => selectedCity = null);
        } else {
          _showErrorSnackbar('تم إنشاء الشحنة ولكن فشل الدفع');
        }
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
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  // ... [ابقاء دوال fetchCities و submitShipment و showErrorSnackbar كما هي] ...

  Future<void> _showPaymentMethodDialog() async {
    String selectedMethod = 'CASH';

    await showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'اختر طريقة الدفع',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButtonFormField<String>(
                      value: selectedMethod,
                      items: [
                        DropdownMenuItem(
                          value: 'CASH',
                          child: Row(
                            children: [
                              Icon(Icons.money, color: Colors.green),
                              SizedBox(width: 10),
                              Text(
                                'نقداً',
                                style: TextStyle(color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'CARD',
                          child: Row(
                            children: [
                              Icon(Icons.credit_card, color: Colors.blue),
                              SizedBox(width: 10),
                              Text(
                                'بطاقة',
                                style: TextStyle(color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (val) => selectedMethod = val!,
                      decoration: InputDecoration(border: InputBorder.none),
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      TextButton(
                        child: Text(
                          'إلغاء',
                          style: TextStyle(color: Colors.grey),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 25,
                            vertical: 12,
                          ),
                        ),
                        child: Text(
                          'تأكيد',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          submitShipment(selectedMethod);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'إنشاء شحنة جديدة',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.deepPurple,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body:
          isLoadingCities
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.deepPurple,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'جاري تحميل المدن...',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                padding: EdgeInsets.all(25),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'معلومات الشحنة',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      SizedBox(height: 5),
                      Divider(color: Colors.grey[300]),
                      SizedBox(height: 20),

                      _buildModernInputField(
                        descriptionController,
                        'وصف الشحنة',
                        Icons.description,
                      ),
                      SizedBox(height: 20),

                      Text(
                        'معلومات المرسل',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      SizedBox(height: 5),
                      Divider(color: Colors.grey[300]),
                      SizedBox(height: 20),

                      _buildModernInputField(
                        senderNameController,
                        'اسم المرسل',
                        Icons.person,
                      ),
                      SizedBox(height: 20),

                      Text(
                        'معلومات المستلم',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      SizedBox(height: 5),
                      Divider(color: Colors.grey[300]),
                      SizedBox(height: 20),

                      _buildModernInputField(
                        receiverNameController,
                        'اسم المستلم',
                        Icons.person_outline,
                      ),
                      SizedBox(height: 20),

                      _buildModernInputField(
                        receiverPhoneController,
                        'هاتف المستلم',
                        Icons.phone,
                        keyboardType: TextInputType.phone,
                      ),
                      SizedBox(height: 20),

                      Text(
                        'وجهة الشحنة',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      SizedBox(height: 5),
                      Divider(color: Colors.grey[300]),
                      SizedBox(height: 20),

                      _buildModernCityDropdown(),
                      SizedBox(height: 30),

                      if (selectedCity != null)
                        Container(
                          padding: EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple[50],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info, color: Colors.deepPurple),
                              SizedBox(width: 10),
                              Text(
                                'تكلفة التوصيل: ${selectedCity!.deliveryCost} د.ل',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(height: 20),

                      ElevatedButton(
                        onPressed:
                            isSubmitting ? null : _showPaymentMethodDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          elevation: 3,
                        ),
                        child:
                            isSubmitting
                                ? SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                : Text(
                                  'إنشاء الشحنة',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildModernInputField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600]),
        prefixIcon: Icon(icon, color: Colors.deepPurple),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.deepPurple, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
      validator: (v) => v == null || v.isEmpty ? 'هذا الحقل مطلوب' : null,
    );
  }

  Widget _buildModernCityDropdown() {
    return DropdownButtonFormField<City>(
      value: selectedCity,
      items:
          cities
              .map(
                (city) => DropdownMenuItem(
                  value: city,
                  child: Text(
                    '${city.name} - ${city.deliveryCost} د.ل',
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ),
              )
              .toList(),
      onChanged: (val) => setState(() => selectedCity = val),
      decoration: InputDecoration(
        labelText: 'اختر المدينة',
        labelStyle: TextStyle(color: Colors.grey[600]),
        prefixIcon: Icon(Icons.location_city, color: Colors.deepPurple),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.deepPurple, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
      validator: (value) => value == null ? 'يرجى اختيار مدينة' : null,
      style: TextStyle(fontSize: 16),
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(12),
      icon: Icon(Icons.arrow_drop_down, color: Colors.deepPurple),
    );
  }
}
