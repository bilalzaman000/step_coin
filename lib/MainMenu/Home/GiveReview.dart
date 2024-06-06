import 'package:flutter/material.dart';

import 'GameName.dart';
import 'Review/GamePage.dart';


class ReviewScreen extends StatelessWidget {
  final List<Game> games = [
    Game(
      name: 'Fifa 23',
      imagePath: 'assets/Games/Fifa.jpg',
      description: 'FIFA 23 is the latest installment in the popular football simulation series.',
    ),
    Game(
      name: 'Pubg',
      imagePath: 'assets/Games/Pubg.jpg',
      description: 'PUBG is a battle royale shooter that pits 100 players against each other in a struggle for survival.',
    ),
    Game(
      name: 'Volarant',
      imagePath: 'assets/Games/Volarant.jpg',
      description: 'Valorant is a team-based tactical shooter and first-person shooter set in the near future.',
    ),
    Game(
      name: 'Genshin',
      imagePath: 'assets/Games/Genshin.jpg',
      description: 'Genshin Impact is an open-world action RPG where players can explore a fantastical world.',
    ),
    Game(
      name: 'Stumble Guys',
      imagePath: 'assets/Games/StumbleGuys.jpg',
      description: 'Stumble Guys is a massive multiplayer party knockout game with up to 32 players online.',
    ),
    Game(
      name: 'Mobile Legends',
      imagePath: 'assets/Games/MobileLegends.jpg',
      description: 'Mobile Legends is a mobile multiplayer online battle arena (MOBA) game.',
    ),
    // Add more games as needed
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Give A Review',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/Coin.png', width: 50, height: 50),
                      SizedBox(width: 8),
                      Text(
                        '500',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 50,
                        ),
                      ),
                      SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Coins',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'per Review',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: games.length,
                itemBuilder: (context, index) {
                  return GameTile(game: games[index], onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => GamePage(game: games[index])),
                    );
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GameTile extends StatelessWidget {
  final Game game;
  final VoidCallback onTap;

  GameTile({required this.game, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: ClipOval(
            child: Image.asset(
              game.imagePath,
              fit: BoxFit.cover,
            ),
          ),
        ),
        title: Text(
          game.name,
          style: TextStyle(color: Colors.white),
        ),
        trailing: Icon(Icons.arrow_forward_ios, color: Colors.white),
        onTap: onTap,
      ),
    );
  }
}
