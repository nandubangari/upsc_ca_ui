// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_content.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetLocalContentCollection on Isar {
  IsarCollection<LocalContent> get localContents => this.collection();
}

const LocalContentSchema = CollectionSchema(
  name: r'LocalContent',
  id: -4913311881926102767,
  properties: {
    r'contentId': PropertySchema(
      id: 0,
      name: r'contentId',
      type: IsarType.string,
    ),
    r'date': PropertySchema(id: 1, name: r'date', type: IsarType.string),
    r'lastFetchedAt': PropertySchema(
      id: 2,
      name: r'lastFetchedAt',
      type: IsarType.dateTime,
    ),
    r'month': PropertySchema(id: 3, name: r'month', type: IsarType.string),
    r'sourceId': PropertySchema(
      id: 4,
      name: r'sourceId',
      type: IsarType.string,
    ),
    r'subtitle': PropertySchema(
      id: 5,
      name: r'subtitle',
      type: IsarType.string,
    ),
    r'title': PropertySchema(id: 6, name: r'title', type: IsarType.string),
    r'type': PropertySchema(id: 7, name: r'type', type: IsarType.string),
    r'url': PropertySchema(id: 8, name: r'url', type: IsarType.string),
    r'year': PropertySchema(id: 9, name: r'year', type: IsarType.string),
  },

  estimateSize: _localContentEstimateSize,
  serialize: _localContentSerialize,
  deserialize: _localContentDeserialize,
  deserializeProp: _localContentDeserializeProp,
  idName: r'id',
  indexes: {
    r'contentId': IndexSchema(
      id: -332487537278013663,
      name: r'contentId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'contentId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _localContentGetId,
  getLinks: _localContentGetLinks,
  attach: _localContentAttach,
  version: '3.3.2',
);

int _localContentEstimateSize(
  LocalContent object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.contentId.length * 3;
  bytesCount += 3 + object.date.length * 3;
  bytesCount += 3 + object.month.length * 3;
  bytesCount += 3 + object.sourceId.length * 3;
  {
    final value = object.subtitle;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.title.length * 3;
  bytesCount += 3 + object.type.length * 3;
  {
    final value = object.url;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.year.length * 3;
  return bytesCount;
}

void _localContentSerialize(
  LocalContent object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.contentId);
  writer.writeString(offsets[1], object.date);
  writer.writeDateTime(offsets[2], object.lastFetchedAt);
  writer.writeString(offsets[3], object.month);
  writer.writeString(offsets[4], object.sourceId);
  writer.writeString(offsets[5], object.subtitle);
  writer.writeString(offsets[6], object.title);
  writer.writeString(offsets[7], object.type);
  writer.writeString(offsets[8], object.url);
  writer.writeString(offsets[9], object.year);
}

LocalContent _localContentDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = LocalContent();
  object.contentId = reader.readString(offsets[0]);
  object.date = reader.readString(offsets[1]);
  object.id = id;
  object.lastFetchedAt = reader.readDateTime(offsets[2]);
  object.month = reader.readString(offsets[3]);
  object.sourceId = reader.readString(offsets[4]);
  object.subtitle = reader.readStringOrNull(offsets[5]);
  object.title = reader.readString(offsets[6]);
  object.type = reader.readString(offsets[7]);
  object.url = reader.readStringOrNull(offsets[8]);
  object.year = reader.readString(offsets[9]);
  return object;
}

P _localContentDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _localContentGetId(LocalContent object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _localContentGetLinks(LocalContent object) {
  return [];
}

void _localContentAttach(
  IsarCollection<dynamic> col,
  Id id,
  LocalContent object,
) {
  object.id = id;
}

extension LocalContentByIndex on IsarCollection<LocalContent> {
  Future<LocalContent?> getByContentId(String contentId) {
    return getByIndex(r'contentId', [contentId]);
  }

  LocalContent? getByContentIdSync(String contentId) {
    return getByIndexSync(r'contentId', [contentId]);
  }

  Future<bool> deleteByContentId(String contentId) {
    return deleteByIndex(r'contentId', [contentId]);
  }

  bool deleteByContentIdSync(String contentId) {
    return deleteByIndexSync(r'contentId', [contentId]);
  }

  Future<List<LocalContent?>> getAllByContentId(List<String> contentIdValues) {
    final values = contentIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'contentId', values);
  }

  List<LocalContent?> getAllByContentIdSync(List<String> contentIdValues) {
    final values = contentIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'contentId', values);
  }

  Future<int> deleteAllByContentId(List<String> contentIdValues) {
    final values = contentIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'contentId', values);
  }

  int deleteAllByContentIdSync(List<String> contentIdValues) {
    final values = contentIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'contentId', values);
  }

  Future<Id> putByContentId(LocalContent object) {
    return putByIndex(r'contentId', object);
  }

  Id putByContentIdSync(LocalContent object, {bool saveLinks = true}) {
    return putByIndexSync(r'contentId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByContentId(List<LocalContent> objects) {
    return putAllByIndex(r'contentId', objects);
  }

  List<Id> putAllByContentIdSync(
    List<LocalContent> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'contentId', objects, saveLinks: saveLinks);
  }
}

