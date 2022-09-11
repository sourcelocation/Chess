import 'package:flutter/material.dart';
import 'package:chess/chess_piece.dart';
import "package:chess/extensions.dart";
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../game_coordinator.dart';

class GameScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => GameScreenState();

  const GameScreen({super.key});
}

class GameScreenState extends State<GameScreen> {
  late final GameCoordinator coordinator =
      GameCoordinator.newGame(pawnReachedEnd);

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

  // Ad
  int undosLeft = 0;
  RewardedAd? _rewardedAd;

  @override
  void initState() {
    super.initState();
    _loadRewardedAd();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: null,
        body: Container(
          margin: EdgeInsets.all(boardMargin),
          decoration:
              const BoxDecoration(color: Color.fromARGB(255, 250, 243, 233)),
          child: Column(children: [
            const Spacer(),
            buildBoard(),
            Row(children: [const Spacer(), buildControls(), const Spacer()]),
            const Spacer()
          ]),
        ));
  }

  Stack buildBoard() {
    return Stack(
      children: [
        Image.asset(
          "assets/images/Board Modern.png",
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
                if (undosLeft > 0) {
                  undosLeft -= 1;
                  setState(() {
                    coordinator.undo();
                    deselectPiece();
                  });
                } else {
                  _rewardedAd?.show(onUserEarnedReward:
                      (AdWithoutView ad, RewardItem rewardItem) {
                    undosLeft = 9999;
                    // Reward the user for watching an ad.
                  });
                }
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
                undosLeft = 2;
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
      moveImageName = "assets/images/${moveTypeStr}_$tileColorStr.png";
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
                coordinator.performMove(Move(fromPos, toPos, null), true);
                deselectPiece();
                final status = coordinator
                    .getCheckStatusForPlayer(coordinator.currentTurn);
                playMoveSound();
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
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ));
    }
  }

  Widget buildPieceSelectionButton(ChessPiece piece) {
    return IconButton(
      onPressed: () {
        Navigator.of(context, rootNavigator: true).pop('dialog');
        setState(() {
          coordinator.addPawnTransform(piece.type);
        });
        playMoveSound();
      },
      icon: Image.asset(piece.fileName),
      iconSize: tileSize,
    );
  }

  void pawnReachedEnd(Pos pos, PlayerColor color) {
    showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
            title: const Text('Piece selection'),
            content: Row(
              children: [
                const Spacer(),
                ...[
                  ChessPiece(PieceType.knight, color),
                  ChessPiece(PieceType.bishop, color),
                  ChessPiece(PieceType.rook, color),
                  ChessPiece(PieceType.queen, color),
                ].map((p) => buildPieceSelectionButton(p)).toList(),
                const Spacer(),
              ],
            )));
  }

  void playMoveSound() {
    final status = coordinator.getCheckStatusForPlayer(coordinator.currentTurn);

    if (status == CheckStatus.check) {
      coordinator.checkAudioPlayer.resume();
    } else if (status == CheckStatus.checkmate) {
      coordinator.checkmateAudioPlayer.resume();
    } else if (status == CheckStatus.none) {
      coordinator.moveAudioPlayer.resume();
    }
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: "ca-app-pub-6804648379784599/8667941163",
      request: AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          print("Ad loaded!");
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              setState(() {
                ad.dispose();
                _rewardedAd = null;
              });
              _loadRewardedAd();
            },
          );

          setState(() {
            _rewardedAd = ad;
          });
        },
        onAdFailedToLoad: (err) {
          print('Failed to load a rewarded ad: ${err.message}');
          if (err.code == 3) {
            undosLeft = 9999;
          }
        },
      ),
    );
  }
}
