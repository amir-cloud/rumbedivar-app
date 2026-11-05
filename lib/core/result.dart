/// Simple Result wrapper to avoid throw-heavy call sites.
sealed class Result<T> {
  const Result();
  factory Result.ok(T value) = Ok<T>;
  factory Result.fail(String message, {String code = 'unknown'}) {
    return Fail<T>(message, code: code);
  }
}

class Ok<T> extends Result<T> {
  final T value;
  const Ok(this.value);
}

class Fail<T> extends Result<T> {
  final String message;
  final String code;
  const Fail(this.message, {this.code = 'unknown'});
}
