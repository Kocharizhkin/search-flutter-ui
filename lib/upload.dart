import 'package:file_picker/_internal/file_picker_web.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:web/web.dart' as web;
import 'dart:async' show Completer;
import 'dart:math' show min;
import 'dart:typed_data' show Uint8List, BytesBuilder;

import 'package:mkniga_search/update_progress.dart';
import 'package:mkniga_search/column_mapping.dart';

class UploadPage extends StatefulWidget {
  @override
  _UploadPageState createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  List<String> titles = List.generate(10, (index) => 'Title ${index + 1}');
  List<String> attributeTitles = ["ISBN", "Author", "Title", "Year", "Publisher", "Price"];
  List<int> dynamicallyAddedFields = []; // To track dynamically added fields
  List<TextEditingController> controllerList = [];

  late DropzoneViewController dropZoneController;
  String dropMessage = 'Drop file here';
  bool highlighted1 = false;

  Map<String, Map> mappedColumnsFromServer = {};
  late List<String> columnNames;
  Map<String, List<String>> fileSchema = {};
  Map<String, Map> selectedValues = {};
  Map<String, dynamic> rawServerMap = {};
  bool isUploadButtonClicked = true;
  Uint8List? fileBytes;
  String? fileName;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < attributeTitles.length; i++) {
      controllerList.add(TextEditingController());
    }
  }


  Future<void> _matchColumns(Uint8List? fileBytes, String? fileName) async {
  try {
    if (fileBytes == null || fileName == null) {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result != null) {
        fileBytes = result.files.first.bytes;
        fileName = result.files.first.name;
        setState(() {
          dropMessage = fileName!;
        });
      } else {
        _showSnackBar('File wasn\'t picked', Colors.red);
        return;
      }
    }

    String apiUrlFile = 'http://localhost:8000/update/matching';
    final dio = Dio();

    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        fileBytes as List<int>,
        filename: fileName,
        contentType: MediaType("application", "vnd.openxmlformats-officedocument.spreadsheetml.sheet"),
      ),
    });

    final response = await dio.post(
      apiUrlFile,
      data: formData,
    );

    if (response.statusCode == 200) {
      print(response.data);
      setState(() {
        rawServerMap = response.data;
        this.fileName = fileName;
        
      });
    } else {
      print('Failed to send column names. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Error sending/receiving column names: $e');
  }
}

// Function to handle sending requests to upload map data and file separately
Future<void> startUpdate() async {
    // Define your server endpoint URLs
    String apiUrlMap = 'http://localhost:8000/update/upload_map';
    String apiUpdate = 'http://localhost:8000/update/update';

    // Create a request to upload the map data
    var mapRequest = http.MultipartRequest('POST', Uri.parse(apiUrlMap));
    mapRequest.fields['data'] = jsonEncode(selectedValues);
    var mapResponse = await mapRequest.send();

    if (mapResponse.statusCode != 200) {
      print('Failed to upload map data. Status code: ${mapResponse.statusCode}');
      _showSnackBar('Failed to upload map data', Colors.red);
      return;
    }

    try {
      print(fileName);
      var updateRequest = http.Request('POST', Uri.parse(apiUpdate));
      updateRequest.headers['Content-Type'] = 'application/json'; // Set the Content-Type header to indicate JSON data
      updateRequest.body = jsonEncode({'filename': fileName});

      var updateResponse = await updateRequest.send();

    if (updateResponse.statusCode == 200) {
      print('File uploaded successfully');
      _showSnackBar('Update started', Colors.green);
    } else {
      print('File or filename is null. Cannot upload.');
      _showSnackBar('File or filename is null. Cannot upload.', Colors.red);
    }
    } catch (error) {
    print('Error uploading file: $error');
    _showSnackBar('Error uploading file: $error', Colors.red);
  }
}

// Function to show SnackBar messages to the user
void _showSnackBar(String message, Color color) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(Icons.error, color: Colors.white),
          SizedBox(width: 8),
          Text(message, style: TextStyle(color: Colors.white)),
        ],
      ),
      backgroundColor: color,
    ),
  );
}

void addSingleBook(){
  
}

