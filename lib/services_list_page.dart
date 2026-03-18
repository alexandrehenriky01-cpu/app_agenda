import 'package:flutter/material.dart';

class ServicesListPage extends StatelessWidget {
  const ServicesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Serviços')),
      body: const Center(
        child: Text('Lista de Serviços'),
      ),
    );
  }
}