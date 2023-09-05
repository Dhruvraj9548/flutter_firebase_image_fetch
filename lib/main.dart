import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Storage',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<String> imageUrls = []; // Store image URLs here

  @override
  void initState() {
    super.initState();
    fetchImageUrls();
  }

  Future<void> fetchImageUrls() async {
    final List<String> urls = [];

    // Replace 'your_folder' with the path to your Firebase Storage folder.
    final Reference storageRef = FirebaseStorage.instance
        .ref('gs://flutter-ptji-webapp.appspot.com/images');

    // List all items (images) in the folder.
    final ListResult result = await storageRef.listAll();

    // Iterate through the items and get download URLs.
    for (final Reference reference in result.items) {
      final String downloadURL = await reference.getDownloadURL();
      urls.add(downloadURL);
    }

    setState(() {
      imageUrls = urls;
    });
  }

  Future<void> deleteImage(int index) async {
    try {
      // Get the reference to the image to be deleted.
      final Reference storageRef = FirebaseStorage.instance
          .refFromURL(imageUrls[index]);

      // Show a confirmation dialog before deleting.
      bool confirmed = await showDeleteConfirmationDialog();

      if (confirmed) {
        // Delete the image from Firebase Storage.
        await storageRef.delete();

        // Remove the URL from the imageUrls list.
        setState(() {
          imageUrls.removeAt(index);
        });
      }
    } catch (e) {
      print('Error deleting image: $e');
    }
  }

  Future<bool> showDeleteConfirmationDialog() async {
    Completer<bool> completer = Completer<bool>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Image'),
          content: Text('Are you sure you want to delete this image?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
                completer.complete(false);
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop(true);
                completer.complete(true);
              },
            ),
          ],
        );
      },
    );

    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Firebase Storage Images'),
      ),
      body: GridView.builder(
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return Column(
            children: [
              Expanded(
                child: CachedNetworkImage(
                  imageUrl: imageUrls[index],
                  fit: BoxFit.cover,
                  width: MediaQuery.of(context).size.width * 0.75,
                  placeholder: (context, url) => CircularProgressIndicator(),
                  errorWidget: (context, url, error) => Icon(Icons.error),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  deleteImage(index);
                },
                child: Text('Delete'),
              ),
            ],
          );
        },
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          crossAxisSpacing: 5.0,
          mainAxisSpacing: 5.0,
        ),
      ),

    );
  }
}
