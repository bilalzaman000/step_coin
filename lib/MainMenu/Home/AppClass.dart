class Game {
  final String name;
  final String imagePath;
  final String description;
  final String appURL;
  final int orderId; // Add the orderId field

  Game({
    required this.name,
    required this.imagePath,
    required this.description,
    required this.appURL,
    required this.orderId, // Include the orderId field in the constructor
  });
}
