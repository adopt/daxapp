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

library daxe_server;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http_server/http_server.dart';
import 'package:mime/mime.dart';

part 'form_field.dart';

final int port = 9473;
String daxeHtmlFilename;
// xdg-open is used to run the default browser
// other possible commands if this fails: sensible-browser (Debian/Ubuntu), open (MacOS)
// TODO: test on various platforms
final String browser = 'xdg-open';
String firstPath;
String key;
bool sessionSet = false;
VirtualDirectory vdir;

/**
 * Starts the server and open the web page, optionally with a file and config to open.
 */
void start(String filepath, String configName, String daxeHtmlPath) {
  daxeHtmlFilename = daxeHtmlPath;
  var rng = new Random();
  key = rng.nextInt((1<<32) - 1).toString();
  vdir = new VirtualDirectory('/')
    ..allowDirectoryListing = true
    ..directoryHandler = directoryHandler;
  HttpServer
      .bind(InternetAddress.LOOPBACK_IP_V4, port)
      .then((server) {
        server.listen((HttpRequest request) {
          handleRequest(request);
        });
        print("Server started.\n");
        startBrowser(filepath, configName);
      })
      .catchError((e) => print("Error starting the web server: " + e.toString()));
}

void directoryHandler(Directory dir, HttpRequest request) {
  HttpResponse response = request.response;
  String listing;
  try {
    listing = directoryListing(dir);
  } on FileSystemException catch(ex) {
    response.statusCode = HttpStatus.FORBIDDEN;
    response.write(ex.message);
    response.close();
    return;
  }
  listing = "<?xml version='1.0' encoding='UTF-8'?>\n" + listing;
  response.headers.contentType =
      new ContentType('text', 'xml', parameters: {'charset': 'utf-8'});
  response.headers.set(HttpHeaders.CACHE_CONTROL, 'no-cache');
  response.write(listing);
  response.close();
}

String directoryListing(Directory dir) {
  StringBuffer sb = new StringBuffer();
  List<String> pathnames = dir.path.split('/');
  if (pathnames.last == '')
    pathnames.removeLast();
  String name = pathnames.last;
  sb.write('<directory name="$name">\n');
  List<FileSystemEntity> list = dir.listSync(recursive: false, followLinks: false);
  for (FileSystemEntity entity in list) {
    FileStat stat = entity.statSync();
    // NOTE: FileSystemEntity.name is missing from the API !
    String name = entity.path.split('/').last;
    if (entity is Directory) {
      sb.write('<directory name="$name"/>\n');
    } else {
      sb.write('<file name="$name"');
      if (stat.size != null)
        sb.write(' size="${stat.size}"');
      if (stat.modified != null) {
        DateTime utc = stat.modified.toUtc();
        sb.write(' modified="${utc.toIso8601String()}"');
      }
      sb.write('/>\n');
    }
  }
  sb.write('</directory>\n');
  return sb.toString();
}

void startBrowser(String filepath, String configName) {
  Uri script_uri = Platform.script;
  List<String> segments;
  if (daxeHtmlFilename.startsWith('/')) {
    segments = new List<String>();
  } else {
    segments = new List<String>.from(script_uri.pathSegments);
    segments.insert(0, '');
    segments.removeLast();
  }
  segments.addAll(daxeHtmlFilename.split('/'));
  // normalize the path, Uri.normalizePath() is not available in 1.10
  for (int i=0; i<segments.length; i++) {
    if (i > 0 && segments[i] == '..') {
      segments.removeAt(i);
      segments.removeAt(i-1);
      i -= 2;
    }
  }
  String htmlPath = segments.join('/');
  firstPath = htmlPath;
  String url = 'http://localhost:$port' + htmlPath;
  if (filepath != null && configName != null)
    url += '?file=' + filepath + '&config=config/' + configName + '_config.xml';
  url += '&save=/save&application=true';
  Process.run(browser, [url]).then((ProcessResult results) {
    if (results.exitCode != 0) {
      print("Error launching the web browser: ${results.exitCode}\n");
      print(results.stderr);
    }
  });
}

void handleRequest(HttpRequest request) {
  switch (request.method) {
    case 'GET':
      handleGet(request);
      break;
    case 'POST':
      handlePost(request);
      break;
    default:
      request.response.statusCode = HttpStatus.METHOD_NOT_ALLOWED;
      request.response.close();
  }
}

