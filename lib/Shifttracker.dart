import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Shifttracker extends StatefulWidget {
  @override
  State<Shifttracker> createState() => _ShifttrackerState();
}

class _ShifttrackerState extends State<Shifttracker> {
  bool isOnShift = false;
  bool isOnBreak = false;
  DateTime? shiftStartTime;
  DateTime? shiftEndTime;
  DateTime? breakStartTime;
  Timer? breakTimer;
  Duration breakDuration = Duration.zero;
  Duration totalPaidTime = Duration.zero;
  String? selectedBreakType;
  String location = "Admin";
  List<Break> breaks = [];

  // New variables to carry time between shifts
  int s = 0, m = 0, h = 0;
  String digsec = "00", digmin = "00", dighr = "00";
  Timer? timer;
  bool started = false;
  String? currentBreakType;

  @override
  void initState() {
    super.initState();
    // If you want to start a shift automatically when the widget is first created
    startShift();
  }

  void startShift() {
    setState(() {
      isOnShift = true;
      shiftStartTime = DateTime.now();
      // Reset timer to zero
      s = 0;
      m = 0;
      h = 0;
      digsec = "00";
      digmin = "00";
      dighr = "00";
      started = false;
      currentBreakType = null;
    });

    // Start the shift timer
    start();
  }

  void stop() {
    timer?.cancel();
    setState(() {
      started = false;
    });
  }

  void reset() {
    timer?.cancel();
    setState(() {
      s = 0;
      m = 0;
      h = 0;
      digsec = "00";
      digmin = "00";
      dighr = "00";
      started = false;
      currentBreakType = null;
    });
  }

