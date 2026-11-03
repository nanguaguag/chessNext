enum MoveSoundChoice { sound1, sound2, followPieceSkin }

extension MoveSoundChoicePresentation on MoveSoundChoice {
  String get label => switch (this) {
    MoveSoundChoice.sound1 => '音效1',
    MoveSoundChoice.sound2 => '音效2',
    MoveSoundChoice.followPieceSkin => '随棋子皮肤',
  };
}
