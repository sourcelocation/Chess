import 'package:flutter/material.dart';
import 'package:chess/chess_piece.dart';
import "package:chess/extensions.dart";
import '../game_coordinator.dart';

class GameScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => GameScreenState();

  const GameScreen({super.key});
}

class GameScreenState extends State<GameScreen> {
  final GameCoordinator coordinator = GameCoordinator.newGame();

  // Sizes
  final double boardMargin = 4;
  late final double boardBorderSize =
      MediaQuery.of(context).size.width * 0.0333;
  double get gridMargin => boardMargin + boardBorderSize;
  late final double tileSize =
      (MediaQuery.of(context).size.width - gridMargin * 2) / 8;

  // Other
  Pos? selectedPiecePos;
  List<Pos>? selectedPieceLegalMoves;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: null,
        body: Container(
            margin: EdgeInsets.all(boardMargin),
            child: Column(children: [
              const Spacer(),
              buildBoard(),
              Row(children: [const Spacer(), buildControls(), const Spacer()]),
              const Spacer()
            ])));
  }

  Stack buildBoard() {
    return Stack(
      children: [
        Image.asset(
          "images/Board Modern(5).png",
        ),
        Container(
            margin: EdgeInsets.all(boardBorderSize),
            child: Column(
              children: [
                ...List.generate(
                    8,
                    (y) => Row(children: [
                          ...List.generate(8, (x) => buildTile(Pos(x, y)))
                        ])).reversed
              ],
            ))
      ],
    );
  }

  Container buildControls() {
    return Container(
        margin: const EdgeInsets.fromLTRB(0, 20, 0, 0),
        child: Row(
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  coordinator.undo();
                  deselectPiece();
                });
              },
              icon: const Icon(
                Icons.arrow_back_rounded,
                size: 48,
              ),
              padding: const EdgeInsets.all(0),
              splashRadius: 32,
            ),
            const SizedBox(width: 16),
            IconButton(
              onPressed: () {
                setState(() {
                  coordinator.resetGame(true);
                  deselectPiece();
                });
              },
              icon: const Icon(
                Icons.refresh_rounded,
                size: 48,
              ),
              padding: const EdgeInsets.all(0),
              splashRadius: 32,
            ),
          ],
        ));
  }

  Stack buildTileContents(Pos pos) {
    final piece = coordinator.pieceOfTile(pos);
    final tile = Container(
        decoration: const BoxDecoration(color: Color.fromARGB(0, 0, 0, 0)),
        width: tileSize,
        height: tileSize,
        child: buildChessPiece(pos));
    String? moveImageName;
    if (selectedPieceLegalMoves?.contains(pos) ?? false) {
      final moveTypeStr = piece == null ? "move" : "capture";
      final tileColorStr = (pos.x + pos.y) % 2 == 0 ? "black" : "white";
      moveImageName = "images/${moveTypeStr}_$tileColorStr.png";
    }
    return Stack(
      children: [
        if (moveImageName != null)
          Image.asset(moveImageName, height: tileSize, width: tileSize),
        Draggable<Pos>(
          data: pos,
          feedback: tile,
          childWhenDragging: SizedBox(width: tileSize, height: tileSize),
          onDragStarted: () {
            if (piece == null) {
              deselectPiece();
            } else {
              selectPiece(pos);
            }
          },
          maxSimultaneousDrags: (piece?.color ?? coordinator.currentTurn) ==
                  coordinator.currentTurn
              ? null
              : 0,
          child: tile,
        ),
      ],
    );
  }

  DragTarget<Pos> buildTile(Pos pos) {
    return DragTarget<Pos>(
        builder: (context, candidateData, rejectedData) =>
            buildTileContents(pos),
        onAccept: (fromPos) {
          final toPos = pos;

          setState(() {
            if (fromPos == toPos) {
              selectedPiecePos = toPos;
            } else {
              if (selectedPieceLegalMoves?.contains(toPos) ?? false) {
                coordinator.performMove(Move(fromPos, toPos), true);
                deselectPiece();
                final status = coordinator
                    .getCheckStatusForPlayer(coordinator.currentTurn);
                showGameEndDialogIfNeeded(status);
              }
              // Todo check moves
            }
          });
        });
  }

  Widget? buildChessPiece(Pos pos) {
    final piece = coordinator.pieceOfTile(pos);
    return Container(
      alignment: Alignment.center,
      child: piece != null
          ? RotatedBox(
              quarterTurns: piece.color == PlayerColor.white ? 0 : 2,
              child: Image.asset(
                piece.fileName,
                height: tileSize * 0.87,
                width: tileSize * 0.87,
              ))
          : null,
    );
  }

  selectPiece(Pos pos) {
    setState(() {
      selectedPiecePos = pos;
      selectedPieceLegalMoves = coordinator.legalMoves(pos);
    });
  }

  deselectPiece() {
    setState(() {
      selectedPiecePos = null;
      selectedPieceLegalMoves = null;
    });
  }

  void showGameEndDialogIfNeeded(CheckStatus status) {
    if (status == CheckStatus.checkmate) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            "Checkmate! ${coordinator.currentTurn.inverted.raw.capitalize()} wins 🎉",
            style: TextStyle(fontSize: 16),
          ),
        ),
      ));
    }
  }
}
