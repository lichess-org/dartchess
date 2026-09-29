// Generates `lib/src/zobrist_tables.dart` from shakmaty's `zobrist.rs`.
//
// The Zobrist masks are transcribed from shakmaty (https://github.com/niklasf/shakmaty),
// whose 128 bit literals carry the Polyglot compatible value in their low 64
// bits. Only that low half is kept here.
//
// Usage:
//   dart run tool/generate_zobrist_tables.dart <path/to/shakmaty/src/zobrist.rs>

import 'dart:io';

/// Roles in shakmaty's `ByRole` declaration order.
const _rustRoles = ['pawn', 'knight', 'bishop', 'rook', 'queen', 'king'];

/// Roles in dartchess `Role.index` order.
const _dartRoles = ['pawn', 'knight', 'bishop', 'rook', 'king', 'queen'];

/// Sides in dartchess `Side.index` order.
const _dartSides = ['white', 'black'];

/// Castling sides in dartchess `CastlingSide.index` order.
const _dartCastlingSides = ['queen', 'king'];

void main(List<String> args) {
  if (args.length != 1) {
    throw ArgumentError(
        'Usage: dart run tool/generate_zobrist_tables.dart <path/to/shakmaty/src/zobrist.rs>');
  }
  final source = File(args.single);
  if (!source.existsSync()) {
    throw ArgumentError.value(args.single, 'source', 'No such file');
  }
  final cursor = _Cursor(source.readAsLinesSync());

  // Piece masks: ByColor<ByRole<[u128; 64]>>.
  final pieces = <String, List<int>>{};
  cursor.seek('static PIECE_MASKS');
  for (final side in ['black', 'white']) {
    cursor.seek('$side: ByRole {');
    for (final role in _rustRoles) {
      cursor.seek('$role: [');
      pieces['$side.$role'] = cursor.take(64);
    }
  }

  cursor.seek('fn zobrist_for_white_turn');
  final whiteTurn = cursor.take(1).single;

  // Castling right masks: ByColor<ByCastlingSide<u128>>.
  final castling = <String, int>{};
  cursor.seek('static CASTLING_RIGHT_MASKS');
  for (final side in ['black', 'white']) {
    cursor.seek('$side: ByCastlingSide {');
    for (final castlingSide in ['king', 'queen']) {
      cursor.seek('${castlingSide}_side:');
      castling['$side.$castlingSide'] = cursor.takeHere();
    }
  }

  cursor.seek('static EN_PASSANT_FILE_MASKS');
  final enPassant = cursor.take(8);

  // Remaining checks masks: ByColor<[u128; 2]>.
  final remainingChecks = <String, List<int>>{};
  cursor.seek('static REMAINING_CHECKS_MASKS');
  for (final side in ['black', 'white']) {
    cursor.seek('$side: [');
    remainingChecks[side] = cursor.take(2);
  }

  cursor.seek('static PROMOTED_MASKS');
  final promoted = cursor.take(64);

  // Pocket masks: ByColor<ByRole<[u128; 7]>>.
  final pockets = <String, List<int>>{};
  cursor.seek('static POCKET_MASKS');
  for (final side in ['black', 'white']) {
    cursor.seek('$side: ByRole {');
    for (final role in _rustRoles) {
      cursor.seek('$role: [');
      pockets['$side.$role'] = cursor.take(7);
    }
  }

  final buffer = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND')
    ..writeln('//')
    ..writeln('// Regenerate with:')
    ..writeln(
        '//   dart run tool/generate_zobrist_tables.dart <path/to/shakmaty/src/zobrist.rs>')
    ..writeln('//')
    ..writeln(
        '// Zobrist masks transcribed from shakmaty (low 64 bits of its 128 bit')
    ..writeln(
        '// literals), which are Polyglot compatible for the standard chess part.')
    ..writeln()
    ..writeln("import 'models.dart';")
    ..writeln();

  _writeBySideByRole(
    buffer,
    name: 'pieceMasks',
    doc: 'Piece masks, indexed by side, role and square.',
    values: pieces,
  );

  _writeList(
    buffer,
    name: 'promotedMasks',
    doc: 'Masks for pieces known to be promoted, indexed by square.',
    values: promoted,
  );

  buffer
    ..writeln('/// Castling right masks, indexed by side and castling side.')
    ..writeln('const BySide<ByCastlingSide<int>> castlingRightMasks = {');
  for (final side in _dartSides) {
    buffer.writeln('  Side.$side: {');
    for (final castlingSide in _dartCastlingSides) {
      buffer.writeln(
          '    CastlingSide.$castlingSide: ${_hex(castling['$side.$castlingSide']!)},');
    }
    buffer.writeln('  },');
  }
  buffer
    ..writeln('};')
    ..writeln();

  _writeList(
    buffer,
    name: 'enPassantFileMasks',
    doc: 'En passant masks, indexed by file.',
    values: enPassant,
  );

  buffer
    ..writeln('/// Remaining checks masks, indexed by side, then by bit of the')
    ..writeln('/// number of checks already given.')
    ..writeln('const BySide<List<int>> remainingChecksMasks = {');
  for (final side in _dartSides) {
    buffer
      ..writeln('  Side.$side: [')
      ..writeln('    ${remainingChecks[side]!.map(_hex).join(', ')},')
      ..writeln('  ],');
  }
  buffer
    ..writeln('};')
    ..writeln();

  _writeBySideByRole(
    buffer,
    name: 'pocketMasks',
    doc: 'Pocket masks, indexed by side, role, then by bit of the number of '
        'pieces.',
    values: pockets,
  );

  buffer
    ..writeln('/// Mask for the white side to move.')
    ..writeln('const int whiteTurnMask = ${_hex(whiteTurn)};');

  File('lib/src/zobrist_tables.dart').writeAsStringSync(buffer.toString());
  stdout.writeln('Wrote lib/src/zobrist_tables.dart');
}

