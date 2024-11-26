import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'game_lobby_screen.dart';

class CreateGameScreen extends StatefulWidget {
  const CreateGameScreen({super.key});

  @override
  State<CreateGameScreen> createState() => _CreateGameScreenState();
}

class _CreateGameScreenState extends State<CreateGameScreen> {
  final _database = FirebaseDatabase.instance.ref();
  bool _isCreating = false;

  Future<void> _createGame() async {
    setState(() => _isCreating = true);
    
    try {
      final user = context.read<AuthService>().user;
      final userData = await context.read<AuthService>().getUserData();
      
      if (user == null || userData == null) return;

      final gameRef = _database.child('games').push();
      final gameData = {
        'hostId': user.uid,
        'hostName': userData['username'],
        'status': 'waiting',
        'createdAt': ServerValue.timestamp,
        'players': {
          user.uid: {
            'username': userData['username'],
            'ready': false,
          }
        }
      };

      await gameRef.set(gameData);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GameLobbyScreen(gameId: gameRef.key!),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating game: $e')),
        );
      }
    } finally {
      setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Game')),
      body: Center(
        child: _isCreating
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: _createGame,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text('Create New Game'),
              ),
      ),
    );
  }
}