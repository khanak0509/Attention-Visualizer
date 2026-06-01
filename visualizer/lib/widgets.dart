import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'painters.dart';
import 'typography.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.detail,
    this.accentColor = AppColors.accent,
  });

  final String label;
  final String value;
  final String? subtitle;
  final String? detail;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: interText(
                    10,
                    color: AppColors.textSecondary,
                    weight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: monoText(16, weight: FontWeight.w700, color: AppColors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: interText(10, color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (detail != null) ...[
            const SizedBox(height: 2),
            Text(
              detail!,
              style: interText(9, color: AppColors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: interText(16, weight: FontWeight.w600)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: interText(12, color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }
}

class FindingCard extends StatelessWidget {
  const FindingCard({
    super.key,
    required this.title,
    required this.body,
    this.icon = Icons.lightbulb_outline,
  });

  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: interText(14, weight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(body, style: interText(13, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ColoredChip extends StatelessWidget {
  const ColoredChip({
    super.key,
    required this.label,
    required this.color,
    this.textColor = AppColors.textPrimary,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(label, style: monoText(11, color: textColor)),
    );
  }
}

class HeadTypeChip extends StatelessWidget {
  const HeadTypeChip({super.key, required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.headTypeColor(type),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.headTypeAccent(type)),
      ),
      child: Text(
        type.toUpperCase(),
        style: monoText(11, weight: FontWeight.w600,
            color: AppColors.headTypeAccent(type)),
      ),
    );
  }
}

class ResearchChip extends StatelessWidget {
  const ResearchChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: monoText(12, weight: FontWeight.w600, color: AppColors.textPrimary),
      ),
    );
  }
}

class SentenceCard extends StatelessWidget {
  const SentenceCard({super.key, required this.tokens});

  final List<String> tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: tokens.map((t) {
          final isSpecial = t == '[CLS]' || t == '[SEP]';
          return ColoredChip(
            label: t,
            color: isSpecial
                ? AppColors.border
                : AppColors.surface,
            textColor: AppColors.textPrimary,
          );
        }).toList(),
      ),
    );
  }
}

class TaxonomyDonut extends StatelessWidget {
  const TaxonomyDonut({super.key, required this.counts});

  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: CustomPaint(
              painter: DonutChartPainter(
                counts: counts,
                colors: AppColors.taxonomyDonutColors,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: counts.entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.taxonomyDonutColors[e.key],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(e.key, style: interText(13)),
                      ),
                      Text(
                        '${e.value}',
                        style: monoText(13, weight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class MiniStatRow extends StatelessWidget {
  const MiniStatRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: interText(13, color: AppColors.textSecondary)),
          ),
          Text(value, style: monoText(12, weight: FontWeight.w600)),
        ],
      ),
    );
  }
}
