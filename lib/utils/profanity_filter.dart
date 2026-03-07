/// Client-side profanity / offensive name filter.
///
/// Two checks:
/// 1. **Exact match** — the trimmed, lowercased name IS a blocked word.
/// 2. **Contains match** — the name contains a blocked substring
///    (catches compound words like "fuckboy", "nazihero", etc.).
///
/// This is a best-effort client gate, not a security boundary.
/// Server-side moderation should be the real enforcement layer.
class ProfanityFilter {
  ProfanityFilter._();

  // ── English ────────────────────────────────────────────────────────
  static const _english = <String>[
    // Profanity / sexual
    'fuck', 'shit', 'ass', 'asshole', 'bitch', 'bastard', 'cunt',
    'dick', 'cock', 'pussy', 'whore', 'slut', 'wanker', 'twat',
    'bollocks', 'prick', 'motherfucker', 'fucker', 'fuckboy',
    'fuckface', 'dumbass', 'jackass', 'dipshit', 'shithead',
    'blowjob', 'handjob', 'dildo', 'orgasm', 'penis', 'vagina',
    'boobs', 'tits', 'cum', 'jizz', 'porn', 'anal', 'anus',
    // Slurs / hate
    'nigger', 'nigga', 'faggot', 'fag', 'retard', 'tranny',
    'spic', 'chink', 'gook', 'kike', 'wetback', 'beaner',
    'cracker', 'honky', 'coon', 'darkie', 'negro',
    'dyke', 'homo',
    // Extremism
    'nazi', 'hitler', 'heil', 'jihad', 'isis', 'alqaeda',
    'kkk', 'aryan', 'whitesupremacy', 'whitepower',
  ];

  // ── Swedish ────────────────────────────────────────────────────────
  static const _swedish = <String>[
    'fan', 'jävla', 'jävlar', 'helvete', 'skit', 'fitta',
    'kuk', 'hora', 'bög', 'neger', 'blatte', 'svansen',
    'knull', 'knulla', 'ransen', 'arsle', 'idiot',
    'cp', 'mongo', 'tant', 'subba', 'slansen',
  ];

  /// Combined lowercase blocklist (computed once).
  static final Set<String> _blocklist = {
    ..._english,
    ..._swedish,
  };

  /// Returns `true` if [name] is considered offensive.
  ///
  /// * Exact-match check (full name equals a blocked word).
  /// * Substring check (name *contains* a blocked word ≥ 4 chars,
  ///   to avoid false positives with short words like "ass" inside
  ///   "Kassandra").
  static bool isOffensive(String name) {
    final lower = name.trim().toLowerCase();
    if (lower.isEmpty) return false;

    // 1. Exact match against every blocked word
    if (_blocklist.contains(lower)) return true;

    // 2. Substring match — only for words ≥ 4 chars to limit
    //    false positives (e.g. "Dick" is blocked exact, but we
    //    don't block "Richard" via substring).
    for (final word in _blocklist) {
      if (word.length >= 4 && lower.contains(word)) return true;
    }

    return false;
  }
}
