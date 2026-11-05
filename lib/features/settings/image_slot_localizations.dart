import '../../l10n/app_localizations.dart';
import '../../ports/board_skin_images.dart';
import '../../ports/piece_images.dart';

extension PieceImageSlotLocalization on PieceImageSlot {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    PieceImageSlot.redRook => l10n.pieceImageRedRook,
    PieceImageSlot.redHorse => l10n.pieceImageRedHorse,
    PieceImageSlot.redElephant => l10n.pieceImageRedElephant,
    PieceImageSlot.redAdvisor => l10n.pieceImageRedAdvisor,
    PieceImageSlot.redGeneral => l10n.pieceImageRedGeneral,
    PieceImageSlot.redCannon => l10n.pieceImageRedCannon,
    PieceImageSlot.redPawn => l10n.pieceImageRedPawn,
    PieceImageSlot.blackRook => l10n.pieceImageBlackRook,
    PieceImageSlot.blackHorse => l10n.pieceImageBlackHorse,
    PieceImageSlot.blackElephant => l10n.pieceImageBlackElephant,
    PieceImageSlot.blackAdvisor => l10n.pieceImageBlackAdvisor,
    PieceImageSlot.blackGeneral => l10n.pieceImageBlackGeneral,
    PieceImageSlot.blackCannon => l10n.pieceImageBlackCannon,
    PieceImageSlot.blackPawn => l10n.pieceImageBlackPawn,
  };
}

extension BoardSkinImageSlotLocalization on BoardSkinImageSlot {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    BoardSkinImageSlot.boardBackground => l10n.boardImageBackground,
    BoardSkinImageSlot.startMarker => l10n.boardImageStartMarker,
    BoardSkinImageSlot.landingMarker => l10n.boardImageLandingMarker,
    BoardSkinImageSlot.selectionFrame => l10n.boardImageSelectionFrame,
  };
}
