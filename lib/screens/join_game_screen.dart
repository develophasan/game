import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'game_lobby_screen.dart';

class JoinGameScreen extends StatelessWidget {
  const JoinGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Game')),
      body: StreamBuilder(
        stream: FirebaseDatabase.instance
            .ref()
            .child('games')
            .orderByChild('status')
            .equalTo('waiting')
            .onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
            return const Center(child: Text('No games available'));
          }

          final games = Map<String, dynamic>.from(
            snapshot.data!.snapshot.value as Map,
          );

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: games.length,
            itemBuilder: (context, index) {
              final gameId = games.keys.elementAt(index);
              final game = Map<String, dynamic>.from(games[gameId]);
              
              return GameCard(
                gameId: gameId,
                hostName: game['hostName'],
                playerCount: (game['players'] as Map).length,
              );
            },
          );
        },
      ),
    );
  }
}

class GameCard extends StatelessWidget {
  final String gameId;
  final String hostName;
  final int playerCount;

  const GameCard({
    super.key,
    required this.gameId,
    required this.hostName,
    required this.playerCount,
  });

  Future<void> _joinGame(BuildContext context) async {
    try {
      final user = context.read<AuthService>().user;
      final userData = await context.read<AuthService>().getUserData();
      
      if (user == null || userData == null) return;

      final gameRef = FirebaseDatabase.instance.ref().child('games/$gameId');
      
      await gameRef.child('players/${user.uid}').set({
        'username': userData['username'],
        'ready': false,
      });

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GameLobbyScreen(gameId: gameId),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error joining game: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        title: Text('Host: $hostName'),
        subtitle: Text('Players: $playerCount/2'),
        trailing: ElevatedButton(
          onPressed: () => _joinGame(context),
          child: const Text('Join'),
        ),
      ),
    );
  }
}