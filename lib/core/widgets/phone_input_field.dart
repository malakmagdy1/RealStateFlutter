import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:real/core/models/country_code.dart';
import 'package:real/core/utils/colors.dart';

class PhoneInputField extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final void Function(CountryCode)? onCountryChanged;
  final CountryCode? initialCountry;
  final String? hintText;
  final bool enabled;

  const PhoneInputField({
    Key? key,
    required this.controller,
    this.validator,
    this.onCountryChanged,
    this.initialCountry,
    this.hintText,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  late CountryCode _selectedCountry;

  @override
  void initState() {
    super.initState();
    _selectedCountry = widget.initialCountry ?? CountryCode.getDefault();
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CountryPickerBottomSheet(
        selectedCountry: _selectedCountry,
        onCountrySelected: (country) {
          setState(() {
            _selectedCountry = country;
          });
          widget.onCountryChanged?.call(country);
          Navigator.pop(context);
        },
      ),
    );
  }

  String? _validatePhone(String? value) {
    if (widget.validator != null) {
      return widget.validator!(value);
    }

    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }

    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.length < _selectedCountry.minLength) {
      return 'Phone number is too short';
    }

    if (digitsOnly.length > _selectedCountry.maxLength) {
      return 'Phone number is too long';
    }

    return null;
  }

  String getFullPhoneNumber() {
    return '${_selectedCountry.dialCode}${widget.controller.text}';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: TextFormField(
        controller: widget.controller,
        enabled: widget.enabled,
        keyboardType: TextInputType.phone,
        textDirection: TextDirection.ltr,
        validator: _validatePhone,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(_selectedCountry.maxLength),
        ],
        style: const TextStyle(
          fontSize: 16,
          letterSpacing: 1.2,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText ?? 'Enter phone number',
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
          filled: true,
          fillColor: Colors.grey[50],
          prefixIcon: _buildCountrySelector(),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.mainColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red[300]!, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildCountrySelector() {
    return InkWell(
      onTap: widget.enabled ? _showCountryPicker : null,
      borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _selectedCountry.flag,
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(width: 6),
            Text(
              _selectedCountry.dialCode,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }
}

class _CountryPickerBottomSheet extends StatefulWidget {
  final CountryCode selectedCountry;
  final void Function(CountryCode) onCountrySelected;

  const _CountryPickerBottomSheet({
    required this.selectedCountry,
    required this.onCountrySelected,
  });

  @override
  State<_CountryPickerBottomSheet> createState() => _CountryPickerBottomSheetState();
}

class _CountryPickerBottomSheetState extends State<_CountryPickerBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<CountryCode> _filteredCountries = CountryCode.arabCountries;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCountries(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCountries = CountryCode.arabCountries;
      } else {
        _filteredCountries = CountryCode.arabCountries.where((country) {
          return country.name.toLowerCase().contains(query.toLowerCase()) ||
              country.nameAr.contains(query) ||
              country.dialCode.contains(query) ||
              country.code.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.mainColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.public_rounded,
                        color: AppColors.mainColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Country',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Choose your country code',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Search field
                TextField(
                  controller: _searchController,
                  onChanged: _filterCountries,
                  decoration: InputDecoration(
                    hintText: 'Search by name or code...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[500]),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),

          // Countries list
          Expanded(
            child: _filteredCountries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No countries found',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredCountries.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: Colors.grey[200],
                    ),
                    itemBuilder: (context, index) {
                      final country = _filteredCountries[index];
                      final isSelected = country.code == widget.selectedCountry.code;

                      return _CountryListItem(
                        country: country,
                        isSelected: isSelected,
                        onTap: () => widget.onCountrySelected(country),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _CountryListItem extends StatelessWidget {
  final CountryCode country;
  final bool isSelected;
  final VoidCallback onTap;

  const _CountryListItem({
    required this.country,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.mainColor.withOpacity(0.08) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              // Flag
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    country.flag,
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Country info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      country.nameAr,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? AppColors.mainColor : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      country.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),

              // Dial code
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.mainColor.withOpacity(0.15)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  country.dialCode,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.mainColor : Colors.black87,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              // Check icon for selected
              if (isSelected) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.mainColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
