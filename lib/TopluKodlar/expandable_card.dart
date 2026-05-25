import 'package:flutter/material.dart';

class ExpandableCard extends StatefulWidget {
  final String title;
  final String content;
  final IconData? icon; // İkon desteği eklendi (Opsiyonel)

  const ExpandableCard({
    super.key,
    required this.title,
    required this.content,
    this.icon, // İkon parametresi constructor'a eklendi
  });

  @override
  State<ExpandableCard> createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<ExpandableCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // Eğer ikon gönderilmişse göster, gönderilmemişse boşluk bırak
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: Colors.blueAccent),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey,
                  ),
                ],
              ),
              // Eğer kart açıksa altındaki metni göster
              if (_isExpanded) ...[
                const Divider(height: 24),
                Text(
                  widget.content,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}