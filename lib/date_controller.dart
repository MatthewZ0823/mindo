import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'utils.dart';

class DateController extends StatelessWidget {
  final DateTime _date;
  final void Function() _onLeftArrowPressed, _onRightArrowPressed;
  static final _formatter = DateFormat.yMd();

  const DateController({
    super.key,
    required date,
    required onLeftArrowPressed,
    required onRightArrowPressed,
  })  : _date = date,
        _onLeftArrowPressed = onLeftArrowPressed,
        _onRightArrowPressed = onRightArrowPressed;

  String _getFormattedDateString() {
    switch (_date.difference(DateTime.now().roundDownDate()).inDays) {
      case -1:
        return "Yesterday";
      case 0:
        return "Today";
      default:
        return _formatter.format(_date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: _onLeftArrowPressed,
          icon: const Icon(Icons.arrow_left),
        ),
        const Icon(Icons.calendar_today),
        const SizedBox(width: 10),
        Text(_getFormattedDateString()),
        IconButton(
          onPressed: _onRightArrowPressed,
          icon: const Icon(Icons.arrow_right),
        ),
      ],
    );
  }
}
