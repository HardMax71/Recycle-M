import 'package:flutter/material.dart';

class CongratulationsScreen extends StatelessWidget {
  final String title;
  final String message;
  final String primaryActionText;
  final String? secondaryActionText;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onSecondaryAction;

  const CongratulationsScreen({super.key, 
    required this.title,
    required this.message,
    this.primaryActionText = 'Continue',
    this.secondaryActionText,
    this.onPrimaryAction,
    this.onSecondaryAction,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF4CAF50),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          if (onPrimaryAction != null) {
                            onPrimaryAction!();
                          } else {
                            Navigator.of(context).pop();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: Text(primaryActionText),
                      ),
                      if (secondaryActionText != null) ...[
                        const SizedBox(height: 10),
                        TextButton(
                          child: Text(
                            secondaryActionText!,
                            style: const TextStyle(color: Color(0xFF4CAF50)),
                          ),
                          onPressed: () {
                            if (onSecondaryAction != null) {
                              onSecondaryAction!();
                            } else {
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
