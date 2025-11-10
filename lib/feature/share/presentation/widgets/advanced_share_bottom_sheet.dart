import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/share_model.dart';
import '../../data/services/share_service.dart';
import 'package:real/core/utils/message_helper.dart';

/// Advanced share bottom sheet with unit selection and field hiding
class AdvancedShareBottomSheet extends StatefulWidget {
  final String type; // 'unit', 'compound', or 'company'
  final String id;
  final List<Map<String, dynamic>>? units; // Available units for compound
  final List<Map<String, dynamic>>? compounds; // Available compounds for company

  const AdvancedShareBottomSheet({
    Key? key,
    required this.type,
    required this.id,
    this.units,
    this.compounds,
  }) : super(key: key);

  @override
  State<AdvancedShareBottomSheet> createState() =>
      _AdvancedShareBottomSheetState();
}

class _AdvancedShareBottomSheetState extends State<AdvancedShareBottomSheet> {
  final ShareService _shareService = ShareService();
  bool _isLoading = false;
  String? _error;
  ShareData? _shareData;

  // Compound selection state (for company shares)
  List<String> _selectedCompoundIds = [];
  bool _showAllCompounds = true;

  // Unit selection state
  List<String> _selectedUnitIds = [];
  bool _showAllUnits = true;

  // Field hiding state
  final List<String> _availableFields = [
    'normal_price',
    'unit_code',
    'built_up_area',
    'land_area',
    'garden_area',
    'number_of_beds',
    'status',
  ];

  final Map<String, String> _fieldLabels = {
    'normal_price': 'Price',
    'unit_code': 'Unit Code',
    'built_up_area': 'Built Up Area',
    'land_area': 'Land Area',
    'garden_area': 'Garden Area',
    'number_of_beds': 'Bedrooms',
    'status': 'Status',
  };

  List<String> _hiddenFields = [];

  // Step management
  int _currentStep = 0; // 0 = unit selection, 1 = field selection, 2 = share options

  @override
  void initState() {
    super.initState();
    // If type is unit, skip to field selection
    if (widget.type == 'unit') {
      _currentStep = 1;
    }
  }

  Future<void> _loadShareLink() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Build parameters
      List<String>? compoundIds;
      if (widget.type == 'company' && !_showAllCompounds && _selectedCompoundIds.isNotEmpty) {
        compoundIds = _selectedCompoundIds;
      }

      List<String>? unitIds;
      if (widget.type == 'compound' && !_showAllUnits && _selectedUnitIds.isNotEmpty) {
        unitIds = _selectedUnitIds;
      }

      final response = await _shareService.getShareLink(
        type: widget.type,
        id: widget.id,
        compoundIds: compoundIds,
        unitIds: unitIds,
        hiddenFields: _hiddenFields.isNotEmpty ? _hiddenFields : null,
      );

