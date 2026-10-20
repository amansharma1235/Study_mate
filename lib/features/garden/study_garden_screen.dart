import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/routing/route_names.dart';
import '../../core/utils/app_haptics.dart';
import '../../data/local/preference_service.dart';

class GardenTreeSpecies {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final int cost;
  final Color themeColor;

  const GardenTreeSpecies({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.cost,
    required this.themeColor,
  });
}

const List<GardenTreeSpecies> kGardenSpeciesList = [
  GardenTreeSpecies(
    id: 'bonsai_sprout',
    name: 'Green Sprout',
    emoji: '🌱',
    description: 'Fresh initial growth from mindful focus',
    cost: 0,
    themeColor: Color(0xFF10B981),
  ),
  GardenTreeSpecies(
    id: 'sakura_tree',
    name: 'Sakura Blossom',
    emoji: '🌸',
    description: 'Serene cherry blossoms of high concentration',
    cost: 50,
    themeColor: Color(0xFFF472B6),
  ),
  GardenTreeSpecies(
    id: 'evergreen_pine',
    name: 'Nordic Pine',
    emoji: '🌲',
    description: 'Resilient and evergreen through intense study',
    cost: 100,
    themeColor: Color(0xFF059669),
  ),
  GardenTreeSpecies(
    id: 'oasis_palm',
    name: 'Oasis Palm',
    emoji: '🌴',
    description: 'Calm tropical focus under exam pressure',
    cost: 150,
    themeColor: Color(0xFF14B8A6),
  ),
  GardenTreeSpecies(
    id: 'glow_mushroom',
    name: 'Glowshroom',
    emoji: '🍄',
    description: 'Magical forest glow for deep late-night study',
    cost: 200,
    themeColor: Color(0xFFA855F7),
  ),
  GardenTreeSpecies(
    id: 'golden_bodhi',
    name: 'Golden Bodhi',
    emoji: '👑',
    description: 'The supreme symbol of academic mastery',
    cost: 350,
    themeColor: Color(0xFFF59E0B),
  ),
];

class PlantedTreeItem {
  final String id;
  final String species;
  final String subject;
  final int durationMinutes;
  final DateTime plantedAt;
  final bool isWithered;

  PlantedTreeItem({
    required this.id,
    required this.species,
    required this.subject,
    required this.durationMinutes,
    required this.plantedAt,
    this.isWithered = false,
  });

  factory PlantedTreeItem.fromJson(Map<String, dynamic> json) {
    return PlantedTreeItem(
      id: json['id'] as String? ?? '',
      species: json['species'] as String? ?? 'bonsai_sprout',
      subject: json['subject'] as String? ?? 'General Study',
      durationMinutes: json['durationMinutes'] as int? ?? 25,
      plantedAt:
          DateTime.tryParse(json['plantedAt'] as String? ?? '') ?? DateTime.now(),
      isWithered: (json['isWithered'] as bool?) ??
          (json['species'] == 'withered_bush'),
    );
  }
}

class StudyGardenScreen extends ConsumerStatefulWidget {
  const StudyGardenScreen({super.key});

  @override
  ConsumerState<StudyGardenScreen> createState() => _StudyGardenScreenState();
}

class _StudyGardenScreenState extends ConsumerState<StudyGardenScreen> {
  late int _coins;
  late List<String> _unlockedSpecies;
  late String _selectedSpecies;
  late List<PlantedTreeItem> _plantedTrees;

  @override
  void initState() {
    super.initState();
    _loadGardenData();
  }

  void _loadGardenData() {
    final prefs = ref.read(preferenceServiceProvider);
    _coins = prefs.getStudyCoins();
    _unlockedSpecies = prefs.getUnlockedTreeIds();
    _selectedSpecies = prefs.getSelectedTreeId();

    final rawJsonList = prefs.getPlantedTreesJsonList();
    _plantedTrees = [];
    for (final jsonStr in rawJsonList) {
      try {
        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
        _plantedTrees.add(PlantedTreeItem.fromJson(decoded));
      } catch (_) {}
    }
    // Sort newest first
    _plantedTrees.sort((a, b) => b.plantedAt.compareTo(a.plantedAt));
    setState(() {});
  }

