part of daxe_server;

// From https://github.com/dart-lang/http_server/blob/master/test/http_multipart_test.dart

// Representation of a form field from a multipart/form-data form POST body.
class FormField {
  // Name of the form field specified in Content-Disposition.
  final String name;
  // Value of the form field. This is either a String or a List<int> depending
  // on the Content-Type.
  final value;
  // Content-Type of the form field.
  final String contentType;
  // Filename if specified in Content-Disposition.
  final String filename;

  FormField(String this.name,
            this.value,
            {String this.contentType,
             String this.filename});

  bool operator==(other) {
    if (value.length != other.value.length) return false;
    for (int i = 0; i < value.length; i++) {
      if (value[i] != other.value[i]) {
        return false;
      }
    }
    return name == other.name &&
           contentType == other.contentType &&
           filename == other.filename;
  }

  int get hashCode => name.hashCode;

  String toString() {
    return "FormField('$name', '$value', '$contentType', '$filename')";
  }
}
