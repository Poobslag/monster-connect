#!/bin/bash
################################################################################
# Analyzes code and assets for stylistic errors, correcting them or printing
# them to the console
#
# Usage:
#   delint.sh:
#     Analyze code for stylistic errors, printing them to the console
#   delint.sh -c, delint.sh --clean:
#     Correct simple errors which can be automatically corrected

# parse arguments
CLEAN=
if [ "$1" = "-c" ] || [ "$1" = "--clean" ]; then
  CLEAN=true
fi

# long lines
RESULT=""
# cannot split a string literal across multiple lines in bash; must use a variable
REGEX="\(^.\{120,\}$"
REGEX+="\|^"$'\t'"\{1\}.\{116,\}$"
REGEX+="\|^"$'\t'"\{2\}.\{112,\}$"
REGEX+="\|^"$'\t'"\{3\}.\{108,\}$"
REGEX+="\|^"$'\t'"\{4\}.\{104,\}$"
REGEX+="\|^"$'\t'"\{5\}.\{100,\}$\)"
RESULT="${RESULT}$(grep -R -n "$REGEX" --include="*.gd" project/src)"
if [ -n "$RESULT" ]; then
  echo ""
  echo "Long lines:"
  echo "$RESULT"
fi

# whitespace at the start of a line
RESULT=$(grep -R -n "^\\s* [^\\s]" --include="*.gd" project/src \
  )
if [ -n "$RESULT" ]; then
  echo ""
  echo "Whitespace at the start of a line:"
  echo "$RESULT"
fi

# whitespace at the end of a line
RESULT=$(grep -R -n "\\S\\s\\s*$" --include="*.gd" project/src)
if [ -n "$RESULT" ]; then
  echo ""
  echo "Whitespace at the end of a line:"
  echo "$RESULT"
  if [ "$CLEAN" ]; then
    # remove whitespace at the end of lines
    find project/src \( -name "*.gd" \) -exec sed -i "s/\(\\S\)\\s\\s*$/\1/g" {} +
    echo "...Whitespace removed."
  fi
fi

# blank gdshader lines
RESULT=$(grep -R -n "^\\s\\s*$" --include="*.gdshader" project/src)
if [ -n "$RESULT" ]; then
  echo ""
  echo "Blank lines in gdshader:"
  echo "$RESULT"
  if [ "$CLEAN" ]; then
    # remove whitespace at the end of gdshaders
    find project/src \( -name "*.gdshader" \) -exec sed -i "s/^\\s\\s*$//g" {} +
    echo "...Whitespace removed."
  fi
fi

