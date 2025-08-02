// lib/screens/medical_treatment_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ayurbloom/screens/nearby_hospitals_screen.dart';
// For better cart management, consider using 'provider' package.
// This example uses basic StatefulWidget state for simplicity.
// import 'package:provider/provider.dart'; // Uncomment if using Provider

// --- Models ---
class Medicine {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String manufacturer;
  final int stockQuantity;

  Medicine({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.manufacturer,
    required this.stockQuantity,
  });

  factory Medicine.fromFirestore(Map<String, dynamic> data, String id) {
    return Medicine(
      id: id,
      name: data['name'] ?? 'Unknown',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      manufacturer: data['manufacturer'] ?? 'Unknown',
      stockQuantity: data['stockQuantity'] ?? 0,
    );
  }
}

class CartItem {
  final Medicine medicine;
  int quantity;

  CartItem({required this.medicine, required this.quantity});

  // Helper to convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'medicineId': medicine.id,
      'medicineName': medicine.name,
      'price': medicine.price,
      'quantity': quantity,
      'imageUrl': medicine.imageUrl,
    };
  }
}

// --- Main Screen ---
class MedicalTreatmentScreen extends StatefulWidget {
  const MedicalTreatmentScreen({super.key});

  @override
  State<MedicalTreatmentScreen> createState() => _MedicalTreatmentScreenState();
}

class _MedicalTreatmentScreenState extends State<MedicalTreatmentScreen> {
  List<Medicine> _allMedicines = [];
  List<Medicine> _filteredMedicines = [];
  List<CartItem> _cartItems = [];
  double _totalAmount = 0.0;
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String _errorMessage = '';

  // --- Payment Configuration ---
  final String _businessUPI = "9381755655@ybl";
  final String _businessName = "AyurBloom Pharmacy";
  final String _merchantCode = "AYUR001";

  @override
  void initState() {
    super.initState();
    _loadMedicines();
  }

