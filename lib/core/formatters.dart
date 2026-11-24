import 'package:intl/intl.dart';

final _inr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
final _inr2 = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

String rupees(double v) => (v == v.roundToDouble()) ? _inr.format(v) : _inr2.format(v);
String fmtDate(DateTime? d) => d == null ? '—' : DateFormat('dd MMM yyyy').format(d);
String fmtDateTime(DateTime? d) => d == null ? '—' : DateFormat('dd MMM yyyy, hh:mm a').format(d);
String humanize(String s) => s.replaceAll('payment_', 'payment ').replaceAll('_', ' ').split(' ').map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1)).join(' ');
