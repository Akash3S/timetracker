// import 'dart:async';
//
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
//
// class EndShift extends StatefulWidget{
//
//
//   @override
//   State<EndShift> createState() => _EndShiftState();
// }
//
// class _EndShiftState extends State<EndShift> {
//
//   void endShift() async {
//     setState(() {
//       shiftEndTime = DateTime.now();
//       // Calculate total paid time by subtracting breaks from shift duration
//       totalPaidTime = shiftEndTime!.difference(shiftStartTime!) -
//           breaks.fold(Duration.zero, (sum, b) => sum + b.duration);
//     });
//
//     // Show End Shift Dialog
//     await showDialog(
//       context: context,
//       builder: (context) => EndShift(
//         startTime: shiftStartTime!,
//         endTime: shiftEndTime!,
//         breaks: breaks,
//         totalPaidTime: totalPaidTime,
//         onAddBreak: addBreak,
//         onDeleteBreak: deleteBreak,
//
//
//       ),
//     );
//
//     setState(() {
//       isOnShift = false;
//       shiftStartTime = null;
//       shiftEndTime = null;
//       isOnBreak = false;
//       breaks.clear();
//       totalPaidTime = Duration.zero;
//     });
//   }
//
//
//   bool isOnShift = false;
//   bool isOnBreak = false;
//   DateTime? shiftStartTime;
//   DateTime? shiftEndTime;
//   DateTime? breakStartTime;
//   Timer? breakTimer;
//   Duration breakDuration = Duration.zero;
//   Duration totalPaidTime = Duration.zero;
//   String? selectedBreakType;
//   String location = "Admin";
//   // Static location for demonstration
//   List<Break> breaks = [];
//
//
//   TextEditingController commentController = TextEditingController();
//   String formatTime (DateTime time)=> DateFormat('hh:mm a').format(time);
//
//   Future<void> _selectTime(BuildContext context, DateTime initialTime, Function(DateTime) onTimeChanged) async {
//     final TimeOfDay? picked = await showTimePicker(
//       context: context,
//       initialTime: TimeOfDay.fromDateTime(initialTime),
//     );
//     if (picked != null) {
//       final DateTime newTime = DateTime(initialTime.year, initialTime.month, initialTime.day, picked.hour, picked.minute);
//       onTimeChanged(newTime);
//     }
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(
//                 'End Shift',
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
//               ),
//               SizedBox(height: 16),
//               Row(
//                 children: [
//                   Icon(Icons.access_time, color: Colors.purple),
//                   SizedBox(width: 8),
//                   Text(
//                     '${widget.totalPaidTime.inMinutes}m',
//                     style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.purple),
//                   ),
//                 ],
//               ),
//               Text('Total Paid Time', style: TextStyle(color: Colors.grey[700])),
//               SizedBox(height: 16),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text('Start time', style: TextStyle(fontWeight: FontWeight.bold)),
//                   Text('End time', style: TextStyle(fontWeight: FontWeight.bold)),
//                 ],
//               ),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(formatTime(widget.startTime)),
//                   Text(formatTime(widget.endTime)),
//                 ],
//               ),
//               SizedBox(height: 16),
//               ...widget.breaks.asMap().entries.map((entry) {
//                 int index = entry.key;
//                 Break breakItem = entry.value;
//                 return Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 8.0),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Expanded(
//                         child: DropdownButton<String>(
//                           value: breakItem.type,
//                           items: [
//                             DropdownMenuItem(value: 'Meal Break', child: Text('Meal Break')),
//                             DropdownMenuItem(value: 'Rest Break', child: Text('Rest Break')),
//                           ],
//                           onChanged: (value) {
//                             setState(() {
//                               breakItem.type = value!;
//                             });
//                           },
//                         ),
//                       ),
//                       SizedBox(width: 8),
//                       Expanded(
//                         child: TextField(
//                           controller: TextEditingController(text: breakItem.duration.inMinutes.toString()),
//                           keyboardType: TextInputType.number,
//                           decoration: InputDecoration(
//                             labelText: 'Duration (mins)',
//                           ),
//                           onSubmitted: (value) {
//                             setState(() {
//                               breakItem.duration = Duration(minutes: int.parse(value));
//                               breakItem.endTime = breakItem.startTime.add(breakItem.duration);
//                             });
//                           },
//                         ),
//                       ),
//                       SizedBox(width: 8),
//                       Checkbox(
//                         value: breakItem.setCustomTimes,
//                         onChanged: (value) {
//                           setState(() {
//                             breakItem.setCustomTimes = value ?? false;
//                           });
//                         },
//                       ),
//                       SizedBox(width: 8),
//                       if (breakItem.setCustomTimes) ...[
//                         TextButton(
//                           onPressed: () => _selectTime(context, breakItem.startTime, (newTime) {
//                             setState(() {
//                               breakItem.startTime = newTime;
//                               breakItem.endTime = newTime.add(breakItem.duration);
//                             });
//                           }),
//                           child: Text('Start: ${formatTime(breakItem.startTime)}', style: TextStyle(color: Colors.purple)),
//                         ),
//                         SizedBox(width: 8),
//                         TextButton(
//                           onPressed: () => _selectTime(context, breakItem.endTime, (newTime) {
//                             setState(() {
//                               breakItem.endTime = newTime;
//                               breakItem.duration = breakItem.endTime.difference(breakItem.startTime);
//                             });
//                           }),
//                           child: Text('End: ${formatTime(breakItem.endTime)}', style: TextStyle(color: Colors.purple)),
//                         ),
//                       ] else ...[
//                         Text('Set break start and end time', style: TextStyle(color: Colors.grey)),
//                       ],
//
//                       IconButton(
//                         icon: Icon(Icons.delete, color: Colors.red),
//                         onPressed: () => widget.onDeleteBreak(index),
//                       ),
//                     ],
//                   ),
//                 );
//               }).toList(),
//               TextButton(
//                 onPressed: widget.onAddBreak,
//                 child: Text('Add Break', style: TextStyle(color: Colors.purple)),
//               ),
//               TextField(
//                 controller: commentController,
//                 decoration: InputDecoration(
//                   labelText: 'Comment',
//                   border: OutlineInputBorder(),
//                 ),
//                 maxLines: 2,
//               ),
//               SizedBox(height: 16),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   TextButton(
//                     onPressed: () {
//                       Navigator.pop(context);
//
//                     },
//                     child: Text('Cancel', style: TextStyle(color: Colors.grey)),
//                   ),
//                   ElevatedButton(
//                     onPressed: () {
//                       Navigator.pop(context);
//                     },
//                     style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
//                     child: Text('End Shift'),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
//
// class Break {
//   String type;
//   Duration duration;
//   DateTime startTime;
//   DateTime endTime;
//   bool setCustomTimes;
//
//   Break({
//     required this.type,
//     required this.duration,
//     required this.startTime,
//     required this.endTime,
//     this.setCustomTimes = false,
//   });
// }