  Future<void> _loadMedicines() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('medicines').get();
      List<Medicine> medicines = snapshot.docs
          .map((doc) =>
              Medicine.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      setState(() {
        _allMedicines = medicines;
        _filteredMedicines = medicines; // Initially show all
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading medicines: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load medicines. Please try again later.';
      });
    }
  }

  // --- Search Functionality ---
  void _performTextSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredMedicines = _allMedicines;
      });
      return;
    }
    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredMedicines = _allMedicines.where((medicine) {
        return medicine.name.toLowerCase().contains(lowerQuery) ||
               medicine.description.toLowerCase().contains(lowerQuery) ||
               medicine.manufacturer.toLowerCase().contains(lowerQuery);
      }).toList();
    });
  }

  // --- Cart Functions ---
  void _addToCart(Medicine medicine) {
    setState(() {
      final existingItemIndex =
          _cartItems.indexWhere((item) => item.medicine.id == medicine.id);
      if (existingItemIndex >= 0) {
        _cartItems[existingItemIndex].quantity++;
      } else {
        _cartItems.add(CartItem(medicine: medicine, quantity: 1));
      }
      _calculateTotal();
    });
    
    // Debug print
    print('Cart items count: ${_cartItems.length}');
    print('Total amount: $_totalAmount');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${medicine.name} added to cart'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _removeFromCart(String medicineId) {
    setState(() {
      _cartItems.removeWhere((item) => item.medicine.id == medicineId);
      _calculateTotal();
    });
  }

  void _updateQuantity(String medicineId, int newQuantity) {
    if (newQuantity <= 0) {
      _removeFromCart(medicineId);
      return;
    }
    setState(() {
      final index = _cartItems.indexWhere((item) => item.medicine.id == medicineId);
      if (index >= 0) {
        _cartItems[index].quantity = newQuantity;
        _calculateTotal();
      }
    });
  }

  void _calculateTotal() {
    double total = 0.0;
    for (var item in _cartItems) {
      total += item.medicine.price * item.quantity;
    }
    setState(() {
      _totalAmount = total;
    });
  }

  // --- Enhanced Payment Processing ---
  Future<void> _processPayment() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty!')),
      );
      return;
    }

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to place an order.')),
      );
      return;
    }

    _showPaymentOptionsDialog();
  }

  void _showPaymentOptionsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Choose Payment Method'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Total Amount: ₹${_totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
              ),
              const SizedBox(height: 20),
              
              // UPI Payment Option
              ListTile(
                leading: const Icon(Icons.account_balance_wallet, color: Colors.blue),
                title: const Text('Pay with UPI'),
                subtitle: const Text('PhonePe, GPay, Paytm, etc.'),
                onTap: () {
                  Navigator.pop(context);
                  _initiateUPIPayment();
                },
              ),
              
              // QR Code Payment Option
              ListTile(
                leading: const Icon(Icons.qr_code, color: Colors.green),
                title: const Text('Show Payment Details'),
                subtitle: const Text('Manual UPI transfer'),
                onTap: () {
                  Navigator.pop(context);
                  _showQRCodePayment();
                },
              ),
              
              // Manual Payment Option
              ListTile(
                leading: const Icon(Icons.phone, color: Colors.orange),
                title: const Text('Call/SMS Payment'),
                subtitle: const Text('Contact us directly'),
                onTap: () {
                  Navigator.pop(context);
                  _showManualPaymentOptions();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // --- UPI Payment ---
  Future<void> _initiateUPIPayment() async {
    final String orderId = 'ORD${DateTime.now().millisecondsSinceEpoch}';
    final User? user = FirebaseAuth.instance.currentUser;
    
    if (user == null) return;

    // Create multiple UPI URIs for different apps
    final List<Map<String, String>> upiApps = [
      {
        'name': 'PhonePe',
        'scheme': 'phonepe://pay',
        'fallback': 'upi://pay'
      },
      {
        'name': 'Google Pay',
        'scheme': 'tez://upi/pay',
        'fallback': 'upi://pay'
      },
      {
        'name': 'Paytm',
        'scheme': 'paytmmp://pay',
        'fallback': 'upi://pay'
      },
      {
        'name': 'Generic UPI',
        'scheme': 'upi://pay',
        'fallback': 'upi://pay'
      },
    ];

    // Try each UPI app
    bool paymentLaunched = false;
    
    for (var app in upiApps) {
      final Uri upiUri = Uri.parse(
        '${app['scheme']}?pa=$_businessUPI&pn=$_businessName&am=${_totalAmount.toStringAsFixed(2)}&cu=INR&tn=Order $orderId from $_businessName'
      );
      
      try {
        if (await canLaunchUrl(upiUri)) {
          await launchUrl(upiUri);
          paymentLaunched = true;
          
          // Show payment confirmation dialog
          _showPaymentConfirmationDialog(orderId, user);
          break;
        }
      } catch (e) {
        print('Error launching ${app['name']}: $e');
        continue;
      }
    }

    if (!paymentLaunched) {
      _showPaymentFallbackDialog(orderId, user);
    }
  }

  // --- Payment Confirmation Dialog ---
  void _showPaymentConfirmationDialog(String orderId, User user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Payment Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.payment, size: 50, color: Colors.blue),
              const SizedBox(height: 15),
              Text('Order ID: $orderId'),
              const SizedBox(height: 10),
              const Text(
                'Have you completed the payment?',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Amount: ₹${_totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // User can retry payment or go back to cart
              },
              child: const Text('No, Retry'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _createOrder(orderId, user);
                if (mounted) {
                  _showSuccessDialog(orderId);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Yes, Paid'),
            ),
          ],
        );
      },
    );
  }

  // --- QR Code Payment ---
  void _showQRCodePayment() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Payment Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey.shade50,
                ),
                child: Column(
                  children: [
                    const Icon(Icons.qr_code_scanner, size: 80, color: Colors.blue),
                    const SizedBox(height: 10),
                    const Text('Scan with any UPI app', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    Text('UPI ID: $_businessUPI', style: const TextStyle(fontSize: 16)),
                    Text('Amount: ₹${_totalAmount.toStringAsFixed(2)}', 
                         style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                    const SizedBox(height: 10),
                    const Text('Or copy UPI ID and pay manually', 
                               style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      _businessUPI,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // Copy to clipboard functionality can be added here
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('UPI ID copied to clipboard')),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 20),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                final String orderId = 'ORD${DateTime.now().millisecondsSinceEpoch}';
                final User? user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  _showPaymentConfirmationDialog(orderId, user);
                }
              },
              child: const Text('I\'ve Paid'),
            ),
          ],
        );
      },
    );
  }

  // --- Manual Payment Options ---
  void _showManualPaymentOptions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Contact for Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Order Amount: ₹${_totalAmount.toStringAsFixed(2)}', 
                   style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
              const SizedBox(height: 15),
              const Text('Payment Details:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              SelectableText('UPI ID: $_businessUPI'),
              SelectableText('Phone: ${_businessUPI.split('@')[0]}'),
              const SizedBox(height: 15),
              const Text('Contact us directly:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final Uri phoneUri = Uri(scheme: 'tel', path: '9381755655');
                        if (await canLaunchUrl(phoneUri)) {
                          await launchUrl(phoneUri);
                        }
                      },
                      icon: const Icon(Icons.phone, size: 16),
                      label: const Text('Call Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final Uri smsUri = Uri(
                          scheme: 'sms',
                          path: '9381755655',
                          queryParameters: {'body': 'Hi, I want to place an order for ₹${_totalAmount.toStringAsFixed(2)} from AyurBloom Pharmacy'},
                        );
                        if (await canLaunchUrl(smsUri)) {
                          await launchUrl(smsUri);
                        }
                      },
                      icon: const Icon(Icons.message, size: 16),
                      label: const Text('SMS'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                final String orderId = 'ORD${DateTime.now().millisecondsSinceEpoch}';
                final User? user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  _showPaymentConfirmationDialog(orderId, user);
                }
              },
              child: const Text('I\'ve Paid'),
            ),
          ],
        );
      },
    );
  }

  // --- Enhanced Payment Fallback ---
  void _showPaymentFallbackDialog(String orderId, User user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('UPI App Not Found'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning, size: 50, color: Colors.orange),
              const SizedBox(height: 15),
              const Text('No UPI app found on your device.'),
              const SizedBox(height: 15),
              const Text('You can:'),
              const SizedBox(height: 10),
              const Text('• Install PhonePe, GPay, or Paytm'),
              const Text('• Use manual payment options'),
              const Text('• Call us directly'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showManualPaymentOptions();
              },
              child: const Text('Manual Payment'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createOrder(String orderId, User user) async {
    try {
      final orderData = {
        'orderId': orderId,
        'userId': user.uid,
        'userEmail': user.email ?? 'N/A',
        'items': _cartItems.map((item) => item.toMap()).toList(),
        'totalAmount': _totalAmount,
        'finalAmount': _totalAmount,
        'orderDate': FieldValue.serverTimestamp(),
        'status': 'Payment Completed',
        'paymentMethod': 'UPI',
        'businessUPI': _businessUPI,
      };

      await FirebaseFirestore.instance.collection('orders').doc(orderId).set(orderData);
      print("Order $orderId created in Firestore.");

      // Clear cart after successful order creation
      setState(() {
        _cartItems.clear();
        _totalAmount = 0.0;
      });

    } catch (e) {
      print('Error creating order: $e');
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order creation failed: $e')),
        );
      }
    }
  }

  void _showSuccessDialog(String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 30),
              SizedBox(width: 10),
              Text('Order Placed Successfully!'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Thank you for your order!',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 10),
                Text(
                  'Order ID: $orderId',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.local_shipping, color: Colors.green, size: 40),
                      SizedBox(height: 10),
                      Text(
                        'Your medicines will be delivered shortly.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'You will receive updates on the order status.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'For any queries, call: 9381755655',
                        style: TextStyle(fontSize: 12, color: Colors.blue),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showCart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: Text(
                  'Your Cart',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(),
              if (_cartItems.isEmpty)
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                        SizedBox(height: 20),
                        Text('Your cart is empty', style: TextStyle(fontSize: 18)),
                        SizedBox(height: 10),
                        Text('Add medicines from the list', style: TextStyle(fontSize: 14, color: Colors.grey)),
                      ],
                    ),
                  ),
                )
              else
                ...[
                  Expanded(
                    child: ListView.builder(
                      itemCount: _cartItems.length,
                      itemBuilder: (context, index) {
                        final item = _cartItems[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          elevation: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: item.medicine.imageUrl.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            item.medicine.imageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) =>
                                                const Icon(Icons.medication, color: Colors.grey),
                                          ))
                                      : const Icon(Icons.medication, color: Colors.grey),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.medicine.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '₹${item.medicine.price.toStringAsFixed(2)}',
                                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        item.medicine.manufacturer,
                                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        _updateQuantity(item.medicine.id, item.quantity - 1);
                                        Navigator.pop(context);
                                        _showCart();
                                      },
                                      icon: const Icon(Icons.remove_circle_outline),
                                      splashRadius: 20,
                                      padding: EdgeInsets.zero,
                                    ),
                                    Text('${item.quantity}'),
                                    IconButton(
                                      onPressed: () {
                                        _updateQuantity(item.medicine.id, item.quantity + 1);
                                        Navigator.pop(context);
                                        _showCart();
                                      },
                                      icon: const Icon(Icons.add_circle_outline),
                                      splashRadius: 20,
                                      padding: EdgeInsets.zero,
                                    ),
                                  ],
                                ),
                                IconButton(
                                  onPressed: () {
                                    _removeFromCart(item.medicine.id);
                                    Navigator.pop(context);
                                    _showCart();
                                  },
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  splashRadius: 20,
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '₹${_totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _processPayment();
                      },
                      icon: const Icon(Icons.payment),
                      label: const Text('Proceed to Pay'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                ],
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AyurBloom Pharmacy'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.local_hospital_outlined),
            tooltip: 'Find Hospitals',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NearbyHospitalsScreen(),
               ),
               );
            },
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                tooltip: 'View Cart',
                onPressed: _showCart,
              ),
              if (_cartItems.isNotEmpty)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${_cartItems.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- Search Bar ---
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search medicines...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performTextSearch('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade200,
              ),
              onChanged: _performTextSearch,
            ),
          ),
          // --- Main Content Area ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 50, color: Colors.red),
                              const SizedBox(height: 15),
                              Text(_errorMessage, textAlign: TextAlign.center),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: _loadMedicines,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                              )
                            ],
                          ),
                        ),
                      )
                    : _filteredMedicines.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.production_quantity_limits, size: 60, color: Colors.grey),
                                SizedBox(height: 15),
                                Text(
                                  'No medicines found',
                                  style: TextStyle(fontSize: 18, color: Colors.grey),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'Try a different search term',
                                  style: TextStyle(fontSize: 14, color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(12.0),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.7,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: _filteredMedicines.length,
                            itemBuilder: (context, index) {
                              final medicine = _filteredMedicines[index];
                              return Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('${medicine.name} - Tap "Add" to include in cart'),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(15.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Medicine Image
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(15.0)),
                                          child: medicine.imageUrl.isNotEmpty
                                              ? Image.network(
                                                  medicine.imageUrl,
                                                  fit: BoxFit.cover,
                                                  width: double.infinity,
                                                  errorBuilder: (context, error, stackTrace) => Container(
                                                    color: Colors.grey.shade300,
                                                    child: const Icon(Icons.image_not_supported, color: Colors.grey),
                                                  ),
                                                )
                                              : Container(
                                                  color: Colors.grey.shade300,
                                                  child: const Icon(Icons.medication, size: 40, color: Colors.grey),
                                                ),
                                        ),
                                      ),
                                      // Medicine Details
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              medicine.name,
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              medicine.manufacturer,
                                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 5),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  '₹${medicine.price.toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                      fontWeight: FontWeight.bold, color: Colors.green),
                                                ),
                                                if (medicine.stockQuantity > 0) ...[
                                                  ElevatedButton(
                                                    onPressed: () => _addToCart(medicine),
                                                    style: ElevatedButton.styleFrom(
                                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                      backgroundColor: Colors.teal.shade700,
                                                      foregroundColor: Colors.white,
                                                      textStyle: const TextStyle(fontSize: 12),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(20),
                                                      ),
                                                    ),
                                                    child: const Text('Add'),
                                                  ),
                                                ] else
                                                  const Text(
                                                    'Out of Stock',
                                                    style: TextStyle(color: Colors.red, fontSize: 12),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}