import 'package:flutter/material.dart';

class ExcelSheetMappingWidget extends StatefulWidget {
  final Map<String, dynamic> sheetData;

  ExcelSheetMappingWidget({required this.sheetData});

  @override
  _ExcelSheetMappingWidgetState createState() => _ExcelSheetMappingWidgetState();
}

class _ExcelSheetMappingWidgetState extends State<ExcelSheetMappingWidget> {
  Map<String, Map<String, String?>> selectedValues = {};


  void _initializeDefaultSelections() {
    // Loop through each sheet in the data
    widget.sheetData.forEach((sheetName, data) {
      Map<String, String?> presetValues = {};
      
      // Retrieve the map for each sheet and check for non-null values
      Map<String, dynamic> map = data['map'] ?? {};
      map.forEach((column, defaultValue) {
        if (defaultValue != null) {
          presetValues[column] = defaultValue.toString();
        }
      });
      
      // Save the preset values for each sheet
      selectedValues[sheetName] = presetValues;
      print(selectedValues);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: widget.sheetData.keys.length,
      child: Column(
        children: [
          Center(
            child: TabBar(
              isScrollable: true,
              tabs: widget.sheetData.keys.map((sheetName) => Tab(text: sheetName)).toList(),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: widget.sheetData.keys.map((sheetName) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      _buildColumnMappingHeader(sheetName),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnMappingHeader(String sheetName) {
    _initializeDefaultSelections();
    // Retrieve data preview for the given sheet name.
    List<Map<String, dynamic>> sheetDataPreview =
        List<Map<String, dynamic>>.from(widget.sheetData[sheetName]['data_preview'] ?? []);
    
    // Ensure that we have data to determine column names
    if (sheetDataPreview.isEmpty) {
      return Center(
        child: Text(
          'No columns available for mapping in $sheetName.',
          style: TextStyle(color: Colors.red),
        ),
      );
    }

    // Extract column names dynamically from the keys of the first entry in sheetDataPreview
    List<String> columnNames = sheetDataPreview.first.keys.toList();

    // Get mapping options from the map dictionary of the specified sheet
    List<String> dropdownOptions = widget.sheetData[sheetName]['map']?.keys.toList() ?? [];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 70,
        columns: columnNames.map((column) {
          print(selectedValues[sheetName]);
          print(columnNames);
          return DataColumn(
            label: Column(
              children: [
                Text(
                  column,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  borderRadius: BorderRadius.all(Radius.circular(15.0)),
                  // Search for the column in values of `selectedValues[sheetName]` to find the corresponding key
                  value: selectedValues[sheetName]?.entries
                          .firstWhere(
                            (entry) => entry.value == column,
                            orElse: () => MapEntry('Null', 'Null'),  // Fallback if not found
                          )
                          .key,
                  onChanged: (String? newValue) {
                    setState(() {
                      if (newValue != null) {
                        selectedValues[sheetName] ??= {};
                        selectedValues[sheetName]![newValue] = column;
                      }
                    });
                  },
                  items: [
                    // Add 'Null' as a default option if needed
                    const DropdownMenuItem<String>(
                      value: 'Null',
                      child: Text('Null'),
                    ),
                    // Include remaining dropdown options, excluding the selected one
                    ...dropdownOptions.map(
                          (String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          },
                        ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
        rows: sheetDataPreview.map((row) {
          return DataRow(
            cells: row.values.map((cell) {
              return DataCell(
                Text(cell != null ? cell.toString() : 'Null'),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}
