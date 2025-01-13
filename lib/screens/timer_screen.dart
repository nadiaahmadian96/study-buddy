import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

class TimerScreen extends StatefulWidget {
  @override
  _TimerScreenState createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  int workTime = 25 * 60; // Default work time in seconds
  int breakTime = 5 * 60; // Default break time in seconds

  int _remainingTime = 25 * 60;
  bool _isRunning = false;
  bool _isBreakTime = false;
  int _completedSessions = 0;

  Timer? _timer;
  final AudioPlayer _audioPlayer = AudioPlayer();

  String _workSound = 'sounds/work_notification.wav';
  String _breakSound = 'sounds/break_notification.wav';
  Color _workColor = Colors.blue;
  Color _breakColor = Colors.green;

  List<Map<String, dynamic>> _sessionHistory = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      workTime = prefs.getInt('workTime') ?? 25 * 60;
      breakTime = prefs.getInt('breakTime') ?? 5 * 60;
      _remainingTime = prefs.getInt('remainingTime') ?? workTime;
      _isBreakTime = prefs.getBool('isBreakTime') ?? false;
      _completedSessions = prefs.getInt('completedSessions') ?? 0;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('workTime', workTime);
    await prefs.setInt('breakTime', breakTime);
    await prefs.setInt('remainingTime', _remainingTime);
    await prefs.setBool('isBreakTime', _isBreakTime);
    await prefs.setInt('completedSessions', _completedSessions);
  }

  void _startTimer() {
    if (_timer != null && _timer!.isActive) return;

    setState(() {
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime > 0) {
          _remainingTime--;
        } else {
          _timer?.cancel();
          _isRunning = false;
          _isBreakTime = !_isBreakTime;
          _remainingTime = _isBreakTime ? breakTime : workTime;
          _completedSessions++;
          _saveSessionHistory();
          _playSound();
          _showSnackBar(_isBreakTime ? 'Time for a Break!' : 'Back to Work!');
        }
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
    _saveSettings();
  }

  void _resetTimer() {
    _stopTimer();
    setState(() {
      _remainingTime = _isBreakTime ? breakTime : workTime;
    });
  }

  void _playSound() {
    _audioPlayer.play(AssetSource(_isBreakTime ? _breakSound : _workSound));
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _saveSessionHistory() {
    final sessionType = _isBreakTime ? 'Break' : 'Work';
    _sessionHistory.add({
      'type': sessionType,
      'duration': _isBreakTime ? breakTime : workTime,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void _showHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Session History'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            itemCount: _sessionHistory.length,
            itemBuilder: (context, index) {
              final session = _sessionHistory[index];
              return ListTile(
                title: Text('${session['type']} Session'),
                subtitle: Text(
                    'Duration: ${session['duration'] ~/ 60} min, Time: ${DateTime.parse(session['timestamp']).toLocal()}'),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    final TextEditingController workController =
        TextEditingController(text: (workTime ~/ 60).toString());
    final TextEditingController breakController =
        TextEditingController(text: (breakTime ~/ 60).toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Timer Durations'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: workController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Work Time (minutes)'),
            ),
            TextField(
              controller: breakController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Break Time (minutes)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                workTime = int.parse(workController.text) * 60;
                breakTime = int.parse(breakController.text) * 60;
                _remainingTime = _isBreakTime ? breakTime : workTime;
                _saveSettings();
              });
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pomodoro Timer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showHistoryDialog,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _isBreakTime ? 'Break Time' : 'Work Time',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: CircularProgressIndicator(
                  value: _isBreakTime
                      ? _remainingTime / breakTime
                      : _remainingTime / workTime,
                  strokeWidth: 8,
                  valueColor: AlwaysStoppedAnimation(
                      _isBreakTime ? _breakColor : _workColor),
                ),
              ),
              Text(
                '${_remainingTime ~/ 60}:${(_remainingTime % 60).toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _isRunning ? _stopTimer : _startTimer,
                child: Text(_isRunning ? 'Pause' : 'Start'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _resetTimer,
                child: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Completed Sessions: $_completedSessions',
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}