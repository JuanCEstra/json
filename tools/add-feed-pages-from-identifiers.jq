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

def widgetKeyScalar($feed; $id): ("widgets/" + $feed + "_" + $id);
def widgetKeyHeader($feed; $pos): ("widgets/" + $feed + "_Header_" + ($pos|tostring));

def addFeed($feed; $lines):
  . as $root
  | (
      $lines
      | map(if isBlank(.) then {kind:"blank"}
            elif isHeader(.) then {kind:"header", text: unquote(.)}
            else {kind:"scalar", id: mapIdent(.; $feed)}
            end)
      | map(select(.kind!="blank"))
    ) as $items
  | (
      $items
      | to_entries
      | map({
          widgetUri:
            (if .value.kind=="scalar" then ($feed + "_" + .value.id)
             else ($feed + "_Header_" + (.key|tostring))
             end),
          gridArea: "area-a",
          dndId:
            ("area-a" +
             (if .value.kind=="scalar" then ($feed + "_" + .value.id)
              else ($feed + "_Header_" + (.key|tostring))
              end)
             + (.key|tostring))
        })
    ) as $bindings
  | (
      $items
      | to_entries
      | map(
          if .value.kind=="scalar" then
            { uri: ($feed + "_" + .value.id), layoutInfo: { width:"1", height:"3" } }
          else
            { uri: ($feed + "_Header_" + (.key|tostring)), layoutInfo: { width:"1", height:"3" } }
          end
        )
    ) as $widgets
  | (
      reduce ($items|to_entries[]) as $e ({};
        if $e.value.kind=="scalar" then
          . + {
            (widgetKeyScalar($feed; $e.value.id)): {
              "aimms.widget.type": { "literal": "scalar" },
              "contents": { "aimms": { "contents": [ $e.value.id ] } },
              "name": { "literal": ($feed + "_" + $e.value.id) },
              "title": { "literal": $e.value.id },
              "contents.labels.visible": { "literal": 1 },
              "views": { "literal": {} }
            }
          }
        else
          . + {
            (widgetKeyHeader($feed; $e.key)): {
              "aimms.widget.type": { "literal": "label" },
              "contents": { "literal": $e.value.text },
              "name": { "literal": ($feed + "_Header_" + ($e.key|tostring)) }
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