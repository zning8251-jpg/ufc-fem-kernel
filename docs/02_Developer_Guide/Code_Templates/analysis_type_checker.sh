#!/bin/bash
#===============================================================================
# Script: analysis_type_checker.sh
# Purpose: CI/CD gate rule for analysis type constraint validation
# 
# Checks:
#   1. PROC_ID values in valid range [1,91]
#   2. PROC_ID → Group mapping consistency
#   3. Material families allowed per group
#   4. Element types allowed per group
#   5. No duplicate analysis types in model
#
# Integration: Add to .pre-commit-config.yaml or GitLab CI/CD pipeline
#===============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/../../.."
UFC_CORE="${ROOT_DIR}/UFC/ufc_core"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
ERRORS=0
WARNINGS=0

echo "=================================================================="
echo "Analysis Type Constraint Checker"
echo "=================================================================="

#=============================================================================
# RULE 1: Check PROC_ID range [1,91]
#=============================================================================
echo ""
echo "Rule 1: Validating PROC_ID range [1,91]..."

PROC_FILES=$(find "${UFC_CORE}" -name "*.f90" -type f 2>/dev/null || true)
PROC_COUNT=0

while IFS= read -r file; do
    while IFS= read -r line; do
        # Match patterns like "analysis_proc = N" or "PROC_ID = N"
        if [[ $line =~ analysis_proc[[:space:]]*=[[:space:]]*([0-9]+) ]]; then
            PROC_ID="${BASH_REMATCH[1]}"
            if (( PROC_ID < 1 || PROC_ID > 91 )); then
                echo -e "${RED}✗ INVALID PROC_ID${NC}: $PROC_ID in file: $file"
                echo "  Line: $line"
                ((ERRORS++))
            else
                ((PROC_COUNT++))
            fi
        fi
    done < "$file"
done <<< "$PROC_FILES"

if [ $PROC_COUNT -gt 0 ]; then
    echo -e "${GREEN}✓ PROC_ID range check passed${NC}: $PROC_COUNT valid IDs found"
fi

#=============================================================================
# RULE 2: Check Group assignment (PROC_ID → Group mapping)
#=============================================================================
echo ""
echo "Rule 2: Validating PROC_ID → Group mapping..."

# PROC to Group mapping (from MD_Analysis_GroupAware_Desc)
declare -A PROC_TO_GROUP=(
    [1]=1  [2]=1  [11]=1  [12]=1  [21]=1  [22]=1  [23]=1  [24]=1  [29]=1  # G1
    [31]=2  # G2
    [25]=3  [27]=3  [28]=3  [62]=3  # G3
    [81]=4  # G4
    [71]=5  # G5
    [32]=6  [34]=6  # G6
    [33]=7  [35]=7  [51]=7  # G7
    [41]=8  [42]=8  # G8
    [43]=9  [44]=9  [61]=9  [91]=9  [95]=9  # G9
)

GROUP_COUNT=0

while IFS= read -r file; do
    while IFS= read -r line; do
        if [[ $line =~ analysis_proc[[:space:]]*=[[:space:]]*([0-9]+) ]]; then
            PROC_ID="${BASH_REMATCH[1]}"
            
            if [[ -n "${PROC_TO_GROUP[$PROC_ID]}" ]]; then
                ((GROUP_COUNT++))
            else
                # PROC_ID valid but not in mapping → warning
                echo -e "${YELLOW}⚠ WARNING${NC}: PROC_ID $PROC_ID has no Group mapping"
                ((WARNINGS++))
            fi
        fi
    done < "$file"
done <<< "$PROC_FILES"

if [ $GROUP_COUNT -gt 0 ]; then
    echo -e "${GREEN}✓ Group mapping check passed${NC}: $GROUP_COUNT valid mappings"
fi

#=============================================================================
# RULE 3: Check Material Family Constraints
#=============================================================================
echo ""
echo "Rule 3: Validating Material Family constraints..."

# Material family to Group constraints (simplified check)
# Group 1 (G1) allows families 01-08
# Group 2 (G2) allows family 09
# etc.

MAT_ISSUES=0

while IFS= read -r file; do
    if grep -q "group_id\s*=\s*1" "$file" 2>/dev/null; then
        # G1 files should NOT contain family 09,10,11 materials
        if grep -q "THERMAL\|ACOUSTIC\|ELECTROMAGNETIC" "$file" 2>/dev/null; then
            echo -e "${RED}✗ CONSTRAINT VIOLATION${NC}: G1 analysis contains non-mechanical materials"
            echo "  File: $file"
            ((ERRORS++))
            ((MAT_ISSUES++))
        fi
    fi
done <<< "$PROC_FILES"

if [ $MAT_ISSUES -eq 0 ]; then
    echo -e "${GREEN}✓ Material family constraints check passed${NC}"
fi

#=============================================================================
# RULE 4: Check Element Type Constraints
#=============================================================================
echo ""
echo "Rule 4: Validating Element Type constraints..."

ELEM_ISSUES=0

while IFS= read -r file; do
    if grep -q "group_id\s*=\s*4" "$file" 2>/dev/null; then
        # G4 (Acoustic) should only contain AC elements
        if grep -q "C3D\|CPS\|CAX\|B\|T\|DC\|EM" "$file" 2>/dev/null; then
            echo -e "${YELLOW}⚠ WARNING${NC}: G4 (Acoustic) contains non-acoustic elements"
            echo "  File: $file"
            ((WARNINGS++))
            ((ELEM_ISSUES++))
        fi
    fi
done <<< "$PROC_FILES"

if [ $ELEM_ISSUES -eq 0 ]; then
    echo -e "${GREEN}✓ Element type constraints check passed${NC}"
fi

#=============================================================================
# RULE 5: Check for Duplicate Analysis Types
#=============================================================================
echo ""
echo "Rule 5: Checking for duplicate analysis type definitions..."

DUPLICATE_COUNT=0

# Check for duplicate PROC_ID assignments in same file
while IFS= read -r file; do
    PROC_IDS=$(grep -oP "analysis_proc\s*=\s*\K[0-9]+" "$file" 2>/dev/null || true)
    if [ -n "$PROC_IDS" ]; then
        DUPES=$(echo "$PROC_IDS" | sort | uniq -d)
        if [ -n "$DUPES" ]; then
            echo -e "${YELLOW}⚠ WARNING${NC}: Duplicate PROC_IDs in $file: $DUPES"
            ((WARNINGS++))
            ((DUPLICATE_COUNT++))
        fi
    fi
done <<< "$PROC_FILES"

if [ $DUPLICATE_COUNT -eq 0 ]; then
    echo -e "${GREEN}✓ No duplicate analysis types found${NC}"
fi

#=============================================================================
# SUMMARY
#=============================================================================
echo ""
echo "=================================================================="
echo "Summary:"
echo "  Errors:   $ERRORS"
echo "  Warnings: $WARNINGS"
echo "  PROC_IDs validated: $PROC_COUNT"
echo "  Group mappings validated: $GROUP_COUNT"
echo "=================================================================="

if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}FAILED: Constraint violations detected${NC}"
    exit 1
elif [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}PASSED (with warnings)${NC}"
    exit 0
else
    echo -e "${GREEN}PASSED: All constraints satisfied${NC}"
    exit 0
fi
