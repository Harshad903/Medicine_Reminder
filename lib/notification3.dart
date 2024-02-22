import 'dart:convert';

import 'package:date_time_picker/date_time_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:medcare3/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones(); // Initialize time zones
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Notifi(),
    );
  }
}

class Notifi extends StatefulWidget {
  const Notifi({Key? key}) : super(key: key);

  @override
  State<Notifi> createState() => _NotifiState();
}

class _NotifiState extends State<Notifi> {
  final _localNotificationservice = FlutterLocalNotificationsPlugin();
  DateTime? selectedDateTime;
  List<DateTime> scheduledDateTimes = [];

  @override
  void initState() {
    intialize();
    super.initState();
    loadScheduledDates();
  }

  Future<void> loadScheduledDates() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    final encodedScheduledDates = sharedPreferences.getString('scheduledDates');
    if (encodedScheduledDates != null) {
      final List<String> decodedScheduledDates = jsonDecode(encodedScheduledDates).cast<String>();
      setState(() {
        scheduledDateTimes = decodedScheduledDates.map((date) => DateTime.parse(date)).toList();
      });
    }
  }

  Future<void> intialize() async {
    tz.initializeTimeZones();
    AndroidInitializationSettings androidInitializationSettings =
    const AndroidInitializationSettings('playstore');
    InitializationSettings settings =
    InitializationSettings(android: androidInitializationSettings);

    await _localNotificationservice.initialize(settings);
  }

  Future<NotificationDetails> _notificationDetails() async {
    const AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails(
      '1',
      'Notifications app',
      channelDescription: 'description',
      importance: Importance.max,
      priority: Priority.max,
    );

    return const NotificationDetails(
      android: androidNotificationDetails,
    );
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    final details = await _notificationDetails();
    await _localNotificationservice.show(id, title, body, details);
  }

  Future<void> scheduleNotifications(List<DateTime> scheduledDateTimes) async {
    // Save scheduled dates to shared preferences
    final sharedPreferences = await SharedPreferences.getInstance();
    final encodedScheduledDates = jsonEncode(scheduledDateTimes.map((date) => date.toIso8601String()).toList());
    await sharedPreferences.setString('scheduledDates', encodedScheduledDates);

    // Schedule notifications
    final details = await _notificationDetails();
    final now = DateTime.now();

    for (var scheduledDateTime in scheduledDateTimes) {
      final scheduledTime = scheduledDateTime.isAfter(now) ? scheduledDateTime : now.add(const Duration(seconds: 1));

      await _localNotificationservice.zonedSchedule(
        scheduledDateTimes.indexOf(scheduledDateTime),
        'MedCare',
        'It is time to take your medicine, according to schedule',
        tz.TZDateTime.from(scheduledTime, tz.local),
        details,
        // ignore: deprecated_member_use
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Notifications"),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // ElevatedButton(
              //   onPressed: () async {
              //     await showNotification(
              //       id: 1,
              //       title: "Tea Time",
              //       body: "It's time to drink tea!",
              //     );
              //   },
              //   child: const Text("Show Notification"),
              // ),
              DateTimePicker(
                type: DateTimePickerType.dateTime,
                initialValue: DateTime.now().toString(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                icon: const Icon(Icons.event),
                style: Theme.of(context)
                    .textTheme
                    .titleSmall!
                    .copyWith(color: kOtherColor),
                onChanged: (val) {
                  setState(() {
                    selectedDateTime = DateTime.parse(val);
                  });
                },
              ),
              Column(
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      if (selectedDateTime != null) {
                        scheduledDateTimes.add(selectedDateTime!);
                        setState(() {
                          selectedDateTime = null;
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select a date and time.'),
                          ),
                        );
                      }
                    },
                    child: const Text("Add Notification"),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: scheduledDateTimes.length,
                    itemBuilder: (context, index) {
                      final dateTime = scheduledDateTimes[index];
                      return ListTile(
                        title: Text("Notification ${index + 1} - ${dateTime
                            .toString()}",
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall!
                              .copyWith(color: kOtherColor),),
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            setState(() {
                              scheduledDateTimes.removeAt(index);
                            });
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () async {
                  if (scheduledDateTimes.isNotEmpty) {
                    await scheduleNotifications(scheduledDateTimes);
                    scheduledDateTimes.clear();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Please add at least one notification time.'),
                      ),
                    );
                  }
                },
                child: const Text("Schedule Notification"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}