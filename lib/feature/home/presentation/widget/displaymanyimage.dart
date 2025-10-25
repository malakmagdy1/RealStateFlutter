import 'package:flutter/material.dart';

import '../../../../core/widget/robust_network_image.dart';
import '../../../compound/data/models/compound_model.dart';

class DisplayManyImage extends StatefulWidget {
  final Compound compound;

  DisplayManyImage({required this.compound});

  @override
  State<DisplayManyImage> createState() => _DisplayManyImageState();
}

class _DisplayManyImageState extends State<DisplayManyImage> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final hasImages = widget.compound.images.isNotEmpty;
    final displayImage = hasImages
        ? widget.compound.images[_currentImageIndex]
        : null;
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.compound.images.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              setState(() {
                _currentImageIndex = index;
              });
            },
            child: Container(
              margin: EdgeInsets.only(right: 10),
              width: 100,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _currentImageIndex == index
                      ? Colors.blue
                      : Colors.grey.shade300,
                  width: _currentImageIndex == index ? 3 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: RobustNetworkImage(
                  imageUrl: widget.compound.images[index],
                  fit: BoxFit.cover,
                  loadingBuilder: (context) => Container(
                    color: Colors.grey.shade200,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorBuilder: (context, url) {
                    print(
                      '[IMAGE ERROR] Failed to load gallery image $index: $url',
                    );
                    return Container(
                      color: Colors.red.shade100,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, color: Colors.red.shade400),
                          SizedBox(height: 4),
                          Text(
                            'Image ${index + 1}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
