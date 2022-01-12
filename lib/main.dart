//@dart = 2.9

import 'dart:io';

import 'package:blue_main/searchpage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_storage/get_storage.dart';

import 'contacts_list_page.dart';
import 'contacts_picker_page.dart';

void main() async {
  await GetStorage.init();
  runApp(ContactsExampleApp());
}

final tt = GetStorage();



// iOS only: Localized labels language setting is equal to CFBundleDevelopmentRegion value (Info.plist) of the iOS project
// Set iOSLocalizedLabels=false if you always want english labels whatever is the CFBundleDevelopmentRegion value.
const iOSLocalizedLabels = false;

class ContactsExampleApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
      routes: <String, WidgetBuilder>{
        '/add': (BuildContext context) => AddContactPage(),
        '/contactsList': (BuildContext context) => ContactListPage(),
        '/nativeContactPicker': (BuildContext context) => ContactPickerPage(),
        '/SearchPage': (BuildContext context) => FlutterBlueApp(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  var test_value = "5";
  var event_value;

  @override
  void initState() {
    event_value = test.read('device') ?? test_value;
    super.initState();
    _askPermissions('');

    var initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    //ios 알림 설정 : 소리, 뱃지 등을 설정하여 줄수가 있습니다.
    var initializationSettingsIOS = IOSInitializationSettings();

    var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);

    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    //onSelectNotification의 경우 알림을 눌렀을때 어플에서 실행되는 행동을 설정하는 부분입니다.
    //onSelectNotification는 없어도 되는 부분입니다. 어떤 행동을 취하게 하고 싶지 않다면 그냥 비워 두셔도 됩니다.
    _flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: onSelectNotification);
  }

  Future onSelectNotification(String payload) async {
    print("payload : $payload");
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('우왕 잘됩니다!!!!우와아아아아아아앙!!!'),
          content: Text('Payload: $payload'),
        ));
  }

  var _flutterLocalNotificationsPlugin;

  Future _showNotification2(FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
        'your channel id', 'your channel name',
        importance: Importance.max, priority: Priority.high);
    var iOSPlatformChannelSpecifics = new IOSNotificationDetails();
    var platformChannelSpecifics = new NotificationDetails(
        android: androidPlatformChannelSpecifics, iOS: iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      'New Notification',
      'Flutter is awesome',
      platformChannelSpecifics,
      payload: 'This is notification detail Text...',
    );
  }


// 알림 발생 함수!!
  Future _showNotification() async {
    var android = AndroidNotificationDetails(
        'your channel id', 'your channel name',
        importance: Importance.max, priority: Priority.high);

    var ios = IOSNotificationDetails();
    var detail = NotificationDetails(android: android, iOS: ios);

    await _flutterLocalNotificationsPlugin.show(
      0,
      '블루투스 연결 성공',
      '연결연결',
      detail,
      payload: 'Hello Flutter',
    );
  }

  Future<void> _askPermissions(String routeName) async {
    PermissionStatus permissionStatus = await _getContactPermission();
    if (permissionStatus == PermissionStatus.granted) {
      if (routeName != null) {
        Navigator.of(context).pushNamed(routeName);
      }
    } else {
      _handleInvalidPermissions(permissionStatus);
    }
  }

  Future<PermissionStatus> _getContactPermission() async {
    PermissionStatus permission = await Permission.contacts.status;
    if (permission != PermissionStatus.granted &&
        permission != PermissionStatus.permanentlyDenied) {
      PermissionStatus permissionStatus = await Permission.contacts.request();
      return permissionStatus;
    } else {
      return permission;
    }
  }

  void _handleInvalidPermissions(PermissionStatus permissionStatus) {
    if (permissionStatus == PermissionStatus.denied) {
      final snackBar = SnackBar(content: Text('Access to contact data denied'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } else if (permissionStatus == PermissionStatus.permanentlyDenied) {
      final snackBar =
      SnackBar(content: Text('Contact data not available on device'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  void startServiceInPlatform() async {
    if(Platform.isAndroid){
      var methodChannel = MethodChannel("com.retroportalstudio.messages");
      String data = await methodChannel.invokeMethod("startService");
      debugPrint(data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contacts Plugin Example')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ElevatedButton(
              child: const Text('Contacts list'),
              onPressed: () => _askPermissions('/contactsList'),
            ),
            ElevatedButton(
              child: const Text('Native Contacts picker'),
              onPressed: () => _askPermissions('/nativeContactPicker'),
            ),
            ElevatedButton(
              child: const Text('기기 연결하기'),
              onPressed: () => _askPermissions('/SearchPage'),
            ),
            ElevatedButton(
              child: const Text('백그라운드'),
              onPressed: () => startServiceInPlatform(),
            ),
            ElevatedButton(
              child: const Text('알림 테스트'),
              onPressed: () => _showNotification2(_flutterLocalNotificationsPlugin),
            ),
            ElevatedButton(
              child: const Text('눌러라'),
              onPressed: () {
                setState(() {
                  tt.write('test',"3");
                });
              },
            ),
            Text(event_value ?? 'n/a')
          ],
        ),
      ),
    );
  }
}
