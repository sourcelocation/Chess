import 'package:chess/chess_piece.dart';
import 'package:collection/collection.dart';

class Move {
  Pos from;
  Pos to;

  Move(this.from, this.to);
}

enum CheckStatus { none, check, checkmate, draw }

class GameCoordinator {
  List<List<ChessPiece?>> pieces;
  List<Move> unslicedHistory;
  int _currentHisoryMoveI = -1;
  List<Move> get history {
    return _currentHisoryMoveI == -1
        ? []
        : unslicedHistory.sublist(0, _currentHisoryMoveI + 1); // todo
  }

  PlayerColor currentTurn = PlayerColor.white;
  ChessPiece? pieceOfTile(Pos pos) => pieces[pos.y][pos.x];

  GameCoordinator(this.pieces, this.unslicedHistory);

  factory GameCoordinator.newGame() {
    final coordinator = GameCoordinator([], []);
    coordinator.resetBoard();
    return coordinator;
  }

  void resetBoard() {
    pieces = [
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
    ];
  }

  void _setPieceOnTile(ChessPiece? piece, Pos pos) {
    pieces[pos.y][pos.x] = piece;
  }

  List<Pos> _legalMovesWithoutChecks(Pos pos) {
    final piece = pieceOfTile(pos);
    switch (piece?.type) {
      case PieceType.pawn:
        return _pawnLegalMoves(pos);
      case PieceType.knight:
        return _knightLegalMoves(pos);
      case PieceType.bishop:
        return _bishopLegalMoves(pos);
      case PieceType.rook:
        return _rookLegalMoves(pos);
      case PieceType.queen:
        return _queenLegalMoves(pos);
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
      _movePiece(pos, to);
      if (!_getCheckForPlayer(piece.color)) {
        legalMoves.add(to);
      }

      // Undo
      _movePiece(to, pos);
      _setPieceOnTile(pieceOnDest, to);
    }
    return legalMoves;
  }

  CheckStatus getCheckStatusForPlayer(PlayerColor color) {
    var check = _getCheckForPlayer(color);
    var noMoves = true;
    pieces.forEachIndexed((y, r) {
      r.forEachIndexed((x, p) {
        if (p != null && p.color == color) {
          final moves = legalMoves(Pos(x, y));
          if (moves.isNotEmpty) {
            noMoves = false;
          }
        }
      });
    });
    if (check && noMoves) {
      return CheckStatus.checkmate;
    } else if (check && !noMoves) {
      return CheckStatus.check;
    } else if (!check && noMoves) {
      return CheckStatus.draw;
    } else {
      return CheckStatus.none;
    }
  }

  void performMove(Move move, bool addToHistory) {
    // Check if move is En Passant
    if (pieceOfTile(move.from)?.type == PieceType.pawn) {
      final enPassantMoveD = move.from - move.to;
      if (enPassantMoveD.x == 1 || enPassantMoveD.x == -1) {
        if (pieceOfTile(move.to) == null) {
          // En Passant move
          // Remove captured pawn
          final pawnPos = history.last.to;
          _setPieceOnTile(null, pawnPos);
        }
      }
    }

    _movePiece(move.from, move.to);
    switchTurn();
    if (addToHistory) {
      addMoveToHistory(move);
    }
  }

  void switchTurn() {
    currentTurn = currentTurn.inverted;
  }

  void resetGame(bool removeHistory) {
    if (removeHistory) unslicedHistory.clear();
    _currentHisoryMoveI = -1;
    currentTurn = PlayerColor.white;
    resetBoard();
  }

  void addMoveToHistory(Move move) {
    unslicedHistory = history;
    unslicedHistory.add(move);
    _currentHisoryMoveI = unslicedHistory.length - 1;
  }

  void undo() {
    if (_currentHisoryMoveI >= 0) {
      jumpToMoveInHistory(_currentHisoryMoveI - 1);
    }
  }

  void jumpToMoveInHistory(int i) {
    resetGame(false);
    _currentHisoryMoveI = i;
    for (final move in history) {
      performMove(move, false);
    }
  }

  void _movePiece(fromPos, toPos) {
    _setPieceOnTile(pieceOfTile(fromPos), toPos);
    _setPieceOnTile(null, fromPos);
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
  List<Pos> _pawnLegalMoves(Pos pos) {
    final piece = pieceOfTile(pos);
    if (piece == null) {
      return [];
    }
    final color = piece.color;
    List<Pos> moves = [];

    final pos1Front = pos + Pos(0, color == PlayerColor.white ? 1 : -1);
    if (pos1Front.isValid) {
      final piece1Front = pieceOfTile(pos1Front);
      if (piece1Front == null) {
        moves.add(pos1Front);

        final pos2Front = pos + Pos(0, color == PlayerColor.white ? 2 : -2);
        if (pos2Front.isValid) {
          final piece2Front = pieceOfTile(pos2Front);
          if (piece2Front == null &&
              pos.y == (color == PlayerColor.white ? 1 : 6)) {
            moves.add(pos2Front);
          }
        }
      }
    }

    for (var dir in [-1, 1]) {
      final diagPos = pos + Pos(dir, color == PlayerColor.white ? 1 : -1);

      if (!diagPos.isValid) {
        continue;
      }
      final diagPiece = pieceOfTile(diagPos);
      if (diagPiece != null && diagPiece.color != color) {
        moves.add(diagPos);
      }

      // En passant
      if (history.isNotEmpty) {
        final lastMove = history.last;

        // Check if the last move was "double" pawn move
        final dxy = lastMove.from - lastMove.to;
        if (dxy.x == 0 &&
            dxy.y == (currentTurn == PlayerColor.white ? 2 : -2)) {
          final enPassantPawnPos = lastMove.to;
          final enPassantPawn = pieceOfTile(enPassantPawnPos);
          // Check if pawn is next to selected
          if (enPassantPawnPos.y == pos.y &&
              enPassantPawnPos.x - pos.x == dir) {
            if (enPassantPawn != null &&
                enPassantPawn.type == PieceType.pawn &&
                enPassantPawn.color != color) {
              moves.add(diagPos);
            }
          }
        }
      }
    }

    return moves;
  }

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
