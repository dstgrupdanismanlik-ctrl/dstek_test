import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../shared/widgets/app_drawer.dart';

class FeedbackManagementScreen extends StatelessWidget {
  const FeedbackManagementScreen({super.key});

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) {
      return '-';
    }

    final date = timestamp.toDate();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day.$month.$year $hour:$minute';
  }

  Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'hata':
        return Colors.red.shade700;
      case 'öneri':
      case 'oneri':
        return Colors.orange.shade700;
      default:
        return Colors.blue.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gelen Bildirimler'),
      ),
      drawer: const AppDrawer(),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('feedbacks')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Bildirimler yuklenirken hata olustu.'),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text('Henüz gelen bildirim bulunmuyor.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final category = (data['category'] ?? 'Soru').toString();
              final title = (data['title'] ?? '').toString();
              final description = (data['description'] ?? '').toString();
              final imageUrl = (data['imageUrl'] ?? '').toString();
              final createdAt = data['createdAt'] as Timestamp?;
              final status = (data['status'] ?? 'open').toString();
              final isResolved = status.toLowerCase() == 'resolved';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title.isEmpty ? '(Baslik yok)' : title,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        category,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _categoryColor(category),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(description.isEmpty ? '-' : description),
                        if (imageUrl.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            height: 250,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: NetworkImage(imageUrl),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          _formatDate(createdAt),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: TextButton.icon(
                    onPressed: () {
                      // Firestore status güncelleme kodu burada kalsın
                      doc.reference.update({
                        'status': isResolved ? 'open' : 'resolved',
                      });
                    },
                    icon: Icon(
                      isResolved ? Icons.done_all : Icons.check_circle_outline,
                      color: isResolved ? Colors.green : Colors.grey,
                    ),
                    label: Text(
                      isResolved ? 'Okundu' : 'Okundu İşaretle',
                      style: TextStyle(color: isResolved ? Colors.green : Colors.grey),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
