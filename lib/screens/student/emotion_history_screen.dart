import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/app_user.dart';
import '../../models/emotion_record.dart';
import '../../services/emotion_service.dart';
import '../../widgets/gradient_background.dart';

class EmotionHistoryScreen extends StatefulWidget {
  final AppUser user;
  final EmotionService emotionService;
  
  const EmotionHistoryScreen({
    super.key,
    required this.user,
    required this.emotionService,
  });

  @override
  State<EmotionHistoryScreen> createState() => _EmotionHistoryScreenState();
}

class _EmotionHistoryScreenState extends State<EmotionHistoryScreen> {
  String _selectedFilter = 'todos';
  final List<String> _filters = ['todos', 'feliz', 'triste', 'enojado', 'ansioso', 'calmado'];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Emociones'),
        backgroundColor: const Color(0xFF00BCD4),
        foregroundColor: Colors.white,
      ),
      body: GradientBackground(
        child: Column(
          children: [
            // Filtros
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filtrar por emoción:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filters.map((filter) {
                        final selected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ElevatedButton(
                            onPressed: () => setState(() => _selectedFilter = filter),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: selected 
                                  ? const Color(0xFF00BCD4)
                                  : Colors.white.withValues(alpha: 0.3),
                              foregroundColor: selected ? Colors.white : Colors.black87,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Text(filter.toUpperCase()),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            
            // Gráfico de líneas temporal
            Container(
              height: 200,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: StreamBuilder<List<EmotionRecord>>(
                    stream: widget.emotionService.watchStudentEmotions(widget.user.uid),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      final emotions = snapshot.data!;
                      if (emotions.isEmpty) {
                        return const Center(
                          child: Text('No hay datos para mostrar'),
                        );
                      }
                      
                      return _buildLineChart(emotions);
                    },
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Lista de emociones
            Expanded(
              child: StreamBuilder<List<EmotionRecord>>(
                stream: widget.emotionService.watchStudentEmotions(widget.user.uid),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  final allEmotions = snapshot.data!;
                  final filteredEmotions = _selectedFilter == 'todos'
                      ? allEmotions
                      : allEmotions.where((e) => 
                          e.emotion.toLowerCase() == _selectedFilter.toLowerCase()
                        ).toList();
                  
                  if (filteredEmotions.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sentiment_neutral, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No hay registros para el filtro seleccionado',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredEmotions.length,
                    itemBuilder: (context, index) {
                      final emotion = filteredEmotions[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _colorForEmotion(emotion.emotion),
                            child: Icon(
                              _getEmotionIcon(emotion.emotion),
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            emotion.emotion,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('dd/MM/yyyy HH:mm').format(emotion.createdAt),
                                style: const TextStyle(fontSize: 12),
                              ),
                              if (emotion.note != null && emotion.note!.isNotEmpty)
                                Text(
                                  'Nota: ${emotion.note}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!emotion.isSynced)
                                const Icon(
                                  Icons.cloud_off,
                                  color: Colors.orange,
                                  size: 16,
                                ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteEmotion(emotion),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(List<EmotionRecord> emotions) {
    // Agrupar emociones por día
    final Map<String, Map<String, int>> dailyEmotions = {};
    
    for (final emotion in emotions) {
      final dayKey = DateFormat('dd/MM').format(emotion.createdAt);
      if (!dailyEmotions.containsKey(dayKey)) {
        dailyEmotions[dayKey] = {};
      }
      dailyEmotions[dayKey]![emotion.emotion] = 
          (dailyEmotions[dayKey]![emotion.emotion] ?? 0) + 1;
    }
    
    final days = dailyEmotions.keys.toList()..sort();
    final emotionTypes = ['Feliz', 'Triste', 'Enojado', 'Ansioso', 'Calmado'];
    
    final lineBarsData = emotionTypes.map((emotionType) {
      final spots = days.asMap().entries.map((entry) {
        final dayIndex = entry.key.toDouble();
        final dayKey = entry.value;
        final count = dailyEmotions[dayKey]?[emotionType] ?? 0;
        return FlSpot(dayIndex, count.toDouble());
      }).toList();
      
      return LineChartBarData(
        spots: spots,
        isCurved: true,
        color: _colorForEmotion(emotionType),
        barWidth: 3,
        dotData: FlDotData(show: true),
        belowBarData: BarAreaData(
          show: true,
          color: _colorForEmotion(emotionType).withValues(alpha: 0.1),
        ),
      );
    }).toList();
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 1,
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < days.length) {
                  return Text(
                    days[value.toInt()],
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: lineBarsData,
        minX: 0,
        maxX: (days.length - 1).toDouble(),
        minY: 0,
        maxY: 5,
      ),
    );
  }

  Future<void> _deleteEmotion(EmotionRecord emotion) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar emoción'),
        content: Text('¿Estás seguro de que quieres eliminar el registro de "${emotion.emotion}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && emotion.id != null) {
      await widget.emotionService.deleteLocalEmotion(emotion.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Emoción eliminada'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _colorForEmotion(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'feliz':
        return Colors.orangeAccent;
      case 'triste':
        return Colors.blueAccent;
      case 'enojado':
        return Colors.redAccent;
      case 'ansioso':
        return Colors.purpleAccent;
      case 'calmado':
        return Colors.greenAccent;
      default:
        return Colors.teal;
    }
  }

  IconData _getEmotionIcon(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'feliz':
        return Icons.sentiment_very_satisfied;
      case 'triste':
        return Icons.sentiment_very_dissatisfied;
      case 'enojado':
        return Icons.sentiment_dissatisfied;
      case 'ansioso':
        return Icons.sentiment_neutral;
      case 'calmado':
        return Icons.sentiment_satisfied;
      default:
        return Icons.sentiment_neutral;
    }
  }
}