extension LocalContentQueryWhereSort
    on QueryBuilder<LocalContent, LocalContent, QWhere> {
  QueryBuilder<LocalContent, LocalContent, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension LocalContentQueryWhere
    on QueryBuilder<LocalContent, LocalContent, QWhereClause> {
  QueryBuilder<LocalContent, LocalContent, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterWhereClause> idNotEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterWhereClause> contentIdEqualTo(
    String contentId,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'contentId', value: [contentId]),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterWhereClause>
  contentIdNotEqualTo(String contentId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'contentId',
                lower: [],
                upper: [contentId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'contentId',
                lower: [contentId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'contentId',
                lower: [contentId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'contentId',
                lower: [],
                upper: [contentId],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension LocalContentQueryFilter
    on QueryBuilder<LocalContent, LocalContent, QFilterCondition> {
  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  contentIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'contentId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  contentIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'contentId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  contentIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'contentId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  contentIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'contentId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  contentIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'contentId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  contentIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'contentId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  contentIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'contentId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  contentIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'contentId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  contentIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'contentId', value: ''),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  contentIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'contentId', value: ''),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition> dateEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'date',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  dateGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'date',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition> dateLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'date',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition> dateBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'date',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  dateStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'date',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition> dateEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'date',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition> dateContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'date',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition> dateMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'date',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  dateIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'date', value: ''),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  dateIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'date', value: ''),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  lastFetchedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastFetchedAt', value: value),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  lastFetchedAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastFetchedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  lastFetchedAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastFetchedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  lastFetchedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastFetchedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition> monthEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'month',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  monthGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'month',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition> monthLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'month',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition> monthBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'month',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  monthStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'month',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition> monthEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'month',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition> monthContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'month',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition> monthMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'month',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  monthIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'month', value: ''),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  monthIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'month', value: ''),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  sourceIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'sourceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  sourceIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sourceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  sourceIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sourceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  sourceIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sourceId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  sourceIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'sourceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  sourceIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'sourceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  sourceIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'sourceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  sourceIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'sourceId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  sourceIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sourceId', value: ''),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  sourceIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'sourceId', value: ''),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  subtitleIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'subtitle'),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  subtitleIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'subtitle'),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  subtitleEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'subtitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  subtitleGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'subtitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  subtitleLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'subtitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  subtitleBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'subtitle',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  subtitleStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'subtitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  subtitleEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'subtitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  subtitleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'subtitle',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  subtitleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'subtitle',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  subtitleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'subtitle', value: ''),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  subtitleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'subtitle', value: ''),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition> titleEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  titleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition> titleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition> titleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'title',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  titleStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition> titleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition> titleContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition> titleMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'title',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'title', value: ''),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'title', value: ''),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition> typeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  typeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition> typeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition> typeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'type',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  typeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition> typeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition> typeContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition> typeMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'type',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  typeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'type', value: ''),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  typeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'type', value: ''),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition> urlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'url'),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  urlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'url'),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition> urlEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'url',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  urlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'url',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition> urlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'url',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition> urlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'url',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition> urlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'url',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition> urlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'url',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition> urlContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'url',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition> urlMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'url',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition> urlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'url', value: ''),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  urlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'url', value: ''),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition> yearEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'year',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  yearGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'year',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition> yearLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'year',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition> yearBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'year',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  yearStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'year',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition> yearEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'year',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition> yearContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'year',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition> yearMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'year',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  yearIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'year', value: ''),
      );
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterFilterCondition>
  yearIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'year', value: ''),
      );
    });
  }
}

extension LocalContentQueryObject
    on QueryBuilder<LocalContent, LocalContent, QFilterCondition> {}

extension LocalContentQueryLinks
    on QueryBuilder<LocalContent, LocalContent, QFilterCondition> {}

