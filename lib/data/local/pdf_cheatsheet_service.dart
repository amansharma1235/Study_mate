import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Service responsible for generating and exporting print-ready A4 Study Cheatsheets,
/// Formula sheets, and Exam Revision Kits.
class PdfCheatsheetService {
  /// Generate a high-yield A4 revision cheatsheet PDF as raw bytes
  static Future<Uint8List> generateCheatsheetPdf({
    required String title,
    required String subject,
    List<String> summaryBullets = const [],
    List<String> formulas = const [],
    List<Map<String, String>> questions = const [],
    String? customNotes,
    bool includeFormulas = true,
    bool includeQuestions = true,
    bool includeSummary = true,
  }) async {
    final pdf = pw.Document(
      title: '$title - Study Cheatsheet',
      author: 'Study Mate App',
    );

    // Load standard font fallback
    final regularFont = await PdfGoogleFonts.outfitRegular();
    final boldFont = await PdfGoogleFonts.outfitBold();
    final semiBoldFont = await PdfGoogleFonts.outfitSemiBold();

    final formattedDate =
        DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: regularFont,
          bold: boldFont,
        ),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Row(
                    children: [
                      pw.Container(
                        width: 28,
                        height: 28,
                        decoration: const pw.BoxDecoration(
                          color: PdfColor.fromInt(0xFF4F46E5), // Indigo
                          shape: pw.BoxShape.circle,
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            'S',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'STUDY MATE',
                            style: pw.TextStyle(
                              font: boldFont,
                              fontSize: 12,
                              color: const PdfColor.fromInt(0xFF4F46E5),
                              letterSpacing: 1.2,
                            ),
                          ),
                          pw.Text(
                            'Exam Cheatsheet & Revision Kit',
                            style: pw.TextStyle(
                              fontSize: 9,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: pw.BoxDecoration(
                      color: const PdfColor.fromInt(0xFFEEF2FF),
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(
                        color: const PdfColor.fromInt(0xFFC7D2FE),
                        width: 1,
                      ),
                    ),
                    child: pw.Text(
                      subject.toUpperCase(),
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 9,
                        color: const PdfColor.fromInt(0xFF4338CA),
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Container(
                height: 2,
                color: const PdfColor.fromInt(0xFFE2E8F0),
              ),
              pw.SizedBox(height: 14),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Column(
            children: [
              pw.SizedBox(height: 8),
              pw.Container(
                height: 1,
                color: const PdfColor.fromInt(0xFFE2E8F0),
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Generated via Study Mate AI • $formattedDate',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.Text(
                    'Page ${context.pageNumber} of ${context.pagesCount}',
                    style: pw.TextStyle(
                      font: semiBoldFont,
                      fontSize: 8,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
        build: (pw.Context context) => [
          // Title Banner
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFF8FAFC),
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(
                color: const PdfColor.fromInt(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 18,
                    color: const PdfColor.fromInt(0xFF0F172A),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'High-Yield Quick Revision & Formula Sheet for Top Exam Scores',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 16),

          // 1. Key Summary Concepts
          if (includeSummary && summaryBullets.isNotEmpty) ...[
            _buildSectionHeader(
              title: 'Key Concepts & High-Yield Summary',
              iconChar: '★',
              boldFont: boldFont,
              accentColor: const PdfColor.fromInt(0xFF059669), // Emerald
            ),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFFF0FDF4),
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(
                  color: const PdfColor.fromInt(0xFFBBF7D0),
                  width: 1,
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: summaryBullets.map((bullet) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 6),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          margin: const pw.EdgeInsets.only(top: 4, right: 8),
                          width: 5,
                          height: 5,
                          decoration: const pw.BoxDecoration(
                            color: PdfColor.fromInt(0xFF059669),
                            shape: pw.BoxShape.circle,
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            bullet,
                            style: const pw.TextStyle(
                              fontSize: 9.5,
                              color: PdfColor.fromInt(0xFF1E293B),
                              lineSpacing: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            pw.SizedBox(height: 16),
          ],

          // 2. Formulas & Definitions Cheatsheet
          if (includeFormulas && formulas.isNotEmpty) ...[
            _buildSectionHeader(
              title: 'Formulas, Rules & Definition Cheatsheet',
              iconChar: '∑',
              boldFont: boldFont,
              accentColor: const PdfColor.fromInt(0xFFD97706), // Amber
            ),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFFFFFBEB),
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(
                  color: const PdfColor.fromInt(0xFFFDE68A),
                  width: 1,
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: formulas.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final formula = entry.value;
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 6),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: pw.BoxDecoration(
                            color: const PdfColor.fromInt(0xFFF59E0B),
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Text(
                            'F$idx',
                            style: pw.TextStyle(
                              font: boldFont,
                              color: PdfColors.white,
                              fontSize: 7.5,
                            ),
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Expanded(
                          child: pw.Text(
                            formula,
                            style: pw.TextStyle(
                              font: semiBoldFont,
                              fontSize: 9.5,
                              color: const PdfColor.fromInt(0xFF78350F),
                              lineSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            pw.SizedBox(height: 16),
          ],

          // 3. Expected Exam Questions & Solutions
          if (includeQuestions && questions.isNotEmpty) ...[
            _buildSectionHeader(
              title: 'Top Expected Exam Questions & Model Answers',
              iconChar: '?',
              boldFont: boldFont,
              accentColor: const PdfColor.fromInt(0xFF4F46E5), // Indigo
            ),
            pw.SizedBox(height: 8),
            ...questions.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final q = entry.value;
              final questionText = q['question'] ?? '';
              final answerText = q['answer'] ?? '';
              final difficulty = q['difficulty'] ?? 'Medium';

              PdfColor diffColor = const PdfColor.fromInt(0xFF2563EB);
              if (difficulty.toLowerCase().contains('hard')) {
                diffColor = const PdfColor.fromInt(0xFFDC2626);
              } else if (difficulty.toLowerCase().contains('easy')) {
                diffColor = const PdfColor.fromInt(0xFF059669);
              }

              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 8),
                padding: const pw.EdgeInsets.all(9),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFFAFAFA),
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(
                    color: const PdfColor.fromInt(0xFFE2E8F0),
                    width: 0.8,
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          'Q$idx. ',
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 10,
                            color: const PdfColor.fromInt(0xFF4F46E5),
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            questionText,
                            style: pw.TextStyle(
                              font: semiBoldFont,
                              fontSize: 9.5,
                              color: const PdfColor.fromInt(0xFF0F172A),
                            ),
                          ),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: pw.BoxDecoration(
                            color: diffColor.flatten(),
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Text(
                            difficulty.toUpperCase(),
                            style: pw.TextStyle(
                              font: boldFont,
                              color: PdfColors.white,
                              fontSize: 7,
                            ),
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(6),
                      decoration: pw.BoxDecoration(
                        color: const PdfColor.fromInt(0xFFF1F5F9),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Ans: ',
                            style: pw.TextStyle(
                              font: boldFont,
                              fontSize: 8.5,
                              color: const PdfColor.fromInt(0xFF475569),
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Text(
                              answerText,
                              style: const pw.TextStyle(
                                fontSize: 8.5,
                                color: PdfColor.fromInt(0xFF334155),
                                lineSpacing: 1.25,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            pw.SizedBox(height: 12),
          ],

          // 4. Custom Notes / Tips if provided
          if (customNotes != null && customNotes.trim().isNotEmpty) ...[
            _buildSectionHeader(
              title: 'Personal Study Notes & Revision Tips',
              iconChar: '✎',
              boldFont: boldFont,
              accentColor: const PdfColor.fromInt(0xFF8B5CF6), // Purple
            ),
            pw.SizedBox(height: 6),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFFFDF4FF),
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(
                  color: const PdfColor.fromInt(0xFFF0ABFC),
                  width: 1,
                ),
              ),
              child: pw.Text(
                customNotes,
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColor.fromInt(0xFF4A044E),
                  lineSpacing: 1.3,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  /// Helper to build consistent, clean section headers
  static pw.Widget _buildSectionHeader({
    required String title,
    required String iconChar,
    required pw.Font boldFont,
    required PdfColor accentColor,
  }) {
    return pw.Row(
      children: [
        pw.Container(
          width: 18,
          height: 18,
          decoration: pw.BoxDecoration(
            color: accentColor,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Center(
            child: pw.Text(
              iconChar,
              style: pw.TextStyle(
                font: boldFont,
                color: PdfColors.white,
                fontSize: 10,
              ),
            ),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Text(
          title,
          style: pw.TextStyle(
            font: boldFont,
            fontSize: 11.5,
            color: const PdfColor.fromInt(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  /// Print or layout the PDF directly
  static Future<void> printCheatsheet({
    required Uint8List pdfBytes,
    required String fileName,
  }) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: fileName,
    );
  }

  /// Share the PDF via Android Share Sheet (WhatsApp, Drive, Email, etc.)
  static Future<void> shareCheatsheet({
    required Uint8List pdfBytes,
    required String fileName,
  }) async {
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: fileName.endsWith('.pdf') ? fileName : '$fileName.pdf',
    );
  }
}
