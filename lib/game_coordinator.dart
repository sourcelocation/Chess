import 'dart:convert';

import 'package:chess/chess_piece.dart';
import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';

class Move {
  Pos from;
  Pos to;

  Move(this.from, this.to);
}

enum CheckStatus { none, check, checkmate }

class GameCoordinator {
  var test = "test";
  final List<List<ChessPiece?>> pieces;
  List<Move> unslicedHistory;
  List<Move> get history {
    return unslicedHistory; // todo
  }

  PlayerColor currentTurn = PlayerColor.white;

  GameCoordinator(this.pieces, this.unslicedHistory);

  factory GameCoordinator.newGame() {
    return GameCoordinator([
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
    ], []);
  }

  ChessPiece? pieceOfTile(Pos pos) => pieces[pos.y][pos.x];
  setPieceOnTile(ChessPiece? piece, Pos pos) {
    pieces[pos.y][pos.x] = piece;
  }

  movePiece(fromPos, toPos) {
    setPieceOnTile(pieceOfTile(fromPos), toPos);
    setPieceOnTile(null, fromPos);
  }

  List<Pos> _legalMovesWithoutChecks(Pos pos) {
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

  List<Pos> legalMoves(Pos pos) {
    final piece = pieceOfTile(pos);
    if (piece == null) {
      return [];
    }
    final moves = _legalMovesWithoutChecks(pos);
    List<Pos> legalMoves = [];
    for (final to in moves) {
      final pieceOnDest = pieceOfTile(to);
      movePiece(pos, to);
      if (!_getCheckForPlayer(piece.color)) {
        legalMoves.add(to);
      }

      // Undo
      movePiece(to, pos);
      setPieceOnTile(pieceOnDest, to);
    }
    return legalMoves;
  }

  bool _getCheckForPlayer(PlayerColor color) {
    var kingPos = _getKingPosition(color);
    var check = false;
    pieces.forEachIndexed((y, r) {
      r.forEachIndexed((x, p) {
        if (p == null || p.color == color || check) {
          return;
        }
        var moves = _legalMovesWithoutChecks(Pos(x, y));
        for (var to in moves) {
          if (to == kingPos) {
            check = true;
          }
        }
      });
    });
    return check;
  }

  Pos _getKingPosition(PlayerColor color) {
    Pos? pos;
    pieces.forEachIndexed((y, r) {
      r.forEachIndexed((x, p) {
        if (p != null && p.type == PieceType.king && p.color == color) {
          pos = Pos(x, y);
        }
      });
    });
    return pos!;
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

  // king, knight, pawn
  List<Pos> _generateOffsetMoves(Pos pos, List<List<int>> offsets) {
    return offsets
        .map((dpos) => Pos(pos.x + dpos[0], pos.y + dpos[1]))
        .where((pos1) => pos1.isValid)
        .where((pos1) => pieceOfTile(pos1)?.color != pieceOfTile(pos)!.color)
        .toList();
  }
}
