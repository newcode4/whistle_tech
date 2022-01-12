
import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/material.dart';

import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:telephony/telephony.dart';

import 'main.dart';



onBackgroundMessage(SmsMessage message) {
  debugPrint("onBackgroundMessage called");
}


class ContactPickerPage extends StatefulWidget {
  @override
  _ContactPickerPageState createState() => _ContactPickerPageState();
}

class _ContactPickerPageState extends State<ContactPickerPage> {

  String location = "Null, Press Button";
  String Address = "search";


  String _message = "";
  final telephony = Telephony.instance;

  final _formKey = GlobalKey<FormState>();
  TextEditingController _phoneController = TextEditingController();
  TextEditingController _msgController = TextEditingController();
  TextEditingController _valueSms = TextEditingController();

  late Contact _contact;
  var phonelist = [];
  var namelist = [];

  @override
  void initState() {
    super.initState();
    initPlatformState();

  }

  onMessage(SmsMessage message) async {
    setState(() {
      _message = message.body ?? "Error reading message body.";
    });
  }

  onSendStatus(SendStatus status) {
    setState(() {
      _message = status == SendStatus.SENT ? "sent" : "delivered";
    });
  }



  Future<void> initPlatformState() async {
    // Platform messages may fail, so we use a try/catch PlatformException.
    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.

    final bool? result = await telephony.requestPhoneAndSmsPermissions;

    if (result != null && result) {
      telephony.listenIncomingSms(
          onNewMessage: onMessage, onBackgroundMessage: onBackgroundMessage);
    }

    if (!mounted) return;
  }

  Future<void> _pickContact() async {
    try {
      final Contact? contact = await ContactsService.openDeviceContactPicker(
          iOSLocalizedLabels: iOSLocalizedLabels);
      setState(() {
        _contact = contact!;
        if (_contact != null) {
          phonelist.add(_contact.phones![0].value);
          namelist.add(_contact.displayName);
        } else
          print('데이터가 없습니다');
      });
    } catch (e) {
      print(e.toString());
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> GetAddressFromLatLong(Position position) async{
    List<Placemark> placemark = await placemarkFromCoordinates(position.latitude, position.longitude);
    print(placemark);
    Placemark place = placemark[0];

    Address = '${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}';

    setState(() {

    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contacts Picker Example')),
      body: SafeArea(
          child: Column(
            children: <Widget>[
              ElevatedButton(
                child: const Text('Pick a contact'),
                onPressed: _pickContact,
              ),
              Container(
                color: Colors.white,
                width: 400,
                height: 200,
                child: ListView.builder(
                  itemCount: phonelist.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Container(
                      margin: EdgeInsets.only(top: 20),
                      child: Row(
                        children: [
                          Text('${namelist[index]} : ${phonelist[index]}')
                        ],
                      ),
                    );
                  },
                ),
              ),
              Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Text(location,
                      style: TextStyle(color:Colors.black, fontSize: 16),),

                      Text('주소'),
                      Text('${Address}',
                      style: TextStyle(fontSize: 18),),

                      // Padding(
                      //   padding: const EdgeInsets.all(8.0),
                      //   child: TextFormField(
                      //     controller: _phoneController,
                      //     keyboardType: TextInputType.phone,
                      //     validator: (value) {
                      //       if (value == null || value.isEmpty) {
                      //         return '값이 없습니다';
                      //       }
                      //       return null;
                      //     },
                      //     decoration: InputDecoration(
                      //         border: OutlineInputBorder(),
                      //         hintText: '보내는 사람',
                      //         labelText: '보내는 사람'
                      //     ),
                      //   ),
                      // ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          controller: _msgController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '값이 입력되지 않았습니다';
                            }
                          },
                          decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: '메세지 입력',
                              labelText: '살려주세요'
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          controller: _valueSms,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '값이 입력되지 않았습니다 sms';
                            }
                          },
                          decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: '반복할 횟수',
                              labelText: '반복'
                          ),
                        ),
                      ),
                      ElevatedButton(
                          onPressed: () => _sendSMS(), child: Text('전송')),
                      ElevatedButton(onPressed: () => _getSMS(), child: const Text('sdf sms')),
                      ElevatedButton(onPressed: () async {
                        Position position = await _determinePosition();
                        print(position.latitude);

                        location = '위도: ${position.latitude}, 경도 : ${position.longitude}';
                        GetAddressFromLatLong(position);
                        setState(() {

                        });
                      }, child: const Text('Get Location')),
                    ],
                  ),
                ),
              ),
              // if (_contact != null){
              //   Text('Contact selected: ${_contact.displayName}'),
              // }
            ],
          )),
    );
  }

  _sendSMS() async {
    int _sms = 0;
    int count = phonelist.length;

    for(var i =0; i<count; i++){
      telephony.sendSms(
                to: phonelist[i].toString(), message: _msgController.text);
    }
    // while (_sms < int.parse(_valueSms.text)) {
    //   telephony.sendSms(
    //       to: phonelist[0].toString(), message: _msgController.text);
    //   _sms ++;
    // }
  }

  _getSMS() async{
    List<SmsMessage> _messages = await telephony.getInboxSms(
      columns: [SmsColumn.ADDRESS, SmsColumn.BODY],
      filter: SmsFilter.where(SmsColumn.ADDRESS).equals(_phoneController.text)
    );

    for(var msg in _messages){
      print(msg.body);
    }
  }
}
