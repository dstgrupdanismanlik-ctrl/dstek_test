import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';

class FeedbackDialog extends StatefulWidget {
  const FeedbackDialog({super.key});

  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _category = 'Hata';
  bool _isLoading = false;

  Uint8List? _selectedImageBytes;
  String? _selectedImageExtension;

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageExtension = image.name.split('.').last;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Görsel seçilemedi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty || _descController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      String? imageUrl;
      if (_selectedImageBytes != null) {
        final ref = FirebaseStorage.instance.ref('feedback_images/${DateTime.now().millisecondsSinceEpoch}.$_selectedImageExtension');
        await ref.putData(_selectedImageBytes!);
        imageUrl = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('feedbacks').add({
        'category': _category,
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'userId': FirebaseAuth.instance.currentUser?.uid ?? 'anonymous',
        'status': 'open',
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Geri bildiriminiz için teşekkürler!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gönderim Hatası: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Hata Radarı (Feedback)'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Kategori', border: OutlineInputBorder()),
              items: ['Hata', 'Öneri', 'Soru'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Başlık', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Detaylı Açıklama', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _pickImage,
              icon: const Icon(Icons.image),
              label: const Text('Ekran Görüntüsü Ekle'),
            ),
            if (_selectedImageBytes != null) ...[
              const SizedBox(height: 12),
              // ÇÖZÜM: Sonsuz genişlik (double.infinity) kaldırıldı. Sabit ve güvenli bir kutu oluşturuldu.
              Center(
                child: SizedBox(
                  width: 250,
                  height: 140,
                  child: Stack(
                    children: [
                      Container(
                        width: 250,
                        height: 140,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300), 
                          borderRadius: BorderRadius.circular(8)
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            _selectedImageBytes!, 
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 14,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.cancel, color: Colors.red, size: 20),
                            onPressed: () => setState(() {
                              _selectedImageBytes = null;
                              _selectedImageExtension = null;
                            }),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              )
            ]
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context), 
          child: const Text('Vazgeç')
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
          child: _isLoading 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
              : const Text('Gönder')
        ),
      ],
    );
  }
}