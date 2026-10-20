import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

import '../../core/constants/app_colors.dart';
import '../../data/local/pdf_cheatsheet_service.dart';
import '../gamification/gamification_controller.dart';

class PdfCheatsheetScreen extends ConsumerStatefulWidget {
  final String title;
  final String subject;
  final List<String> summaryBullets;
  final List<String> formulas;
  final List<Map<String, String>> questions;
  final String? customNotes;

  const PdfCheatsheetScreen({
    super.key,
    this.title = 'Complete Physics - Quantum Mechanics & Wave Optics',
    this.subject = 'Physics',
    this.summaryBullets = const [
      'Wave-Particle Duality: De Broglie wavelength λ = h/p connects momentum with particle wavelength.',
      'Heisenberg Uncertainty: Δx · Δp ≥ ℏ/2 establishes quantum mechanical limits on simultaneous measurement.',
      'Photoelectric Equation: Kinetic Energy max = hν - Φ, where Φ is the material work function.',
      'Superposition Principle: Total wavefunction is linear sum of individual states: Ψ = c₁ψ₁ + c₂ψ₂.',
      'Constructive Interference: Path difference Δx = nλ gives central bright fringe maximums.',
    ],
    this.formulas = const [
      'λ = h / (m · v) (De Broglie Wavelength formula)',
      'E = h · ν = (h · c) / λ (Photon energy equation)',
      'K_max = e · V_s = hν - Φ (Einstein photoelectric formula)',
      'Δx · Δp ≥ h / (4π) (Heisenberg uncertainty limit)',
      'β = (λ · D) / d (Young\'s double slit fringe width)',
    ],
    this.questions = const [
      {
        'question': 'Derive Einstein\'s Photoelectric equation and explain stopping potential.',
        'answer': 'When radiation of frequency ν strikes metal, photon gives energy hν. Work function Φ removes electron, remaining becomes max kinetic energy: K_max = hν - Φ = eV_0.',
        'difficulty': 'Hard',
      },
      {
        'question': 'State Heisenberg Uncertainty principle and its physical significance.',
        'answer': 'Simultaneous determination of position and momentum of subatomic particle with absolute precision is impossible: Δx · Δp ≥ ℏ/2.',
        'difficulty': 'Medium',
      },
      {
        'question': 'What is the condition for sustained constructive interference?',
        'answer': 'Sources must be coherent (constant phase difference), monochromatic, and path difference must be an integer multiple: Δx = nλ.',
        'difficulty': 'Easy',
      },
    ],
    this.customNotes,
  });

  @override
  ConsumerState<PdfCheatsheetScreen> createState() =>
      _PdfCheatsheetScreenState();
}

class _PdfCheatsheetScreenState extends ConsumerState<PdfCheatsheetScreen> {
  bool _includeSummary = true;
  bool _includeFormulas = true;
  bool _includeQuestions = true;
  bool _hasAwardedXp = false;

  Uint8List? _cachedBytes;

  Future<Uint8List> _buildPdfDoc(PdfPageFormat format) async {
    final bytes = await PdfCheatsheetService.generateCheatsheetPdf(
      title: widget.title,
      subject: widget.subject,
      summaryBullets: widget.summaryBullets,
      formulas: widget.formulas,
      questions: widget.questions,
      customNotes: widget.customNotes,
      includeSummary: _includeSummary,
      includeFormulas: _includeFormulas,
      includeQuestions: _includeQuestions,
    );
    _cachedBytes = bytes;
    return bytes;
  }

  void _triggerXpReward() {
    if (!_hasAwardedXp) {
      _hasAwardedXp = true;
      ref.read(gamificationControllerProvider.notifier).awardXp(
            amount: 25,
            reason: 'Generated PDF Cheatsheet',
            context: context,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A4 Revision Cheatsheet',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Share PDF',
            icon: const Icon(Icons.share_rounded),
            onPressed: () async {
              _triggerXpReward();
              if (_cachedBytes != null) {
                await PdfCheatsheetService.shareCheatsheet(
                  pdfBytes: _cachedBytes!,
                  fileName: '${widget.title}_cheatsheet',
                );
              }
            },
          ),
          IconButton(
            tooltip: 'Print / Save PDF',
            icon: const Icon(Icons.print_rounded),
            onPressed: () async {
              _triggerXpReward();
              if (_cachedBytes != null) {
                await PdfCheatsheetService.printCheatsheet(
                  pdfBytes: _cachedBytes!,
                  fileName: '${widget.title}_cheatsheet',
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    avatar: Icon(
                      _includeSummary ? Icons.check_circle : Icons.circle_outlined,
                      size: 16,
                      color: _includeSummary ? Colors.white : AppColors.primary,
                    ),
                    label: Text(
                      'Summary (${widget.summaryBullets.length})',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _includeSummary ? Colors.white : null,
                      ),
                    ),
                    selected: _includeSummary,
                    selectedColor: AppColors.primary,
                    onSelected: (val) {
                      setState(() => _includeSummary = val);
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    avatar: Icon(
                      _includeFormulas ? Icons.check_circle : Icons.circle_outlined,
                      size: 16,
                      color: _includeFormulas ? Colors.white : AppColors.warning,
                    ),
                    label: Text(
                      'Formulas (${widget.formulas.length})',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _includeFormulas ? Colors.white : null,
                      ),
                    ),
                    selected: _includeFormulas,
                    selectedColor: AppColors.warning,
                    onSelected: (val) {
                      setState(() => _includeFormulas = val);
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    avatar: Icon(
                      _includeQuestions ? Icons.check_circle : Icons.circle_outlined,
                      size: 16,
                      color: _includeQuestions ? Colors.white : AppColors.secondary,
                    ),
                    label: Text(
                      'Exam Q&As (${widget.questions.length})',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _includeQuestions ? Colors.white : null,
                      ),
                    ),
                    selected: _includeQuestions,
                    selectedColor: AppColors.secondary,
                    onSelected: (val) {
                      setState(() => _includeQuestions = val);
                    },
                  ),
                ],
              ),
            ),
          ),

          // Interactive PDF Preview
          Expanded(
            child: PdfPreview(
              maxPageWidth: 700,
              build: (format) => _buildPdfDoc(format),
              canChangeOrientation: false,
              canChangePageFormat: false,
              canDebug: false,
              actions: [
                PdfPreviewAction(
                  icon: const Icon(Icons.card_giftcard, color: Colors.amber),
                  onPressed: (context, build, page) async {
                    _triggerXpReward();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🎉 +25 Scholar XP Awarded for studying!'),
                      ),
                    );
                  },
                ),
              ],
              onPrinted: (context) => _triggerXpReward(),
              onShared: (context) => _triggerXpReward(),
            ),
          ),
        ],
      ),
    );
  }
}
