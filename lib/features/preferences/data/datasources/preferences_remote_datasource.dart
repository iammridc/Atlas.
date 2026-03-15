import 'package:atlas/core/errors/app_exception.dart';
import 'package:atlas/features/preferences/data/models/category_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class PreferencesRemoteDatasource {
  Future<List<CategoryModel>> getCategories();
  Future<void> savePreferences(String uid, List<String> categoryIds);
  Future<bool> hasPreferences(String uid);
}

class InterestsRemoteDatasourceImpl implements PreferencesRemoteDatasource {
  final FirebaseFirestore _firestore;

  InterestsRemoteDatasourceImpl(this._firestore);

  @override
  Future<List<CategoryModel>> getCategories() async {
    try {
      final snapshot = await _firestore
          .collection('categories')
          .orderBy('group')
          .orderBy('order')
          .get();

      return snapshot.docs
          .map((doc) => CategoryModel.fromJson(doc.data()))
          .where((cat) => cat.table == 'A' && cat.group != 'Geographical Areas')
          .toList();
    } catch (e) {
      print('FIRESTORE ERROR: $e');
      throw ServerException(message: 'Failed to fetch categories');
    }
  }

  @override
  Future<void> savePreferences(String uid, List<String> categoryIds) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'preferences': categoryIds,
      }, SetOptions(merge: true));
    } catch (e) {
      throw ServerException(message: 'Failed to save categories.');
    }
  }

  @override
  Future<bool> hasPreferences(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final preferences = doc.data()?['preferences'] as List?;
      return doc.exists && (preferences?.isNotEmpty ?? false);
    } catch (e) {
      throw ServerException(message: 'Failed to check preferences.');
    }
  }
}
