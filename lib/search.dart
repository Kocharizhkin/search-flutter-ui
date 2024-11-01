import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'dart:html' as html;
import 'package:universal_html/html.dart' as u_html;
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';

import 'models/product.dart';
import 'login.dart';
import 'package:mkniga_search/upload.dart';

class SearchMkniga extends StatefulWidget {
  const SearchMkniga({super.key});

  @override
  _SearchMknigaState createState() => _SearchMknigaState();
}

class _SearchMknigaState extends State<SearchMkniga> {
  List<TextEditingController> controllerList = [];
  bool multipleTerms = false;
  bool _saveToFile = false;
  bool searching = false;
  bool resultsView = false;
  bool booksFound = true;
  List<Product> _products = [];
  List<String> attributeTitles = ["ISBN", "Author", "Title", "Year", "Publisher"];
  List<String> fieldsTitles = ["isbn", "author", "title", "publication_year", "publisher"];
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < attributeTitles.length; i++) {
      controllerList.add(TextEditingController());
    }
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void toggleSwitch(bool value) {
    setState(() {
      multipleTerms = value;
    });
  }
  void toggleSaveToFile(bool value) {
    setState(() {
      _saveToFile = value;
    });
  }

  // Function to download a file in the browser
void _openUrlInNewTab(String url) {
  // Create an anchor element
  html.AnchorElement anchorElement =  new html.AnchorElement(href: url);
   anchorElement.download = url;
   anchorElement.click();
}

  TextEditingController searchController = TextEditingController();

  void performSearch() async {
  setState(() {
    searching = true;
  });
  try {
    // Gather text from text fields
    String searchTerm = "";
    if (!multipleTerms) {
      // Single search term request
      searchTerm = searchController.text;
    } else {
      // Multiple search term request
      for (int i = 0; i < attributeTitles.length; i++) {
        if (searchTerm.isNotEmpty) {
          searchTerm += ",";
        }
        searchTerm += "${fieldsTitles[i]}=${controllerList[i].text}";
      }
    }

    // Construct the URL based on the search term
    var url = "http://localhost:8000/search/search";
    if (multipleTerms) {
      url += "?multiple=$searchTerm";
    } else {
      url += "?searchTerm=$searchTerm";
    }

    // Include _saveToFile in the request
    if (_saveToFile) {
      // Modify the URL to include _saveToFile information
      url += "&saveToFile=true";
    }

    // Make the HTTP request and handle the response
    var response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      if (_saveToFile) {
        // Assuming the file URL is present in the response
        String fileUrl = response.body;
        if (fileUrl.isNotEmpty) {
          // Use browser download function
          _openUrlInNewTab(fileUrl);
        } }else {
        // If saveToFile is false, process the JSON data
        var jsonData = json.decode(response.body);
        setState(() {
          // Update the products list with the fetched data
          _products = [];

          for (var prod in jsonData) {
            Product product = Product.fromJSON(prod);
            _products.add(product);
          }
        });
      }
    } else {
      print("Server-side error fetching products: ${response.statusCode}");
      // Handle error: Show a snackbar, display an error message, etc.
    }
  } catch (error) {
    print("Error in PerformSearch: $error");
    // Handle error: Show a snackbar, display an error message, etc.
  }
  setState(() {
    searching = false;
    print(_products);
    if (_products.isNotEmpty) {
      resultsView = true;
      booksFound = true;
      print(booksFound);
    } else {
      booksFound = false;
    }
  });
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _focusNode.requestFocus();
  });
}

