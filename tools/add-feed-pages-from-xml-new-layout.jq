def feeds: ["A","B","C","D","E","F"];

def slug($l): ("feed_" + ($l|ascii_downcase));
def pageKey($l): ("pages/" + slug($l));
def widgetName($l): ("Feed_" + $l + "_XML");
def widgetKey($l): ("widgets/" + widgetName($l));

def newLayoutId: "custom_feed_props_single_area";
def layoutKey: ("layouts/" + newLayoutId);

def xmlFor($l; $xml): ($xml[0][$l]);

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
      "displayName": { "literal": "Feed Properties (XML)" }
    }
  };

def addWidgetsAndPages($xml):
  . as $root
  | reduce feeds[] as $l
      (.;
        . + {
          (widgetKey($l)): {
            "aimms.widget.type": { "literal": "text" },
            "name": { "literal": widgetName($l) },
            "local.ui.editable": { "literal": 0 },
            "contents": { "literal": xmlFor($l; $xml) }
          },
          (pageKey($l)): {
            "aimms.widget.type": { "literal": "pagev2-grid" },
            "layoutId": { "literal": newLayoutId },
            "bindings": {
              "literal": [
                {
                  "widgetUri": widgetName($l),
                  "gridArea": "area-a",
                  "dndId": ("area-a" + widgetName($l) + "0")
                }
              ]
            },
            "widgets": {
              "literal": [
                {
                  "uri": widgetName($l),
                  "layoutInfo": { "width": "1", "height": "1" }
                }
              ]
            }
          }
        }
      );

. 
| ensureLayout
| addWidgetsAndPages($xml)
| addNavPages