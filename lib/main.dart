import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibration/vibration.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:women_safety_app/config/app_config.dart';
import 'package:women_safety_app/core/services/shake_service.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  await dotenv.load();

  // Initialize Firebase for logging only (non-blocking)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // Firebase initialization failed - app can still work without logging
    debugPrint('Firebase initialization failed: $e');
  }

  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
  final hasContacts = prefs.getString('emergency_contacts') != null;
  final hasUserData = prefs.getString('user_name') != null;

  if (!isLoggedIn && hasUserData && hasContacts) {
    await prefs.setBool('is_logged_in', true);
  }

  runApp(
    WomenSafetyApp(
      initialRoute:
          isLoggedIn ? (hasContacts ? '/dashboard' : '/contacts') : '/welcome',
    ),
  );
}
class WomenSafetyApp extends StatelessWidget {
  final String initialRoute;

  const WomenSafetyApp({super.key, this.initialRoute = '/welcome'});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Safety Shield Pro',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        fontFamily: 'SF Pro Display',
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      initialRoute: initialRoute,
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/contacts': (context) => const ContactsSetupScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/support-chat': (context) => const SupportChatScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.5,
            colors: [Color(0xFF0f0c29), Color(0xFF302b63), Color(0xFF24243e)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.purple, Colors.blue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.security,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Safety Shield Pro',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Your Ultimate Safety Companion',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 40),
                const Text(
                  '🔐 App Permissions Required',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                _buildPermissionItem(
                  '📍 Location Access - For emergency location sharing',
                ),
                _buildPermissionItem(
                  '📞 Phone & SMS - For emergency calls and alerts',
                ),
                _buildPermissionItem(
                  '🔊 Notifications - For important safety alerts',
                ),
                const SizedBox(height: 20),
                const Text(
                  '🚨 Emergency Features:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '• One-tap SOS & Emergency alerts\n• Real-time location sharing\n• Direct SMS/WhatsApp messages\n• Quick emergency calls',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () async {
                      await Permission.location.request();
                      await Permission.phone.request();
                      await Permission.sms.request();
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                    child: const Text(
                      'GRANT PERMISSIONS & CONTINUE',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      
      // ADDED: Floating Action Button added cleanly outside the body container context!
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.cyan,
        child: const Icon(Icons.psychology, color: Colors.white, size: 30),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const JarvisVoiceScreen()),
          );
        },
      ),
    );
  }

  Widget _buildPermissionItem(String text) {
    return ListTile(
      leading: const Icon(Icons.check_circle, color: Colors.green, size: 20),
      title: Text(
        text,
        style: const TextStyle(color: Colors.white70, fontSize: 14),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  Future<void> _login() async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      _showError('Please enter your name and phone number');
      return;
    }

    if (!_isValidPhone(_phoneController.text)) {
      _showError('Please enter a valid phone number (+91 format)');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _nameController.text);
    await prefs.setString('user_phone', _phoneController.text);
    await prefs.setBool('is_logged_in', true);

    Navigator.pushReplacementNamed(context, '/contacts');
  }

  bool _isValidPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[+\s]'), '');
    return RegExp(r'^91[6-9]\d{9}$').hasMatch(cleaned) ||
        RegExp(r'^[6-9]\d{9}$').hasMatch(cleaned);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.5,
            colors: [Color(0xFF0f0c29), Color(0xFF302b63), Color(0xFF24243e)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.purple, Colors.blue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.security,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Safety Shield Pro',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Setup Your Profile',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Your Name',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white30),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.purple),
                    ),
                    prefixIcon: Icon(Icons.person, color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Your Phone (+91XXXXXXXXXX)',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white30),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.purple),
                    ),
                    prefixIcon: Icon(Icons.phone, color: Colors.white70),
                    prefixText: '+91 ',
                  ),
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                    child: const Text(
                      'CONTINUE TO CONTACTS',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ContactsSetupScreen extends StatefulWidget {
  const ContactsSetupScreen({super.key});

  @override
  State<ContactsSetupScreen> createState() => _ContactsSetupScreenState();
}

class _ContactsSetupScreenState extends State<ContactsSetupScreen> {
  final List<TextEditingController> _nameControllers = List.generate(
    3,
    (_) => TextEditingController(),
  );
  final List<TextEditingController> _phoneControllers = List.generate(
    3,
    (_) => TextEditingController(),
  );

  Future<void> _saveContacts() async {
    int filledContacts = 0;
    final List<Map<String, String>> contacts = [];

    for (int i = 0; i < 3; i++) {
      final name = _nameControllers[i].text.trim();
      final phone = _phoneControllers[i].text.trim();

      if (name.isNotEmpty && phone.isNotEmpty) {
        if (!_isValidPhone(phone)) {
          _showError('Invalid phone number for Contact ${i + 1}');
          return;
        }
        contacts.add({'name': name, 'phone': _formatPhone(phone)});
        filledContacts++;
      }
    }

    if (filledContacts < 1) {
      _showError('Please add at least 1 emergency contact');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('emergency_contacts', json.encode(contacts));

    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  bool _isValidPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[+\s]'), '');
    return RegExp(r'^91[6-9]\d{9}$').hasMatch(cleaned) ||
        RegExp(r'^[6-9]\d{9}$').hasMatch(cleaned);
  }

  String _formatPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[+\s]'), '');
    if (cleaned.length == 10) {
      return '+91$cleaned';
    }
    return '+$cleaned';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.5,
            colors: [Color(0xFF0f0c29), Color(0xFF302b63), Color(0xFF24243e)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                'Add Emergency Contacts (1-3)',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'These contacts will receive emergency alerts',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: 3,
                  itemBuilder: (context, index) {
                    return _buildContactCard(index);
                  },
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveContacts,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'SAVE & ACTIVATE',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  

  Widget _buildContactCard(int index) {
    return Card(
      color: Colors.white.withOpacity(0.05),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact ${index + 1}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameControllers[index],
              decoration: const InputDecoration(
                labelText: 'Name',
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white30),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.purple),
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneControllers[index],
              decoration: const InputDecoration(
                labelText: 'Phone (+91XXXXXXXXXX)',
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white30),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.purple),
                ),
                prefixText: '+91 ',
              ),
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class LocationService {
  static Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      return null;
    }
  }

  static String getGoogleMapsLink(double latitude, double longitude) {
    return 'https://maps.google.com/?q=$latitude,$longitude';
  }
}

