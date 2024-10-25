import 'package:ez_wait/ticket_input.dart';
import 'package:flutter/material.dart';

class TicketDisplayScreen extends StatelessWidget {
  final String ticketNumber;

  TicketDisplayScreen({required this.ticketNumber});

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
          children: [
            Text(
              '受付番号',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            Text(
              ticketNumber,
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              '呼び出しまでお待ちください。',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 30),
            SizedBox(
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
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TicketInputScreen(),
                      ),
                    );
                  },
                  child: Text('完了'),
                )),
          ],
        ),
      ),
    );
  }
}