// Function for handling file upload
  Future<void> _handleUpload() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'], // Specify the allowed file extensions
      );
      
      if (result != null) {
      // File picked successfully
      // You can access the selected file using result.files.first
      Uint8List fileBytes = result.files.first.bytes!;
      String fileName = result.files.first.name!;

      // Send the file to the Flask server
      await _uploadFile(fileBytes, fileName);
      } else {
        // User canceled the file picking
        print('User canceled file picking');
      }
    } catch (e) {
      print('Error picking file: $e');
      // Handle the error, display a message, etc.
    }
  }

  Future<void> _uploadFile(Uint8List fileBytes, String fileName) async {
  try {
    String apiUrl = 'http://localhost:8000/search/search'; // Replace with your Flask server URL

    // Create a multipart request
    var request = http.MultipartRequest('POST', Uri.parse(apiUrl));

    // Attach the file to the request
    request.files.add(http.MultipartFile.fromBytes('file', fileBytes, filename: fileName));

    // Send the request
    var response = await request.send();

    if (response.statusCode == 200) {
      print('File uploaded successfully');

      // Use utf8.decode to convert the stream of bytes to a String
      String fileUrl = await response.stream.bytesToString();
      
      if (fileUrl.isNotEmpty) {
        // Use browser download function
        _openUrlInNewTab(fileUrl);
      }
    } else {
      print('Failed to upload file. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Error uploading file: $e');
    // Handle the error, display a message, etc.
  }
}

void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _scrollController.animateTo(
          _scrollController.offset + 60, // Adjust the value as per your row height
          duration: Duration(milliseconds: 200),
          curve: Curves.ease,
        );
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _scrollController.animateTo(
          _scrollController.offset - 60, // Adjust the value as per your row height
          duration: Duration(milliseconds: 200),
          curve: Curves.ease,
        );
      }
    }
  }

Future<void> _exportToExcel() async {
    var excel = Excel.createExcel();
    var sheet = excel['Products'];

    // Add header row
    sheet.appendRow([
      TextCellValue('ISBN'),
      TextCellValue('Author'),
      TextCellValue('Title'),
      TextCellValue('Year'),
      TextCellValue('Publisher'),
      TextCellValue('Suppliers')
    ]);

    // Add data rows
    for (var product in _products) {
      sheet.appendRow([
        TextCellValue(product.isbn),
        TextCellValue(product.author),
        TextCellValue(product.title),
        TextCellValue(product.publicationYear),
        TextCellValue(product.publisher),
        TextCellValue(product.suppliers ?? ''),
      ]);
    }

    var bytes = excel.save();
    if (bytes != null) {
      final blob = u_html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = u_html.Url.createObjectUrlFromBlob(blob);
      final anchor = u_html.AnchorElement(href: url)
        ..setAttribute('download', 'products.xlsx')
        ..click();
      u_html.Url.revokeObjectUrl(url);
    }

    // Optionally, you can show a message that the file has been saved
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Excel file saved to Dowloads')),
    );
  }


  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      actions: [
        IconButton(
          icon: Icon(Icons.upload),
          onPressed: () {
            // Navigate to the login page when the user icon is pressed
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => UploadPage()),
            );
          },
        ),
      ],
    ),
    body: Container(
      width: MediaQuery.of(context).size.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: (resultsView) ? 50 : 200,),
          Container(
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 212, 244, 189), // Set the background color to green
              borderRadius: BorderRadius.circular(30), // Set border radius to make corners round
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 7, horizontal: 15),
              child: Text(
                "SEARCH MKNIGA",
                style: TextStyle(
                  fontSize: 30,
                  color: Color.fromARGB(255, 66, 118, 28),
                  fontWeight: FontWeight.w100,
                ),
              ),
            ),
          ),
          const SizedBox(height: 30,),
          Container(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: SettingsMenu(
                    multipleTerms: multipleTerms,
                    saveToFile: _saveToFile,
                    toggleSwitch: toggleSwitch,
                    toggleSaveToFile: toggleSaveToFile,
                    handleUpload: _handleUpload,
                  ),
                ),
                Visibility(
                  visible: multipleTerms,
                  child: Expanded(
                    child: Row(
                      children: [
                        for (int i = 0; i < attributeTitles.length; i++)
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              child: TextField(
                                onSubmitted: (value) => performSearch(),
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
                      ],
                    ),
                  ),
                ),
                Visibility(
                  visible: !multipleTerms,
                  child: Expanded(
                    child: TextField(
                      controller: searchController,
                      onSubmitted: (value) => performSearch(),
                      decoration: InputDecoration(
                        fillColor: const Color.fromARGB(255, 120, 53, 17),
                        hintText: "ISBN, title, author or year...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25.0),
                          borderSide: const BorderSide(color: Colors.green),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: IconButton(
                    icon: Icon(Icons.search),
                    onPressed: performSearch,
                  ),
                ),
              ],
            ),
          ),
          if (searching == true)
            const Center(child: CircularProgressIndicator(),),
          if (resultsView == true)
            Visibility(
              child: Expanded(
                child: Column(
                  children: [
                    // ElevatedButton to export the data
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                        child: ElevatedButton(
                          onPressed: _exportToExcel,
                          child: Text("Export to Excel"),
                        ),
                      ),
                    ),
                    Expanded(
                      child: RawKeyboardListener(
                        focusNode: _focusNode,
                        onKey: _handleKeyEvent,
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 40),
                              child: DataTable(
                                dividerThickness: 1.0,
                                dataRowMinHeight: 60,
                                dataRowMaxHeight: 80,
                                clipBehavior: Clip.antiAlias,
                                columns: const [
                                  DataColumn(label: Text('ISBN')),
                                  DataColumn(label: Text('Author')),
                                  DataColumn(label: Text('Title')),
                                  DataColumn(label: Text('Year')),
                                  DataColumn(label: Text('Publisher')),
                                  DataColumn(label: Text('Suppliers')),
                                ],
                                rows: List<DataRow>.generate(
                                  _products.length,
                                  (int index) => DataRow(
                                    cells: [
                                      DataCell(SelectableText(_products[index].isbn)),
                                      DataCell(SelectableText(_products[index].author)),
                                      DataCell(SelectableText(_products[index].title)),
                                      DataCell(SelectableText(_products[index].publicationYear)),
                                      DataCell(SelectableText(_products[index].publisher)),
                                      DataCell(SelectableText(_products[index].suppliers ?? '')),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (booksFound == false)
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            Container(
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 189, 234, 244), // Set the background color to green
                borderRadius: BorderRadius.circular(30), // Set border radius to make corners round
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 7, horizontal: 15),
                child: Text(
                  "Nothing..",
                  style: TextStyle(
                    fontSize: 30,
                    color: Color.fromARGB(255, 28, 73, 118),
                    fontWeight: FontWeight.w100,
                  ),
                ),
              ),
            ),
          ]),
          SizedBox(height: 50,)
        ],
      ),
    ),
  );
}
}

