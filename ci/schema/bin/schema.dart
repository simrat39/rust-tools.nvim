import 'dart:convert';
import 'dart:io';

void main() async {
  var proc = Process.runSync('rust-analyzer', ['--print-config-schema']);

  Map<String, dynamic> decoded = jsonDecode(proc.stdout);

  String md = "**Possible rust-analyzer settings**  \n";
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
    var defaultValue = value["default"];
    String desc = value["markdownDescription"];

    String titleMD = "**`$key`**: ";

    if (type is List) {
      for (var t in type) {
        titleMD += "`$t`, ";
      }
    } else {
      titleMD += "`$type`";
    }

    String defaultMD = "**Default**: `$defaultValue`";
    String descriptionMD = "**Description**: " + desc;

    md += titleMD + "  \n";
    md += defaultMD + "  \n";
    md += descriptionMD + "  \n";
    md += "\n---\n";
  });

  File fmd = File('output.md');
  fmd.writeAsString(md);
}
