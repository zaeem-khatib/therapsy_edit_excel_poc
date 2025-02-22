import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ExcelEditor(),
    );
  }
}

class ExcelEditor extends StatefulWidget {
  @override
  _ExcelEditorState createState() => _ExcelEditorState();
}

class _ExcelEditorState extends State<ExcelEditor> {
  Excel? excel;
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  Uint8List? fileBytes;

  @override
  void initState() {
    super.initState();
    loadExcelFromAssets().then((_) {
      setState(() {});
    });
  }


  Future<void> loadExcelFromAssets() async {
    ByteData data = await rootBundle.load("assets/TestSheet.xlsx");
    fileBytes = data.buffer.asUint8List();
    excel = Excel.decodeBytes(fileBytes!);
  }

  void updateExcel() {
    if (excel == null) return;

    for (var sheetName in excel!.tables.keys) {
      Sheet? sheet = excel!.tables[sheetName];
      if (sheet == null) continue;

      for (int rowIndex = 0; rowIndex < sheet.maxRows; rowIndex++) {
        for (int colIndex = 0; colIndex < sheet.maxColumns; colIndex++) {
          var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: rowIndex));

          if (cell.value != null) {
            String cellValue = cell.value.toString();

            if (cellValue == "{firstname}" || cellValue == "{lastname}") {
              // Save original style
              CellStyle? originalStyle = cell.cellStyle;

              // Update cell value
              String updateValue = cellValue == "{firstname}" ? firstNameController.text : lastNameController.text;
              cell.value = TextCellValue(updateValue);

              // Restore original style
              if (originalStyle != null) {
                cell.cellStyle = originalStyle;
              }
            }
          }
        }
      }
    }
  }


  /*void updateExcel() {
    if (excel == null) return;

    // Find and replace placeholders across all sheets
    for (var sheet in excel!.sheets.values) {
        sheet.findAndReplace("{firstname}", firstNameController.text);
        sheet.findAndReplace("{lastname}", lastNameController.text);
    }
  }*/

  /*void updateExcel() {
    if (excel == null || excel!.tables.isEmpty) return;

    for (var sheetName in excel!.tables.keys) {
      Sheet? currentSheet = excel!.tables[sheetName];
      if (currentSheet == null) continue; // Skip null sheets

      for (int rowIndex = 0; rowIndex < currentSheet.maxRows; rowIndex++) {
        for (int colIndex = 0; colIndex < currentSheet.maxColumns; colIndex++) {
          var cell = currentSheet.cell(CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: rowIndex));

          if (cell.value.toString() == "{firstname}") {
            currentSheet.updateCell(CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: rowIndex), TextCellValue(firstNameController.text));
          }
          if (cell.value.toString() == "{lastname}") {
            currentSheet.updateCell(CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: rowIndex), TextCellValue(lastNameController.text));
          }
        }
      }
    }
  }*/


  /*void updateExcel() {
    if (excel == null || excel!.tables.isEmpty) return;

    for (var sheet in excel!.tables.keys) {
      Sheet? currentSheet = excel!.tables[sheet];
      if (currentSheet == null) continue; // Skip null sheets

      for (var row in currentSheet.rows) {
        if (row.isEmpty) continue; // Avoid null row errors
        for (var cell in row) {
          if (cell == null || cell.value == null) continue; // Avoid null cell errors

          if (cell.value.toString() == "{firstname}") {
            currentSheet.updateCell(
              CellIndex.indexByColumnRow(
                columnIndex: cell.columnIndex,
                rowIndex: cell.rowIndex,
              ),
                TextCellValue(firstNameController.text)
            );
          }
          if (cell.value.toString() == "{lastname}") {
            currentSheet.updateCell(
              CellIndex.indexByColumnRow(
                columnIndex: cell.columnIndex,
                rowIndex: cell.rowIndex,
              ),
              TextCellValue(lastNameController.text)
            );
          }
        }
      }
    }
  }*/

  Future<void> exportExcel() async {
    updateExcel();
    List<int>? bytes = excel?.encode();

    if (bytes == null || bytes.isEmpty) {
      print("Error: Failed to generate Excel file bytes.");
      return;
    }

    // Get the temporary directory
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/UpdatedExcel.xlsx';

    // Save the file temporarily
    File file = File(filePath);
    await file.writeAsBytes(Uint8List.fromList(bytes));

    // Share the file
    await Share.shareXFiles([XFile(filePath)]);
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Excel Editor")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: firstNameController,
              decoration: InputDecoration(labelText: "Enter First Name"),
            ),
            TextField(
              controller: lastNameController,
              decoration: InputDecoration(labelText: "Enter Last Name"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: exportExcel,
              child: Text("Export Excel"),
            ),
          ],
        ),
      ),
    );
  }
}