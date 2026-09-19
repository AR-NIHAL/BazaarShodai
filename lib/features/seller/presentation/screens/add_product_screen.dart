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
/// with camera/gallery photo upload via Cloudinary.
class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _stockController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  Uint8List? _imageBytes;

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
    _descController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImage = pickedFile;
          _imageBytes = bytes;
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
                'Select Product Photo',
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
    if (_selectedImage == null || _imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a product photo before publishing.'),
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
      _uploadStatus = 'Uploading photo to free cloud storage...';
    });

    try {
      // 1. Upload photo to Cloudinary
      final cloudImageUrl = await CloudImageService.uploadImage(_selectedImage!);

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

      // 3. Create Product Domain Entity
      final product = ProductModel(
        id: '', // Will be assigned documentId in repository
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        price: price,
        originalPrice: originalPrice,
        stock: stock,
        category: _selectedCategory,
        imageUrls: [cloudImageUrl],
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
                // Image Picker Container
                GestureDetector(
                  onTap: _isSubmitting ? null : _showImageSourceSheet,
                  child: Container(
                    height: 190,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _imageBytes != null ? AppColors.primary : AppColors.border,
                        width: 1.5,
                      ),
                    ),
                    child: _imageBytes != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.memory(
                                  _imageBytes!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                                    onPressed: _showImageSourceSheet,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySurface,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add_a_photo_outlined,
                                  size: 32,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Upload Product Photo',
                                style: TextStyle(
                                  fontSize: 15,
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
                ),
                const SizedBox(height: 20),

                // Product Title
                TextFormField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.words,
                  enabled: !_isSubmitting,
                  decoration: const InputDecoration(
                    labelText: 'Product Title',
                    hintText: 'e.g. Fresh Organic Red Tomato 1kg',
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

                // Category Dropdown
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

                // Price and Original Price Row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        enabled: !_isSubmitting,
                        decoration: const InputDecoration(
                          labelText: 'Price (৳)',
                          hintText: 'e.g. 65',
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
                          hintText: 'e.g. 80 (Optional)',
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

                // Stock Quantity
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

                // Product Description
                TextFormField(
                  controller: _descController,
                  maxLines: 4,
                  enabled: !_isSubmitting,
                  decoration: const InputDecoration(
                    labelText: 'Product Description',
                    hintText: 'Describe freshness, farm source, origin, packaging, etc.',
                    alignLabelWithHint: true,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Enter product description';
                    }
                    if (val.trim().length < 10) {
                      return 'Description must be at least 10 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // Submit Button / Progress Indicator
                if (_isSubmitting)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primaryLight),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _uploadStatus,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _handlePublishProduct,
                    icon: const Icon(Icons.cloud_upload_outlined),
                    label: const Text('Publish Product to Marketplace'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