  Future<void> _unlockSpecies(GardenTreeSpecies species) async {
    if (_coins < species.cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Need ${species.cost - _coins} more 🪙 coins! Complete more Pomodoro sessions to earn.',
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final prefs = ref.read(preferenceServiceProvider);
    await prefs.setStudyCoins(_coins - species.cost);
    await prefs.unlockTreeId(species.id);
    await prefs.setSelectedTreeId(species.id);

    AppHaptics.celebration();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 Unlocked ${species.name} ${species.emoji}! Now active in focus sessions.'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );

    _loadGardenData();
  }

  Future<void> _selectSpecies(String speciesId) async {
    final prefs = ref.read(preferenceServiceProvider);
    await prefs.setSelectedTreeId(speciesId);
    AppHaptics.selection();
    if (!mounted) return;
    setState(() {
      _selectedSpecies = speciesId;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Equipped tree for upcoming focus sessions! 🌱'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  GardenTreeSpecies _findSpecies(String id) {
    return kGardenSpeciesList.firstWhere(
      (s) => s.id == id,
      orElse: () => kGardenSpeciesList.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalFocusMinutes = _plantedTrees.fold<int>(0, (sum, t) => sum + t.durationMinutes);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Row(
          children: [
            Text('Virtual Study Garden 🌲', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        actions: [
          // Coins balance chip
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🪙', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  '$_coins',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Garden Stats Hero Card
            _buildGardenStatsCard(totalFocusMinutes),
            const SizedBox(height: 20),

            // Seed Nursery / Tree Shop
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tree Species Nursery 🌿',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${_unlockedSpecies.length}/${kGardenSpeciesList.length} Unlocked',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondaryDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildSpeciesCarousel(),
            const SizedBox(height: 24),

            // Planted Sanctuary Grid Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Forest Sanctuary 🏡',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${_plantedTrees.length} Trees Grown',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Forest Grid or Empty State
            if (_plantedTrees.isEmpty)
              _buildEmptyGardenState()
            else
              _buildForestGrid(),

            const SizedBox(height: 32),
            // Start Focus CTA
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => context.push(AppRoutes.timer),
                icon: const Icon(Icons.timer_rounded, color: Colors.white),
                label: const Text(
                  'Start Focus Session (+10 🪙 & 1 Tree)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildGardenStatsCard(int totalFocusMinutes) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF064E3B), Color(0xFF047857), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Text('🌲', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Virtual Focus Forest',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Every completed timer plants a real virtual tree!',
                      style: TextStyle(
                        color: Color(0xFFD1FAE5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Trees', '${_plantedTrees.length}', '🌳'),
                _buildStatDivider(),
                _buildStatItem('Focus Time', '${totalFocusMinutes}m', '⏱️'),
                _buildStatDivider(),
                _buildStatItem('Coins Earned', '${_plantedTrees.length * 10}', '🪙'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String emoji) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 17,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFA7F3D0),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 28,
      color: Colors.white.withValues(alpha: 0.2),
    );
  }

  Widget _buildSpeciesCarousel() {
    return SizedBox(
      height: 175,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: kGardenSpeciesList.length,
        separatorBuilder: (_, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final species = kGardenSpeciesList[index];
          final isUnlocked = _unlockedSpecies.contains(species.id);
          final isSelected = _selectedSpecies == species.id;

          return Container(
            width: 145,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? species.themeColor.withValues(alpha: 0.15)
                  : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? species.themeColor
                    : Colors.grey.withValues(alpha: 0.2),
                width: isSelected ? 2.0 : 1.0,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: species.themeColor.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Emoji Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: species.themeColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Text(species.emoji, style: const TextStyle(fontSize: 28)),
                ),
                Text(
                  species.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                Text(
                  species.description,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                ),
                if (isSelected)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: species.themeColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'ACTIVE 🌱',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  )
                else if (isUnlocked)
                  SizedBox(
                    width: double.infinity,
                    height: 26,
                    child: OutlinedButton(
                      onPressed: () => _selectSpecies(species.id),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        side: BorderSide(color: species.themeColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Equip',
                        style: TextStyle(
                          color: species.themeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    height: 26,
                    child: ElevatedButton(
                      onPressed: () => _unlockSpecies(species),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🪙', style: TextStyle(fontSize: 10)),
                          const SizedBox(width: 4),
                          Text(
                            '${species.cost}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyGardenState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Text('🌱', style: TextStyle(fontSize: 36)),
          ),
          const SizedBox(height: 14),
          const Text(
            'Your Sanctuary is Ready!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Start a 25-minute Pomodoro study session. Once complete, your active tree will grow here and you will earn +10 coins 🪙!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondaryDark,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForestGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _plantedTrees.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.88,
      ),
      itemBuilder: (context, index) {
        final tree = _plantedTrees[index];
        final species = _findSpecies(tree.species);
        final isWithered = tree.isWithered;
        final treeEmoji = isWithered ? '🥀' : species.emoji;
        final treeColor = isWithered ? Colors.grey : species.themeColor;
        final treeLabel = isWithered ? 'Withered' : '${tree.durationMinutes}m focus';

        return InkWell(
          onTap: () {
            AppHaptics.light();
            _showTreeDetailModal(tree, species);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isWithered
                  ? Colors.black.withValues(alpha: 0.05)
                  : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isWithered
                    ? Colors.red.withValues(alpha: 0.3)
                    : species.themeColor.withValues(alpha: 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(treeEmoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(height: 6),
                Text(
                  tree.subject,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    decoration: isWithered ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  treeLabel,
                  style: TextStyle(
                    fontSize: 9,
                    color: treeColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTreeDetailModal(PlantedTreeItem tree, GardenTreeSpecies species) {
    final isWithered = tree.isWithered;
    final emoji = isWithered ? '🥀' : species.emoji;
    final title = isWithered ? 'Withered Tree 🥀' : '${species.name} Tree';
    final desc = isWithered
        ? 'This tree withered because focus was broken during Strict Anti-Distraction Mode.'
        : 'Grown during study of "${tree.subject}"';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryDark),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Chip(
                  avatar: const Text('⏱️', style: TextStyle(fontSize: 12)),
                  label: Text('${tree.durationMinutes} Minutes'),
                ),
                const SizedBox(width: 10),
                Chip(
                  avatar: const Text('🪙', style: TextStyle(fontSize: 12)),
                  label: const Text('+10 Coins Earned'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Planted on: ${tree.plantedAt.day}/${tree.plantedAt.month}/${tree.plantedAt.year} at ${tree.plantedAt.hour.toString().padLeft(2, '0')}:${tree.plantedAt.minute.toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
