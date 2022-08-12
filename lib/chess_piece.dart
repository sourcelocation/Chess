enum PlayerColor { white, black }

extension PlayerColorExtension on PlayerColor {
  String get raw {
    switch (this) {
      case PlayerColor.white:
        return "white";
      case PlayerColor.black:
        return "black";
    }
  }

  PlayerColor get inverted {
    return this == PlayerColor.white ? PlayerColor.black : PlayerColor.white;
  }
}

enum PieceType { pawn, knight, bishop, rook, queen, king }

extension PieceTypeExtension on PieceType {
  String get raw {
    switch (this) {
      case PieceType.pawn:
        return "pawn";
      case PieceType.knight:
        return "knight";
      case PieceType.bishop:
        return "bishop";
      case PieceType.rook:
        return "rook";
      case PieceType.queen:
        return "queen";
      case PieceType.king:
        return "king";
    }
  }
}

class Pos {
  final int x;
  final int y;

  Pos(this.x, this.y);

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
  bool get isValid => x >= 0 && x <= 7 && y >= 0 && y <= 7;

  @override
  bool operator ==(Object other) {
    return other is Pos && (x == other.x && y == other.y);
  }

  Pos operator +(Pos other) {
    return Pos(x + other.x, y + other.y);
  }

  Pos operator -(Pos other) {
    return Pos(x - other.x, y - other.y);
  }

  @override
  String toString() => "Pos($x, $y)";
}

class ChessPiece {
  PlayerColor color;
  PieceType type;

  ChessPiece(this.type, this.color);

  String get fileName => "images/${color.raw}_${type.raw}.png";
}