  void start() {
    setState(() {
      started = true;
    });

    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      int localsec = s + 1;
      int localmin = m;
      int localhr = h;

      if (localsec > 59) {
        localmin++;
        localsec = 0;
      }
      if (localmin > 59) {
        localhr++;
        localmin = 0;
      }

      setState(() {
        s = localsec;
        m = localmin;
        h = localhr;
        digsec = (s >= 10) ? "$s" : "0$s";
        digmin = (m >= 10) ? "$m" : "0$m";
        dighr = (h >= 10) ? "$h" : "0$h";
      });
    });
  }

  void addBreak() {
    setState(() {
      breaks.add(Break(
        type: 'Meal Break',
        duration: Duration(minutes: 5),
        startTime: DateTime.now(),
        endTime: DateTime.now().add(Duration(minutes: 5)),
      ));
    });
  }

  void deleteBreak(int index) {
    if (index < 0 || index >= breaks.length) return; // Safety check

    setState(() {
      // Remove the break at the specified index
      breaks.removeAt(index);

      // Recalculate total paid time after removing the break
      if (shiftEndTime != null && shiftStartTime != null) {
        totalPaidTime = shiftEndTime!.difference(shiftStartTime!) -
            breaks.fold(Duration.zero, (sum, b) => sum + b.duration);
      }

      // If we were on this break, end it
      if (isOnBreak && breakStartTime != null) {
        final currentBreakDuration = DateTime.now().difference(breakStartTime!);
        if (currentBreakDuration.inMinutes < 30) { // Less than typical break duration
          isOnBreak = false;
          breakStartTime = null;
          breakDuration = Duration.zero;
          breakTimer?.cancel();
          selectedBreakType = null;
        }
      }
    });
  }


  void endShift() async {
    // Stop the timer
    timer?.cancel();

    setState(() {
      shiftEndTime = DateTime.now();
      // Calculate total paid time by subtracting breaks from shift duration
      totalPaidTime = shiftEndTime!.difference(shiftStartTime!) -
          breaks.fold(Duration.zero, (sum, b) => sum + b.duration);
    });

    // Show End Shift Dialog
    bool? confirmEnd = await showDialog<bool>(
      context: context,
      builder: (context) => EndShiftdiloug(
        startTime: shiftStartTime!,
        endTime: shiftEndTime!,
        breaks: breaks,
        totalPaidTime: totalPaidTime,
        onAddBreak: addBreak,
        onDeleteBreak: deleteBreak,
      ),
    );

    // Only reset if the shift is confirmed to be ended
    if (confirmEnd == true) {
      setState(() {
        isOnShift = false;
        shiftStartTime = null;
        shiftEndTime = null;
        isOnBreak = false;
        breaks.clear();
        totalPaidTime = Duration.zero;

        // Reset timer
        s = 0;
        m = 0;
        h = 0;
        digsec = "00";
        digmin = "00";
        dighr = "00";
        started = false;
        currentBreakType = null;
      });
    }
  }

  Future<void> showBreakSelection() async {
    String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        String? selectedBreakType;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(''),
              content: const Text(
                'Which break do you want to start?',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              actions: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedBreakType = 'Meal Break';
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.all(12),
                    margin: EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: selectedBreakType == 'Meal Break'
                            ? Colors.blue
                            : Colors.grey,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Meal Break',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Unscheduled',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedBreakType = 'Rest Break';
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.all(12),
                    margin: EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: selectedBreakType == 'Rest Break'
                            ? Colors.blue
                            : Colors.grey,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Rest Break',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Unscheduled',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: selectedBreakType != null
                          ? () {
                        Navigator.pop(context, selectedBreakType);
                      }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Start Break',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        currentBreakType = result;
      });
      showBreakConfirmation();
      start();
    }
  }

  void showBreakConfirmation() {
    showDialog(
      context: context,
      builder: (context) => Breakconfarmation(),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey[300],
              child: Text(
                'TR',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Tushar Rai',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Column(
              children: [
                Text(
                  currentBreakType ?? 'Not on break',
                  style: TextStyle(
                    fontSize: 16,
                    color: started ? Colors.orange : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  '$dighr:$digmin:$digsec',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: started ? stop : showBreakSelection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[200],
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    started ? "Stop break" : "Start break",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.purple[700],
                    ),
                  ),
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: isOnShift ? endShift : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'End Shift',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            TextButton(
              onPressed: () {
                // Add edit functionality here
              },
              child: Text(
                'Edit shift',
                style: TextStyle(
                  color: Colors.purple,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

//
// Future<void> Breakselection(BuildContext context) async {
//   return showDialog(
//     context: context,
//     builder: (BuildContext context) {
//
//       String? selectedBreakType;
//
//       return AlertDialog(
//         title: const Text(''),
//         content: const Text('                 Which break do you want to start?',
//           style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//         ),
//
//         actions: [
//
//           GestureDetector(
//             onTap: () {
//               setState(() {
//                 selectedBreakType = 'Meal Break';
//               });
//             },
//             child: Container(
//               padding: EdgeInsets.all(12),
//               margin: EdgeInsets.symmetric(vertical: 8),
//               decoration: BoxDecoration(
//                 border: Border.all(
//                   color: selectedBreakType == 'Meal Break'
//                       ? Colors.blue
//                       : Colors.grey,
//                 ),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     'Meal Break',
//                     style: TextStyle(fontSize: 16),
//                   ),
//                   Text(
//                     'Unscheduled',
//                     style: TextStyle(color: Colors.grey),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           GestureDetector(
//             onTap: () {
//               setState(() {
//                 selectedBreakType = 'Rest Break';
//               });
//             },
//             child: Container(
//               padding: EdgeInsets.all(12),
//               margin: EdgeInsets.symmetric(vertical: 8),
//               decoration: BoxDecoration(
//                 border: Border.all(
//                   color: selectedBreakType == 'Rest Break'
//                       ? Colors.blue
//                       : Colors.grey,
//                 ),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     'Rest Break',
//                     style: TextStyle(fontSize: 16),
//                   ),
//                   Text(
//                     'Unscheduled',
//                     style: TextStyle(color: Colors.grey),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//
//           Row(
//             mainAxisAlignment: MainAxisAlignment.end,
//             children: [
//
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('Cancel'),
//               ),
//               ElevatedButton(onPressed: (){
//                 Navigator.push(context, MaterialPageRoute(builder: (context)=>Breakconfarmation()));
//
//               },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.red,
//                     padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   child:const Text('Start Break',style: TextStyle(color: Colors.white),)
//               )
//             ],
//           ),
//         ],
//       );
//     },
//   );
// }
//
// void setState(Null Function() param0) {
// }


class Breakconfarmation extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return  Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Break Time',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height : 16),
            Icon(
              Icons.thumb_up_alt_rounded,
              size: 64,
              color: Colors.lightBlue,
            ),
            SizedBox(height: 16),
            Text(
              'Enjoy your ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 height: 8),
            Text(
              'See you back soon.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

}


class Break {
  String type;
  Duration duration;
  DateTime startTime;
  DateTime endTime;
  bool setCustomTimes;

  Break({
    required this.type,
    required this.duration,
    required this.startTime,
    required this.endTime,
    this.setCustomTimes = false,
  });
}


class EndShiftdiloug extends StatefulWidget{
  final DateTime startTime;
    final DateTime endTime;
    final List  breaks;
    final Duration totalPaidTime;
    final VoidCallback onAddBreak;
    final ValueChanged<int> onDeleteBreak;
  EndShiftdiloug({
    required this.startTime,
    required this.endTime,
    required this.breaks,
    required this.totalPaidTime,
    required this.onAddBreak,
    required this.onDeleteBreak,


});


  @override
  State<EndShiftdiloug> createState() => _EndShiftdilougState();
}
class _EndShiftdilougState extends State<EndShiftdiloug> {
  TextEditingController commentController = TextEditingController();
  String formatTime (DateTime time)=> DateFormat('hh:mm a').format(time);

  Future<void> _selectTime(BuildContext context, DateTime initialTime, Function(DateTime) onTimeChanged) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialTime),
    );
    if (picked != null) {
      final DateTime newTime = DateTime(initialTime.year, initialTime.month, initialTime.day, picked.hour, picked.minute);
      onTimeChanged(newTime);
    }
  }



  @override
  Widget build(BuildContext context) {
   return Dialog(
     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
     child: Padding(
       padding: const EdgeInsets.all(16.0),
       child: SingleChildScrollView(
         child: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             Text(
               'End Shift',
               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
             ),
             SizedBox(height: 16),
             Row(
               children: [
                 Icon(Icons.access_time, color: Colors.purple),
                 SizedBox(width: 8),
                 Text(
                   '${widget.totalPaidTime.inMinutes}m',
                   style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.purple),
                 ),
               ],
             ),
             Text('Total Paid Time', style: TextStyle(color: Colors.grey[700])),
             SizedBox(height: 16),
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Text('Start time', style: TextStyle(fontWeight: FontWeight.bold)),
                 Text('End time', style: TextStyle(fontWeight: FontWeight.bold)),
               ],
             ),
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Text(formatTime(widget.startTime)),
                 Text(formatTime(widget.endTime)),
               ],
             ),
             SizedBox(height: 16),
             ...widget.breaks.asMap().entries.map((entry) {
               int index = entry.key;
               Break breakItem = entry.value;
               return Padding(
                 padding: const EdgeInsets.symmetric(vertical: 8.0),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     Expanded(
                       child: DropdownButton<String>(
                         value: breakItem.type,
                         items: [
                           DropdownMenuItem(value: 'Meal Break', child: Text('Meal Break')),
                           DropdownMenuItem(value: 'Rest Break', child: Text('Rest Break')),
                         ],
                         onChanged: (value) {
                           setState(() {
                             breakItem.type = value!;
                           });
                         },
                       ),
                     ),
                     SizedBox(width: 8),
                     Expanded(
                       child: TextField(
                         controller: TextEditingController(text: breakItem.duration.inMinutes.toString()),
                         keyboardType: TextInputType.number,
                         decoration: InputDecoration(
                           labelText: 'Duration (mins)',
                         ),
                         onSubmitted: (value) {
                           setState(() {
                             breakItem.duration = Duration(minutes: int.parse(value));
                             breakItem.endTime = breakItem.startTime.add(breakItem.duration);
                           });
                         },
                       ),
                     ),
                     SizedBox(width: 8),
                     Checkbox(
                       value: breakItem.setCustomTimes,
                       onChanged: (value) {
                         setState(() {
                           breakItem.setCustomTimes = value ?? false;
                         });
                       },
                     ),
                     SizedBox(width: 8),
                     if (breakItem.setCustomTimes) ...[
                       TextButton(
                         onPressed: () => _selectTime(context, breakItem.startTime, (newTime) {
                           setState(() {
                             breakItem.startTime = newTime;
                             breakItem.endTime = newTime.add(breakItem.duration);
                           });
                         }),
                         child: Text('Start: ${formatTime(breakItem.startTime)}', style: TextStyle(color: Colors.purple)),
                       ),
                       SizedBox(width: 8),
                       TextButton(
                         onPressed: () => _selectTime(context, breakItem.endTime, (newTime) {
                           setState(() {
                             breakItem.endTime = newTime;
                             breakItem.duration = breakItem.endTime.difference(breakItem.startTime);
                           });
                         }),
                         child: Text('End: ${formatTime(breakItem.endTime)}', style: TextStyle(color: Colors.purple)),
                       ),
                     ] else ...[
                       Text('Set break start and end time', style: TextStyle(color: Colors.grey)),
                      ],

                     IconButton(
                       icon: Icon(Icons.delete, color: Colors.red),
                       onPressed: () => widget.onDeleteBreak(index),
                     ),
                   ],
                 ),
               );
             }).toList(),
             TextButton(
               onPressed: widget.onAddBreak,
               child: Text('Add Break', style: TextStyle(color: Colors.purple)),
             ),
             TextField(
               controller: commentController,
               decoration: InputDecoration(
                 labelText: 'Comment',
                 border: OutlineInputBorder(),
               ),
               maxLines: 2,
             ),
             SizedBox(height: 16),
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 TextButton(
                   onPressed: () {
                     Navigator.pop(context);

                   },
                   child: Text('Cancel', style: TextStyle(color: Colors.grey)),
                 ),
                 ElevatedButton(
                   onPressed: () {
                     Navigator.pop(context);
                   },
                   style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                   child: Text('End Shift'),
                 ),
               ],
             ),
           ],
         ),
       ),
     ),
   );
  }
}



