import 'dart:math';

abstract class Kaomojis {
  static String getRandomFromHappySet() {
    return happySet[Random(
      DateTime.now().millisecondsSinceEpoch,
    ).nextInt(happySet.length)];
  }

  static const happySet = [
    '(¯▿¯)',
    '＼(￣▽￣)／',
    '( ˙▿˙ )',
    '(⌒ω⌒)',
    '╰(▔∀▔)╯',
    '(ﾉ´ з )ノ',
  ];
}
