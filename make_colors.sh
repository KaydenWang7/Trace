#!/bin/bash
ASSETS="Trace/Assets.xcassets"

make_color() {
    NAME=$1
    LR=$2; LG=$3; LB=$4
    DR=$5; DG=$6; DB=$7

    DIR="$ASSETS/$NAME.colorset"
    mkdir -p "$DIR"
    cat << JSON > "$DIR/Contents.json"
{
  "colors" : [
    {
      "idiom" : "universal",
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "red" : "$LR",
          "green" : "$LG",
          "blue" : "$LB",
          "alpha" : "1.000"
        }
      }
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "dark"
        }
      ],
      "idiom" : "universal",
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "red" : "$DR",
          "green" : "$DG",
          "blue" : "$DB",
          "alpha" : "1.000"
        }
      }
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
JSON
}

# Mint: Logo is (184, 227, 208) -> (0.72, 0.89, 0.82)
# Light mode: darker for contrast (0.45, 0.75, 0.62)
make_color "TraceMint" "0.45" "0.75" "0.62" "0.72" "0.89" "0.82"

# Peach: Logo is (254, 168, 141) -> (0.99, 0.66, 0.55)
# Light mode: darker for contrast (0.85, 0.45, 0.35)
make_color "TracePeach" "0.85" "0.45" "0.35" "0.99" "0.66" "0.55"

# Lavender: Logo is (212, 154, 213) -> (0.83, 0.60, 0.83)
# Light mode: darker for contrast (0.65, 0.45, 0.70)
make_color "TraceLavender" "0.65" "0.45" "0.70" "0.83" "0.60" "0.83"

