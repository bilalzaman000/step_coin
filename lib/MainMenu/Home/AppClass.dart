class Game {
  final String name;
  final String imagePath;
  final String description;
  final String appURL;
  final int orderId;
  final String? reviewStatus; // Add this line

  Game({
    required this.name,
    required this.imagePath,
    required this.description,
    required this.appURL,
    required this.orderId,
    this.reviewStatus, // Add this line
  });
}
