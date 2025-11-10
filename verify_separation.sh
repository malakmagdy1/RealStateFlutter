#!/bin/bash

echo "=========================================="
echo "Web & Mobile Separation Verification"
echo "=========================================="
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check 1: Web importing mobile UI
echo "1. Checking for mobile UI imports in web files..."
MOBILE_IN_WEB=$(find lib/feature_web -name "*.dart" -type f -exec grep -l "import.*feature/.*presentation/screen" {} \; 2>/dev/null)
MOBILE_WIDGETS_IN_WEB=$(find lib/feature_web -name "*.dart" -type f -exec grep -l "import.*feature/.*presentation/widget" {} \; 2>/dev/null)

if [ -z "$MOBILE_IN_WEB" ] && [ -z "$MOBILE_WIDGETS_IN_WEB" ]; then
    echo -e "${GREEN}✅ PASS: No mobile UI imports in web${NC}"
else
    echo -e "${RED}❌ FAIL: Found mobile UI imports in web:${NC}"
    echo "$MOBILE_IN_WEB"
    echo "$MOBILE_WIDGETS_IN_WEB"
fi

echo ""

# Check 2: Mobile importing web UI
echo "2. Checking for web UI imports in mobile files..."
WEB_IN_MOBILE=$(find lib/feature -name "*.dart" -type f -exec grep -l "import.*feature_web" {} \; 2>/dev/null)

if [ -z "$WEB_IN_MOBILE" ]; then
    echo -e "${GREEN}✅ PASS: No web UI imports in mobile${NC}"
else
    echo -e "${RED}❌ FAIL: Found web UI imports in mobile:${NC}"
    echo "$WEB_IN_MOBILE"
fi

echo ""

# Check 3: Web-specific widgets exist
echo "3. Checking web-specific widgets exist..."
WEB_WIDGETS=(
    "lib/feature_web/widgets/web_company_logo.dart"
    "lib/feature_web/widgets/web_sale_slider.dart"
    "lib/feature_web/widgets/web_unit_card.dart"
    "lib/feature_web/widgets/web_compound_card.dart"
)

ALL_EXIST=true
for widget in "${WEB_WIDGETS[@]}"; do
    if [ -f "$widget" ]; then
        echo -e "${GREEN}✅ Found: $widget${NC}"
    else
        echo -e "${RED}❌ Missing: $widget${NC}"
        ALL_EXIST=false
    fi
done

echo ""

# Check 4: Web home screen uses web widgets
echo "4. Checking web home screen imports..."
WEB_HOME="lib/feature_web/home/presentation/web_home_screen.dart"

if grep -q "web_company_logo.dart" "$WEB_HOME" && grep -q "web_sale_slider.dart" "$WEB_HOME"; then
    echo -e "${GREEN}✅ PASS: Web home uses web-specific widgets${NC}"
else
    echo -e "${RED}❌ FAIL: Web home not using web widgets${NC}"
fi

echo ""

# Check 5: Animation files
echo "5. Checking animation implementations..."
ANIMATIONS=(
    "lib/feature/home/presentation/widget/company_name_scrol.dart"
    "lib/feature/home/presentation/profileScreen.dart"
)

for anim in "${ANIMATIONS[@]}"; do
    if [ -f "$anim" ]; then
        if grep -q "AnimationController" "$anim" && grep -q "HapticFeedback" "$anim"; then
            echo -e "${GREEN}✅ Animations implemented: $(basename $anim)${NC}"
        else
            echo -e "${YELLOW}⚠️  Animations may be incomplete: $(basename $anim)${NC}"
        fi
    else
        echo -e "${RED}❌ Missing animation file: $anim${NC}"
    fi
done

echo ""

# Check 6: Card UI updates
echo "6. Checking card UI updates..."
CARDS=(
    "lib/feature/compound/presentation/widget/unit_card.dart"
    "lib/feature_web/widgets/web_unit_card.dart"
    "lib/feature/home/presentation/widget/compunds_name.dart"
    "lib/feature_web/widgets/web_compound_card.dart"
)

for card in "${CARDS[@]}"; do
    if [ -f "$card" ]; then
        if grep -q "borderRadius.*24" "$card"; then
            echo -e "${GREEN}✅ Modern UI applied: $(basename $card)${NC}"
        else
            echo -e "${YELLOW}⚠️  May need UI update: $(basename $card)${NC}"
        fi
    else
        echo -e "${RED}❌ Missing card file: $card${NC}"
    fi
done

echo ""

# Check 7: Documentation files
echo "7. Checking documentation files..."
DOCS=(
    "MODERN_CARD_UI_UPDATE.md"
    "SCROLL_ANIMATIONS_COMPLETE.md"
    "TUTORIAL_FIX_SUMMARY.md"
    "WEB_MOBILE_SEPARATION_COMPLETE.md"
    "ALL_UPDATES_SUMMARY.md"
)

for doc in "${DOCS[@]}"; do
    if [ -f "$doc" ]; then
        echo -e "${GREEN}✅ Found: $doc${NC}"
    else
        echo -e "${YELLOW}⚠️  Missing: $doc${NC}"
    fi
done

echo ""
echo "=========================================="
echo "Verification Complete!"
echo "=========================================="
