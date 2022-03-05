import 'dart:convert';
import 'dart:io';

String getVersion() {
  var proc = Process.runSync('rust-analyzer', ['--version']);

  var ret = proc.stdout as String;
  ret = ret.substring(0, ret.length - 1);

  return ret;
}

void main() async {
  var proc = Process.runSync('rust-analyzer', ['--print-config-schema']);

  Map<String, dynamic> decoded = jsonDecode(proc.stdout);

  String md = "**Possible rust-analyzer settings (${getVersion()})**  \n";
  md += "```lua\n";
  md += "-- example opts  \n";
  md += "local opts = {  \n";
  md += "  -- other configurations  \n";
  md += "  server = {\n";
  md += "    settings = {\n";
  md += "      ['rust-analyzer'] {\n";
  md += "        cargo = {\n";
  md += "          autoReload = true\n";
  md += "        }\n";
  md += "      }\n";
  md += "    }\n";
  md += "  }\n";
  md += "}\n";
  md += "```\n";
  md += "\n---\n";

  decoded.forEach((key, value) {
    var type = value["type"];
    var typeList = [];
    var defaultValue = value["default"];
    String desc = value["markdownDescription"];

    String titleMD = "**`$key`**: ";

    if (type is List) {
      typeList = type;
    } else {
      typeList.add(type);
    }

    for (var t in typeList) {
      titleMD += "`$t`, ";
    }

    String defaultMD = "**Default**: `$defaultValue`";
    String descriptionMD = "**Description**: " + desc;

    md += titleMD + "  \n";
    md += defaultMD + "  \n";
    md += descriptionMD + "  \n";
    if (typeList.contains("string")) {
      md += getStringExtra(value);
    }
    md += "\n---\n";
  });

  File fmd = File('output.md');
  fmd.writeAsString(md);
}

String getStringExtra(dynamic value) {
  var enums = value['enum'];
  if (enums == null) {
    return "";
  }
  List<dynamic> enumDescriptions = value['enumDescriptions'];

  String ret = "**Possible Values**\n";

  int i = 0;
  for (var en in enums) {
    ret += "- **$en**: ${enumDescriptions[i]}\n";
    i++;
  }

  return ret;
}
