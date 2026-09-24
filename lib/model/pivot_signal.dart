/// Sinyal pivot yang dipakai bersama oleh Hangseng maupun Gold.
///
/// Enum ini SENGAJA hanya dideklarasikan di satu tempat. Sebelumnya enum yang
/// sama dideklarasikan ulang di model dan di viewmodel, sehingga ketika sebuah
/// file meng-import keduanya Dart menganggap `PivotSignal` ambigu
/// (error: 'PivotSignal' is imported from both ...).
enum PivotSignal { buy, sell, neutral, unavailable }