# too many consecutive newlines
# shellcheck disable=SC2016
RESULT=$(find project/src -type f -name "*.gd" -print0 | xargs -0 awk '
FNR == 1 { blank_count = 0 }
/^$/ {
  blank_count++
  if (blank_count >= 3) {
    print FILENAME ":" FNR ":" $0
  }
  next
}
{ blank_count = 0 }
')
if [ -n "$RESULT" ]; then
  echo ""
  echo "Too many consecutive newlines:"
  echo "$RESULT"
fi

# comments with incorrect whitespace
REGEX="\(^##"$'\t'"\|## "$'\t\t\t'"\|^"$'\t\t'"*##\)"
RESULT=$(grep -R -n "$REGEX" --include="*.gd" project/src \
  | grep -v "save_data_upgrader\.gd.*## Method that performs the upgrade" \
  | grep -v "save_data_upgrader\.gd.*## Version that this method upgrades from" \
  | grep -v "save_data_upgrader\.gd.*## Version that this method upgrades to" \
  )
if [ -n "$RESULT" ]; then
  echo ""
  echo "Comments with incorrect whitespace:"
  echo "$RESULT"
fi

# comments with standalone '##' without [br]
# shellcheck disable=SC2016
RESULT=$(find project/src -type f -name "*.gd" -print0 | xargs -0 awk '
FNR == 1 { in_class = 0 }
/^(class_name|extends)/ { in_class = 1; next }
/^##$/ {
  if (!in_class) {
    print FILENAME ":" FNR ":" $0
  }
  next
}
/^(@export|var |func )/ { in_class = 0 }
' \
  | grep -v "project/src/main/nurikabe/fast/fast_solver\.gd.*$" \
  )
if [ -n "$RESULT" ]; then
  echo ""
  echo "Comments with standalone '##' without [br]:"
  echo "$RESULT"
fi

# illegal references to demo/test code
REGEX="\(src\/test\|src\/demo\|assets\/test\|assets\/demo\)"
RESULT=$(grep -R -n "$REGEX" --include="*.gd" --include="*.tscn" project/src/main \
  )
if [ -n "$RESULT" ]; then
  echo ""
  echo "Illegal references to demo/test code in main:"
  echo "$RESULT"
fi

# illegal references to demo/test code in project.godot
REGEX="\(src\/test\|src\/demo\|assets\/test\|assets\/demo\)"
RESULT=$(grep "$REGEX" project/project.godot \
  | grep -v '"res://assets/demo/": "yellow"' \
  | grep -v '"res://assets/test/": "orange"' \
  | grep -v '"res://src/demo/": "yellow"' \
  | grep -v '"res://src/test/": "orange"' \
  )
if [ -n "$RESULT" ]; then
  echo ""
  echo "Illegal references to demo/test code in project.godot:"
  echo "$RESULT"
fi

# malformed block comments
RESULT=$(grep -R -n "^#[^#]" --include="*.gd" project/src)
if [ -n "$RESULT" ]; then
  echo ""
  echo "Malformed block comments:"
  echo "$RESULT"
fi

# signal functions with bad capitalization
RESULT=$(grep -R -n "func _on_[A-Z]" --include="*.gd" project/src \
  )
if [ -n "$RESULT" ]; then
  echo ""
  echo "Signal functions with bad capitalization:"
  echo "$RESULT"
fi

# temporary files
RESULT=$(find project -name "*.TMP" -o -name "*.gd~" -o -name "*.tmp")
if [ -n "$RESULT" ]; then
  echo ""
  echo "Temporary files:"
  echo "$RESULT"
  if [ "$CLEAN" ]; then
    # remove temporary files
    find project \( -name "*.TMP" -o -name "*.gd~" -o -name "*.tmp" \) -exec rm {} +
    echo "...Temporary files deleted."
  fi
fi

# orphaned .import files
FILES=$(find project/assets -type f -iname "*.import")
if [ -n "$FILES" ]; then
  RESULT=()
  for FILE in $FILES; do
    # check for no file without the .import extension
    if ! [ -f "${FILE%.*}" ]; then
      RESULT+=("${FILE}")
    fi
  done

  if [ -n "${RESULT[*]}" ]; then
    echo ""
    echo "Orphaned .import files:"
    for FILE in "${RESULT[@]}"; do
      echo "${FILE}"
    done
    if [ "$CLEAN" ]; then
      for FILE in "${RESULT[@]}"; do
        rm "${FILE}"
      done
      echo "...Orphaned .import files deleted."
    fi
  fi
fi

# non-snake case filenames
RESULT=$(find project/src project/assets -type f ! -regex '.*/[a-z0-9_.]+')
if [ -n "$RESULT" ]; then
  echo ""
  echo "Non-snake case filenames:"
  echo "$RESULT"
fi

# project settings which are enabled temporarily, but shouldn't be pushed
RESULT=
RESULT=${RESULT}"Ê"$(grep "emulate_touch_from_mouse=true" project/project.godot)
RESULT=${RESULT}"Ê"$(grep "^window/size/test_width=" project/project.godot)
RESULT=${RESULT}"Ê"$(grep "^window/size/test_height=" project/project.godot)
RESULT=$(echo "${RESULT}" |
  sed 's/ÊÊÊ*/Ê/g' | # remove consecutive newline placeholders
  sed 's/^Ê\(.*\)$/\1/g' | # remove trailing newline placeholders
  sed 's/^\(.*\)Ê$/\1/g' | # remove following newline placeholders
  sed 's/Ê/\n/g') # convert newline placeholders to newlines
if [ -n "$RESULT" ]; then
  echo ""
  echo "Temporary project settings:"
  echo "$RESULT"
  if [ "$CLEAN" ]; then
    # unset project settings
    sed -i "/emulate_touch_from_mouse=true/d" project/project.godot
    sed -i "/^window\/size\/test_width=/d" project/project.godot
    sed -i "/^window\/size\/test_height=/d" project/project.godot
    echo "...Temporary settings reverted."
  fi
fi

# print statements that got left in by mistake
RESULT=$(git diff main -- **/*.gd | grep print\()
RESULT=${RESULT}"Ê"$(git diff main -- **/*.gd | grep print_debug\()
RESULT=$(echo "${RESULT}" |
  sed 's/ÊÊÊ*/Ê/g' | # remove consecutive newline placeholders
  sed 's/^Ê\(.*\)$/\1/g' | # remove trailing newline placeholders
  sed 's/^\(.*\)Ê$/\1/g' | # remove following newline placeholders
  sed 's/Ê/\n/g') # convert newline placeholders to newlines
if [ -n "$RESULT" ]; then
  echo ""
  echo "Print statements:"
  echo "$RESULT"
fi

# redundant 'range(0, x)' call
RESULT=$(grep -R -nP '[^_a-z]range\(0,\s*[^,)]*\)' --include="*.gd" project/src \
  )
if [ -n "$RESULT" ]; then
  echo ""
  echo "Redundant 'range(0, x)':"
  echo "$RESULT"
fi

# node names with spaces
RESULT=$(grep -R -n "node name=\"[^\"]* [^\"]*\"" --include="*.tscn" project/src)
if [ -n "$RESULT" ]; then
  echo ""
  echo "Node names with spaces:"
  echo "$RESULT"
fi

# arrays missing type hint
RESULT=$(grep -R -n "\(^[^#]*Array[^\[]\|:= \[\]\)" --include="*.gd" project/src \
  | grep -v "\(Array\]\|\[Array\)" \
  | grep -v "PackedVector2Array\|PackedStringArray\|PackedInt32Array" \
  )
if [ -n "$RESULT" ]; then
  echo ""
  echo "Arrays missing type hint:"
  echo "$RESULT"
fi

# for loops missing type hint
RESULT=$(grep -R -n "^\\s*for [A-Za-z][A-Za-z0-9]* in [A-Za-z0-9]" --include="*.gd" project/src \
  | grep -v "for [ixy] in " \
  )
if [ -n "$RESULT" ]; then
  echo ""
  echo "For loops missing type hint:"
  echo "$RESULT"
fi

# avoid := if type is not on same line
RESULT=$(grep -R -n " := " --include="*.gd" project/src \
  | grep -v " := -\?[0-9]" \
  | grep -v " := \(true\|false\)" \
  | grep -v " := \(\"\|'\|r\"\|&\"\|^\"\)" \
  | grep -v " := \(\[\|\{\)" \
  | grep -v " := \(Color\|Vector\|Vector2i\|PackedStringArray\)" \
  | grep -v " := [A-Z][A-Za-z0-9]*\.new()" \
  )
if [ -n "$RESULT" ]; then
  echo ""
  echo "':=' operator with ambiguous type:"
  echo "$RESULT"
fi
