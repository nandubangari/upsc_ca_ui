// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_sync_metadata.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetLocalSyncMetadataCollection on Isar {
  IsarCollection<LocalSyncMetadata> get localSyncMetadatas => this.collection();
}

const LocalSyncMetadataSchema = CollectionSchema(
  name: r'LocalSyncMetadata',
  id: 8774875281398298340,
  properties: {
    r'cloudUpdatedAt': PropertySchema(
      id: 0,
      name: r'cloudUpdatedAt',
      type: IsarType.long,
    ),
    r'collection': PropertySchema(
      id: 1,
      name: r'collection',
      type: IsarType.string,
    ),
    r'documentId': PropertySchema(
      id: 2,
      name: r'documentId',
      type: IsarType.string,
    ),
    r'isDirty': PropertySchema(id: 3, name: r'isDirty', type: IsarType.bool),
    r'lastFetchedCloudCopy': PropertySchema(
      id: 4,
      name: r'lastFetchedCloudCopy',
      type: IsarType.string,
    ),
    r'lastSyncedAt': PropertySchema(
      id: 5,
      name: r'lastSyncedAt',
      type: IsarType.long,
    ),
    r'localData': PropertySchema(
      id: 6,
      name: r'localData',
      type: IsarType.string,
    ),
    r'localUpdatedAt': PropertySchema(
      id: 7,
      name: r'localUpdatedAt',
      type: IsarType.long,
    ),
    r'originalDocId': PropertySchema(
      id: 8,
      name: r'originalDocId',
      type: IsarType.string,
    ),
    r'syncVersion': PropertySchema(
      id: 9,
      name: r'syncVersion',
      type: IsarType.long,
    ),
  },

  estimateSize: _localSyncMetadataEstimateSize,
  serialize: _localSyncMetadataSerialize,
  deserialize: _localSyncMetadataDeserialize,
  deserializeProp: _localSyncMetadataDeserializeProp,
  idName: r'id',
  indexes: {
    r'documentId': IndexSchema(
      id: 4187168439921340405,
      name: r'documentId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'documentId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _localSyncMetadataGetId,
  getLinks: _localSyncMetadataGetLinks,
  attach: _localSyncMetadataAttach,
  version: '3.3.2',
);

int _localSyncMetadataEstimateSize(
  LocalSyncMetadata object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.collection.length * 3;
  bytesCount += 3 + object.documentId.length * 3;
  bytesCount += 3 + object.lastFetchedCloudCopy.length * 3;
  bytesCount += 3 + object.localData.length * 3;
  bytesCount += 3 + object.originalDocId.length * 3;
  return bytesCount;
}

void _localSyncMetadataSerialize(
  LocalSyncMetadata object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.cloudUpdatedAt);
  writer.writeString(offsets[1], object.collection);
  writer.writeString(offsets[2], object.documentId);
  writer.writeBool(offsets[3], object.isDirty);
  writer.writeString(offsets[4], object.lastFetchedCloudCopy);
  writer.writeLong(offsets[5], object.lastSyncedAt);
  writer.writeString(offsets[6], object.localData);
  writer.writeLong(offsets[7], object.localUpdatedAt);
  writer.writeString(offsets[8], object.originalDocId);
  writer.writeLong(offsets[9], object.syncVersion);
}

LocalSyncMetadata _localSyncMetadataDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = LocalSyncMetadata();
  object.cloudUpdatedAt = reader.readLong(offsets[0]);
  object.collection = reader.readString(offsets[1]);
  object.documentId = reader.readString(offsets[2]);
  object.id = id;
  object.isDirty = reader.readBool(offsets[3]);
  object.lastFetchedCloudCopy = reader.readString(offsets[4]);
  object.lastSyncedAt = reader.readLong(offsets[5]);
  object.localData = reader.readString(offsets[6]);
  object.localUpdatedAt = reader.readLong(offsets[7]);
  object.originalDocId = reader.readString(offsets[8]);
  object.syncVersion = reader.readLong(offsets[9]);
  return object;
}