void _addNewField() {
  TextEditingController _newAttributeController = TextEditingController();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Enter New Attribute Title'),
        content: TextField(
          controller: _newAttributeController,
          decoration: InputDecoration(
            hintText: 'New Attribute Title',
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.0),
              borderSide: BorderSide(color: Colors.green),
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('Add'),
            onPressed: () {
              if (_newAttributeController.text.isNotEmpty) {
                setState(() {
                  // Add the user-specified title to the attributeTitles list
                  attributeTitles.add(_newAttributeController.text);

                  // Add a new TextEditingController for the new field
                  controllerList.add(TextEditingController());

                  // Track the index of dynamically added fields
                  dynamicallyAddedFields.add(attributeTitles.length - 1);
                });
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      );
    },
  );
}

void _deleteField(int index) {
  setState(() {
    // Remove the field from attributeTitles and its controller
    attributeTitles.removeAt(index);
    controllerList.removeAt(index);

    // Also remove from the dynamicallyAddedFields tracking list
    dynamicallyAddedFields.remove(index);
  });
}

Widget buildDropZone(BuildContext context) => Builder(
  builder: (context) => DropzoneView(
    operation: DragOperation.copy,
    cursor: CursorType.grab,
    onCreated: (controller) => dropZoneController = controller,
    onLoaded: () => debugPrint('Dropzone loaded'),
    onError: (error) => debugPrint('Dropzone error: $error'),
    onDrop: (event) async {
      if (event is web.File && event.name.endsWith('.xlsx')) {
        setState(() {
          dropMessage = event.name;
        });

        final fileBytes = await dropZoneController.getFileData(event);
        await _matchColumns(fileBytes, event.name);  // Pass dropped file for upload
      } else {
        setState(() {
          dropMessage = 'Invalid file type. Only .xlsx files are allowed.';
        });
      }
    },
    onDropInvalid: (invalidMime) => debugPrint('Invalid MIME type: $invalidMime'),
    onDropMultiple: (event) async {
      debugPrint('Multiple items dropped: $event');
    },
  ),
);


@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
    ),
    body: SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 100,),
          const Center(
            child: Text(
              "Input new data manually",
              style: TextStyle(fontSize: 25),
            )
          ),
          Padding(padding: EdgeInsets.symmetric(horizontal: 60, vertical: 20),
          child: Row(
            children: [
              for (int i = 0; i < attributeTitles.length; i++)
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          child: TextField(
                            onSubmitted: (value) => {},
                            controller: controllerList[i],
                            decoration: InputDecoration(
                              hintText: attributeTitles[i],
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15.0),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20.0),
                                borderSide: BorderSide(color: Colors.green),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (dynamicallyAddedFields.contains(i))
                        IconButton(
                          icon: const Icon(Icons.delete, size: 12),
                          onPressed: () => _deleteField(i),
                        ),
                    ],
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.add, size: 40),
                onPressed: _addNewField,
              ),
            ],
          ),
          ),
          Padding(padding: EdgeInsets.all(10),
          child: ElevatedButton(
            onPressed: addSingleBook,
            child: Text('Add Book'),
          ),
          ),
          const SizedBox(height: 100,),
          Container(
            width: MediaQuery.of(context).size.width * 0.8, // 80% of screen width
            height: rawServerMap.isEmpty ? MediaQuery.of(context).size.height * 0.0 : MediaQuery.of(context).size.height * 0.4, // 80% of screen width
            child: ExcelSheetMappingWidget(sheetData: rawServerMap), // Insert the widget here
          ),
          Container(
            height: 400,
            width: 400,
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 212, 244, 189), // Set the background color to green
              borderRadius: BorderRadius.circular(30), // Set border radius to make corners round
            ),
            child: Stack(
              children: [
                buildDropZone(context),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Center(
                      child: Text(dropMessage,
                        style: const TextStyle(fontSize: 40,
                          color:  Color.fromARGB(255, 55, 36, 6)
                        ),
                      )
                    ),
                    Center(
                      child: IconButton(
                        icon: const Icon(Icons.upload, size: 60,),
                        onPressed:() async {
                          await _matchColumns(null, null);  // Calling the function without fileBytes and fileName
                        },
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 20), // Add some space between the categories and the submit button
          ElevatedButton(
            onPressed: startUpdate,
            child: Text('Submit'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    ),
  );
}
}