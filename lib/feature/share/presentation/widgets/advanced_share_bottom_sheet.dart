import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:real/core/utils/colors.dart';
import 'package:real/core/utils/text_style.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/share_model.dart';
import '../../data/services/share_service.dart';
import 'package:real/core/utils/message_helper.dart';
import 'package:real/l10n/app_localizations.dart';

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

  // Level-specific hidden fields
  List<String> _hiddenCompanyFields = [];
  List<String> _hiddenCompoundFields = [];
  List<String> _hiddenUnitFields = [];

  // Category icons
  final Map<String, IconData> _categoryIcons = {
    'price': Icons.attach_money,
    'payment': Icons.payment,
    'area': Icons.square_foot,
    'finishing': Icons.format_paint,
    'delivery': Icons.calendar_today,
    'contact': Icons.contact_phone,
    'images': Icons.image,
    'location': Icons.location_on,
    'building': Icons.business,
    'specs': Icons.settings,
    'type': Icons.category,
    'status': Icons.info,
    'description': Icons.description,
    'code': Icons.qr_code,
  };

  // Step management
  int _currentStep = 0; // 0 = selection, 1 = field selection, 2 = share options

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
      if ((widget.type == 'compound' || widget.type == 'company') &&
          !_showAllUnits && _selectedUnitIds.isNotEmpty) {
        unitIds = _selectedUnitIds;
      }

      final response = await _shareService.getShareLink(
        type: widget.type,
        id: widget.id,
        compoundIds: compoundIds,
        unitIds: unitIds,
        hiddenCompanyFields: _hiddenCompanyFields.isNotEmpty ? _hiddenCompanyFields : null,
        hiddenCompoundFields: _hiddenCompoundFields.isNotEmpty ? _hiddenCompoundFields : null,
        hiddenUnitFields: _hiddenUnitFields.isNotEmpty ? _hiddenUnitFields : null,
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

  void _toggleFieldVisibility(String level, String field) {
    setState(() {
      switch (level) {
        case 'company':
          if (_hiddenCompanyFields.contains(field)) {
            _hiddenCompanyFields.remove(field);
          } else {
            _hiddenCompanyFields.add(field);
          }
          break;
        case 'compound':
          if (_hiddenCompoundFields.contains(field)) {
            _hiddenCompoundFields.remove(field);
          } else {
            _hiddenCompoundFields.add(field);
          }
          break;
        case 'unit':
          if (_hiddenUnitFields.contains(field)) {
            _hiddenUnitFields.remove(field);
          } else {
            _hiddenUnitFields.add(field);
          }
          break;
      }
    });
  }

  String _getCategoryLabel(String category, bool isArabic) {
    if (isArabic) {
      return ShareService.categoryLabelsAr[category] ?? category;
    }
    return ShareService.categoryLabels[category] ?? category;
  }

  List<String> _getCategoriesForLevel(String level) {
    return ShareService.levelCategories[level] ?? [];
  }

  List<String> _getHiddenFieldsForLevel(String level) {
    switch (level) {
      case 'company':
        return _hiddenCompanyFields;
      case 'compound':
        return _hiddenCompoundFields;
      case 'unit':
        return _hiddenUnitFields;
      default:
        return [];
    }
  }

  int _getTotalHiddenFields() {
    return _hiddenCompanyFields.length +
           _hiddenCompoundFields.length +
           _hiddenUnitFields.length;
  }

  Widget _buildStepIndicator() {
    final bool hasSelectionStep = widget.type == 'compound' || widget.type == 'company';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (hasSelectionStep) ...[
          _buildStepDot(0, widget.type == 'company' ? 'Select' : 'Units'),
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

  Widget _buildSelectionStep() {
    // For company type, show compound selection
    if (widget.type == 'company' && widget.compounds != null) {
      return _buildCompoundSelectionUI();
    }

    // For compound type, show unit selection
    return _buildUnitSelectionUI();
  }

  Widget _buildCompoundSelectionUI() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText18(
          l10n.localeName == 'ar' ? 'اختر المجمعات للمشاركة' : 'Select Compounds to Share',
          bold: true,
          color: AppColors.black,
        ),
        SizedBox(height: 8),
        CustomText14(
          l10n.localeName == 'ar'
              ? 'اختر مجمعات محددة أو شارك جميع المجمعات'
              : 'Choose specific compounds or share all company compounds',
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
                  l10n.localeName == 'ar'
                      ? 'مشاركة كل المجمعات (${widget.compounds?.length ?? 0})'
                      : 'Share All Compounds (${widget.compounds?.length ?? 0})',
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
            l10n.localeName == 'ar'
                ? 'تم اختيار: ${_selectedCompoundIds.length} مجمع'
                : 'Selected: ${_selectedCompoundIds.length} compounds',
            color: AppColors.mainColor,
            bold: true,
          ),
          SizedBox(height: 12),
          Container(
            constraints: BoxConstraints(maxHeight: 250),
            child: widget.compounds!.isEmpty
                ? Center(
                    child: CustomText14(
                      l10n.localeName == 'ar' ? 'لا توجد مجمعات متاحة' : 'No compounds available',
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
              l10n.localeName == 'ar' ? 'التالي: إخفاء الحقول' : 'Next: Hide Fields',
              color: AppColors.white,
              bold: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnitSelectionUI() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText18(
          l10n.localeName == 'ar' ? 'اختر الوحدات للمشاركة' : 'Select Units to Share',
          bold: true,
          color: AppColors.black,
        ),
        SizedBox(height: 8),
        CustomText14(
          l10n.localeName == 'ar'
              ? 'اختر وحدات محددة أو شارك جميع الوحدات المتاحة'
              : 'Choose specific units or share all available units',
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
                  l10n.localeName == 'ar'
                      ? 'مشاركة كل الوحدات (${widget.units?.length ?? 0})'
                      : 'Share All Units (${widget.units?.length ?? 0})',
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
            l10n.localeName == 'ar'
                ? 'تم اختيار: ${_selectedUnitIds.length} وحدة'
                : 'Selected: ${_selectedUnitIds.length} units',
            color: AppColors.mainColor,
            bold: true,
          ),
          SizedBox(height: 12),
          Container(
            constraints: BoxConstraints(maxHeight: 250),
            child: widget.units == null || widget.units!.isEmpty
                ? Center(
                    child: CustomText14(
                      l10n.localeName == 'ar' ? 'لا توجد وحدات متاحة' : 'No units available',
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
                CustomText16(
                  l10n.localeName == 'ar' ? 'التالي: اختر الحقول' : 'Next: Select Fields',
                  color: Colors.white,
                  bold: true
                ),
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
    final l10n = AppLocalizations.of(context)!;
    final isArabic = l10n.localeName == 'ar';
    final bool hasSelectionStep = widget.type == 'compound' || widget.type == 'company';

    // Determine which levels to show based on type
    List<String> levelsToShow = [];
    if (widget.type == 'company') {
      levelsToShow = ['company', 'compound', 'unit'];
    } else if (widget.type == 'compound') {
      levelsToShow = ['compound', 'unit'];
    } else {
      levelsToShow = ['unit'];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (hasSelectionStep)
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
                isArabic ? 'إخفاء المعلومات الحساسة' : 'Hide Sensitive Information',
                bold: true,
                color: AppColors.black,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        CustomText14(
          isArabic
              ? 'اختر المعلومات التي تريد إخفاءها قبل المشاركة'
              : 'Select information to hide before sharing',
          color: Colors.grey[600],
        ),
        SizedBox(height: 16),

        // Summary
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getTotalHiddenFields() == 0
                ? Colors.green.withOpacity(0.1)
                : Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getTotalHiddenFields() == 0 ? Colors.green : Colors.orange,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _getTotalHiddenFields() == 0 ? Icons.visibility : Icons.visibility_off,
                color: _getTotalHiddenFields() == 0 ? Colors.green : Colors.orange,
              ),
              SizedBox(width: 12),
              Expanded(
                child: CustomText14(
                  _getTotalHiddenFields() == 0
                      ? (isArabic ? 'جميع الحقول مرئية' : 'All fields visible')
                      : (isArabic
                          ? '${_getTotalHiddenFields()} حقل مخفي'
                          : '${_getTotalHiddenFields()} fields hidden'),
                  bold: true,
                  color: _getTotalHiddenFields() == 0 ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 16),

        // Level-specific field sections
        Container(
          constraints: BoxConstraints(maxHeight: 320),
          child: SingleChildScrollView(
            child: Column(
              children: levelsToShow.map((level) {
                return _buildLevelSection(level, isArabic);
              }).toList(),
            ),
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
                      CustomText16(
                        isArabic ? 'إنشاء رابط المشاركة' : 'Generate Share Link',
                        color: Colors.white,
                        bold: true
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.share, color: Colors.white, size: 20),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildLevelSection(String level, bool isArabic) {
    final categories = _getCategoriesForLevel(level);
    final hiddenFields = _getHiddenFieldsForLevel(level);

    String levelTitle;
    IconData levelIcon;
    Color levelColor;

    switch (level) {
      case 'company':
        levelTitle = isArabic ? 'معلومات الشركة' : 'Company Info';
        levelIcon = Icons.business;
        levelColor = Colors.blue;
        break;
      case 'compound':
        levelTitle = isArabic ? 'معلومات المجمع' : 'Compound Info';
        levelIcon = Icons.apartment;
        levelColor = Colors.purple;
        break;
      case 'unit':
        levelTitle = isArabic ? 'معلومات الوحدة' : 'Unit Info';
        levelIcon = Icons.home;
        levelColor = Colors.teal;
        break;
      default:
        levelTitle = level;
        levelIcon = Icons.info;
        levelColor = Colors.grey;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: levelColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(levelIcon, color: levelColor, size: 20),
          ),
          title: Row(
            children: [
              Expanded(
                child: CustomText14(levelTitle, bold: true),
              ),
              if (hiddenFields.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${hiddenFields.length}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((category) {
                  final isHidden = hiddenFields.contains(category);
                  final label = _getCategoryLabel(category, isArabic);
                  final icon = _categoryIcons[category] ?? Icons.settings;

                  return FilterChip(
                    avatar: Icon(
                      isHidden ? Icons.visibility_off : icon,
                      size: 16,
                      color: isHidden ? Colors.red : Colors.green,
                    ),
                    label: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: isHidden ? Colors.red : Colors.green.shade700,
                        fontWeight: isHidden ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isHidden,
                    onSelected: (selected) => _toggleFieldVisibility(level, category),
                    backgroundColor: isHidden
                        ? Colors.red.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    selectedColor: Colors.red.withOpacity(0.2),
                    checkmarkColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isHidden ? Colors.red.withOpacity(0.5) : Colors.green.withOpacity(0.3),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOptionsStep() {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = l10n.localeName == 'ar';

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
                isArabic ? 'مشاركة عبر' : 'Share Via',
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
                  child: Text(isArabic ? 'إعادة المحاولة' : 'Retry'),
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
                      isArabic ? 'تم إنشاء رابط المشاركة!' : 'Share link generated!',
                      bold: true,
                      color: AppColors.black,
                    ),
                    SizedBox(height: 8),
                    if (!_showAllUnits && _selectedUnitIds.isNotEmpty)
                      CustomText12(
                        isArabic
                            ? '${_selectedUnitIds.length} وحدة محددة'
                            : '${_selectedUnitIds.length} units selected',
                        color: Colors.grey[600],
                      ),
                    if (!_showAllCompounds && _selectedCompoundIds.isNotEmpty)
                      CustomText12(
                        isArabic
                            ? '${_selectedCompoundIds.length} مجمع محدد'
                            : '${_selectedCompoundIds.length} compounds selected',
                        color: Colors.grey[600],
                      ),
                    if (_getTotalHiddenFields() > 0)
                      CustomText12(
                        isArabic
                            ? '${_getTotalHiddenFields()} حقل مخفي'
                            : '${_getTotalHiddenFields()} fields hidden',
                        color: Colors.grey[600],
                      ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Share options
              _ShareOption(
                icon: Icons.link,
                label: isArabic ? 'نسخ الرابط' : 'Copy Link',
                color: AppColors.mainColor,
                onTap: () => _copyToClipboard(_shareData!.url),
              ),
              SizedBox(height: 12),
              _ShareOption(
                icon: Icons.message,
                label: isArabic ? 'واتساب' : 'WhatsApp',
                color: Color(0xFF25D366),
                onTap: () => _launchUrl(_shareData!.whatsappUrl),
              ),
              SizedBox(height: 12),
              _ShareOption(
                icon: Icons.facebook,
                label: isArabic ? 'فيسبوك' : 'Facebook',
                color: Color(0xFF1877F2),
                onTap: () => _launchUrl(_shareData!.facebookUrl),
              ),
              SizedBox(height: 12),
              _ShareOption(
                icon: Icons.email,
                label: isArabic ? 'البريد الإلكتروني' : 'Email',
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
                  _buildSelectionStep()
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
