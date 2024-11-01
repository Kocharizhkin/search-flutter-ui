import 'package:flutter/material.dart';

class WorkInProgress extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ShaderMask(
              shaderCallback: (bounds) {
                return RadialGradient(
                  center: Alignment.center,
                  radius: 0.6,
                  colors: [
                    Colors.white,
                    Colors.white.withOpacity(0.0),
                  ],
                  stops: [0.4, 0.8],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: Image.asset(
                'imgs/workin.webp',
                width: 400,
                height: 400,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 20),
            const Text(
              "We're coding now..",
              style: TextStyle(fontSize: 30),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
