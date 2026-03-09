def feeds: ["A","B","C","D","E","F"];
def mapLetter($l):
  if $l == "E" then "M"
  elif $l == "F" then "N"
  else $l end;

def slug($l): ("feed_" + ($l|ascii_downcase));
def pageKey($l): ("pages/" + slug($l));

def newLayoutId: "custom_feed_props_single_area";
def layoutKey: ("layouts/" + newLayoutId);

# A single scrolling area layout
def ensureLayout:
  . + {
    (layoutKey): {
      "definition": {
        "literal": {
          "componentName": "Grid",
          "props": {
            "gridTemplateColumns": "1fr",
            "gridTemplateRows": "1fr",
            "gridTemplateAreas": "\"area-a\""
          },
          "items": [
            {
              "componentName": "WidgetArea",
              "props": {
                "gridArea": "area-a",
                "name": "Area A",
                "gridAutoFlow": "row"
              }
            }
          ]
        }
      },
      "displayName": { "literal": "Feed Properties" }
    }
  };

def isHeader($s): ($s|test("^\".*\"$"));
def unquote($s): ($s|sub("^\"";"")|sub("\"$";""));
def isBlank($s): ($s == "\"\"" or $s == "");

# Map identifiers from Feed A to other feeds
# - FAxxx -> FBxxx / FCxxx / ... and E->M, F->N
# - FEED_A_TYPE -> FEED_B_TYPE etc.
def mapIdent($id; $feed):
  ($feed | mapLetter) as $to
  | ($id
      | gsub("FEED_A_TYPE"; ("FEED_" + $to + "_TYPE"))
      | gsub("FEEDA_TYPE"; ("FEED" + $to + "_TYPE"))
      | gsub("\\bFA([A-Z0-9_]+)\\b"; ("F" + $to + "\\1"))
    );

def widgetKey($feed; $name): ("widgets/" + $feed + "_" + $name);

# Build widgets + bindings preserving order
def addFeed($feed; $lines):
  . as $root
  | (
      $lines
      | to_entries
      | map(
          .key as $i
          | .value as $raw
          | if isBlank($raw) then
              { kind: "blank", i: $i }
            elif isHeader($raw) then
              { kind: "header", i: $i, text: unquote($raw) }
            else
              { kind: "scalar", i: $i, id: mapIdent($raw; $feed), name: $raw }
            end
        )
    ) as $items
  | (
      $items
      | map(select(.kind != "blank"))
      | to_entries
      | map(
          .key as $pos
          | .value as $it
          | {
              widgetUri:
                (if $it.kind=="scalar" then
                   ($feed + "_" + ($it.id))
                 else
                   ($feed + "_Header_" + ($pos|tostring))
                 end),
              gridArea: "area-a",
              dndId:
                ("area-a" +
                 (if $it.kind=="scalar" then ($feed + "_" + ($it.id)) else ($feed + "_Header_" + ($pos|tostring)) end)
                 + ($pos|tostring))
            }
        )
    ) as $bindings
  | (
      $items
      | map(select(.kind != "blank"))
      | to_entries
      | map(
          .key as $pos
          | .value as $it
          | if $it.kind=="scalar" then
              {
                uri: ($feed + "_" + ($it.id)),
                layoutInfo: { width: "1", height: "1" }
              }
            else
              {
                uri: ($feed + "_Header_" + ($pos|tostring)),
                layoutInfo: { width: "1", height: "1" }
              }
            end
        )
    ) as $widgets
  | (
      # widgets objects to add
      reduce ($items | map(select(.kind != "blank")) | to_entries[]) as $e ({};
        ($e.value) as $it
        | ($e.key) as $pos
        | if $it.kind=="scalar" then
            . + {
              (widgetKey($feed; $it.id)): {
                "aimms.widget.type": { "literal": "scalar" },
                "contents": { "aimms": { "contents": [ $it.id ] } },
                "name": { "literal": ($feed + "_" + $it.id) },
                "views": { "literal": {} }
              }
            }
          else
            . + {
              (("widgets/" + $feed + "_Header_" + ($pos|tostring))): {
                "aimms.widget.type": { "literal": "label" },
                "contents": { "literal": $it.text },
                "name": { "literal": ($feed + "_Header_" + ($pos|tostring)) }
              }
            }
          end
      )
    ) as $newWidgets
  | $root
    + $newWidgets
    + {
        (pageKey($feed)): {
          "aimms.widget.type": { "literal": "pagev2-grid" },
          "layoutId": { "literal": newLayoutId },
          "bindings": { "literal": $bindings },
          "widgets": { "literal": $widgets }
        }
      };

# Add nav links under Front Page II children
def addNavPages:
  . as $root
  | (["application","pages","literal","children",0,"children",0,"children"]) as $kidsPath
  | ($root | getpath($kidsPath)) as $kids
  | ($kids
     + (feeds | map({
         "name": ("Feed " + .),
         "type": "pagev2-grid",
         "slug": slug(.),
         "children": []
       }))
    ) as $newKids
  | $root | setpath($kidsPath; $newKids);

# Entry point: $lines comes from --slurpfile
. as $root
| ensureLayout
| reduce feeds[] as $f
    (.;
      addFeed($f; $lines[0])
    )
| addNavPages