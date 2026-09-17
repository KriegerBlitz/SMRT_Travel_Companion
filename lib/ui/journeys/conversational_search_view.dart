import 'package:flutter/material.dart';
import '../../ai/trip_input_parser.dart';

class ConversationalSearchView extends StatefulWidget {
  final ValueChanged<ParsedTripIntent> onTripPlanned;

  const ConversationalSearchView({
    super.key,
    required this.onTripPlanned,
  });

  @override
  State<ConversationalSearchView> createState() =>
      _ConversationalSearchViewState();
}

class _ConversationalSearchViewState extends State<ConversationalSearchView> {
  final TextEditingController _controller = TextEditingController();
  ParsedTripIntent? _currentParsed;

  @override
  void initState() {
    super.initState();
    _controller.text = 'get me from Bugis to Jurong avoiding crowds';
    _performParse();
  }

  void _performParse() {
    final parsed = TripInputParser.parse(_controller.text);
    setState(() {
      _currentParsed = parsed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI Header
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.indigo.shade600),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.cyanAccent, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Conversational Trip Input Parser',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Natural language queries are parsed into structured {origin, destination, preference} parameters to feed OneMap public transport routing.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                onChanged: (_) => _performParse(),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'e.g. from Bedok to SGH with wheelchair access',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.black38,
                  prefixIcon: const Icon(Icons.chat_bubble_outline, color: Colors.cyanAccent),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward, color: Colors.cyanAccent),
                    onPressed: () {
                      _performParse();
                      if (_currentParsed != null) {
                        widget.onTripPlanned(_currentParsed!);
                      }
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.blueGrey.shade700),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Sample Benchmark Test Cases (Tap to Test):',
                style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: TripInputParser.benchmarkCases.take(5).map((c) {
                  final text = c['input'] as String;
                  return ActionChip(
                    label: Text(text, style: const TextStyle(fontSize: 10)),
                    backgroundColor: Colors.blueGrey.shade800,
                    labelStyle: const TextStyle(color: Colors.white),
                    onPressed: () {
                      _controller.text = text;
                      _performParse();
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Structured JSON Parser Output Card
        if (_currentParsed != null)
          Card(
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Structured Parser Output',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade900.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.greenAccent),
                        ),
                        child: Text(
                          'Confidence: ${(_currentParsed!.confidence * 100).toInt()}%',
                          style: const TextStyle(color: Colors.greenAccent, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.blueGrey, height: 20),
                  _buildDetailRow('Origin Station', _currentParsed!.fromStation ?? 'Not detected', Colors.greenAccent),
                  _buildDetailRow('Destination Station', _currentParsed!.toStation ?? 'Not detected', Colors.cyanAccent),
                  _buildDetailRow('Routing Preference', _currentParsed!.preference.toUpperCase(), Colors.amberAccent),
                  _buildDetailRow('Accessibility Constraints', _currentParsed!.isAccessibilityRequested ? 'YES (Step-free / Lifts)' : 'Standard', Colors.purpleAccent),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => widget.onTripPlanned(_currentParsed!),
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Render Route on OpenStreetMap'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF009645),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
