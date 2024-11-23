import 'dart:convert';
import 'dart:developer';

import 'package:json_annotation/json_annotation.dart';
import 'package:sup_gen_model/extensions/string_extension.dart';
import 'dart:io';

@JsonSerializable(fieldRename: FieldRename.snake)
class TableModel {
  final String name;
  final List<TableProperty> properties;
  TableModel({required this.name, required this.properties});

  bool get hasValidName => isValidDartClassName(name);
  String get className => snakeToPascalCase(name);
  factory TableModel.fromJson(Map<String, dynamic> json) {
    // final ex= Map<String,dynamic>.from("json");
    return TableModel(
      name: json['name'],
      properties: json['properties'],
    );
  }
  String get fromJsonFunction {
    final buffer = StringBuffer();
    buffer.writeln("factory $className.fromJson(Map<String, dynamic> json) {");
    buffer.writeln("return $className(");

    for (var element in properties) {
      if (element.type == 'json' || element.type == 'jsonb') {
        final command = '''
jsonDecode(json['${element.name}'].toString()) as Map<String, dynamic>
''';
        buffer.writeln(
            "${element.dartName}: json['${element.name}'] != null ? $command: null,");
      } else {
        buffer.writeln("${element.dartName}: json['${element.name}'],");
      }
    }
    buffer.writeln("}");
    return buffer.toString();
  }

  Map<String, dynamic> toJson(dynamic data) {
    final mapped = jsonDecode(data.toString()) as Map<String, dynamic>;
    return mapped;
  }
}

@JsonSerializable(fieldRename: FieldRename.snake)
class TableProperty {
  final String name;
  final String type;
  final bool isNullable;
  final bool isPrimaryKey;
  final bool isAutoIncrement;

  TableProperty({
    required this.name,
    required this.type,
    required this.isNullable,
    required this.isPrimaryKey,
    required this.isAutoIncrement,
  });

  String get dartName => snakeToCamelCase(name);
  String get dartType => _dartType;
  String get _dartType {
    switch (type) {
      case 'integer' ||
            'int4' ||
            'int' ||
            'int2' ||
            'int8' ||
            'bigint' ||
            'smallint' ||
            'serial' ||
            'bigserial':
        return 'int';

      case 'numeric':
        return 'num';
      case 'boolean' || 'bool':
        return 'bool';
      case '_numeric':
        return 'List<num>';
      case 'text' ||
            'uuid' ||
            'character varying' ||
            'varchar' ||
            'timestamp' ||
            'timestamptz' ||
            'date':
        return 'String';
      case 'json':
        return 'Map<String, dynamic>';
      case 'jsonb':
        return 'Map<String, dynamic>';
      default:
        log(type);
        stdout.writeln('Unknown type: $type');
        return snakeToPascalCase(type);
    }
  }

  String get field {
    return "final $dartType${isNullable ? "?" : ""} $dartName;";
  }
}

class EnumModel {
  final String name;
  final List<String> values;
  EnumModel({required this.name, required this.values});

  String get namePascalCase {
    final pascalCase =
        snakeToPascalCase(name.replaceAll('"', '').replaceAll(" ", "_"));
    return pascalCase[0].toUpperCase() + pascalCase.substring(1);
  }

  List<String> get dartValues => values.map((e) {
        final pascalCase =
            snakeToPascalCase(e.replaceAll('"', '').replaceAll(" ", "_"));
        final result = pascalCase[0].toUpperCase() + pascalCase.substring(1);
        return result;
      }).toList();
}