P _localSyncMetadataDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readLong(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _localSyncMetadataGetId(LocalSyncMetadata object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _localSyncMetadataGetLinks(
  LocalSyncMetadata object,
) {
  return [];
}

void _localSyncMetadataAttach(
  IsarCollection<dynamic> col,
  Id id,
  LocalSyncMetadata object,
) {
  object.id = id;
}

extension LocalSyncMetadataByIndex on IsarCollection<LocalSyncMetadata> {
  Future<LocalSyncMetadata?> getByDocumentId(String documentId) {
    return getByIndex(r'documentId', [documentId]);
  }

  LocalSyncMetadata? getByDocumentIdSync(String documentId) {
    return getByIndexSync(r'documentId', [documentId]);
  }

  Future<bool> deleteByDocumentId(String documentId) {
    return deleteByIndex(r'documentId', [documentId]);
  }

  bool deleteByDocumentIdSync(String documentId) {
    return deleteByIndexSync(r'documentId', [documentId]);
  }

  Future<List<LocalSyncMetadata?>> getAllByDocumentId(
    List<String> documentIdValues,
  ) {
    final values = documentIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'documentId', values);
  }

  List<LocalSyncMetadata?> getAllByDocumentIdSync(
    List<String> documentIdValues,
  ) {
    final values = documentIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'documentId', values);
  }

  Future<int> deleteAllByDocumentId(List<String> documentIdValues) {
    final values = documentIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'documentId', values);
  }

  int deleteAllByDocumentIdSync(List<String> documentIdValues) {
    final values = documentIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'documentId', values);
  }

  Future<Id> putByDocumentId(LocalSyncMetadata object) {
    return putByIndex(r'documentId', object);
  }

  Id putByDocumentIdSync(LocalSyncMetadata object, {bool saveLinks = true}) {
    return putByIndexSync(r'documentId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByDocumentId(List<LocalSyncMetadata> objects) {
    return putAllByIndex(r'documentId', objects);
  }

  List<Id> putAllByDocumentIdSync(
    List<LocalSyncMetadata> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'documentId', objects, saveLinks: saveLinks);
  }
}

