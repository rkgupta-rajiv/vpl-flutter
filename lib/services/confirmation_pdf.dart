import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/formatters.dart';
import '../models/models.dart';
import '../models/options.dart';

/// Builds the downloadable registration confirmation (A5 PDF).
Future<Uint8List> buildConfirmationPdf(Confirmation c, {Uint8List? photo}) async {
  final doc = pw.Document(title: 'Registration ${c.registrationNo}', author: c.tournament);
  const green = PdfColor.fromInt(0xFF13704A);
  const dark = PdfColor.fromInt(0xFF0A3A28);
  const gold = PdfColor.fromInt(0xFFF5B301);

  pw.Widget row(String k, String? v) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 3),
        child: pw.Row(children: [
          pw.SizedBox(width: 110, child: pw.Text(k, style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 10))),
          pw.Expanded(child: pw.Text((v == null || v.isEmpty) ? '-' : v, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10.5))),
        ]),
      );

  doc.addPage(pw.Page(
    pageFormat: PdfPageFormat.a5,
    margin: const pw.EdgeInsets.all(24),
    build: (_) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
      pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: const pw.BoxDecoration(color: dark, borderRadius: pw.BorderRadius.all(pw.Radius.circular(10))),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('REGISTRATION CONFIRMATION', style: pw.TextStyle(color: gold, fontSize: 9, fontWeight: pw.FontWeight.bold, letterSpacing: 1.5)),
          pw.SizedBox(height: 4),
          pw.Text(c.tournament, style: pw.TextStyle(color: PdfColors.white, fontSize: 16, fontWeight: pw.FontWeight.bold)),
        ]),
      ),
      pw.SizedBox(height: 14),
      pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        if (photo != null)
          pw.Container(
            width: 80,
            height: 96,
            margin: const pw.EdgeInsets.only(right: 14),
            child: pw.ClipRRect(horizontalRadius: 6, verticalRadius: 6, child: pw.Image(pw.MemoryImage(photo), fit: pw.BoxFit.cover)),
          ),
        pw.Expanded(
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(c.playerName, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: const pw.BoxDecoration(color: gold, borderRadius: pw.BorderRadius.all(pw.Radius.circular(6))),
              child: pw.Text('Registration ID: ${c.registrationNo}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
            ),
            pw.SizedBox(height: 6),
            pw.Text('Status: CONFIRMED (payment verified)', style: pw.TextStyle(color: green, fontWeight: pw.FontWeight.bold, fontSize: 10)),
          ]),
        ),
      ]),
      pw.SizedBox(height: 14),
      pw.Divider(color: PdfColors.grey300),
      row('Mobile', c.mobile),
      row('Email', c.email),
      row('Village', c.village),
      row('Age / Gender', '${c.age ?? '-'} / ${Options.label(Options.genders, c.gender)}'),
      row('Playing role', Options.label(Options.roles, c.playingRole)),
      row('Batting / Bowling', '${Options.label(Options.batting, c.battingStyle)} / ${Options.label(Options.bowling, c.bowlingStyle)}'),
      row('T-shirt size', c.tshirtSize),
      row('Jersey', '#${c.jerseyNumber ?? '-'}  ${c.jerseyName ?? ''}'),
      pw.Divider(color: PdfColors.grey300),
      row('Fee paid', 'Rs. ${c.feePaid.toStringAsFixed(2)}'),
      row('Transaction / UTR', c.transactionId),
      row('Confirmed on', fmtDateTime(c.confirmedAt)),
      pw.Spacer(),
      pw.Text('Please carry this confirmation and your original Aadhaar card on the tournament day.',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700), textAlign: pw.TextAlign.center),
    ]),
  ));
  return doc.save();
}
