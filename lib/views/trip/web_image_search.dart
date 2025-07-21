import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:holiday_planner/src/rust/api/trips.dart';
import 'package:holiday_planner/src/rust/commands/search_web_images.dart';
import 'package:holiday_planner/src/rust/models/web_images.dart';

class WebImageSearchView extends StatefulWidget {
  const WebImageSearchView({super.key});

  @override
  State<WebImageSearchView> createState() => _WebImageSearchViewState();
}

class _WebImageSearchViewState extends State<WebImageSearchView> {
  final TextEditingController _searchController = TextEditingController();
  List<WebImage> _images = [];
  bool _isLoading = false;
  String? _errorMessage;
  WebImage? _selectedImage;
  Uint8List? _downloadedImage;
  bool _isDownloading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchImages() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _errorMessage = "Please enter a search term";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _images = [];
    });

    try {
      final command = SearchWebImages(query: query);
      final images = await searchWebImages(command: command);
      setState(() {
        _images = images;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Error searching for images: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _selectImage(WebImage image) async {
    setState(() {
      _selectedImage = image;
      _isDownloading = true;
    });

    try {
      final imageBytes = await downloadWebImage(imageUrl: image.url);
      setState(() {
        _downloadedImage = imageBytes;
        _isDownloading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Error downloading image: $e";
        _isDownloading = false;
      });
    }
  }

  void _confirmSelection() {
    if (_downloadedImage != null) {
      Navigator.pop(context, _downloadedImage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Web Images'),
        centerTitle: true,
        actions: [
          if (_downloadedImage != null)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: FilledButton(
                onPressed: _confirmSelection,
                child: const Text("Select"),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search for images...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _searchImages(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _searchImages,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Search'),
                ),
              ],
            ),
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _images.isEmpty
                    ? Center(
                        child: Text(
                          'No images found. Try searching for something.',
                          style: textTheme.bodyLarge,
                        ),
                      )
                    : _selectedImage != null && _isDownloading
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text('Downloading image...'),
                              ],
                            ),
                          )
                        : _downloadedImage != null
                            ? _buildPreviewImage()
                            : _buildImageGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid() {
    final width = MediaQuery.of(context).size.width;
    int crossAxisCount;
    double childAspectRatio = 1.0;
    
    if (width < 600) {
      crossAxisCount = 2;
      childAspectRatio = 1.0;
    } else if (width < 900) {
      crossAxisCount = 3;
      childAspectRatio = 1.0;
    } else if (width < 1200) {
      crossAxisCount = 4;
      childAspectRatio = 0.9;
    } else {
      crossAxisCount = 5;
      childAspectRatio = 0.85;
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: _images.length,
      itemBuilder: (context, index) {
        final image = _images[index];
        return InkWell(
          onTap: () => _selectImage(image),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  image.thumbnailUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.error_outline, color: Colors.red),
                      ),
                    );
                  },
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.black.withOpacity(0.5),
                    child: Text(
                      'By ${image.author}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreviewImage() {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                _downloadedImage!,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedImage = null;
                    _downloadedImage = null;
                  });
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to results'),
              ),
              FilledButton.icon(
                onPressed: _confirmSelection,
                icon: const Icon(Icons.check),
                label: const Text('Use this image'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