class SettingsMenu extends StatefulWidget {
  final bool multipleTerms;
  final bool saveToFile;
  final Function(bool) toggleSwitch;
  final Function(bool) toggleSaveToFile;
  final Function() handleUpload;

  SettingsMenu({
    required this.multipleTerms,
    required this.saveToFile,
    required this.toggleSwitch,
    required this.toggleSaveToFile,
    required this.handleUpload,
  });

  @override
  _SettingsMenuState createState() => _SettingsMenuState();
}

class _SettingsMenuState extends State<SettingsMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 200));
    _rotationAnimation = Tween<double>(begin: 0, end: 0.5).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
    children: [
      InkWell(
          onTap: () {
            setState(() {
              _isMenuOpen = !_isMenuOpen;
              if (_isMenuOpen) {
                _controller.forward();
              } else {
                _controller.reverse();
              }
            });
          },
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationAnimation.value * 3.14,
                child: Icon(
                  Icons.settings,
                  size: 25,
                  color: Colors.black.withOpacity(0.6),
                  weight: 0.1,
                ),
              );
            },
          ),
        ),
      if (_isMenuOpen)
      Column(
        children: [
          Transform.scale(scale: 0.7,
            child: Switch(value: widget.multipleTerms, onChanged: widget.toggleSwitch),
          ),
          Text('Multiple'),
        ]
      ),
      if (_isMenuOpen)
      SizedBox(width: 10,),
      if (_isMenuOpen)
      Column(
        children: [
          Transform.scale(scale: 0.7,
            child: Switch( value: widget.saveToFile, onChanged: widget.toggleSaveToFile,),
          ),
          Text('Save to File'),
        ],
      ),
      IconButton(
        icon: Icon(Icons.upload),
        onPressed: widget.handleUpload,
        tooltip: "Upload your search queries here (xlsx)",
      ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}