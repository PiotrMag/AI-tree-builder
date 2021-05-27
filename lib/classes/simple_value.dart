class SimpleValue<T> {
  T? value;

  SimpleValue({value}) {
    if (value != null) {
      this.value = value;
    }
  }
}
