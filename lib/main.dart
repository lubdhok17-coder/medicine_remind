import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:home_widget/home_widget.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

@pragma('vm:entry-point')
Future<void> backgroundCallback(Uri? uri) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  HomeWidget.registerInteractivityCallback(backgroundCallback);
  runApp(const MediReminderApp());
}

class MediReminderApp extends StatelessWidget {
  const MediReminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medi Reminder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'HindSiliguri',
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontFamily: 'HindSiliguri'),
          bodyLarge: TextStyle(fontFamily: 'HindSiliguri'),
          bodyMedium: TextStyle(fontFamily: 'HindSiliguri'),
        ),
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
      ),
      home: const RoleSelectionScreen(),
    );
  }
}

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medi Reminder - প্রবেশ', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'HindSiliguri')),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'আপনি কোন মোডে অ্যাপটি ব্যবহার করতে চান?', 
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'HindSiliguri'), 
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(55),
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SeniorSetupScreen())),
              child: const Text('আমি প্রবীণ (বাবা/মা)', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'HindSiliguri')),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(55),
                backgroundColor: Colors.indigo,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CaregiverSyncScreen())),
              child: const Text('আমি কেয়ারগিভার (সন্তান)', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'HindSiliguri')),
            ),
          ],
        ),
      ),
    );
  }
}

class SeniorSetupScreen extends StatelessWidget {
  const SeniorSetupScreen({super.key});
  final String seniorId = "senior_user_001";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('প্রবীণ মোড ও কিউআর পেয়ারিং', style: TextStyle(fontFamily: 'HindSiliguri'))),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'সন্তানের অ্যাপ থেকে নিচের QR কোডটি স্ক্যান করে ডিভাইস যুক্ত করুন:', 
              style: TextStyle(fontSize: 18, fontFamily: 'HindSiliguri'), 
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Center(
              child: QrImageView(
                data: seniorId,
                version: QrVersions.auto,
                size: 220.0,
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'আপনার পেয়ারিং আইডি: $seniorId', 
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey, fontFamily: 'HindSiliguri'),
            ),
          ],
        ),
      ),
    );
  }
}

class CaregiverSyncScreen extends StatefulWidget {
  const CaregiverSyncScreen({super.key});

  @override
  State<CaregiverSyncScreen> createState() => _CaregiverSyncScreenState();
}

class _CaregiverSyncScreenState extends State<CaregiverSyncScreen> {
  String? connectedSeniorId;

  @override
  Widget build(BuildContext context) {
    if (connectedSeniorId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('বাবা-মায়ের QR কোড স্ক্যান করুন', style: TextStyle(fontFamily: 'HindSiliguri'))),
        body: MobileScanner(
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              setState(() {
                connectedSeniorId = barcode.rawValue;
              });
              break;
            }
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('লাইভ ড্যাশবোর্ড ($connectedSeniorId)', style: const TextStyle(fontFamily: 'HindSiliguri'))),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(connectedSeniorId)
            .collection('medicines')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'কোনো ওষুধের রিমাইন্ডার যুক্ত করা হয়নি।', 
                style: TextStyle(fontSize: 18, color: Colors.grey, fontFamily: 'HindSiliguri'),
              ),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final bool isTaken = data['status'] == 'taken';

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text(data['name'] ?? 'ওষুধ', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'HindSiliguri')),
                  subtitle: Text('সময়: ${data['time']}', style: const TextStyle(fontSize: 16, fontFamily: 'HindSiliguri')),
                  trailing: Text(
                    isTaken ? 'খেয়েছেন ✅' : 'বাকি আছে ⏰',
                    style: TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold, 
                      color: isTaken ? Colors.green : Colors.orange,
                      fontFamily: 'HindSiliguri',
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
