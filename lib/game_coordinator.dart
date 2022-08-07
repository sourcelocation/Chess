import 'package:chess/chess_piece.dart';

class GameCoordinator {
  final List<List<ChessPiece?>> pieces;
  PlayerColor currentTurn = PlayerColor.white;

  GameCoordinator(this.pieces);

  factory GameCoordinator.newGame() {
    return GameCoordinator(
      [
        [
          ChessPiece(PieceType.rook, PlayerColor.white),
          ChessPiece(PieceType.knight, PlayerColor.white),
          ChessPiece(PieceType.bishop, PlayerColor.white),
          ChessPiece(PieceType.queen, PlayerColor.white),
          ChessPiece(PieceType.king, PlayerColor.white),
          ChessPiece(PieceType.bishop, PlayerColor.white),
          ChessPiece(PieceType.knight, PlayerColor.white),
          ChessPiece(PieceType.rook, PlayerColor.white),
        ],
        [
          ChessPiece(PieceType.pawn, PlayerColor.white),
          ChessPiece(PieceType.pawn, PlayerColor.white),
          ChessPiece(PieceType.pawn, PlayerColor.white),
          ChessPiece(PieceType.pawn, PlayerColor.white),
          ChessPiece(PieceType.pawn, PlayerColor.white),
          ChessPiece(PieceType.pawn, PlayerColor.white),
          ChessPiece(PieceType.pawn, PlayerColor.white),
          ChessPiece(PieceType.pawn, PlayerColor.white),
        ],
        [null, null, null, null, null, null, null, null],
        [null, null, null, null, null, null, null, null],
        [null, null, null, null, null, null, null, null],
        [null, null, null, null, null, null, null, null],
        [
          ChessPiece(PieceType.pawn, PlayerColor.black),
          ChessPiece(PieceType.pawn, PlayerColor.black),
          ChessPiece(PieceType.pawn, PlayerColor.black),
          ChessPiece(PieceType.pawn, PlayerColor.black),
          ChessPiece(PieceType.pawn, PlayerColor.black),
          ChessPiece(PieceType.pawn, PlayerColor.black),
          ChessPiece(PieceType.pawn, PlayerColor.black),
          ChessPiece(PieceType.pawn, PlayerColor.black),
        ],
        [
          ChessPiece(PieceType.rook, PlayerColor.black),
          ChessPiece(PieceType.knight, PlayerColor.black),
          ChessPiece(PieceType.bishop, PlayerColor.black),
          ChessPiece(PieceType.queen, PlayerColor.black),
          ChessPiece(PieceType.king, PlayerColor.black),
          ChessPiece(PieceType.bishop, PlayerColor.black),
          ChessPiece(PieceType.knight, PlayerColor.black),
          ChessPiece(PieceType.rook, PlayerColor.black),
        ],
      ],
    );
  }

  ChessPiece? pieceOfTile(Pos pos) => pieces[pos.y][pos.x];
  setPieceOnTile(ChessPiece? piece, Pos pos) {
    pieces[pos.y][pos.x] = piece;
  }

  movePiece(fromPos, toPos) {
    setPieceOnTile(pieceOfTile(fromPos), toPos);
    setPieceOnTile(null, fromPos);
  }

  List<Pos> legalMoves(Pos pos) {
    final piece = pieceOfTile(pos);
    switch (piece?.type) {
      case PieceType.bishop:
        return _bishopLegalMoves(pos);
      case PieceType.rook:
        return _rookLegalMoves(pos);
      case PieceType.queen:
        return _queenLegalMoves(pos);
      case PieceType.knight:
        return _knightLegalMoves(pos);
      case PieceType.king:
        return _kingLegalMoves(pos);
      default:
        return [Pos(3, 3)];
    }
  }

  // == Pieces ==
  List<Pos> _bishopLegalMoves(Pos pos) {
    return <Pos>[
      ..._generateMovesOnLine(pos, 1, 1),
      ..._generateMovesOnLine(pos, -1, 1),
      ..._generateMovesOnLine(pos, 1, -1),
      ..._generateMovesOnLine(pos, -1, -1),
    ].toList();
  }

  List<Pos> _rookLegalMoves(Pos pos) {
    return <Pos>[
      ..._generateMovesOnLine(pos, 1, 0),
      ..._generateMovesOnLine(pos, 0, 1),
      ..._generateMovesOnLine(pos, -1, 0),
      ..._generateMovesOnLine(pos, 0, -1),
    ].toList();
  }

  List<Pos> _knightLegalMoves(Pos pos) {
    return _generateOffsetMoves(pos, [
      [1, 2],
      [2, 1],
      [2, -1],
      [1, -2],
      [-1, -2],
      [-2, -1],
      [-2, 1],
      [-1, 2]
    ]);
  }

  List<Pos> _kingLegalMoves(Pos pos) {
    return _generateOffsetMoves(pos, [
      [-1, -1],
      [-1, 0],
      [-1, 1],
      [0, -1],
      [0, 1],
      [1, -1],
      [1, 0],
      [1, 1]
    ]);
  }

  List<Pos> _queenLegalMoves(Pos pos) {
    return <Pos>[
      ..._generateMovesOnLine(pos, 1, 0),
      ..._generateMovesOnLine(pos, 0, 1),
      ..._generateMovesOnLine(pos, -1, 0),
      ..._generateMovesOnLine(pos, 0, -1),
      ..._generateMovesOnLine(pos, 1, 1),
      ..._generateMovesOnLine(pos, -1, 1),
      ..._generateMovesOnLine(pos, 1, -1),
      ..._generateMovesOnLine(pos, -1, -1),
    ].toList();
  }

  // For queen, bishop and rook
  List<Pos> _generateMovesOnLine(
    Pos pos,
    int upK,
    int rightK,
  ) {
    bool obstructed = false;

    return List<Pos?>.generate(8, (i) {
      if (obstructed) return null;
      if (i == 0) return null;

      int dx = upK * i;
      int dy = rightK * i;

      final destination = Pos(pos.x + dx, pos.y + dy);
      if (!destination.isValid) {
        return null;
      }
      final pieceOnLocation = pieceOfTile(destination);

      if (pieceOnLocation != null) {
        obstructed = true;
        if (pieceOnLocation.color == pieceOfTile(pos)!.color) {
          return null;
        }
      }

      return destination;
    }).whereType<Pos>().where((location) => location.isValid).toList();
  }

  List<Pos> _generateOffsetMoves(Pos pos, List<List<int>> offsets) {
    return offsets
        .map((dpos) => Pos(pos.x + dpos[0], pos.y + dpos[1]))
        .where((pos1) => pos1.isValid)
        .where((pos1) => pieceOfTile(pos1)?.color != pieceOfTile(pos)!.color)
        .toList();
  }
}
