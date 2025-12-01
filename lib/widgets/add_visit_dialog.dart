import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/coffee_shop.dart';

class AddVisitDialog extends StatefulWidget {
  final CoffeeShop coffeeShop;

  const AddVisitDialog({
    super.key,
    required this.coffeeShop,
  });

  @override
  State<AddVisitDialog> createState() => _AddVisitDialogState();
}

class _AddVisitDialogState extends State<AddVisitDialog> {
  String _selectedOption = 'want_to_visit';
  bool _showVisitedForm = false;
  double _personalRating = 0.0;
  final TextEditingController _reviewController = TextEditingController();
  DateTime? _selectedDate;
  List<DateTime> _additionalDates = [];

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Add to Your List',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(
              widget.coffeeShop.name,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Dropdown button dengan panah ke bawah
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF6F4E37)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: PopupMenuButton<String>(
                onSelected: (String value) {
                  setState(() {
                    _selectedOption = value;
                    if (value == 'visited') {
                      _showVisitedForm = true;
                    } else {
                      _showVisitedForm = false;
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedOption.isEmpty
                            ? 'Choose option...'
                            : _selectedOption == 'want_to_visit'
                                ? 'Want to Visit'
                                : 'Visited',
                        style: GoogleFonts.inter(
                          color: _selectedOption.isEmpty
                              ? Colors.grey[600]
                              : const Color(0xFF6F4E37),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: const Color(0xFF6F4E37),
                      ),
                    ],
                  ),
                ),
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'want_to_visit',
                    child: Row(
                      children: [
                        Icon(Icons.bookmark_outline, color: Colors.blue, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Want to Visit',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'visited',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Visited',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Form untuk visited (muncul setelah pilih visited)
            if (_showVisitedForm) ...[
              const SizedBox(height: 24),
              Text(
                'Visit Details',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),

              // Rating dengan支持 setengah bintang
              Text(
                'Personal Rating',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return _buildStarButton(index);
                }),
              ),
              if (_personalRating > 0) ...[
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    '${_personalRating.toStringAsFixed(1)} stars',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Private Review
              Text(
                'Private Review (Your notes)',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _reviewController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add your private notes about this coffee shop...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),

              const SizedBox(height: 16),

              // Visit Date
              Text(
                'Visit Date',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                        child: Text(
                          _selectedDate != null
                              ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                              : 'Select date',
                          style: GoogleFonts.inter(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedDate = DateTime.now();
                      });
                    },
                    child: Text(
                      'Today',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              // Additional dates (hanya muncul jika ada tanggal pertama)
              if (_selectedDate != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Additional Visit Dates',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _addAdditionalDate,
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(
                        'Add Date',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_additionalDates.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _additionalDates.asMap().entries.map((entry) {
                      final index = entry.key;
                      final date = entry.value;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6F4E37).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF6F4E37).withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${date.day}/${date.month}/${date.year}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF6F4E37),
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _additionalDates.removeAt(index);
                                });
                              },
                              child: Icon(
                                Icons.close,
                                size: 14,
                                color: const Color(0xFF6F4E37),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ],
          ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: GoogleFonts.inter(),
          ),
        ),
        if (_selectedOption == 'want_to_visit')
          ElevatedButton(
            onPressed: _addToWantToVisit,
            child: Text(
              'Add to List',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (_selectedOption == 'visited')
          ElevatedButton(
            onPressed: _saveAsVisited,
            child: Text(
              'Save Visit',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStarButton(int index) {
    bool isFilled = false;
    bool isHalfFilled = false;

    if (_personalRating > index) {
      if (_personalRating >= index + 1) {
        isFilled = true;
      } else {
        isHalfFilled = true;
      }
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_personalRating == index + 0.5) {
            // Jika saat ini setengah, klik lagi menjadi full
            _personalRating = index + 1.0;
          } else if (_personalRating == index + 1.0) {
            // Jika saat ini full, klik lagi menjadi setengah
            _personalRating = index + 0.5;
          } else {
            // Klik normal ke full
            _personalRating = index + 1.0;
          }
        });
      },
      child: Icon(
        isHalfFilled ? Icons.star_half : (isFilled ? Icons.star : Icons.star_border),
        color: Colors.orange[400],
        size: 32,
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _addAdditionalDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _additionalDates.add(picked);
        // Sort dates
        _additionalDates.sort((a, b) => a.compareTo(b));
      });
    }
  }

  void _addToWantToVisit() {
    Navigator.of(context).pop('want_to_visit');
  }

  void _saveAsVisited() {
    // Create visit dates list
    List<DateTime> visitDates = [];

    // Add selected date if exists
    if (_selectedDate != null) {
      visitDates.add(_selectedDate!);
    }

    // Add additional dates
    visitDates.addAll(_additionalDates);

    // If no visit dates are selected, use today's date as default
    if (visitDates.isEmpty) {
      visitDates.add(DateTime.now());
    }

    final Map<String, dynamic> result = {
      'personalRating': _personalRating > 0 ? _personalRating : null,
      'privateReview': _reviewController.text.trim().isNotEmpty ? _reviewController.text.trim() : null,
      'visitDates': visitDates,
    };

    // Debug print to see what's being saved
    if (kDebugMode) {
      print('Saving as visited: $result');
    }

    Navigator.of(context).pop(result);
  }
}

