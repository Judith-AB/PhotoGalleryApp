import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class GalleryScreen extends StatefulWidget {
  @override
  _GalleryScreenState createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  Map<String, List<String>> albums = {"All Photos": []};
  List<String> favorites = [];
  String selectedAlbum = "All Photos";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      albums = Map<String, List<String>>.from(prefs
              .getStringList('albums')
              ?.asMap()
              .map((_, album) =>
                  MapEntry(album, prefs.getStringList(album) ?? [])) ??
          {"All Photos": []});
      favorites = prefs.getStringList('favorites') ?? [];
    });
  }

  Future<void> _addPhotos() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        albums[selectedAlbum] ??= [];
        List<String> paths = pickedFiles.map((file) => file.path).toList();

        // 🛑 Prevent duplicates by checking if they already exist
        for (String path in paths) {
          if (!albums[selectedAlbum]!.contains(path)) {
            albums[selectedAlbum]!.add(path);
          }
          if (!albums["All Photos"]!.contains(path)) {
            albums["All Photos"]!.add(path);
          }
        }
      });

      // Save only after preventing duplicates
      await prefs.setStringList(selectedAlbum, albums[selectedAlbum]!);
      await prefs.setStringList("All Photos", albums["All Photos"]!);
    }
  }

  Future<void> _createAlbum() async {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Create Album"),
        content: TextField(controller: controller),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          TextButton(
            onPressed: () {
              String albumName = controller.text.trim();
              if (albumName.isNotEmpty && !albums.containsKey(albumName)) {
                setState(() {
                  albums[albumName] = [];
                });
                _saveAlbums();
              }
              Navigator.pop(context);
            },
            child: Text("Create"),
          ),
        ],
      ),
    );
  }

  Future<void> _renameAlbum(String oldName) async {
    TextEditingController controller = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Rename Album"),
        content: TextField(controller: controller),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          TextButton(
            onPressed: () {
              String newName = controller.text.trim();
              if (newName.isNotEmpty && !albums.containsKey(newName)) {
                setState(() {
                  albums[newName] = albums.remove(oldName)!;
                  selectedAlbum = newName;
                });
                _saveAlbums();
              }
              Navigator.pop(context);
            },
            child: Text("Rename"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAlbum(String albumName) async {
    if (albumName == "All Photos") return;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      albums.remove(albumName);
      selectedAlbum = "All Photos";
    });
    _saveAlbums();
  }

  Future<void> _deletePhoto(String photoPath) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      albums[selectedAlbum]?.remove(photoPath);
      albums["All Photos"]?.remove(photoPath);
      favorites.remove(photoPath);
    });
    _saveAlbums();
  }

  Future<void> _toggleFavorite(String photoPath) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      if (favorites.contains(photoPath)) {
        favorites.remove(photoPath);
      } else {
        favorites.add(photoPath);
      }
    });
    await prefs.setStringList('favorites', favorites);
  }

  Future<void> _saveAlbums() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('albums', albums.keys.toList());
    for (var album in albums.keys) {
      await prefs.setStringList(album, albums[album]!);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> photos;
    if (selectedAlbum == "Favorites") {
      photos = favorites;
    } else {
      photos = albums[selectedAlbum] ?? [];
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Photo Gallery"),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                selectedAlbum = value;
              });
            },
            itemBuilder: (context) => [
              ...albums.keys.map(
                  (album) => PopupMenuItem(value: album, child: Text(album))),
              PopupMenuItem(value: "Favorites", child: Text("Favorites")),
            ],
          ),
        ],
      ),
      body: photos.isEmpty
          ? Center(child: Text("No photos added yet"))
          : GridView.builder(
              padding: EdgeInsets.all(10),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, crossAxisSpacing: 4, mainAxisSpacing: 4),
              itemCount: photos.length,
              itemBuilder: (context, index) {
                String photo = photos[index];
                return Stack(
                  children: [
                    Image.file(File(photo),
                        fit: BoxFit.cover, width: double.infinity),
                    Positioned(
                      top: 5,
                      right: 5,
                      child: IconButton(
                        icon: Icon(
                          favorites.contains(photo)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: Colors.red,
                        ),
                        onPressed: () => _toggleFavorite(photo),
                      ),
                    ),
                    Positioned(
                      bottom: 5,
                      right: 5,
                      child: IconButton(
                        icon: Icon(Icons.delete, color: Colors.white),
                        onPressed: () => _deletePhoto(photo),
                      ),
                    ),
                  ],
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPhotos,
        child: Icon(Icons.add),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            ListTile(
              title: Text("Create Album"),
              leading: Icon(Icons.create_new_folder),
              onTap: () {
                Navigator.pop(context);
                _createAlbum();
              },
            ),
            ListTile(
              title: Text("All Photos"),
              onTap: () {
                setState(() => selectedAlbum = "All Photos");
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text("Favorites"),
              onTap: () {
                setState(() => selectedAlbum = "Favorites");
                Navigator.pop(context);
              },
            ),
            ...albums.keys
                .where((album) => album != "All Photos")
                .map((album) => ListTile(
                      title: Text(album),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == "Rename") _renameAlbum(album);
                          if (value == "Delete") _deleteAlbum(album);
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(value: "Rename", child: Text("Rename")),
                          PopupMenuItem(value: "Delete", child: Text("Delete")),
                        ],
                      ),
                      onTap: () {
                        setState(() => selectedAlbum = album);
                        Navigator.pop(context);
                      },
                    )),
          ],
        ),
      ),
    );
  }
}
