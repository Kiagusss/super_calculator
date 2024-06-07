import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HiddenPage extends StatefulWidget {
  const HiddenPage({super.key});

  @override
  _HiddenPageState createState() => _HiddenPageState();
}

class _HiddenPageState extends State<HiddenPage> {
  final List<File> _selectedFiles = [];
  List<String> _savedFilePaths = [];

  @override
  void initState() {
    super.initState();
    _loadSavedFiles();
  }

  Future<void> _openFileExplorer() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        List<File> files = result.paths.map((path) => File(path!)).toList();

        setState(() {
          _selectedFiles.addAll(files);
        });

        await _saveFilesToLocalDirectory(files);

        await _saveFilePathsToPrefs();
      }
    } catch (e) {
      print('File picking failed: $e');
    }
  }

  Future<void> _saveFilesToLocalDirectory(List<File> files) async {
    final appDir = await getApplicationDocumentsDirectory();

    for (File file in files) {
      final fileName = file.path.split('/').last;
      final newPath = '${appDir.path}/$fileName';

      try {
        await file.copy(newPath);
        print('File saved locally: $newPath');
      } catch (e) {
        print('Failed to save file locally: $e');
      }
    }
  }

  Future<void> _loadSavedFiles() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedFilePaths = prefs.getStringList('savedFilePaths') ?? [];
    });

    List<File> loadedFiles = [];
    for (String path in _savedFilePaths) {
      loadedFiles.add(File(path));
    }
    setState(() {
      _selectedFiles.addAll(loadedFiles);
    });
  }

  Future<void> _saveFilePathsToPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> filePaths = _selectedFiles.map((file) => file.path).toList();
    await prefs.setStringList('savedFilePaths', filePaths);
  }

  Future<void> _removeFileByTag(String tag) async {
    File? fileToRemove;
    for (File file in _selectedFiles) {
      String fileName = file.path.split('/').last;
      if (fileName == tag) {
        fileToRemove = file;
        break;
      }
    }

    if (fileToRemove != null) {
      _selectedFiles.remove(fileToRemove);
      setState(() {});

      await File(fileToRemove.path).delete();

      await _saveFilePathsToPrefs();
      Navigator.pop(context);
    }
  }

  Future<void> _removeFile(int index) async {
    String filePath = _selectedFiles[index].path;
    _selectedFiles.removeAt(index);
    setState(() {});

    await File(filePath).delete();

    await _saveFilePathsToPrefs();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Hide'),
      ),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // Jumlah kolom dalam grid
          crossAxisSpacing: 8, // Spasi antar kolom
          mainAxisSpacing: 8, // Spasi antar baris
        ),
        itemCount: _selectedFiles.length,
        itemBuilder: (context, index) {
          File file = _selectedFiles[index];
          String fileName = file.path.split('/').last;

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _buildImagePreview(file, fileName),
                ),
              );
            },
            child: Stack(
              children: [
                Positioned.fill(
                  child: Hero(
                    tag: fileName,
                    child: Image.file(
                      file,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openFileExplorer,
        tooltip: 'Add Image',
        child: const Icon(Icons.add_a_photo_outlined),
      ),
    );
  }

  Widget _buildImagePreview(File file, String tag) {
    String fileName = file.path.split('/').last;
    return Scaffold(
      appBar: AppBar(
        title: Text(tag),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Hero(
              tag: file.path,
              child: Image.file(file),
            ),
          ),
          Container(
            height: 50,
            color: Colors.black,
            child: IconButton(
              icon: const Icon(Icons.delete_forever_outlined,
                  color: Colors.white),
              onPressed: () => _removeFileByTag(tag),
            ),
          ),
        ],
      ),
    );
  }
}
