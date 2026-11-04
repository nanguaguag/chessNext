import 'dart:typed_data';

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
    this.isStale = false,
    this.cachedAt,
  });
  final List<PublicPieceSkin> items;
  final int page;
  final int pageSize;
  final int total;
  final bool isStale;
  final DateTime? cachedAt;
}

final class CachedPieceSkinCatalogResponse {
  const CachedPieceSkinCatalogResponse(this.body, this.cachedAt);
  final String body;
  final DateTime cachedAt;
}

abstract interface class PieceSkinCatalogCache {
  Future<CachedPieceSkinCatalogResponse?> read(String key);
  Future<void> write(String key, String body, DateTime cachedAt);
}

abstract interface class PieceSkinCatalog {
  Future<PieceSkinCatalogPage> search({
    required Uri endpoint,
    required String query,
    required PublicPieceSkinSort sort,
    int page = 1,
    int pageSize = 24,
  });

  Future<Uint8List> downloadPackage({
    required Uri endpoint,
    required String id,
    required String expectedSha256,
  });
}

/// Board skins use the same bounded metadata and transport contract, but a
/// separate server route and package codec.
typedef PublicBoardSkin = PublicPieceSkin;
typedef PublicBoardSkinSort = PublicPieceSkinSort;
typedef BoardSkinCatalogPage = PieceSkinCatalogPage;
typedef CachedBoardSkinCatalogResponse = CachedPieceSkinCatalogResponse;
typedef BoardSkinCatalogCache = PieceSkinCatalogCache;

abstract interface class BoardSkinCatalog {
  Future<BoardSkinCatalogPage> search({
    required Uri endpoint,
    required String query,
    required PublicBoardSkinSort sort,
    int page = 1,
    int pageSize = 24,
  });

  Future<Uint8List> downloadPackage({
    required Uri endpoint,
    required String id,
    required String expectedSha256,
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
