import 'package:flutter/material.dart';

class MyCommunitiesPage extends StatelessWidget {
  const MyCommunitiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Communities'),
      ),
      body: const Center(
        child: Text('My Communities'),
      ),
    );
  }
}