class VisitDetailsDialog extends StatefulWidget {
  final CoffeeShop coffeeShop;
  final bool isEditing;

  const VisitDetailsDialog({
    super.key,
    required this.coffeeShop,
    this.isEditing = false,
  });

  @override
  State<VisitDetailsDialog> createState() => _VisitDetailsDialogState();
}

class _VisitDetailsDialogState extends State<VisitDetailsDialog> {
  double _personalRating = 0.0;
  final TextEditingController _reviewController = TextEditingController();
  List<DateTime> _visitDates = [];

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.coffeeShop.visitData != null) {
      _personalRating = widget.coffeeShop.visitData!.personalRating ?? 0.0;
      _reviewController.text = widget.coffeeShop.visitData!.privateReview ?? '';
      _visitDates = List.from(widget.coffeeShop.visitData!.visitDates);
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.isEditing ? 'Edit Visit Details' : 'Visit Details',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Personal Rating',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return _buildStarButton(index);
                }),
              ),
              if (_personalRating > 0) ...[
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    '${_personalRating.toStringAsFixed(1)} stars',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Private Review (Your notes)',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _reviewController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add your private notes about this coffee shop...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Visit Dates',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: _addVisitDate,
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(
                      'Add Date',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              if (_visitDates.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _visitDates.asMap().entries.map((entry) {
                    final index = entry.key;
                    final date = entry.value;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6F4E37).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF6F4E37).withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () => _editVisitDate(index),
                            child: Text(
                              '${date.day}/${date.month}/${date.year}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF6F4E37),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _visitDates.removeAt(index);
                              });
                            },
                            child: Icon(
                              Icons.close,
                              size: 14,
                              color: const Color(0xFF6F4E37),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: GoogleFonts.inter(),
          ),
        ),
        ElevatedButton(
          onPressed: _saveVisitDetails,
          child: Text(
            widget.isEditing ? 'Update' : 'Save',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStarButton(int index) {
    bool isFilled = false;
    bool isHalfFilled = false;

    if (_personalRating > index) {
      if (_personalRating >= index + 1) {
        isFilled = true;
      } else {
        isHalfFilled = true;
      }
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_personalRating == index + 0.5) {
            _personalRating = index + 1.0;
          } else if (_personalRating == index + 1.0) {
            _personalRating = index + 0.5;
          } else {
            _personalRating = index + 1.0;
          }
        });
      },
      child: Icon(
        isHalfFilled ? Icons.star_half : (isFilled ? Icons.star : Icons.star_border),
        color: Colors.orange[400],
        size: 32,
      ),
    );
  }

  Future<void> _addVisitDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _visitDates.add(picked);
        _visitDates.sort((a, b) => a.compareTo(b));
      });
    }
  }

  Future<void> _editVisitDate(int index) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _visitDates[index],
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _visitDates[index]) {
      setState(() {
        _visitDates[index] = picked;
        _visitDates.sort((a, b) => a.compareTo(b));
      });
    }
  }

  void _saveVisitDetails() {
    final Map<String, dynamic> result = {
      'personalRating': _personalRating > 0 ? _personalRating : null,
      'privateReview': _reviewController.text.trim().isNotEmpty ? _reviewController.text.trim() : null,
      'visitDates': _visitDates,
    };

    // Debug print to see what's being saved
    if (kDebugMode) {
      print('Saving visit details: $result');
    }

    Navigator.of(context).pop(result);
  }
}

class AddRevisitDialog extends StatefulWidget {
  final CoffeeShop coffeeShop;

  const AddRevisitDialog({
    super.key,
    required this.coffeeShop,
  });

  @override
  State<AddRevisitDialog> createState() => _AddRevisitDialogState();
}

class _AddRevisitDialogState extends State<AddRevisitDialog> {
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Add Revisit Date',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select the date you revisited ${widget.coffeeShop.name}',
            style: GoogleFonts.inter(),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _selectDate,
            child: InputDecorator(
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              child: Text(
                _selectedDate != null
                    ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                    : 'Select date',
                style: GoogleFonts.inter(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedDate = DateTime.now();
                    });
                  },
                  child: Text(
                    'Set to Today',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: GoogleFonts.inter(),
          ),
        ),
        ElevatedButton(
          onPressed: _selectedDate != null
              ? () => Navigator.of(context).pop(_selectedDate)
              : null,
          child: Text(
            'Add Date',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
}

class RemoveFromTrackingDialog extends StatelessWidget {
  final CoffeeShop coffeeShop;
  final String trackingType;

  const RemoveFromTrackingDialog({
    super.key,
    required this.coffeeShop,
    required this.trackingType,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Remove from Your List',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you sure you want to remove "${coffeeShop.name}" from your list?',
            style: GoogleFonts.inter(),
          ),
          if (trackingType == 'want_to_visit') ...[
            const SizedBox(height: 8),
            Text(
              'This will remove it from your "Want to Visit" list.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: GoogleFonts.inter(),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop('remove'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: Text(
            'Remove',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}