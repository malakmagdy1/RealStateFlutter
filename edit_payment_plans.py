import re

# Mobile file
mobile_file = r'C:\Users\B-Smart\AndroidStudioProjects\real\lib\feature\compound\presentation\screen\unit_detail_screen.dart'

with open(mobile_file, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace delivery section with payment summary section
old_section = '''          // Delivery & Finishing Info
          if (plan.deliveryDate != null || plan.finishingType != null) ...[
            SizedBox(height: 12),
            Divider(color: Colors.grey.shade300),
            SizedBox(height: 8),
            Row(
              children: [
                if (plan.deliveryDate != null &&
                    plan.deliveryDate!.isNotEmpty) ...[
                  Icon(Icons.event_available, size: 14, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    'Delivery: ${plan.deliveryDate}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  ),
                  SizedBox(width: 16),
                ],
                if (plan.finishingType != null &&
                    plan.finishingType!.isNotEmpty) ...[
                  Icon(Icons.format_paint, size: 14, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    plan.finishingType!,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  ),
                ],
              ],
            ),
          ],'''

new_section = '''          // Payment Summary Info (for installment plans)
          if (!isCash && duration != '0') ...[
            SizedBox(height: 12),
            Divider(color: Colors.grey.shade300),
            SizedBox(height: 8),
            _buildPaymentSummarySection(plan, l10n),
          ],'''

if old_section in content:
    content = content.replace(old_section, new_section)
    with open(mobile_file, 'w', encoding='utf-8') as f:
        f.write(content)
    print('Successfully updated mobile unit_detail_screen.dart')
else:
    print('Could not find exact match in mobile file')

# Web file
web_file = r'C:\Users\B-Smart\AndroidStudioProjects\real\lib\feature_web\compound\presentation\web_unit_detail_screen.dart'

with open(web_file, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace delivery section with payment summary section for web
old_section_web = '''          // Delivery & Finishing Info
          if ((plan.deliveryDate != null && plan.deliveryDate!.isNotEmpty) ||
              (plan.finishingType != null &&
                  plan.finishingType!.isNotEmpty)) ...[
            SizedBox(height: 8),
            Divider(color: Color(0xFFE6E6E6)),
            SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                if (plan.deliveryDate != null && plan.deliveryDate!.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_available, size: 12,
                          color: Color(0xFF666666)),
                      SizedBox(width: 4),
                      Text(
                        'Delivery: ${plan.deliveryDate}',
                        style: TextStyle(
                            fontSize: 11, color: Color(0xFF666666)),
                      ),
                    ],
                  ),
                if (plan.finishingType != null &&
                    plan.finishingType!.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.format_paint, size: 12,
                          color: Color(0xFF666666)),
                      SizedBox(width: 4),
                      Text(
                        plan.finishingType!,
                        style: TextStyle(
                            fontSize: 11, color: Color(0xFF666666)),
                      ),
                    ],
                  ),
                if (plan.totalArea != null && plan.totalArea!.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.square_foot, size: 12,
                          color: Color(0xFF666666)),
                      SizedBox(width: 4),
                      Text(
                        '${plan.totalArea} m²',
                        style: TextStyle(
                            fontSize: 11, color: Color(0xFF666666)),
                      ),'''

new_section_web = '''          // Payment Summary Info (for installment plans)
          if (!isCash && duration != '0') ...[
            SizedBox(height: 8),
            Divider(color: Color(0xFFE6E6E6)),
            SizedBox(height: 8),
            _buildPaymentSummarySection(plan, l10n),'''

if old_section_web in content:
    content = content.replace(old_section_web, new_section_web)
    with open(web_file, 'w', encoding='utf-8') as f:
        f.write(content)
    print('Successfully updated web web_unit_detail_screen.dart')
else:
    print('Could not find exact match in web file')

print('Done!')
