import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class ProgressScreen extends StatefulWidget {
  @override
  _ProgressScreenState createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  double _progress = 0.0;
  int _processedRows = 0;
  int _totalRows = 0;
  String _currentSheet = "";
  String _updateStartTime = "";
  int dotCounter = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchProgressData();
    _timer = Timer.periodic(Duration(seconds: 10), (Timer t) => _fetchProgressData());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> startUpdate() async {
    String apiUpdate = 'http://localhost:8000/update/test_update';

    try {
      var updateRequest = http.Request('GET', Uri.parse(apiUpdate));

      var updateResponse = await updateRequest.send();

    if (updateResponse.statusCode == 200) {
      print('File uploaded successfully');
    } else {
      print('File or filename is null. Cannot upload.');
    }
    } catch (error) {
    print('Error uploading file: $error');
  }
}

  Future<void> _fetchProgressData() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:8000/update/progress'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _processedRows = data['processed_rows'];
          _totalRows = data['total_rows'];
          _currentSheet = (_processedRows == "0" ? 'initializing' : data['current_sheet']) + ('.' * dotCounter);
          _updateStartTime = data['update_start_time'];
          _progress = _processedRows / _totalRows;
        });
      } else {
        throw Exception('Failed to load progress data');
      }
      dotCounter += 1;
      if (dotCounter == 4){
        dotCounter = 0;
      }
    } catch (e) {
      // Handle errors
      print('Error fetching progress data: $e');
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
    ),
    body: Center( // Wrap the Column with Center
      child: Container(
        width: 500,
        height: 350,
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 149, 179, 255),
          borderRadius: BorderRadius.all(Radius.circular(50))
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ElevatedButton(onPressed: startUpdate, child: Text('Test update')),
            Text(
              '$_currentSheet',
              style: const TextStyle(
                fontSize: 40,
                color: Colors.white
              ),
            ),
            SizedBox(height: 60),
            Container(
              width: 400,
              child: LinearProgressIndicator(
                color: Color.fromARGB(255, 61, 86, 149),
                backgroundColor: Colors.white,
                value: _progress,
                minHeight: 8,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ),
            SizedBox(height: 8),
            Container(
              width: 380,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$_processedRows',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white
                    ),
                  ),
                  Text(
                    '$_totalRows',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 60),
            Text(
              'Update Start Time: $_updateStartTime',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white
              ),
            ),
          ],
        ),
      )
    ),
  );
}
}