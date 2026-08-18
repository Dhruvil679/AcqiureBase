// Wrapper for paginated lists from Firestore.
class PaginatedResult<T> {
  const PaginatedResult({
    required this.items,
    this.lastDocument,
    this.hasMore = true,
  });

  final List<T> items;
  final dynamic lastDocument;
  final bool hasMore;
}