extension LocalSyncMetadataQueryWhereSort
    on QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QWhere> {
  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension LocalSyncMetadataQueryWhere
    on QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QWhereClause> {
  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterWhereClause>
  idNotEqualTo(Id id) {
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

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterWhereClause>
  idBetween(
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

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterWhereClause>
  documentIdEqualTo(String documentId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'documentId', value: [documentId]),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterWhereClause>
  documentIdNotEqualTo(String documentId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'documentId',
                lower: [],
                upper: [documentId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'documentId',
                lower: [documentId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'documentId',
                lower: [documentId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'documentId',
                lower: [],
                upper: [documentId],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension LocalSyncMetadataQueryFilter
    on QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QFilterCondition> {
  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  cloudUpdatedAtEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'cloudUpdatedAt', value: value),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  cloudUpdatedAtGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'cloudUpdatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  cloudUpdatedAtLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'cloudUpdatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  cloudUpdatedAtBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'cloudUpdatedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  collectionEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'collection',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  collectionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'collection',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  collectionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'collection',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  collectionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'collection',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  collectionStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'collection',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  collectionEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'collection',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  collectionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'collection',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  collectionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'collection',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  collectionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'collection', value: ''),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  collectionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'collection', value: ''),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  documentIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'documentId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  documentIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'documentId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  documentIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'documentId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  documentIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'documentId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  documentIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'documentId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  documentIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'documentId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  documentIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'documentId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  documentIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'documentId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  documentIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'documentId', value: ''),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  documentIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'documentId', value: ''),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
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

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  idLessThan(Id value, {bool include = false}) {
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

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  idBetween(
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

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  isDirtyEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isDirty', value: value),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  lastFetchedCloudCopyEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'lastFetchedCloudCopy',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  lastFetchedCloudCopyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastFetchedCloudCopy',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  lastFetchedCloudCopyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastFetchedCloudCopy',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  lastFetchedCloudCopyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastFetchedCloudCopy',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  lastFetchedCloudCopyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'lastFetchedCloudCopy',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  lastFetchedCloudCopyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'lastFetchedCloudCopy',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  lastFetchedCloudCopyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'lastFetchedCloudCopy',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  lastFetchedCloudCopyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'lastFetchedCloudCopy',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  lastFetchedCloudCopyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastFetchedCloudCopy', value: ''),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  lastFetchedCloudCopyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          property: r'lastFetchedCloudCopy',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  lastSyncedAtEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastSyncedAt', value: value),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  lastSyncedAtGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastSyncedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  lastSyncedAtLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastSyncedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  lastSyncedAtBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastSyncedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  localDataEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'localData',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  localDataGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'localData',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  localDataLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'localData',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  localDataBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'localData',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  localDataStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'localData',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  localDataEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'localData',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  localDataContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'localData',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  localDataMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'localData',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  localDataIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'localData', value: ''),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  localDataIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'localData', value: ''),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  localUpdatedAtEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'localUpdatedAt', value: value),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  localUpdatedAtGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'localUpdatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  localUpdatedAtLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'localUpdatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  localUpdatedAtBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'localUpdatedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  originalDocIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'originalDocId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  originalDocIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'originalDocId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  originalDocIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'originalDocId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  originalDocIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'originalDocId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  originalDocIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'originalDocId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  originalDocIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'originalDocId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  originalDocIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'originalDocId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  originalDocIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'originalDocId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  originalDocIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'originalDocId', value: ''),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  originalDocIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'originalDocId', value: ''),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  syncVersionEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'syncVersion', value: value),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  syncVersionGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'syncVersion',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  syncVersionLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'syncVersion',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterFilterCondition>
  syncVersionBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'syncVersion',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension LocalSyncMetadataQueryObject
    on QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QFilterCondition> {}

extension LocalSyncMetadataQueryLinks
    on QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QFilterCondition> {}

extension LocalSyncMetadataQuerySortBy
    on QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QSortBy> {
  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterSortBy>
  sortByCloudUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cloudUpdatedAt', Sort.asc);
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterSortBy>
  sortByCloudUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cloudUpdatedAt', Sort.desc);
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterSortBy>
  sortByCollection() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'collection', Sort.asc);
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterSortBy>
  sortByCollectionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'collection', Sort.desc);
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterSortBy>
  sortByDocumentId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'documentId', Sort.asc);
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterSortBy>
  sortByDocumentIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'documentId', Sort.desc);
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterSortBy>
  sortByIsDirty() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDirty', Sort.asc);
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterSortBy>
  sortByIsDirtyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDirty', Sort.desc);
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterSortBy>
  sortByLastFetchedCloudCopy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastFetchedCloudCopy', Sort.asc);
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterSortBy>
  sortByLastFetchedCloudCopyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastFetchedCloudCopy', Sort.desc);
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterSortBy>
  sortByLastSyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedAt', Sort.asc);
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterSortBy>
  sortByLastSyncedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedAt', Sort.desc);
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterSortBy>
  sortByLocalData() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localData', Sort.asc);
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterSortBy>
  sortByLocalDataDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localData', Sort.desc);
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterSortBy>
  sortByLocalUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localUpdatedAt', Sort.asc);
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterSortBy>
  sortByLocalUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localUpdatedAt', Sort.desc);
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterSortBy>
  sortByOriginalDocId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalDocId', Sort.asc);
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterSortBy>
  sortByOriginalDocIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalDocId', Sort.desc);
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterSortBy>
  sortBySyncVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncVersion', Sort.asc);
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterSortBy>
  sortBySyncVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncVersion', Sort.desc);
    });
  }
}

