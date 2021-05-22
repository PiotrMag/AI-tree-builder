class DataFrame {
  late List<String> _headers;
  late List<List<String?>> _rows;

  DataFrame() {
    _headers = [];
    _rows = [];
  }

  // Dodaje nową kolumnę do [DataFrame]
  //
  // Należy podać nazwę kolumny, która ma zostać utworzona
  // Jeżeli nazwa jest pusta, to kolumna nie zostanie dodana
  void addColumn(String name) {
    if (name.isNotEmpty) {
      _headers.add(name);
      _rows.forEach((row) {
        row.add(null);
      });
    }
  }

  // Usuwa kolumnę na podanym indeksie - [index]
  //
  // Jeżeli [index] jest niewłaściwy, to nic się nie dzieje
  void removeColumn(int index) {
    if (index >= 0 && index < _headers.length) {
      _headers.removeAt(index);
      if (_headers.length <= 0) {
        _rows.clear();
      } else {
        _rows.forEach((row) {
          row.removeAt(index);
        });
      }
    }
  }

  // Zwraca wszystkie nagłówki przechowywane w [DataFrame]
  List<String> getHeaders() {
    return _headers;
  }

  // Dodaje nowy wiersz do [DataFrame]
  //
  // Komórki wiersza mogą być null
  // Opcjonalny parametr [fillIfShorter] pozwala określić
  // czy w przypadku jeżeli pdany wiersz jest krótszy
  // od tego czego spodziewało by się [DataFrame], to czy ma
  // on być uzupełniony wartością [fillValue]
  // Dodatkowo parametr [throwIfLonger] pozwala określić, czy
  // wyrzucany jest wyjątek w przypadku, gdy wiersz podany do
  // dodania jest dłuższy niż to, czego spodziewałoby się
  // [DataFrame]
  void addRow(
    List<String?> row, {
    fillIfShorter = true,
    fillValue = null,
    throwIfLonger = false,
  }) {
    int headersCount = _headers.length;
    int rowLength = row.length;

    if (headersCount == rowLength) {
      _rows.add(row);
    } else if (headersCount < rowLength) {
      if (throwIfLonger) {
        throw Exception(
            'Próbowano dodać wiersz o długości $rowLength, a spodziewano się długości $headersCount (za długi wiersz)');
      } else {
        List<String?> sublist = row.sublist(0, headersCount);
        _rows.add(sublist);
      }
    } else {
      if (fillIfShorter) {
        for (int i = 0; i < (headersCount - rowLength); i++) {
          row.add(fillValue);
        }
        _rows.add(row);
      } else {
        throw Exception(
            'Próbowano dodać wiersz o długości $rowLength, a spodziewano się długości $headersCount (za krótki wiersz)');
      }
    }
  }

  // Usuwa wiersz na podanym [index]
  //
  // Jeżeli [index] jest poza zakresem [DataFrame]
  // to nic się nie dzieje
  void removeRow(int index) {
    if (index >= 0 && index < _rows.length) {
      _rows.removeAt(index);
    }
  }

  // Zwraca wszystkie wiersze z [DataFrame]
  List<List<String?>> getRows() {
    return _rows;
  }
}
