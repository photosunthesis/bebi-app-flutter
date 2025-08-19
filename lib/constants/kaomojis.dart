import 'dart:math';

abstract class Kaomojis {
  static String getRandomFromHappySet() =>
      happySet[Random().nextInt(happySet.length)];

  static String getRandomFromSadSet() =>
      sadSet[Random().nextInt(sadSet.length)];

  static const happySet = [
    '(¯▿¯)',
    '＼(￣▽￣)／',
    '( ˙▿˙ )',
    '(⌒ω⌒)',
    '╰(▔∀▔)╯',
    '(ﾉ´ з )ノ',
  ];

  static const sadSet = [
    '(◞‸◟；)',
    '(ಥ﹏ಥ)',
    '(ಥ_ಥ)',
    '( • ᴖ • ｡)',
    '(╥﹏╥)',
    '(╥﹏╥)',
  ];
}