void handleGet(HttpRequest request) {
  HttpResponse response = request.response;
  if (request.requestedUri.path == firstPath && !sessionSet) {
    Cookie cookie = new Cookie('daxe-key', key);
    cookie.path = '/';
    response.cookies.add(cookie);
  } else {
    if (!checkCookie(request)) {
      response.statusCode = HttpStatus.FORBIDDEN;
      response.write('Missing session cookie, sorry.');
      response.close();
      return;
    }
  }
  if (request.requestedUri.path == '/quit') {
    response.write('ok');
    response.close();
    print("Server stopped.");
    Timer.run(() => exit(0));
    return;
  }
  readFileRequest(request);
}

bool checkCookie(HttpRequest request) {
  bool foundCookie = false;
  for (Cookie cookie in request.cookies) {
    if (cookie.name == 'daxe-key' && cookie.value == key) {
      foundCookie = true;
      break;
    }
  }
  return foundCookie;
}

void readFileRequest(HttpRequest request) {
  request.response.headers.set(HttpHeaders.CACHE_CONTROL, 'no-cache');
  vdir.serveRequest(request);
}

Future handlePost(HttpRequest request) async {
  HttpResponse response = request.response;
  if (!checkCookie(request)) {
    response.statusCode = HttpStatus.FORBIDDEN;
    response.write('Missing session cookie, sorry.');
    response.close();
    return;
  }
  if (request.uri.path != '/save') {
    print('wrong POST URI: ' + request.uri.path);
    response.statusCode = HttpStatus.NOT_FOUND;
    response.close();
    return;
  }
  if (request.headers.contentType.parameters['boundary'] == null) {
    print('POST: missing boundary for multipart');
    response.statusCode = HttpStatus.METHOD_NOT_ALLOWED;
    response.close();
    return;
  }
  try {
    List<FormField> fields = await getFields(request);
    if (fields.length == 2 && fields[0].name == 'path' && fields[1].name == 'file') {
      File f = await saveFile(fields.first.value, fields[1].value);
    }
    response.write('ok');
    response.close();
  } catch (error) {
    response.write("error\n");
    response.write(error.toString());
    response.close();
  }
}

/**
 * Returns a list of fields, assuming they are UTF8 strings.
 */
Future<List<FormField>> getFields(HttpRequest request) async {
  // NOTE: it would be nice if we could use HttpMultipartFormData from http_server
  // to finish parsing the request after MimeMultipartTransformer,
  // but it only handles JSON data !
  // (I was hoping to be able to reuse some code from
  // https://github.com/dart-lang/http_server/blob/master/test/http_multipart_test.dart
  // )
  String boundary = request.headers.contentType.parameters['boundary'];
  Stream<MimeMultipart> partStream = await request.transform(
      new MimeMultipartTransformer(boundary));
  Stream<Future<FormField>> futureFieldStream = await partStream.map(convertPartToField);
  List<Future<FormField>> futureFieldList = await futureFieldStream.toList();
  List<FormField> fields = await Future.wait(futureFieldList);
  return fields;
}

Future<FormField> convertPartToField(MimeMultipart part) async {
  ContentType type;
  HeaderValue encoding;
  HeaderValue disposition;
  for (String key in part.headers.keys) {
    switch (key) {
      case 'content-type':
        type = ContentType.parse(part.headers[key]);
        break;
      
      case 'content-transfer-encoding':
        encoding = HeaderValue.parse(part.headers[key]);
        break;
      
      case 'content-disposition':
        disposition = HeaderValue.parse(part.headers[key],
                                        preserveBackslash: true);
        break;
    }
  }
  String name = disposition.parameters['name'];
  var data; // String or List<int>
  if (encoding == 'UTF-8' || encoding == 'UTF8' ||
      (type != null && type.charset != null && type.charset.toLowerCase() == 'utf-8') ||
      name == 'path') {
    // finding if it's a string is hard when sent by FormData !
    // FIXME: find a way to detect a string and remove "name == 'path'" above
    Stream<String> stream = part.transform(UTF8.decoder);
    data = await stream.join();
  } else {
    BytesBuilder builder = await part.fold(new BytesBuilder(), (builder, d) => builder..add(d));
    data = builder.takeBytes();
  }
  String contentType;
  if (type != null)
    contentType = type.mimeType;
  return new FormField(name, data, contentType:contentType,
    filename:disposition.parameters['filename']);
}

Future<File> saveFile(String filepath, content) async {
  File f = new File(filepath);
  if (content is String)
    return f.writeAsString(content);
  else if (content is List<int>)
    return f.writeAsBytes(content);
  else
    throw new Exception("File saving: wrong content type.");
}
