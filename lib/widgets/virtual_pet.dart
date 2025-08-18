import 'package:flutter/material.dart';
import 'dart:math' as math;

class VirtualPet extends StatefulWidget {
  final String dominantEmotion;
  final int totalEmotions;
  
  const VirtualPet({
    super.key,
    required this.dominantEmotion,
    required this.totalEmotions,
  });

  @override
  State<VirtualPet> createState() => _VirtualPetState();
}

class _VirtualPetState extends State<VirtualPet>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _blinkController;
  late AnimationController _breathingController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _blinkAnimation;
  late Animation<double> _breathingAnimation;

  @override
  void initState() {
    super.initState();
    
    // Controlador para el rebote
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Controlador para el parpadeo
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    // Controlador para la respiración
    _breathingController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));

    _blinkAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _blinkController,
      curve: Curves.easeInOut,
    ));

    _breathingAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _breathingController,
      curve: Curves.easeInOut,
    ));

    _startAnimations();
  }

  void _startAnimations() {
    // Iniciar respiración continua
    _breathingController.repeat(reverse: true);
    
    // Iniciar parpadeo ocasional
    _startBlinking();
    
    // Iniciar rebote según la emoción
    _startBounce();
  }

  void _startBlinking() {
    Future.delayed(Duration(seconds: 2 + math.Random().nextInt(4)), () {
      if (mounted) {
        _blinkController.forward().then((_) {
          _blinkController.reverse().then((_) {
            _startBlinking();
          });
        });
      }
    });
  }

  void _startBounce() {
    // Rebote más frecuente para emociones más activas
    int delaySeconds;
    switch (widget.dominantEmotion.toLowerCase()) {
      case 'feliz':
        delaySeconds = 3;
        break;
      case 'enojado':
        delaySeconds = 2;
        break;
      case 'ansioso':
        delaySeconds = 1;
        break;
      case 'triste':
        delaySeconds = 8;
        break;
      case 'calmado':
        delaySeconds = 6;
        break;
      default:
        delaySeconds = 5;
    }

    Future.delayed(Duration(seconds: delaySeconds), () {
      if (mounted) {
        _bounceController.forward().then((_) {
          _bounceController.reset();
          _startBounce();
        });
      }
    });
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _blinkController.dispose();
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_bounceAnimation, _blinkAnimation, _breathingAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _breathingAnimation.value,
          child: Transform.translate(
            offset: Offset(0, -10 * _bounceAnimation.value),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: _getPetColor(),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _getPetColor().withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Cuerpo de la mascota
                  _buildPetBody(),
                  
                  // Ojos
                  Positioned(
                    top: 35,
                    left: 30,
                    child: _buildEye(25),
                  ),
                  Positioned(
                    top: 35,
                    right: 30,
                    child: _buildEye(25),
                  ),
                  
                  // Boca
                  Positioned(
                    bottom: 30,
                    child: _buildMouth(),
                  ),
                  
                  // Detalles adicionales según la emoción
                  ..._buildEmotionDetails(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPetBody() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: _getPetColor(),
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            _getPetColor(),
            _getPetColor().withOpacity(0.7),
          ],
        ),
      ),
    );
  }

  Widget _buildEye(double size) {
    return Container(
      width: size,
      height: size * _blinkAnimation.value,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.black26,
          width: 2,
        ),
      ),
      child: Center(
        child: Container(
          width: size * 0.4,
          height: size * 0.4,
          decoration: const BoxDecoration(
            color: Colors.black87,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildMouth() {
    switch (widget.dominantEmotion.toLowerCase()) {
      case 'feliz':
        return Container(
          width: 40,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
        );
      case 'triste':
        return Container(
          width: 40,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
        );
      case 'enojado':
        return Container(
          width: 35,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      case 'ansioso':
        return Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.black87,
            shape: BoxShape.circle,
          ),
        );
      case 'calmado':
        return Container(
          width: 25,
          height: 3,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      default:
        return Container(
          width: 30,
          height: 3,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(2),
          ),
        );
    }
  }

  List<Widget> _buildEmotionDetails() {
    List<Widget> details = [];
    
    switch (widget.dominantEmotion.toLowerCase()) {
      case 'feliz':
        // Orejas felices
        details.addAll([
          Positioned(
            top: 10,
            left: 20,
            child: Container(
              width: 15,
              height: 20,
              decoration: BoxDecoration(
                color: _getPetColor(),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 20,
            child: Container(
              width: 15,
              height: 20,
              decoration: BoxDecoration(
                color: _getPetColor(),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
              ),
            ),
          ),
        ]);
        break;
      case 'triste':
        // Lágrimas
        details.addAll([
          Positioned(
            top: 60,
            left: 35,
            child: Container(
              width: 4,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.7),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Positioned(
            top: 60,
            right: 35,
            child: Container(
              width: 4,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.7),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ]);
        break;
      case 'enojado':
        // Cejas enojadas
        details.addAll([
          Positioned(
            top: 25,
            left: 25,
            child: Container(
              width: 20,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Positioned(
            top: 25,
            right: 25,
            child: Container(
              width: 20,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ]);
        break;
      case 'ansioso':
        // Sudor
        details.addAll([
          Positioned(
            top: 15,
            right: 15,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ]);
        break;
    }
    
    return details;
  }

  Color _getPetColor() {
    switch (widget.dominantEmotion.toLowerCase()) {
      case 'feliz':
        return Colors.orange;
      case 'triste':
        return Colors.blue;
      case 'enojado':
        return Colors.red;
      case 'ansioso':
        return Colors.purple;
      case 'calmado':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
