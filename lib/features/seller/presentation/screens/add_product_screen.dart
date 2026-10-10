import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/cloud_image_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../buyer/domain/models/product_model.dart';
import '../providers/seller_providers.dart';

/// Screen allowing verified merchants to publish new grocery/produce items
/// with multiple photo uploads, video URL link, Bengali subtitle, origin,
/// and category-specific options (custom fish cuts for fish/meat, package sizes for veg/fruit).
class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bengaliTitleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _originController = TextEditingController();
  final _videoUrlController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedImages = [];
  final List<Uint8List> _imageBytesList = [];

  String _selectedCategory = 'Vegetables';
  final List<String> _categories = [
    'Vegetables',
    'Fruits',
    'Fish & Meat',
    'Spices & Oil',
    'Dairy & Eggs',
    'Rice & Grains',
    'Bakery & Snacks',
    'Other Groceries',
  ];

  bool _isSubmitting = false;
  String _uploadStatus = '';

  @override
  void dispose() {
    _titleController.dispose();
    _bengaliTitleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _stockController.dispose();
    _originController.dispose();
    _videoUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (_selectedImages.length >= 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maximum 4 photos allowed per product.'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }

      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImages.add(pickedFile);
          _imageBytesList.add(bytes);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to select photo: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _removeImageAt(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      _imageBytesList.removeAt(index);
    });
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add Product Photo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                title: const Text('Take a Photo with Camera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handlePublishProduct() async {
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one product photo before publishing.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _uploadStatus = 'Uploading photos to cloud storage...';
    });

    try {
      // 1. Upload photos to ImgBB / Cloudinary
      final List<String> uploadedUrls = [];
      for (int i = 0; i < _selectedImages.length; i++) {
        setState(() {
          _uploadStatus = 'Uploading photo ${i + 1} of ${_selectedImages.length}...';
        });
        final url = await CloudImageService.uploadImage(_selectedImages[i]);
        uploadedUrls.add(url);
      }

      if (!mounted) return;
      setState(() {
        _uploadStatus = 'Publishing item to BazaarShodai marketplace...';
      });

      // 2. Fetch logged-in seller information
      final authUser = ref.read(firebaseAuthProvider).currentUser;
      final userProfile = ref.read(currentUserProfileStreamProvider).value;

      final sellerId = authUser?.uid ?? '';
      final sellerName = userProfile?.shopDetails?.shopName.isNotEmpty == true
          ? userProfile!.shopDetails!.shopName
          : (userProfile?.name.isNotEmpty == true ? userProfile!.name : 'Local Vendor');

      final price = double.parse(_priceController.text.trim());
      double? originalPrice;
      if (_originalPriceController.text.trim().isNotEmpty) {
        originalPrice = double.tryParse(_originalPriceController.text.trim());
      }
      final stock = int.parse(_stockController.text.trim());

      final bengaliTitle = _bengaliTitleController.text.trim().isNotEmpty
          ? _bengaliTitleController.text.trim()
          : null;
      final origin = _originController.text.trim().isNotEmpty
          ? _originController.text.trim()
          : null;
      final videoUrl = _videoUrlController.text.trim().isNotEmpty
          ? _videoUrlController.text.trim()
          : null;

      // 3. Create Product Domain Entity
      final product = ProductModel(
        id: '', // Will be assigned documentId in repository
        title: _titleController.text.trim(),
        bengaliTitle: bengaliTitle,
        description: _descController.text.trim(),
        price: price,
        originalPrice: originalPrice,
        stock: stock,
        category: _selectedCategory,
        imageUrls: uploadedUrls,
        videoUrl: videoUrl,
        origin: origin,
        sellerId: sellerId,
        sellerName: sellerName,
        rating: 5.0,
        reviewCount: 0,
        isFeatured: false,
        createdAt: DateTime.now(),
      );

      // 4. Save to Firestore
      final sellerRepo = ref.read(sellerRepositoryProvider);
      await sellerRepo.addProduct(product);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product published successfully! It is now live in the marketplace.'),
          backgroundColor: AppColors.primaryDark,
          duration: Duration(seconds: 3),
        ),
      );

      Navigator.of(context).pop();
    } on CloudImageException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image Upload Error: ${e.message}'),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to publish product: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _uploadStatus = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFishOrMeat = _selectedCategory == 'Fish & Meat';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Product'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Multiple Images Picker Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Product Photos (Up to 4)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${_selectedImages.length}/4 Photos',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (_selectedImages.isEmpty)
                  GestureDetector(
                    onTap: _isSubmitting ? null : _showImageSourceSheet,
                    child: Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add_a_photo_outlined,
                              size: 26,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Add Product Photos',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Tap to choose from Gallery or Camera',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length + (_selectedImages.length < 4 ? 1 : 0),
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        if (index == _selectedImages.length) {
                          return GestureDetector(
                            onTap: _isSubmitting ? null : _showImageSourceSheet,
                            child: Container(
                              width: 100,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary),
                                  SizedBox(height: 4),
                                  Text('Add More', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          );
                        }

                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.memory(
                                _imageBytesList[index],
                                width: 100,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: InkWell(
                                onTap: _isSubmitting ? null : () => _removeImageAt(index),
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 18),

                // 2. Video Link Field
                TextFormField(
                  controller: _videoUrlController,
                  enabled: !_isSubmitting,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Video URL (Optional)',
                    hintText: 'e.g. https://... or YouTube video link',
                    prefixIcon: Icon(Icons.videocam_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Product Title (English)
                TextFormField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.words,
                  enabled: !_isSubmitting,
                  decoration: const InputDecoration(
                    labelText: 'Product Title (English)',
                    hintText: 'e.g. Fresh Padma River Hilsa',
                    prefixIcon: Icon(Icons.shopping_bag_outlined),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter a product title';
                    }
                    if (val.trim().length < 3) {
                      return 'Title must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 4. Bengali Title (Optional)
                TextFormField(
                  controller: _bengaliTitleController,
                  enabled: !_isSubmitting,
                  decoration: const InputDecoration(
                    labelText: 'বাংলা শিরোনাম / Bengali Subtitle (Optional)',
                    hintText: 'e.g. তাজা পদ্মা নদীর রূপালী ইলিশ',
                    prefixIcon: Icon(Icons.translate_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                // 5. Origin / Farm Harvest Region
                TextFormField(
                  controller: _originController,
                  enabled: !_isSubmitting,
                  decoration: const InputDecoration(
                    labelText: 'Harvest Origin / Region (Optional)',
                    hintText: 'e.g. Chandpur Mohona Confluence, Padma River',
                    prefixIcon: Icon(Icons.place_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                // 6. Category Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: _categories.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(cat),
                    );
                  }).toList(),
                  onChanged: _isSubmitting
                      ? null
                      : (val) {
                          if (val != null) {
                            setState(() => _selectedCategory = val);
                          }
                        },
                ),
                const SizedBox(height: 16),

                // Category-Smart Info Notice
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isFishOrMeat ? const Color(0xFFEFF6FF) : const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isFishOrMeat ? const Color(0xFFBFDBFE) : const Color(0xFFA7F3D0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isFishOrMeat ? Icons.set_meal_outlined : Icons.eco_outlined,
                        color: isFishOrMeat ? const Color(0xFF1E40AF) : const Color(0xFF065F46),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isFishOrMeat
                            ? 'Fish & Meat options: Customers will be able to select piece weights & custom cuts (Whole, Curry Cut, Head+Steak).'
                            : 'Produce options: Customers will see convenient package weight tiers (500g, 1kg, 2kg, 5kg).',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isFishOrMeat ? const Color(0xFF1E40AF) : const Color(0xFF065F46),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 7. Price & Original Price Row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        enabled: !_isSubmitting,
                        decoration: const InputDecoration(
                          labelText: 'Price (৳)',
                          hintText: 'e.g. 1450',
                          prefixIcon: Icon(Icons.payments_outlined),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Enter price';
                          }
                          final p = double.tryParse(val.trim());
                          if (p == null || p <= 0) {
                            return 'Enter valid price';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _originalPriceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        enabled: !_isSubmitting,
                        decoration: const InputDecoration(
                          labelText: 'Original Price (৳)',
                          hintText: 'e.g. 1750 (Optional)',
                          prefixIcon: Icon(Icons.discount_outlined),
                        ),
                        validator: (val) {
                          if (val != null && val.trim().isNotEmpty) {
                            final orig = double.tryParse(val.trim());
                            final price = double.tryParse(_priceController.text.trim());
                            if (orig == null || orig <= 0) {
                              return 'Invalid price';
                            }
                            if (price != null && orig < price) {
                              return 'Must be ≥ price';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 8. Stock Quantity
                TextFormField(
                  controller: _stockController,
                  keyboardType: TextInputType.number,
                  enabled: !_isSubmitting,
                  decoration: const InputDecoration(
                    labelText: 'Available Stock Quantity',
                    hintText: 'e.g. 50',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Enter available stock count';
                    }
                    final s = int.tryParse(val.trim());
                    if (s == null || s < 1) {
                      return 'Stock must be at least 1';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 9. Product Description
                TextFormField(
                  controller: _descController,
                  maxLines: 4,
                  enabled: !_isSubmitting,
                  decoration: const InputDecoration(
                    labelText: 'Product Description',
                    hintText: 'Describe freshness, farm source, origin, packaging, cold-chain, etc.',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please provide a product description';
                    }
                    if (val.trim().length < 10) {
                      return 'Description must be at least 10 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // 10. Status Message when Uploading
                if (_uploadStatus.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _uploadStatus,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // 11. Submit Button
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _handlePublishProduct,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Publish Product to Marketplace',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
