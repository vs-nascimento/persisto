import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/persisto_exception.dart';
import 'adapter_interface.dart';

/// Signature used to customize Firestore queries before execution.
typedef FirebaseQueryBuilder =
    Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>> query);

/// Signature used to transform Firestore documents prior to returning.
typedef FirebaseDocumentMapper =
    Map<String, dynamic> Function(Map<String, dynamic> data, String id);

/// Firestore adapter that supports query customization and realtime streams.
class FirebaseAdapter implements DataAdapter {
  /// Creates a new [FirebaseAdapter] for the collection at [collectionPath].
  FirebaseAdapter({
    FirebaseFirestore? firestore,
    required this.collectionPath,
    this.queryBuilder,
    this.documentMapper,
  }) : firestore = firestore ?? FirebaseFirestore.instance;

  /// Firestore instance backing the adapter.
  final FirebaseFirestore firestore;

  /// Root collection path handled by this adapter.
  final String collectionPath;

  /// Optional default query customizer.
  final FirebaseQueryBuilder? queryBuilder;

  /// Optional transformer used to map Firestore snapshots.
  final FirebaseDocumentMapper? documentMapper;

  CollectionReference<Map<String, dynamic>> get _collection => firestore
      .collection(collectionPath)
      .withConverter<Map<String, dynamic>>(
        fromFirestore: (snapshot, _) =>
            Map<String, dynamic>.from(snapshot.data() ?? {}),
        toFirestore: (value, _) => value,
      );

  Map<String, dynamic> _mapDocument(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (documentMapper != null && data != null) {
      return documentMapper!(data, snapshot.id);
    }
    if (data == null) return {'id': snapshot.id};
    return {'id': snapshot.id, ...data};
  }

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? params}) async {
    try {
      final builder =
          params?['queryBuilder'] as FirebaseQueryBuilder? ?? queryBuilder;

      if (path.isEmpty) {
        Query<Map<String, dynamic>> query = _collection;
        if (builder != null) {
          query = builder(query);
        }
        final snapshot = await query.get();
        return snapshot.docs.map(_mapDocument).toList();
      } else {
        final doc = await _collection.doc(path).get();
        if (!doc.exists) return null;
        return _mapDocument(doc);
      }
    } on FirebaseException catch (e) {
      throw AdapterException(
        'Firestore error: ${e.message ?? 'Unknown Firestore error'}',
        e,
      );
    } catch (e) {
      if (e is PersistoException) {
        rethrow;
      }
      throw AdapterException(
        'Unexpected error in FirebaseAdapter.get',
        e,
      );
    }
  }

  @override
  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    try {
      final docRef = await _collection.add(body);
      final snapshot = await docRef.get();
      return _mapDocument(snapshot);
    } on FirebaseException catch (e) {
      throw AdapterException(
        'Firestore error: ${e.message ?? 'Unknown Firestore error'}',
        e,
      );
    } catch (e) {
      if (e is PersistoException) {
        rethrow;
      }
      throw AdapterException(
        'Unexpected error in FirebaseAdapter.post',
        e,
      );
    }
  }

  @override
  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    if (path.isEmpty) {
      throw ArgumentError('Document path is required for FirebaseAdapter.put');
    }
    try {
      final docRef = _collection.doc(path);
      await docRef.set(body, SetOptions(merge: true));
      final snapshot = await docRef.get();
      return _mapDocument(snapshot);
    } on FirebaseException catch (e) {
      throw AdapterException(
        'Firestore error: ${e.message ?? 'Unknown Firestore error'}',
        e,
      );
    } catch (e) {
      if (e is PersistoException) {
        rethrow;
      }
      throw AdapterException(
        'Unexpected error in FirebaseAdapter.put',
        e,
      );
    }
  }

  @override
  Future<dynamic> delete(String path) async {
    if (path.isEmpty) {
      throw ArgumentError(
        'Document path is required for FirebaseAdapter.delete',
      );
    }
    try {
      await _collection.doc(path).delete();
      return {'id': path, 'deleted': true};
    } on FirebaseException catch (e) {
      throw AdapterException(
        'Firestore error: ${e.message ?? 'Unknown Firestore error'}',
        e,
      );
    } catch (e) {
      if (e is PersistoException) {
        rethrow;
      }
      throw AdapterException(
        'Unexpected error in FirebaseAdapter.delete',
        e,
      );
    }
  }

  @override
  Stream<dynamic>? listen(String path) {
    if (path.isEmpty) {
      Query<Map<String, dynamic>> query = _collection;
      if (queryBuilder != null) {
        query = queryBuilder!(query);
      }
      return query.snapshots().map(
        (snapshot) => snapshot.docs.map(_mapDocument).toList(),
      );
    } else {
      return _collection.doc(path).snapshots().map((snapshot) {
        if (!snapshot.exists) return null;
        return _mapDocument(snapshot);
      });
    }
  }
}
