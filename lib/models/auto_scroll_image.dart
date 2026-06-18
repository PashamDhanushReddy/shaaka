class AutoScrollImage {
  final int id;
  final String image;
  final String? title;
  final bool isActive;
  final int order;
  final String placement;

  AutoScrollImage({
    required this.id,
    required this.image,
    this.title,
    required this.isActive,
    required this.order,
    required this.placement,
  });

  factory AutoScrollImage.fromJson(Map<String, dynamic> json) {
    String rawImage = json['image_url']?.toString() ?? '';
    if (rawImage.isEmpty) {
      rawImage = json['image']?.toString() ?? '';
    }
    
    final String fullImageUrl = rawImage.startsWith('http') 
        ? rawImage 
        : 'https://shaaka-33pq.onrender.com/media/$rawImage';

    return AutoScrollImage(
      id: json['id'],
      image: fullImageUrl,
      title: json['title'],
      isActive: json['is_active'] ?? true,
      order: json['order'] ?? 0,
      placement: json['placement']?.toString().toLowerCase() ?? 'top',
    );
  }
}
