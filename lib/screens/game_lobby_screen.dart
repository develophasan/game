import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'game_screen.dart';

class GameLobbyScreen extends StatefulWidget {
  final String gameId;

  const GameLobbyScreen({
    super.key,
    required this.gameId,
  });

  @override
  State<GameLobbyScreen> createState() => _GameLobbyScreenState();
}

class _GameLobbyScreenState extends State<GameLobbyScreen> {
  late final DatabaseReference _gameRef;
  bool _isReady = false;
  bool _isHost = false;
  static const int maxPlayers = 2;

  @override
  void initState() {
    super.initState();
    _gameRef = FirebaseDatabase.instance.ref().child('games/${widget.gameId}');
    _setupGameListener();
    _setupDisconnectHandler();
    _checkIfHost();
  }

  void _checkIfHost() async {
    final snapshot = await _gameRef.child('hostId').get();
    final user = context.read<AuthService>().user;
    if (user != null && snapshot.value == user.uid) {
      setState(() => _isHost = true);
    }
  }

  void _setupDisconnectHandler() async {
    final user = context.read<AuthService>().user;
    if (user != null) {
      try {
        // Set up player removal on disconnect
        final playerRef = _gameRef.child('players/${user.uid}');
        await playerRef.onDisconnect().remove();

        // If host, remove entire game on disconnect
        if (_isHost) {
          await _gameRef.onDisconnect().remove();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error setting up disconnect handler: $e')),
          );
        }
      }
    }
  }

  void _setupGameListener() {
    _gameRef.onValue.listen((event) {
      if (!mounted) return;

      if (event.snapshot.value == null) {
        Navigator.pop(context);
        return;
      }

      final gameData = Map<String, dynamic>.from(
        event.snapshot.value as Map,
      );

      if (gameData['status'] == 'started') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GameScreen(
              gameId: widget.gameId,
              playerId: context.read<AuthService>().user!.uid,
            ),
          ),
        );
      }
    });
  }

  Future<void> _toggleReady() async {
    final user = context.read<AuthService>().user;
    if (user == null) return;

    setState(() => _isReady = !_isReady);
    await _gameRef.child('players/${user.uid}/ready').set(_isReady);
  }

  Future<void> _startGame() async {
    await _gameRef.child('status').set('started');
  }

  Future<void> _leaveLobby() async {
    final user = context.read<AuthService>().user;
    if (user != null) {
      if (_isHost) {
        // If host leaves, remove the entire game
        await _gameRef.remove();
      } else {
        // If player leaves, just remove their entry
        await _gameRef.child('players/${user.uid}').remove();
      }
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _leaveLobby();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Game Lobby'),
          actions: [
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: _leaveLobby,
            ),
          ],
        ),
        body: StreamBuilder(
          stream: _gameRef.onValue,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final gameData = Map<String, dynamic>.from(
              snapshot.data!.snapshot.value as Map,
            );
            final players = Map<String, dynamic>.from(gameData['players']);
            final currentUser = context.read<AuthService>().user;

            // Update local ready state based on server data
            if (currentUser != null && players.containsKey(currentUser.uid)) {
              _isReady = players[currentUser.uid]['ready'] ?? false;
            }

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: players.length,
                    itemBuilder: (context, index) {
                      final playerId = players.keys.elementAt(index);
                      final player =
                          Map<String, dynamic>.from(players[playerId]);

                      return Card(
                        child: ListTile(
                          leading: Icon(
                            player['ready']
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: player['ready'] ? Colors.green : Colors.grey,
                          ),
                          title: Text(player['username']),
                          trailing: Text(
                            playerId == gameData['hostId'] ? 'Host' : 'Player',
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Players: ${players.length}/$maxPlayers',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: _toggleReady,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isReady ? Colors.green : null,
                              minimumSize: const Size(120, 40),
                            ),
                            child: Text(_isReady ? 'Ready!' : 'Not Ready'),
                          ),
                          if (_isHost)
                            ElevatedButton(
                              onPressed: players.length == maxPlayers &&
                                      players.values.every((p) => p['ready'])
                                  ? _startGame
                                  : null,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(120, 40),
                              ),
                              child: const Text('Start Game'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _gameRef.onDisconnect().cancel();
    super.dispose();
  }
}