void _writeList(
  StringBuffer buffer, {
  required String name,
  required String doc,
  required List<int> values,
}) {
  buffer
    ..writeln('/// $doc')
    ..writeln('const List<int> $name = [');
  _writeValues(buffer, values, indent: '  ');
  buffer
    ..writeln('];')
    ..writeln();
}

void _writeBySideByRole(
  StringBuffer buffer, {
  required String name,
  required String doc,
  required Map<String, List<int>> values,
}) {
  buffer
    ..writeln('/// $doc')
    ..writeln('const BySide<ByRole<List<int>>> $name = {');
  for (final side in _dartSides) {
    buffer.writeln('  Side.$side: {');
    for (final role in _dartRoles) {
      buffer.writeln('    Role.$role: [');
      _writeValues(buffer, values['$side.$role']!, indent: '      ');
      buffer.writeln('    ],');
    }
    buffer.writeln('  },');
  }
  buffer
    ..writeln('};')
    ..writeln();
}

void _writeValues(
  StringBuffer buffer,
  List<int> values, {
  required String indent,
}) {
  // As many masks per line as fit in the 80 columns the formatter targets.
  const width = 18; // '0x' + 16 hexadecimal digits
  var perLine = 1;
  while (indent.length + (perLine + 1) * (width + 2) <= 81) {
    perLine++;
  }
  for (var i = 0; i < values.length; i += perLine) {
    final chunk = values.skip(i).take(perLine).map(_hex).join(', ');
    // No trailing comma: it would make the formatter split the masks one per
    // line, quadrupling the size of this table.
    buffer.writeln('$indent$chunk${i + perLine < values.length ? ',' : ''}');
  }
}

/// Formats [value] as an unsigned 64 bit Dart hexadecimal literal.
///
/// Dart wraps such a literal to the corresponding negative signed value.
String _hex(int value) {
  final high = (value >> 32) & 0xffffffff;
  final low = value & 0xffffffff;
  return '0x${high.toRadixString(16).padLeft(8, '0')}'
      '${low.toRadixString(16).padLeft(8, '0')}';
}

/// A line cursor over the Rust source, extracting the low 64 bits of the
/// 128 bit mask literals it walks over.
class _Cursor {
  _Cursor(this.lines);

  final List<String> lines;
  int _index = 0;

  static final _literal = RegExp(r'0x([0-9a-f_]{39})\b');

  /// Advances to just after the first line containing [needle].
  void seek(String needle) {
    while (_index < lines.length && !lines[_index].contains(needle)) {
      _index++;
    }
    if (_index == lines.length) {
      throw StateError('Could not find "$needle" in the source');
    }
    _index++;
  }

  /// Reads the mask on the line the cursor just moved past.
  int takeHere() => _parse(lines[_index - 1]);

  /// Reads the next [count] masks.
  List<int> take(int count) {
    final masks = <int>[];
    while (masks.length < count) {
      if (_index == lines.length) {
        throw StateError('Unexpected end of source while reading masks');
      }
      final line = lines[_index++];
      if (_literal.hasMatch(line)) {
        masks.add(_parse(line));
      }
    }
    return masks;
  }

  int _parse(String line) {
    final match = _literal.firstMatch(line);
    if (match == null) {
      throw StateError('Expected a 128 bit mask literal, got: $line');
    }
    final digits = match.group(1)!.replaceAll('_', '');
    // Only the low 64 bits are Polyglot compatible; the high half is a
    // shakmaty extension used by its wider hashes, which we do not port.
    final low64 = digits.substring(16);
    final high = int.parse(low64.substring(0, 8), radix: 16);
    final low = int.parse(low64.substring(8), radix: 16);
    return (high << 32) | low;
  }
}
