import 'package:flutter/material.dart';

class MessageWidget extends StatelessWidget {
  final String text;
  final bool isFromUser;

  const MessageWidget({
    required this.text,
    required this.isFromUser,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isFromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: isFromUser ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isFromUser ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}