class SMSService {
  static Future<bool> sendDirectSMS(String phone, String message) async {
    try {
      final cleanedPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
      final Uri smsUri = Uri(
        scheme: 'sms',
        path: cleanedPhone,
        queryParameters: {'body': message},
      );

      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> sendWhatsApp(String phone, String message) async {
    try {
      final cleanedPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
      final whatsappNumber = cleanedPhone.startsWith('91')
          ? cleanedPhone.substring(2)
          : cleanedPhone;

      final Uri whatsappUri = Uri(
        scheme: 'https',
        host: 'wa.me',
        path: whatsappNumber,
        queryParameters: {'text': message},
      );

      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

class SafetyService {
  static final SafetyService _instance = SafetyService._internal();
  factory SafetyService() => _instance;
  SafetyService._internal();

  List<Map<String, String>> _contacts = [];
  String? _userName;
  String? _userPhone;
  Position? _lastLocation;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString('user_name');
    _userPhone = prefs.getString('user_phone');

    final contactsJson = prefs.getString('emergency_contacts');
    if (contactsJson != null) {
      final List<dynamic> contactsList = json.decode(contactsJson);
      _contacts = contactsList.map<Map<String, String>>((contact) {
        return {
          'name': contact['name'] as String,
          'phone': contact['phone'] as String,
        };
      }).toList();
    }

    await _updateLocation();
  }

  Future<void> _updateLocation() async {
    try {
      _lastLocation = await LocationService.getCurrentLocation();
    } catch (e) {
      print('Location update failed: $e');
    }
  }

  String _getLocationText() {
    if (_lastLocation != null) {
      final mapsLink = LocationService.getGoogleMapsLink(
        _lastLocation!.latitude,
        _lastLocation!.longitude,
      );
      return '📍 Location: ${_lastLocation!.latitude.toStringAsFixed(6)}, ${_lastLocation!.longitude.toStringAsFixed(6)}\n🗺️ Maps: $mapsLink';
    }
    return '📍 Location: Unable to get current location';
  }

  Future<void> triggerSOS({bool useWhatsApp = false}) async {
    await _updateLocation();

    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(pattern: [500, 1000, 500, 1000]);
    }

    final message = '''
🚨 SOS ALERT from $_userName!

I need immediate help! Please contact me or alert authorities.

My phone: $_userPhone
Time: ${DateTime.now()}
${_getLocationText()}

This is an automated emergency alert from Safety Shield Pro.
''';

    final phones = _contacts.map((contact) => contact['phone']!).toList();
    for (final phone in phones) {
      if (useWhatsApp) {
        await SMSService.sendWhatsApp(phone, message);
      } else {
        await SMSService.sendDirectSMS(phone, message);
      }
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  Future<void> triggerEmergency({bool useWhatsApp = false}) async {
    await _updateLocation();

    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 2000);
    }

    final message = '''
🚨 EMERGENCY ALERT from $_userName!

I need URGENT assistance! Please contact me immediately.

My phone: $_userPhone
Time: ${DateTime.now()}
${_getLocationText()}

This is an automated emergency alert from Safety Shield Pro.
''';

    final phones = _contacts.map((contact) => contact['phone']!).toList();
    for (final phone in phones) {
      if (useWhatsApp) {
        await SMSService.sendWhatsApp(phone, message);
      } else {
        await SMSService.sendDirectSMS(phone, message);
      }
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  List<Map<String, String>> get contacts => _contacts;
  String? get userName => _userName;
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final SafetyService _safetyService = SafetyService();
  late ShakeService _shakeService;
  String _currentTime = '';
  String _currentDate = '';
  String _currentLocation = 'Getting location...';
  Timer? _timer;
  List<Map<String, dynamic>> _activityLog = [];

  @override
  void initState() {
    super.initState();
    _initializeApp();
    _initializeShakeDetector();
    _updateDateTime();
    _updateLocation();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateDateTime();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shakeService.dispose();
    super.dispose();
  }

  /// Initialize shake detector for emergency trigger via device vibration
  void _initializeShakeDetector() {
    _shakeService = ShakeService(
      onShakeDetected: () {
        _logActivity('Emergency triggered via shake gesture', 'SHAKE');
        _triggerEmergencyViaSMS();
      },
    );
    _shakeService.initialize();
  }

  /// Trigger emergency alert via SMS using sequential contact loop
  Future<void> _triggerEmergencyViaSMS() async {
    try {
      await _safetyService.triggerEmergency(useWhatsApp: false);
      _logActivity('Emergency alert sent via SMS', 'EMERGENCY');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Emergency alert sent to all contacts via SMS'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      _logActivity('Emergency alert failed: $e', 'ERROR');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send emergency alert'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _initializeApp() async {
    await _safetyService.initialize();
    _logActivity("App activated", "System");
  }

  void _logActivity(String action, String type) {
    setState(() {
      _activityLog.insert(0, {
        'action': action,
        'type': type,
        'timestamp': DateTime.now(),
      });
    });
  }

  void _updateDateTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      _currentDate =
          '${_getWeekday(now.weekday)}, ${now.day} ${_getMonth(now.month)}';
    });
  }

  Future<void> _updateLocation() async {
    final position = await LocationService.getCurrentLocation();
    if (position != null) {
      setState(() {
        _currentLocation =
            '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      });
    }
  }

  String _getWeekday(int weekday) {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days[weekday - 1];
  }

  String _getMonth(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.5,
            colors: [Color(0xFF0f0c29), Color(0xFF302b63), Color(0xFF24243e)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeaderSection(),
              const SizedBox(height: 20),
              _buildEmergencySection(),
              const SizedBox(height: 20),
              _buildQuickActions(),
              const SizedBox(height: 20),
              _buildActivitySection(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.cyan,
        icon: const Icon(Icons.psychology, color: Colors.white),
        label: const Text("Talk to Mitra", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const JarvisVoiceScreen()),
          );
        },
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentTime,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _currentDate,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hello, ${_safetyService.userName ?? "User"}',
                  style: const TextStyle(fontSize: 12, color: Colors.white60),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 12,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _currentLocation,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.green,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.green, Colors.lightGreen],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.security, size: 16, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'ACTIVE',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const Text(
            'EMERGENCY RESPONSE',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildEmergencyButton(
                'SOS',
                'Quick Alert',
                Icons.warning_amber,
                Colors.orange,
                () => _showSendOptions('SOS'),
              ),
              _buildEmergencyButton(
                'EMERGENCY',
                'Full Alert',
                Icons.emergency,
                Colors.red,
                () => _showSendOptions('EMERGENCY'),
              ),
              _buildEmergencyButton(
                'DISCREET',
                'Silent Help',
                Icons.visibility_off,
                Colors.blue,
                () => _showSendOptions('DISCREET'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  color.withOpacity(0.9),
                  color.withOpacity(0.7),
                  color.withOpacity(0.5),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 9,
            color: Colors.white70,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'QUICK ACTIONS',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: [
              _buildActionItem(
                Icons.contacts,
                'Contacts',
                Colors.purple,
                _viewContacts,
              ),
              _buildActionItem(Icons.call, 'Police', Colors.blue, _callPolice),
              _buildActionItem(
                Icons.medical_services,
                'Ambulance',
                Colors.red,
                _callAmbulance,
              ),
              _buildActionItem(
                Icons.female,
                'Helpline',
                Colors.pink,
                _callHelpline,
              ),
              _buildActionItem(
                Icons.location_on,
                'Location',
                Colors.green,
                _viewLocation,
              ),
              _buildActionItem(
                Icons.refresh,
                'Refresh',
                Colors.teal,
                _updateLocation,
              ),
              _buildActionItem(
                Icons.settings,
                'Settings',
                Colors.grey,
                _showSettings,
              ),
              _buildActionItem(
                Icons.logout,
                'Logout',
                Colors.red,
                _showLogoutDialog,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitySection() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.05),
                Colors.white.withOpacity(0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'ACTIVITY LOG',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ),
              Expanded(
                child: _activityLog.isEmpty
                    ? const Center(
                        child: Text(
                          'No activity yet\nYour safety actions will appear here',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _activityLog.length,
                        itemBuilder: (context, index) {
                          final activity = _activityLog[index];
                          return _buildActivityItem(activity);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.05),
            Colors.white.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            _getActivityIcon(activity['type']),
            color: _getActivityColor(activity['type']),
            size: 16,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['action'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _formatTime(activity['timestamp']),
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'Emergency':
        return Icons.emergency;
      case 'SMS':
        return Icons.message;
      case 'System':
        return Icons.security;
      default:
        return Icons.info;
    }
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'Emergency':
        return Colors.red;
      case 'SMS':
        return Colors.teal;
      case 'System':
        return Colors.green;
      default:
        return Colors.white;
    }
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  void _showSendOptions(String alertType) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1a1a2e),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Send $alertType Alert Via',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSendOption(
                  Icons.sms,
                  'SMS',
                  Colors.blue,
                  () => _sendAlert(alertType, useWhatsApp: false),
                ),
                _buildSendOption(
                  Icons.chat,
                  'WhatsApp',
                  Colors.green,
                  () => _sendAlert(alertType, useWhatsApp: true),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSendOption(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Icon(icon, color: color, size: 35),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _sendAlert(String alertType, {bool useWhatsApp = false}) {
    Navigator.pop(context);
    String appName = useWhatsApp ? 'WhatsApp' : 'SMS';

    switch (alertType) {
      case 'SOS':
        _logActivity("SOS Alert via $appName", "Emergency");
        _safetyService.triggerSOS(useWhatsApp: useWhatsApp);
        _showSuccessDialog(
          'Opening $appName!',
          'Please TAP SEND to deliver the SOS alert.',
          Colors.orange,
        );
        break;
      case 'EMERGENCY':
        _logActivity("Emergency Alert via $appName", "Emergency");
        _safetyService.triggerEmergency(useWhatsApp: useWhatsApp);
        _showSuccessDialog(
          'Opening $appName!',
          'Please TAP SEND to deliver the emergency alert.',
          Colors.red,
        );
        break;
      case 'DISCREET':
        _logActivity("Discreet Alert via $appName", "SMS");
        _safetyService.triggerSOS(useWhatsApp: useWhatsApp);
        _showSuccessDialog(
          'Opening $appName!',
          'Please TAP SEND to deliver the discreet alert.',
          Colors.blue,
        );
        break;
    }
  }

  void _viewContacts() {
    final contacts = _safetyService.contacts;
    if (contacts.isEmpty) {
      _showError('No emergency contacts found');
      return;
    }

    String contactsText = 'Your Emergency Contacts:\n\n';
    for (final contact in contacts) {
      contactsText += '• ${contact['name']}: ${contact['phone']}\n';
    }

    _showInfoDialog('Emergency Contacts', contactsText, Colors.purple);
  }

  void _viewLocation() async {
    final position = await LocationService.getCurrentLocation();
    if (position != null) {
      final mapsLink = LocationService.getGoogleMapsLink(
        position.latitude,
        position.longitude,
      );
      _showInfoDialog(
        'Current Location',
        '📍 Coordinates: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}\n\n🗺️ Google Maps: $mapsLink',
        Colors.green,
      );
      _logActivity("Viewed location", "System");
    } else {
      _showError('Unable to get location');
    }
  }

  void _showSettings() {
    _showInfoDialog(
      'Settings',
      'App settings will be available in the next update.',
      Colors.grey,
    );
  }

  void _callPolice() async {
    _logActivity("Called Police", "System");
    const String policeNumber = '100';
    final Uri telUri = Uri(scheme: 'tel', path: policeNumber);
    if (await canLaunchUrl(telUri)) {
      await launchUrl(telUri);
    } else {
      _showError('Cannot make call');
    }
  }

  void _callAmbulance() async {
    _logActivity("Called Ambulance", "System");
    const String ambulanceNumber = '108';
    final Uri telUri = Uri(scheme: 'tel', path: ambulanceNumber);
    if (await canLaunchUrl(telUri)) {
      await launchUrl(telUri);
    } else {
      _showError('Cannot make call');
    }
  }

  void _callHelpline() async {
    _logActivity("Called Women Helpline", "System");
    const String helplineNumber = '1091';
    final Uri telUri = Uri(scheme: 'tel', path: helplineNumber);
    if (await canLaunchUrl(telUri)) {
      await launchUrl(telUri);
    } else {
      _showError('Cannot make call');
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text(
          'Logout',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: _logout,
            child: const Text('LOGOUT', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
    Navigator.pushReplacementNamed(context, '/login');
    _logActivity("User logged out", "System");
  }

  void _showSuccessDialog(String title, String content, Color color) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: Text(
          title,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
        content: Text(content, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(String title, String content, Color color) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: Text(
          title,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Text(content, style: const TextStyle(color: Colors.white70)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}

/// Emotional support AI chat screen for high-stress situations
/// Provides calming, empathetic responses via LLM endpoint integration
class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<_ChatMessage> _chatHistory = [];
  bool _isLoading = false;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Add welcome message from AI companion
  void _addWelcomeMessage() {
    setState(() {
      _chatHistory.add(
        _ChatMessage(
          text:
              'Hello. I\'m here to support you. Take a deep breath. Whatever you\'re going through, you\'re not alone. How can I help you today?',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    });
    _scrollToBottom();
  }

  /// Send user message and get AI response
  Future<void> _sendMessage(String userText) async {
    if (userText.trim().isEmpty) return;

    setState(() {
      _chatHistory.add(
        _ChatMessage(
          text: userText,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _isLoading = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      final aiResponse = await _getAIResponse(userText);
      setState(() {
        _chatHistory.add(
          _ChatMessage(
            text: aiResponse,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
    } catch (e, stackTrace) {
      debugPrint('SupportChatScreen:: Error getting AI response: ${e.toString()}');
      debugPrint('SupportChatScreen:: stackTrace: $stackTrace');
      final errorMessage = 'Error: $e';
      setState(() {
        _chatHistory.add(
          _ChatMessage(
            text: errorMessage,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  /// Direct Gemini REST API (v1beta) via http POST.
  Future<String> _getAIResponse(String userMessage) async {
    final Uri url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${AppConfig.geminiApiKey}'
    );

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': userMessage},
              ],
            },
          ],
        }),
      );

      if (response.statusCode != 200) {
        debugPrint(response.body);
        throw Exception(response.body);
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = data['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw Exception('Gemini API response missing candidates');
      }

      final content = candidates[0]['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      final text = parts?[0]['text'] as String?;

      if (text == null || text.trim().isEmpty) {
        throw Exception('Gemini API response missing text in parts');
      }

      debugPrint('SupportChatScreen:: AI response received');
      return text.trim();
    } catch (e, stackTrace) {
      debugPrint(
        'SupportChatScreen:: Exception querying Gemini: ${e.toString()}',
      );
      debugPrint('SupportChatScreen:: stackTrace: $stackTrace');
      rethrow;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Emotional Support',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.5,
            colors: [Color(0xFF0f0c29), Color(0xFF302b63), Color(0xFF24243e)],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: _chatHistory.length,
                itemBuilder: (context, index) {
                  final message = _chatHistory[index];
                  return Align(
                    alignment: message.isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      decoration: BoxDecoration(
                        color: message.isUser
                            ? Colors.purple.withOpacity(0.7)
                            : Colors.blue.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: message.isUser
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatTime(message.timestamp),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(Colors.blue),
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Companion is thinking...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      enabled: !_isLoading,
                      maxLines: null,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Share your feelings...',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      onSubmitted: (text) => _sendMessage(text),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _isLoading
                        ? null
                        : () => _sendMessage(_messageController.text),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.blue, Colors.purple],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.send,
                        color: Colors.white.withOpacity(_isLoading ? 0.5 : 1),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

/// Data model for chat messages
class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  _ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
// THIS IS YOUR NEW JARVIS VOICE SCREEN CODE PUT DIRECTLY IN MAIN.DART
// FULLY FUNCTIONAL MICROPHONE AND SPEECH SYSTEM FOR MITRA AI
class JarvisVoiceScreen extends StatefulWidget {
  const JarvisVoiceScreen({super.key});

  @override
  State<JarvisVoiceScreen> createState() => _JarvisVoiceScreenState();
}

class _JarvisVoiceScreenState extends State<JarvisVoiceScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _isListening = false;
  String _userSpeechText = "Tap the mic and start talking...";
  String _mitraResponseText = "Hello! I am Mitra, your safety companion. How can I support you today?";

  @override
  void initState() {
    super.initState();
    _initVoiceSystem();
  }

  Future<String> _getVoiceAIResponse(String userMessage) async {
    final Uri url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${AppConfig.geminiApiKey}',
    );

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': userMessage},
              ],
            },
          ],
        }),
      );

      if (response.statusCode != 200) {
        debugPrint(response.body);
        throw Exception(response.body);
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final text = data['candidates'][0]['content']['parts'][0]['text']
          as String;

      debugPrint('JarvisVoiceScreen:: AI response received');
      return text.trim();
    } catch (e, stackTrace) {
      debugPrint(
        'JarvisVoiceScreen:: Exception querying Gemini: ${e.toString()}',
      );
      debugPrint('JarvisVoiceScreen:: stackTrace: $stackTrace');
      rethrow;
    }
  }

  void _initVoiceSystem() async {
    try {
      await _tts.setLanguage("en-IN"); 
      await _tts.setSpeechRate(0.45); 
    } catch (e) {
      debugPrint("Voice init error: $e");
    }
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onError: (val) => print('Speech Error: $val'),
        onStatus: (val) => print('Speech Status: $val'),
      );
      
      if (available) {
        setState(() {
          _isListening = true;
          _userSpeechText = "Listening...";
        });
        
        _speech.listen(
          onResult: (val) => setState(() {
            _userSpeechText = val.recognizedWords;
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      await _speech.stop();
      
      final transcript = _userSpeechText.trim();
      if (transcript.isNotEmpty &&
          transcript != "Listening..." &&
          transcript != "Tap the mic and start talking...") {
        if (!mounted) return;
        setState(() => _mitraResponseText = "Thinking...");

        try {
          final reply = await _getVoiceAIResponse(transcript);
          if (!mounted) return;
          setState(() => _mitraResponseText = reply);
          await _tts.speak(reply);
        } catch (e, stackTrace) {
          debugPrint(
            'JarvisVoiceScreen:: Voice AI error: ${e.toString()}',
          );
          debugPrint('JarvisVoiceScreen:: stackTrace: $stackTrace');
          if (!mounted) return;
          setState(() => _mitraResponseText = 'Error: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        title: const Text("Mitra Safety Assistant"), 
        backgroundColor: Colors.transparent, 
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Card(
              color: Colors.blueGrey[800],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("You: $_userSpeechText", style: const TextStyle(color: Colors.white70, fontSize: 16)),
                    const Divider(color: Colors.white24, height: 30),
                    Text("Mitra: $_mitraResponseText", style: const TextStyle(color: Colors.cyanAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            Column(
              children: [
                GestureDetector(
                  onTap: _listen,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: _isListening ? Colors.redAccent : Colors.cyan,
                    child: Icon(_isListening ? Icons.mic : Icons.mic_none, size: 45, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  _isListening ? "Tap to stop & process voice" : "Tap to Speak to Mitra", 
                  style: const TextStyle(color: Colors.white60),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}