extension LocalSyncMetadataQuerySortThenBy
    on QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QSortThenBy> {
  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterSortBy>
  thenByCloudUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cloudUpdatedAt', Sort.asc);
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterSortBy>
  thenByCloudUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cloudUpdatedAt', Sort.desc);
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterSortBy>
  thenByCollection() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'collection', Sort.asc);
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterSortBy>
  thenByCollectionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'collection', Sort.desc);
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterSortBy>
  thenByDocumentId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'documentId', Sort.asc);
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterSortBy>
  thenByDocumentIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'documentId', Sort.desc);
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterSortBy>
  thenByIsDirty() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDirty', Sort.asc);
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterSortBy>
  thenByIsDirtyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDirty', Sort.desc);
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterSortBy>
  thenByLastFetchedCloudCopy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastFetchedCloudCopy', Sort.asc);
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterSortBy>
  thenByLastFetchedCloudCopyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastFetchedCloudCopy', Sort.desc);
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterSortBy>
  thenByLastSyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedAt', Sort.asc);
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterSortBy>
  thenByLastSyncedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedAt', Sort.desc);
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterSortBy>
  thenByLocalData() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localData', Sort.asc);
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterSortBy>
  thenByLocalDataDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localData', Sort.desc);
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterSortBy>
  thenByLocalUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localUpdatedAt', Sort.asc);
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterSortBy>
  thenByLocalUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localUpdatedAt', Sort.desc);
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterSortBy>
  thenByOriginalDocId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalDocId', Sort.asc);
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterSortBy>
  thenByOriginalDocIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalDocId', Sort.desc);
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterSortBy>
  thenBySyncVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncVersion', Sort.asc);
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QAfterSortBy>
  thenBySyncVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncVersion', Sort.desc);
    });
  }
}

extension LocalSyncMetadataQueryWhereDistinct
    on QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QDistinct> {
  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QDistinct>
  distinctByCloudUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cloudUpdatedAt');
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QDistinct>
  distinctByCollection({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'collection', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QDistinct>
  distinctByDocumentId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'documentId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QDistinct>
  distinctByIsDirty() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isDirty');
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QDistinct>
  distinctByLastFetchedCloudCopy({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'lastFetchedCloudCopy',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QDistinct>
  distinctByLastSyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastSyncedAt');
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QDistinct>
  distinctByLocalData({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'localData', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QDistinct>
  distinctByLocalUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'localUpdatedAt');
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QDistinct>
  distinctByOriginalDocId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'originalDocId',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QDistinct>
  distinctBySyncVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncVersion');
    });
  }
}

extension LocalSyncMetadataQueryProperty
    on QueryBuilder<LocalSyncMetadata, LocalSyncMetadata, QQueryProperty> {
  QueryBuilder<LocalSyncMetadata, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<LocalSyncMetadata, int, QQueryOperations>
  cloudUpdatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cloudUpdatedAt');
    });
  }

  QueryBuilder<LocalSyncMetadata, String, QQueryOperations>
  collectionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'collection');
    });
  }

  QueryBuilder<LocalSyncMetadata, String, QQueryOperations>
  documentIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'documentId');
    });
  }

  QueryBuilder<LocalSyncMetadata, bool, QQueryOperations> isDirtyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isDirty');
    });
  }

  QueryBuilder<LocalSyncMetadata, String, QQueryOperations>
  lastFetchedCloudCopyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastFetchedCloudCopy');
    });
  }

  QueryBuilder<LocalSyncMetadata, int, QQueryOperations>
  lastSyncedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastSyncedAt');
    });
  }

  QueryBuilder<LocalSyncMetadata, String, QQueryOperations>
  localDataProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'localData');
    });
  }

  QueryBuilder<LocalSyncMetadata, int, QQueryOperations>
  localUpdatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'localUpdatedAt');
    });
  }

  QueryBuilder<LocalSyncMetadata, String, QQueryOperations>
  originalDocIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'originalDocId');
    });
  }

  QueryBuilder<LocalSyncMetadata, int, QQueryOperations> syncVersionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncVersion');
    });
  }
}
