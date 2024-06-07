class AppInfo {
  final String appURL;
  final String appTitle;
  final String iconUrl;
  final int orderId;

  AppInfo({
    required this.appURL,
    required this.appTitle,
    required this.iconUrl,
    required this.orderId,
  });

  factory AppInfo.fromJson(Map<String, dynamic> json) {
    return AppInfo(
      appURL: json['appURL'],
      appTitle: json['app_title'],
      iconUrl: json['icon_url'],
      orderId: json['order_id'],
    );
  }
}
