String objectPluralPL(int count) {
  if (count <= 0) {
    return 'obiektów';
  } else if (count == 1) {
    return 'obiekt';
  } else if (count < 5) {
    return 'obiekty';
  } else {
    return 'obiektów';
  }
}
