import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:step_coin/Api/ReviewApi/AppInfo.dart';

Future<List<AppInfo>> fetchApps() async {
  final response = await http.post(
    Uri.parse('https://apporater.com/api/get_order_third_party/'),
    headers: {
      'Auth': 'tf@i@32m!)3-y8c)7snlt-wb&dphtcujgs)4wl@mdz5e0ln^s',
    },
    body: {
      'device_type': 'android',
    },
  );

  if (response.statusCode == 200) {
    final jsonResponse = jsonDecode(response.body);
    if (jsonResponse['result'] == 'success') {
      final List<dynamic> data = jsonResponse['data'];
      return data.map((item) => AppInfo.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load apps');
    }
  } else {
    throw Exception('Failed to load apps');
  }
}
