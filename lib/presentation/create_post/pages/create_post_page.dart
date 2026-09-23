import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../domain/repositories/feed_repository.dart';
import '../../widgets/app_avatar.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _captionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  XFile? _selectedImage;
  String _visibility = 'Public';
  String _status = 'Live';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<void> _submitPost() async {
    if (_captionController.text.trim().isEmpty && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add some content or an image')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Create post via repository
      await context.read<PostsRepository>().createPost(
        type: _status.toLowerCase(), // draft or live
        caption: _captionController.text.trim(),
        mediaRef: _selectedImage?.path, // in a real app, upload first and pass URL
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post successfully created!')),
      );
      Navigator.of(context).pop(true); // Return true to signal refresh needed
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create post: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Create Post', style: AppTextStyles.headlineSmall),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.close, color: cs.onSurfaceVariant),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          _isSubmitting
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: TextButton(
                    onPressed: _submitPost,
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                    child: const Text('Publish'),
                  ),
                ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Author Row
              Row(
                children: [
                  const AppAvatar(name: 'User', size: 42),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Alex Trader', style: AppTextStyles.titleMedium),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildDropdown(
                            value: _visibility,
                            items: ['Public', 'Followers', 'Private'],
                            icon: Icons.public_rounded,
                            onChanged: (val) =>
                                setState(() => _visibility = val!),
                          ),
                          const SizedBox(width: 8),
                          _buildDropdown(
                            value: _status,
                            items: ['Live', 'Draft'],
                            icon: Icons.edit_note_rounded,
                            onChanged: (val) => setState(() => _status = val!),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Caption Text Field
              TextField(
                controller: _captionController,
                maxLines: null,
                minLines: 4,
                style: AppTextStyles.bodyLarge,
                decoration: const InputDecoration(
                  hintText: 'Share your market insights or thought with traders...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: AppColors.textTertiary),
                ),
              ),
              const SizedBox(height: 16),

              // Image Preview
              if (_selectedImage != null)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_selectedImage!.path),
                        width: double.infinity,
                        height: 250,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedImage = null),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              
              const SizedBox(height: 32),
              
              // Action Buttons
              Row(
                children: [
                  IconButton(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image_outlined, color: AppColors.primary),
                    tooltip: 'Attach Image',
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.insert_chart_outlined, color: AppColors.primary),
                    tooltip: 'Attach Chart',
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.poll_outlined, color: AppColors.primary),
                    tooltip: 'Create Poll',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required IconData icon,
    required void Function(String?) onChanged,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: Icon(Icons.arrow_drop_down, color: cs.onSurfaceVariant, size: 16),
          isDense: true,
          onChanged: onChanged,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 12, color: cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(item, style: AppTextStyles.labelSmall),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
