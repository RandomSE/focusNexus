/// Levenshtein edit distance between [a] and [b].
int assistantLevenshteinDistance(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;

  final rows = a.length + 1;
  final cols = b.length + 1;
  final matrix = List.generate(rows, (_) => List<int>.filled(cols, 0));

  for (var i = 0; i < rows; i++) {
    matrix[i][0] = i;
  }
  for (var j = 0; j < cols; j++) {
    matrix[0][j] = j;
  }

  for (var i = 1; i < rows; i++) {
    for (var j = 1; j < cols; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      matrix[i][j] = [
        matrix[i - 1][j] + 1,
        matrix[i][j - 1] + 1,
        matrix[i - 1][j - 1] + cost,
      ].reduce((left, right) => left < right ? left : right);
    }
  }
  return matrix[a.length][b.length];
}

/// True when [haystack] contains [needle] or a close token match.
bool assistantFuzzyContains(String haystack, String needle) {
  if (needle.isEmpty) return false;
  if (haystack.contains(needle)) return true;
  if (needle.length < 5) return false;

  final maxDistance = needle.length <= 6 ? 1 : 2;
  for (final token in haystack.split(' ')) {
    if (token.length < 4) continue;
    if (assistantLevenshteinDistance(token, needle) <= maxDistance) {
      return true;
    }
  }
  return false;
}