extension LocalContentQuerySortBy
    on QueryBuilder<LocalContent, LocalContent, QSortBy> {
  QueryBuilder<LocalContent, LocalContent, QAfterSortBy> sortByContentId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contentId', Sort.asc);
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterSortBy> sortByContentIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contentId', Sort.desc);
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterSortBy> sortByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterSortBy> sortByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterSortBy> sortByLastFetchedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastFetchedAt', Sort.asc);
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterSortBy>
  sortByLastFetchedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastFetchedAt', Sort.desc);
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterSortBy> sortByMonth() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'month', Sort.asc);
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterSortBy> sortByMonthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'month', Sort.desc);
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterSortBy> sortBySourceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceId', Sort.asc);
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterSortBy> sortBySourceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceId', Sort.desc);
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterSortBy> sortBySubtitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtitle', Sort.asc);
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterSortBy> sortBySubtitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtitle', Sort.desc);
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterSortBy> sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterSortBy> sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterSortBy> sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterSortBy> sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterSortBy> sortByUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.asc);
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterSortBy> sortByUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.desc);
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterSortBy> sortByYear() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'year', Sort.asc);
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterSortBy> sortByYearDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'year', Sort.desc);
    });
  }
}

extension LocalContentQuerySortThenBy
    on QueryBuilder<LocalContent, LocalContent, QSortThenBy> {
  QueryBuilder<LocalContent, LocalContent, QAfterSortBy> thenByContentId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contentId', Sort.asc);
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterSortBy> thenByContentIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contentId', Sort.desc);
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterSortBy> thenByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterSortBy> thenByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterSortBy> thenByLastFetchedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastFetchedAt', Sort.asc);
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterSortBy>
  thenByLastFetchedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastFetchedAt', Sort.desc);
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterSortBy> thenByMonth() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'month', Sort.asc);
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterSortBy> thenByMonthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'month', Sort.desc);
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterSortBy> thenBySourceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceId', Sort.asc);
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterSortBy> thenBySourceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceId', Sort.desc);
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterSortBy> thenBySubtitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtitle', Sort.asc);
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterSortBy> thenBySubtitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subtitle', Sort.desc);
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterSortBy> thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterSortBy> thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterSortBy> thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterSortBy> thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterSortBy> thenByUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.asc);
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterSortBy> thenByUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.desc);
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterSortBy> thenByYear() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'year', Sort.asc);
    });
  }

  QueryBuilder<LocalContent, LocalContent, QAfterSortBy> thenByYearDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'year', Sort.desc);
    });
  }
}

extension LocalContentQueryWhereDistinct
    on QueryBuilder<LocalContent, LocalContent, QDistinct> {
  QueryBuilder<LocalContent, LocalContent, QDistinct> distinctByContentId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'contentId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalContent, LocalContent, QDistinct> distinctByDate({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'date', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalContent, LocalContent, QDistinct>
  distinctByLastFetchedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastFetchedAt');
    });
  }

  QueryBuilder<LocalContent, LocalContent, QDistinct> distinctByMonth({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'month', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalContent, LocalContent, QDistinct> distinctBySourceId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourceId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalContent, LocalContent, QDistinct> distinctBySubtitle({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'subtitle', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalContent, LocalContent, QDistinct> distinctByTitle({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalContent, LocalContent, QDistinct> distinctByType({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalContent, LocalContent, QDistinct> distinctByUrl({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'url', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalContent, LocalContent, QDistinct> distinctByYear({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'year', caseSensitive: caseSensitive);
    });
  }
}

extension LocalContentQueryProperty
    on QueryBuilder<LocalContent, LocalContent, QQueryProperty> {
  QueryBuilder<LocalContent, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<LocalContent, String, QQueryOperations> contentIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'contentId');
    });
  }

  QueryBuilder<LocalContent, String, QQueryOperations> dateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'date');
    });
  }

  QueryBuilder<LocalContent, DateTime, QQueryOperations>
  lastFetchedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastFetchedAt');
    });
  }

  QueryBuilder<LocalContent, String, QQueryOperations> monthProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'month');
    });
  }

  QueryBuilder<LocalContent, String, QQueryOperations> sourceIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceId');
    });
  }

  QueryBuilder<LocalContent, String?, QQueryOperations> subtitleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'subtitle');
    });
  }

  QueryBuilder<LocalContent, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<LocalContent, String, QQueryOperations> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }

  QueryBuilder<LocalContent, String?, QQueryOperations> urlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'url');
    });
  }

  QueryBuilder<LocalContent, String, QQueryOperations> yearProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'year');
    });
  }
}
