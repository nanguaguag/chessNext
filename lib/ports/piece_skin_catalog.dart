/// Public metadata from a self-hosted skin catalog. Package bytes are fetched
/// separately so callers can show license and attribution before importing.
final class PublicPieceSkin {
  const PublicPieceSkin({
    required this.id,
    required this.name,
    required this.author,
    required this.description,
    required this.likes,
    required this.publishedAt,
    required this.license,
    required this.attribution,
    required this.packageSha256,
  });

  final String id;
  final String name;
  final String author;
  final String description;
  final int likes;
  final DateTime publishedAt;
  final String license;
  final String attribution;
  final String packageSha256;
}

enum PublicPieceSkinSort { defaultOrder, likes, name, author, recent }

final class PieceSkinCatalogPage {
  const PieceSkinCatalogPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
  });
  final List<PublicPieceSkin> items;
  final int page;
  final int pageSize;
  final int total;
}

abstract interface class PieceSkinCatalog {
  Future<PieceSkinCatalogPage> search({
    required Uri endpoint,
    required String query,
    required PublicPieceSkinSort sort,
    int page = 1,
    int pageSize = 24,
  });
}

sealed class PieceSkinCatalogException implements Exception {
  const PieceSkinCatalogException();
}

final class PieceSkinCatalogUnavailable extends PieceSkinCatalogException {
  const PieceSkinCatalogUnavailable();
}

final class PieceSkinCatalogInvalidResponse extends PieceSkinCatalogException {
  const PieceSkinCatalogInvalidResponse();
}

final class PieceSkinCatalogRejected extends PieceSkinCatalogException {
  const PieceSkinCatalogRejected(this.statusCode);
  final int statusCode;
}
