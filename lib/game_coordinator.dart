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
    return [Pos(3, 3), Pos(4, 4), Pos(1, 2), Pos(2, 0), Pos(5, 6)];
  }
}
