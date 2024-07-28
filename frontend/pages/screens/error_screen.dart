import 'package:flutter/material.dart';

class ErrorScreen extends StatelessWidget {
  final String title;
  final dynamic errorData;

  const ErrorScreen({
    Key? key,
    required this.title,
    required this.errorData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String errorMessage = '';
    String stackTrace = '';

    if (errorData is Map<String, dynamic>) {
      if (errorData.containsKey('detail') && errorData['detail'] is List) {
        // Handle the case where detail is a list of errors
        var errors = errorData['detail'] as List;
        errorMessage = errors.map((error) {
          if (error is Map<String, dynamic>) {
            return error['msg'] ?? 'Unknown error';
          }
          return error.toString();
        }).join('\n');
      } else {
        errorMessage = errorData['detail'] ?? 'An unknown error occurred';
      }

      if (errorData['stack_trace'] is String) {
        stackTrace = _processStackTrace(errorData['stack_trace']);
      }
    } else if (errorData is String) {
      errorMessage = errorData;
    } else {
      errorMessage = 'An unknown error occurred';
    }

    return Scaffold(
      backgroundColor: Colors.green,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        errorMessage,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (stackTrace.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text(
                          stackTrace,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                            fontFamily: 'monospace',
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ],
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: const Text(
                            'Ok',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _processStackTrace(String fullStackTrace) {
    final lines = fullStackTrace.split('\n');
    final packageName = 'recycle_m_mobile';
    final packageIndex = lines.indexWhere((line) => line.contains(packageName));

    if (packageIndex != -1) {
      final relevantLines = lines.sublist(packageIndex, packageIndex + 4);
      return relevantLines.join('\n');
    } else {
      return lines.take(3).join('\n');
    }
  }
}