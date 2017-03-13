/*
  This file is part of Daxe.

  Daxe is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  Daxe is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with Daxe.  If not, see <http://www.gnu.org/licenses/>.
*/

import 'dart:io';
import 'package:daxe_server/daxe_server.dart' as daxe_server;

/**
 * Arguments: XML file path, Config name.
 */
main(List<String> args) {
  if (args != null && args.length == 1)
    daxe_server.start(filepath:args[0]);
  else if (args != null && args.length == 2 && args[0] == '-config')
    daxe_server.start(configName:args[1]);
  else if (args != null && args.length == 3 && args[0] == '-config')
    daxe_server.start(configName:args[1], filepath:args[2]);
  else {
    stderr.writeln("Usage: dart main.dart [-config config_name] [file.xml]\n");
    exitCode = 2;
  }
}
