import 'package:flutter/material.dart';
import 'virtual_pet.dart';

class VirtualPetDemo extends StatefulWidget {
  const VirtualPetDemo({super.key});

  @override
  State<VirtualPetDemo> createState() => _VirtualPetDemoState();
}

class _VirtualPetDemoState extends State<VirtualPetDemo> {
  final List<String> emotions = ['feliz', 'triste', 'enojado', 'ansioso', 'calmado'];
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demo - Mascota Virtual'),
        backgroundColor: const Color(0xFF00BCD4),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Emoción: ${emotions[currentIndex].toUpperCase()}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            VirtualPet(
              dominantEmotion: emotions[currentIndex],
              totalEmotions: 5,
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      currentIndex = (currentIndex - 1 + emotions.length) % emotions.length;
                    });
                  },
                  child: const Text('Anterior'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      currentIndex = (currentIndex + 1) % emotions.length;
                    });
                  },
                  child: const Text('Siguiente'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              _getEmotionDescription(emotions[currentIndex]),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getEmotionDescription(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'feliz':
        return 'La mascota está feliz y energética.\nSe mueve más rápido y tiene orejas puntiagudas.';
      case 'triste':
        return 'La mascota está triste y apagada.\nSe mueve lentamente y tiene lágrimas.';
      case 'enojado':
        return 'La mascota está enojada y tensa.\nTiene cejas fruncidas y se mueve de forma agitada.';
      case 'ansioso':
        return 'La mascota está ansiosa y nerviosa.\nTiene sudor y se mueve de forma irregular.';
      case 'calmado':
        return 'La mascota está tranquila y serena.\nSe mueve suavemente y respira de forma relajada.';
      default:
        return 'Estado emocional neutral.';
    }
  }
}
