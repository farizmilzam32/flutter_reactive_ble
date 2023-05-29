T selectFrom<T>(List<T> values,
    {required BigInt? index, required T Function(BigInt? index) fallback}) {
  if (index != null && index >= 0 && index < values.length) {
    return values[index];
  }
  return fallback(index);
}