      setState(() {
        _shareData = response.share;
        _isLoading = false;
        _currentStep = 2; // Move to share options
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          MessageHelper.showError(context, 'Could not open link');
        }
      }
    } catch (e) {
      if (mounted) {
        MessageHelper.showError(context, 'Error: $e');
      }
    }
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      MessageHelper.showSuccess(context, 'Link copied to clipboard!');
      Navigator.pop(context);
    }
  }

  void _toggleCompoundSelection(String compoundId) {
    setState(() {
      if (_selectedCompoundIds.contains(compoundId)) {
        _selectedCompoundIds.remove(compoundId);
      } else {
        _selectedCompoundIds.add(compoundId);
      }
    });
  }

  void _toggleUnitSelection(String unitId) {
    setState(() {
      if (_selectedUnitIds.contains(unitId)) {
        _selectedUnitIds.remove(unitId);
      } else {
        _selectedUnitIds.add(unitId);
      }
    });
  }

  void _toggleFieldVisibility(String field) {
    setState(() {
      if (_hiddenFields.contains(field)) {
        _hiddenFields.remove(field);
      } else {
        _hiddenFields.add(field);
      }
    });
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.type == 'compound') ...[
          _buildStepDot(0, 'Units'),
          Container(width: 40, height: 2, color: _currentStep > 0 ? AppColors.mainColor : Colors.grey.shade300),
        ],
        _buildStepDot(1, 'Fields'),
        Container(width: 40, height: 2, color: _currentStep > 1 ? AppColors.mainColor : Colors.grey.shade300),
        _buildStepDot(2, 'Share'),
      ],
    );
  }

  Widget _buildStepDot(int step, String label) {
    final isActive = _currentStep >= step;
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.mainColor : Colors.grey.shade300,
          ),
          child: Center(
            child: Text(
              '${step + 1}',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isActive ? AppColors.mainColor : Colors.grey,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildUnitSelectionStep() {
    // For company type, show compound selection
    if (widget.type == 'company' && widget.compounds != null) {
      return _buildCompoundSelectionUI();
    }

    // For compound type, show unit selection
    return _buildUnitSelectionUI();
  }

  Widget _buildCompoundSelectionUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText18(
          'Select Compounds to Share',
          bold: true,
          color: AppColors.black,
        ),
        SizedBox(height: 8),
        CustomText14(
          'Choose specific compounds or share all company compounds',
          color: Colors.grey[600],
        ),
        SizedBox(height: 20),

        // Share All Toggle
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.mainColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _showAllCompounds ? AppColors.mainColor : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.select_all,
                color: AppColors.mainColor,
              ),
              SizedBox(width: 12),
              Expanded(
                child: CustomText16(
                  'Share All Compounds (${widget.compounds?.length ?? 0})',
                  bold: _showAllCompounds,
                ),
              ),
              Switch(
                value: _showAllCompounds,
                onChanged: (value) {
                  setState(() {
                    _showAllCompounds = value;
                    if (value) {
                      _selectedCompoundIds.clear();
                    }
                  });
                },
                activeColor: AppColors.mainColor,
              ),
            ],
          ),
        ),

        if (!_showAllCompounds) ...[
          SizedBox(height: 16),
          CustomText14(
            'Selected: ${_selectedCompoundIds.length} compounds',
            color: AppColors.mainColor,
            bold: true,
          ),
          SizedBox(height: 12),
          Container(
            constraints: BoxConstraints(maxHeight: 300),
            child: widget.compounds!.isEmpty
                ? Center(
                    child: CustomText14(
                      'No compounds available',
                      color: Colors.grey,
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: widget.compounds!.length,
                    itemBuilder: (context, index) {
                      final compound = widget.compounds![index];
                      final compoundId = compound['id'].toString();
                      final isSelected = _selectedCompoundIds.contains(compoundId);

                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (value) => _toggleCompoundSelection(compoundId),
                        title: CustomText14(
                          compound['project'] ?? 'Compound $compoundId',
                          bold: isSelected,
                        ),
                        subtitle: compound['location'] != null
                            ? CustomText12(
                                '${compound['location']} • ${compound['totalUnits'] ?? '0'} units',
                                color: Colors.grey[600],
                              )
                            : null,
                        activeColor: AppColors.mainColor,
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8),
                      );
                    },
                  ),
          ),
        ],

        SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _showAllCompounds || _selectedCompoundIds.isNotEmpty
                ? () {
                    setState(() {
                      _currentStep = 1;
                    });
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mainColor,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: CustomText16(
              'Next: Hide Fields',
              color: AppColors.white,
              bold: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnitSelectionUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText18(
          'Select Units to Share',
          bold: true,
          color: AppColors.black,
        ),
        SizedBox(height: 8),
        CustomText14(
          'Choose specific units or share all available units',
          color: Colors.grey[600],
        ),
        SizedBox(height: 20),

        // Share All Toggle
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.mainColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _showAllUnits ? AppColors.mainColor : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.select_all,
                color: AppColors.mainColor,
              ),
              SizedBox(width: 12),
              Expanded(
                child: CustomText16(
                  'Share All Units (${widget.units?.length ?? 0})',
                  bold: _showAllUnits,
                ),
              ),
              Switch(
                value: _showAllUnits,
                onChanged: (value) {
                  setState(() {
                    _showAllUnits = value;
                    if (value) {
                      _selectedUnitIds.clear();
                    }
                  });
                },
                activeColor: AppColors.mainColor,
              ),
            ],
          ),
        ),

        if (!_showAllUnits) ...[
          SizedBox(height: 16),
          CustomText14(
            'Selected: ${_selectedUnitIds.length} units',
            color: AppColors.mainColor,
            bold: true,
          ),
          SizedBox(height: 12),
          Container(
            constraints: BoxConstraints(maxHeight: 300),
            child: widget.units == null || widget.units!.isEmpty
                ? Center(
                    child: CustomText14(
                      'No units available',
                      color: Colors.grey,
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: widget.units!.length,
                    itemBuilder: (context, index) {
                      final unit = widget.units![index];
                      final unitId = unit['id'].toString();
                      final isSelected = _selectedUnitIds.contains(unitId);

                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (value) => _toggleUnitSelection(unitId),
                        title: CustomText14(
                          unit['unit_name'] ?? 'Unit $unitId',
                          bold: isSelected,
                        ),
                        subtitle: unit['unit_code'] != null
                            ? CustomText12(
                                unit['unit_code'],
                                color: Colors.grey[600],
                              )
                            : null,
                        activeColor: AppColors.mainColor,
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8),
                      );
                    },
                  ),
          ),
        ],

        SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _showAllUnits || _selectedUnitIds.isNotEmpty
                ? () {
                    setState(() {
                      _currentStep = 1;
                    });
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mainColor,
              padding: EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomText16('Next: Select Fields', color: Colors.white, bold: true),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldSelectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (widget.type == 'compound')
              IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _currentStep = 0;
                  });
                },
              ),
            Expanded(
              child: CustomText18(
                'Choose Visible Fields',
                bold: true,
                color: AppColors.black,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        CustomText14(
          'Hide sensitive information before sharing',
          color: Colors.grey[600],
        ),
        SizedBox(height: 20),

        // Show All Toggle
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _hiddenFields.isEmpty
                ? AppColors.mainColor.withOpacity(0.1)
                : Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hiddenFields.isEmpty ? AppColors.mainColor : Colors.orange,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _hiddenFields.isEmpty ? Icons.visibility : Icons.visibility_off,
                color: _hiddenFields.isEmpty ? AppColors.mainColor : Colors.orange,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText16(
                      _hiddenFields.isEmpty ? 'All Fields Visible' : '${_hiddenFields.length} Fields Hidden',
                      bold: true,
                    ),
                    if (_hiddenFields.isNotEmpty)
                      CustomText12(
                        'Tap fields below to show/hide',
                        color: Colors.grey[600],
                      ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    if (_hiddenFields.isEmpty) {
                      _hiddenFields = List.from(_availableFields);
                    } else {
                      _hiddenFields.clear();
                    }
                  });
                },
                child: Text(_hiddenFields.isEmpty ? 'Hide All' : 'Show All'),
              ),
            ],
          ),
        ),

        SizedBox(height: 16),

        // Field list
        Container(
          constraints: BoxConstraints(maxHeight: 300),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _availableFields.length,
            itemBuilder: (context, index) {
              final field = _availableFields[index];
              final label = _fieldLabels[field] ?? field;
              final isHidden = _hiddenFields.contains(field);

              return Container(
                margin: EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isHidden ? Colors.red.withOpacity(0.05) : Colors.green.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isHidden ? Colors.red.withOpacity(0.3) : Colors.green.withOpacity(0.3),
                  ),
                ),
                child: SwitchListTile(
                  value: !isHidden,
                  onChanged: (value) => _toggleFieldVisibility(field),
                  title: CustomText14(label, bold: !isHidden),
                  secondary: Icon(
                    isHidden ? Icons.visibility_off : Icons.visibility,
                    color: isHidden ? Colors.red : Colors.green,
                  ),
                  activeColor: Colors.green,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
              );
            },
          ),
        ),

        SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loadShareLink,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mainColor,
              padding: EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomText16('Generate Share Link', color: Colors.white, bold: true),
                      SizedBox(width: 8),
                      Icon(Icons.share, color: Colors.white, size: 20),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildShareOptionsStep() {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                setState(() {
                  _currentStep = 1;
                  _shareData = null;
                });
              },
            ),
            Expanded(
              child: CustomText18(
                'Share Via',
                bold: true,
                color: AppColors.black,
              ),
            ),
          ],
        ),
        SizedBox(height: 20),

        if (_error != null)
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red),
                SizedBox(height: 12),
                CustomText16(_error!, color: Colors.red, align: TextAlign.center),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadShareLink,
                  child: Text('Retry'),
                ),
              ],
            ),
          )
        else if (_shareData != null)
          Column(
            children: [
              // Summary
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.mainColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 48),
                    SizedBox(height: 12),
                    CustomText16(
                      'Share link generated!',
                      bold: true,
                      color: AppColors.black,
                    ),
                    SizedBox(height: 8),
                    if (!_showAllUnits && _selectedUnitIds.isNotEmpty)
                      CustomText12(
                        '${_selectedUnitIds.length} units selected',
                        color: Colors.grey[600],
                      ),
                    if (_hiddenFields.isNotEmpty)
                      CustomText12(
                        '${_hiddenFields.length} fields hidden',
                        color: Colors.grey[600],
                      ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Share options
              _ShareOption(
                icon: Icons.link,
                label: 'Copy Link',
                color: AppColors.mainColor,
                onTap: () => _copyToClipboard(_shareData!.url),
              ),
              SizedBox(height: 12),
              _ShareOption(
                icon: Icons.message,
                label: 'WhatsApp',
                color: Color(0xFF25D366),
                onTap: () => _launchUrl(_shareData!.whatsappUrl),
              ),
              SizedBox(height: 12),
              _ShareOption(
                icon: Icons.facebook,
                label: 'Facebook',
                color: Color(0xFF1877F2),
                onTap: () => _launchUrl(_shareData!.facebookUrl),
              ),
              SizedBox(height: 12),
              _ShareOption(
                icon: Icons.email,
                label: 'Email',
                color: Color(0xFFEA4335),
                onTap: () => _launchUrl(_shareData!.emailUrl),
              ),
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 20),

                // Step indicator
                _buildStepIndicator(),
                SizedBox(height: 24),

                // Current step content
                if (_currentStep == 0)
                  _buildUnitSelectionStep()
                else if (_currentStep == 1)
                  _buildFieldSelectionStep()
                else if (_currentStep == 2)
                  _buildShareOptionsStep(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            SizedBox(width: 16),
            CustomText16(label, bold: true, color: color),
            Spacer(),
            Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ],
        ),
      ),
    );
  }
}
