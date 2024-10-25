import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sunmi_printer_plus/enums.dart';
import 'ticket_display.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';
import 'package:intl/intl.dart';

class TicketInputScreen extends StatefulWidget {
  @override
  _TicketInputScreenState createState() => _TicketInputScreenState();
}

class _TicketInputScreenState extends State<TicketInputScreen> {
  final TextEditingController _groupSizeController = TextEditingController();
  int? estimatedWaitTime;

  @override
  void initState() {
    super.initState();
    _fetchEstimatedWaitTime();
    _groupSizeController.value = TextEditingValue(text: '1');
  }

  Future<void> _fetchEstimatedWaitTime() async {
    try {
      await SunmiPrinter.bindingPrinter();
      DocumentSnapshot settingsDoc = await FirebaseFirestore.instance
          .collection('SETTINGS')
          .doc('QUEUE_SETTINGS')
          .get();

      if (settingsDoc.exists) {
        int waitTimePerPerson = settingsDoc.get('averageWaitTime');
        int maxConcurrentService = settingsDoc.get('maxConcurrentService');

        QuerySnapshot waitingTickets = await FirebaseFirestore.instance
            .collection('QUEUE')
            .where('status', isEqualTo: 'waiting')
            .get();

        int totalWaitingPeople = 0;
        for (var doc in waitingTickets.docs) {
          totalWaitingPeople += doc.get('groupSize') as int;
        }

        // 同時にサービスを受けられる人数で除算し、待ち時間を算出
        int waitingSlots = (totalWaitingPeople / maxConcurrentService).ceil();

        setState(() {
          estimatedWaitTime = waitingSlots * waitTimePerPerson;
        });
      }
    } catch (e) {
      print("待ち時間の取得エラー: $e");
    }
  }

  Future<void> _printTicket(String ticketNumber) async {
    DateFormat dateFormat = DateFormat('yyyy年MM月dd日 HH時mm分');
    try {
      await SunmiPrinter.lineWrap(2);
      await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
      await SunmiPrinter.setFontSize(SunmiFontSize.LG);
      await SunmiPrinter.bold();
      await SunmiPrinter.printText('受付番号');
      await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
      await SunmiPrinter.setFontSize(SunmiFontSize.XL);
      await SunmiPrinter.bold();
      await SunmiPrinter.printText(ticketNumber);
      await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
      await SunmiPrinter.setFontSize(SunmiFontSize.MD);
      await SunmiPrinter.bold();
      await SunmiPrinter.printText('おおよその待ち時間: $estimatedWaitTime 分');
      await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
      await SunmiPrinter.setFontSize(SunmiFontSize.MD);
      await SunmiPrinter.bold();
      await SunmiPrinter.printText('受付人数: ${_groupSizeController.text}人');
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
      await SunmiPrinter.bold();
      await SunmiPrinter.printText('以下のQRコードから呼び出し状況の確認やLINE呼び出しの設定ができます');
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
      await SunmiPrinter.printQRCode('https://wait.ja1ykl.com/');
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.setAlignment(SunmiPrintAlign.RIGHT);
      // 発行時刻
      await SunmiPrinter.printText(dateFormat.format(DateTime.now()));
      await SunmiPrinter.setAlignment(SunmiPrintAlign.RIGHT);
      await SunmiPrinter.printText('EZ WAIT SYSTEM');
      await SunmiPrinter.lineWrap(5);
    } catch (e) {
      print("プリンターのエラー: $e");
    }
  }

  Future<String> _getTicketNumber() async {
    QuerySnapshot latestTicket = await FirebaseFirestore.instance
        .collection('QUEUE')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();
    if (latestTicket.docs.isNotEmpty) {
      return (int.parse(latestTicket.docs.first.get('ticketNumber')) + 1)
          .toString();
    } else {
      return '1';
    }
  }

  Future<void> _submitTicket() async {
    final int groupSize = int.parse(_groupSizeController.text);
    String ticketNumber = await _getTicketNumber();
    // Firestoreにデータを保存する処理を追加
    try {
      await FirebaseFirestore.instance.collection('QUEUE').add({
        'ticketNumber': ticketNumber,
        'groupSize': groupSize,
        'status': 'waiting',
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _printTicket(ticketNumber);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TicketDisplayScreen(ticketNumber: ticketNumber),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('エラーが発生しました。もう一度お試しください。'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('EZ WAIT SYSTEM'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '受付人数を入力',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _groupSizeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '人数',
                border: OutlineInputBorder(),
              ),
              readOnly: true,
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(0),
                          ),
                        ),
                        onPressed: () {
                          if (_groupSizeController.text == '1') return;
                          int groupSize = int.parse(_groupSizeController.text);
                          _groupSizeController.value =
                              TextEditingValue(text: '${groupSize - 1}');
                        },
                        child: Text('-', style: TextStyle(fontSize: 20)))),
                const SizedBox(width: 10),
                Expanded(
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(0),
                          ),
                        ),
                        onPressed: () {
                          int groupSize = int.parse(_groupSizeController.text);
                          _groupSizeController.value =
                              TextEditingValue(text: '${groupSize + 1}');
                        },
                        child: Text('+', style: TextStyle(fontSize: 20)))),
              ],
            ),
            SizedBox(height: 20),
            if (estimatedWaitTime != null)
              Text(
                'おおよその待ち時間: $estimatedWaitTime 分',
                style: TextStyle(fontSize: 18, color: Colors.black87),
              ),
            SizedBox(height: 20),
            SizedBox(
                height: 40,
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(0),
                    ),
                  ),
                  onPressed: _submitTicket,
                  child: Text('受付'),
                )),
          ],
        ),
      ),
    );
  }
}
