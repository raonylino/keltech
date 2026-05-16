import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:desafio/scr/models/document_model.dart';

enum GetDocumentsStatus { initial, loading, loaded, error }

class GetDocumentsState {
  const GetDocumentsState({
    this.status = GetDocumentsStatus.initial,
    this.documents = const [],
    this.errorMessage,
    this.deleteError,
  });

  final GetDocumentsStatus status;
  final List<DocumentModel> documents;
  final String? errorMessage;

  /// Preenchido quando uma exclusão falha; limpo na próxima operação.
  final String? deleteError;

  bool get isLoading => status == GetDocumentsStatus.loading;
  bool get isLoaded => status == GetDocumentsStatus.loaded;
  bool get hasError => status == GetDocumentsStatus.error;

  GetDocumentsState copyWith({
    GetDocumentsStatus? status,
    List<DocumentModel>? documents,
    String? errorMessage,
    String? deleteError,
    bool clearErrorMessage = false,
    bool clearDeleteError = false,
  }) {
    return GetDocumentsState(
      status: status ?? this.status,
      documents: documents ?? this.documents,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      deleteError: clearDeleteError ? null : (deleteError ?? this.deleteError),
    );
  }
}

class GetDocumentsController extends Cubit<GetDocumentsState> {
  GetDocumentsController() : super(const GetDocumentsState());

  Future<void> fetchDocuments() async {
    emit(
      state.copyWith(
        status: GetDocumentsStatus.loading,
        clearErrorMessage: true,
      ),
    );
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('documents')
          .orderBy('timestamp', descending: true)
          .get();

      final docs = snapshot.docs
          .map((doc) => DocumentModel.fromFirestore(doc))
          .toList();

      emit(state.copyWith(status: GetDocumentsStatus.loaded, documents: docs));
    } on FirebaseException catch (e) {
      emit(
        state.copyWith(
          status: GetDocumentsStatus.error,
          errorMessage:
              'Erro ao buscar documentos: ${e.message ?? 'tente novamente.'}',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: GetDocumentsStatus.error,
          errorMessage: 'Erro inesperado. Tente novamente.',
        ),
      );
    }
  }

  /// Remove o documento do Firestore e atualiza a lista local.
  Future<void> deleteDocument(String id) async {
    try {
      await FirebaseFirestore.instance.collection('documents').doc(id).delete();
      final updated = state.documents.where((d) => d.id != id).toList();
      emit(state.copyWith(documents: updated, clearDeleteError: true));
    } on FirebaseException catch (e) {
      emit(
        state.copyWith(
          deleteError: 'Erro ao apagar: ${e.message ?? 'tente novamente.'}',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          deleteError: 'Erro inesperado ao apagar. Tente novamente.',
        ),
      );
    }
  }
}
