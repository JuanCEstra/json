def feeds: ["A","B","C","D","E","F"];
def mapLetter($l):
  if $l == "E" then "M"
  elif $l == "F" then "N"
  else $l end;

def slug($l): ("feed_" + ($l|ascii_downcase));
def pageKey($l): ("pages/" + slug($l));

def newLayoutId: "custom_feed_props_single_area";
def layoutKey: ("layouts/" + newLayoutId);

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

def mapIdent($id; $feed):
  (mapLetter($feed)) as $to
  | ($id
      | gsub("FEED_A_TYPE"; ("FEED_" + $to + "_TYPE"))
      | gsub("FEEDA_TYPE"; ("FEED" + $to + "_TYPE"))
      | sub("^FA"; ("F" + $to))
    );

# Turn the raw lines into grouped sections based on headers:
# returns array like: [{title:"Riser 1", ids:["FDAFR",...]}, ...]
# Build grouped sections based on header lines.
# Output: [{title:"Riser 1", ids:[...]}, ...]
def toGroups($lines; $feed):
  reduce $lines[] as $line
    (
      { curTitle: null, groups: [] };
      if isBlank($line) then
        .
      elif isHeader($line) then
        .curTitle = unquote($line)
      else
        (mapIdent($line; $feed)) as $id
        | if .curTitle == null then
            .curTitle = ("Feed " + $feed)
            | .groups += [{ title: .curTitle, ids: [$id] }]
          else
            .curTitle as $t
            | ( .groups | map(.title) | index($t) ) as $idx
            | if $idx == null then
                .groups += [{ title: $t, ids: [$id] }]
              else
                .groups[$idx].ids += [$id]
              end
          end
      end
    )
  | .groups;def widgetNameGroup($feed; $i): ("Feed_" + $feed + "_Group_" + ($i|tostring));
def widgetKeyGroup($feed; $i): ("widgets/" + widgetNameGroup($feed; $i));

def addFeed($feed; $lines):
  . as $root
  | (toGroups($lines; $feed)) as $groups
  | (
      $groups
      | to_entries
      | map({
          widgetUri: widgetNameGroup($feed; .key),
          gridArea: "area-a",
          dndId: ("area-a" + widgetNameGroup($feed; .key) + (.key|tostring))
        })
    ) as $bindings
  | (
      $groups
      | to_entries
      | map({
          uri: widgetNameGroup($feed; .key),
          layoutInfo: { width:"1", height:"1" }
        })
    ) as $widgets
  | (
      reduce ($groups|to_entries[]) as $g ({};
        . + {
          (widgetKeyGroup($feed; $g.key)): {
            "aimms.widget.type": { "literal": "scalar" },
            "name": { "literal": widgetNameGroup($feed; $g.key) },
            "title": { "literal": $g.value.title },
            "contents.labels.visible": { "literal": 1 },
            "contents": { "aimms": { "contents": $g.value.ids } },
            "views": { "literal": {} }
          }
        }
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

def addNavPages:
  . as $root
  | (["application","pages","literal","children",0,"children",0,"children"]) as $kidsPath
  | ($root | getpath($kidsPath)) as $kids
  | ($kids + (feeds | map({
      "name": ("Feed " + .),
      "type": "pagev2-grid",
      "slug": slug(.),
      "children": []
    }))) as $newKids
  | $root | setpath($kidsPath; $newKids);

. as $root
| ensureLayout
| reduce feeds[] as $f
    (.;
      addFeed($f; $lines[0])
    )
| addNavPages