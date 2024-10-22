import 'package:flutter/foundation.dart';

class AttendanceModel extends ChangeNotifier {
  String? _timeIn;
  String? _timeOut;
  bool _isTimeInRecorded = false;
  bool _isTimeOutRecorded = false;

  String _timeInLocation = 'No location';
  String _timeOutLocation = 'No location';

  String? get timeIn => _timeIn;
  String? get timeOut => _timeOut;

  String? get timeInLocation => _timeInLocation;
  String? get timeOutLocation => _timeOutLocation;

  bool get isTimeInRecorded => _isTimeInRecorded;
  bool get isTimeOutRecorded => _isTimeOutRecorded;

  void updateTimeInLocation(String location) {
    _timeInLocation = location;
    notifyListeners();
  }

  void updateTimeOutLocation(String location) {
    _timeOutLocation = location;
    notifyListeners();
  }

  void updateTimeIn(String? timeIn) {
    _timeIn = timeIn;
    notifyListeners();
  }

  void updateTimeOut(String? timeOut) {
    _timeOut = timeOut;
    notifyListeners();
  }

  void setIsTimeInRecorded(bool isRecorded) {
    _isTimeInRecorded = isRecorded;
    notifyListeners();
  }

  void setIsTimeOutRecorded(bool isRecorded) {
    _isTimeOutRecorded = isRecorded;
    notifyListeners();
  }

  void reset() {
    _timeIn = null;
    _timeOut = null;
    _isTimeInRecorded = false;
    _isTimeOutRecorded = false;
    _timeInLocation = 'No location';
    _timeOutLocation = 'No location';
    notifyListeners();
  }
}
