import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../shared/constants/app_colors.dart';

/// Supported 3D Card Types based on skeuomorphic neo-glass inspiration
enum Card3DType {
  totalCapital,
  availableCapital,
  totalInvestment,
  totalSales,
  unsoldStock,
  totalProfit,
  totalLoss,
  finalProfit,
  totalBaki,
  damagedStockLoss,
  mobileSales,
  mobileUnits,
  mobileProfit,
  mobileLoss,
  mobileReturned,
  mobileDamaged,
  gadgetSales,
  gadgetUnits,
  gadgetProfit,
  gadgetLoss,
  gadgetReturned,
  gadgetDamaged,
  salaryExpense,
  officeRentExpense,
  shopRentExpense,
  extraCostExpense,
}

/// Redesigned Dashboard 3D Skeuomorphic Card
class Dashboard3DCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData badgeIcon;
  final Card3DType type;
  final VoidCallback? onTap;
  final Widget? customMicroWidget;
  final double valueFontSize;
  final double titleFontSize;

  const Dashboard3DCard({
    required this.title,
    required this.value,
    required this.badgeIcon,
    required this.type,
    this.onTap,
    this.customMicroWidget,
    this.valueFontSize = 20,
    this.titleFontSize = 13,
    super.key,
  });

  @override
  State<Dashboard3DCard> createState() => _Dashboard3DCardState();
}

class _Dashboard3DCardState extends State<Dashboard3DCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final style = _getCardStyle(widget.type);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: style.bgGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: _isHovered
                ? style.accentColor.withValues(alpha: 0.7)
                : style.borderColor,
            width: _isHovered ? 1.6 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: style.shadowColor.withValues(alpha: _isHovered ? 0.22 : 0.08),
              blurRadius: _isHovered ? 18 : 8,
              offset: Offset(0, _isHovered ? 6 : 3),
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.7),
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              // Background Pattern / Wave / Glow
              Positioned.fill(
                child: CustomPaint(
                  painter: _CardBackgroundPainter(
                    type: widget.type,
                    accentColor: style.accentColor,
                  ),
                ),
              ),

              // Card Content
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  hoverColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  splashColor: style.accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(22),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Row: Floating Squircle Badge & Optional Top-Right Tag
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Floating embossed Squircle Badge
                            _buildSquircleBadge(style),

                            // Optional top-right status indicator / trend pill
                            if (_hasTopRightPill(widget.type))
                              _buildTopRightIndicator(style),
                          ],
                        ),

                        // Center 3D Illustration Graphic (Adaptive scaling with FittedBox)
                        Expanded(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: SizedBox(
                                  width: 110,
                                  height: 70,
                                  child: Transform.scale(
                                    scale: 1.35,
                                    child: CustomPaint(
                                      painter: _CardCenterpiecePainter(
                                        type: widget.type,
                                        accentColor: style.accentColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Bottom Row: Value & Title (Left) + Micro-Widget (Right)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final cardW = constraints.maxWidth;
                            final showMicro = cardW >= 170;

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Value & Title
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          widget.value,
                                          style: TextStyle(
                                            fontFamily: 'Roboto',
                                            fontWeight: FontWeight.w800,
                                            fontSize: widget.valueFontSize,
                                            color: const Color(0xFF1E293B), // Deep Slate
                                            letterSpacing: -0.5,
                                            height: 1.1,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        widget.title,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: widget.titleFontSize,
                                          color: const Color(0xFF64748B), // Slate 500
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                if (showMicro) ...[
                                  const SizedBox(width: 6),
                                  // Bottom Right Micro Widget
                                  Flexible(
                                    flex: 0,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.bottomRight,
                                      child: widget.customMicroWidget ??
                                          _buildDefaultMicroWidget(widget.type, style),
                                    ),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSquircleBadge(_CardStyle style) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: style.accentColor.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          widget.badgeIcon,
          size: 24,
          color: style.accentColor,
        ),
      ),
    );
  }

  bool _hasTopRightPill(Card3DType type) {
    return type == Card3DType.totalProfit ||
        type == Card3DType.totalLoss ||
        type == Card3DType.finalProfit ||
        type == Card3DType.mobileProfit ||
        type == Card3DType.gadgetProfit;
  }

  Widget _buildTopRightIndicator(_CardStyle style) {
    final isPositive = widget.type != Card3DType.totalLoss &&
        widget.type != Card3DType.mobileLoss &&
        widget.type != Card3DType.gadgetLoss;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white, width: 1),
        boxShadow: [
          BoxShadow(
            color: style.accentColor.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            size: 13,
            color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultMicroWidget(Card3DType type, _CardStyle style) {
    switch (type) {
      case Card3DType.availableCapital:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'liquidity bar',
              style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 3),
            Container(
              width: 58,
              height: 7,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: const LinearGradient(
                  colors: [Color(0xFF2DD4BF), Color(0xFF818CF8)],
                ),
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: 3,
                  height: 7,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );

      case Card3DType.totalInvestment:
        return Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.9),
            boxShadow: [
              BoxShadow(
                color: style.accentColor.withValues(alpha: 0.2),
                blurRadius: 4,
              ),
            ],
          ),
          child: CustomPaint(painter: _PieChartPainter()),
        );

      case Card3DType.totalSales:
      case Card3DType.mobileSales:
      case Card3DType.gadgetSales:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 4,
              ),
            ],
          ),
          child: const Text(
            '৳ LIVE',
            style: TextStyle(
              color: Color(0xFF38BDF8),
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        );

      case Card3DType.unsoldStock:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Stock Ratio',
              style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 3),
            Container(
              width: 54,
              height: 7,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: const LinearGradient(
                  colors: [Color(0xFFA78BFA), Color(0xFFEC4899)],
                ),
              ),
            ),
          ],
        );

      case Card3DType.totalProfit:
      case Card3DType.finalProfit:
      case Card3DType.mobileProfit:
      case Card3DType.gadgetProfit:
        return Container(
          width: 32,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(10),
          ),
          child: CustomPaint(painter: _GaugeMeterPainter(color: style.accentColor)),
        );

      case Card3DType.totalLoss:
      case Card3DType.mobileLoss:
      case Card3DType.gadgetLoss:
      case Card3DType.damagedStockLoss:
      case Card3DType.mobileDamaged:
      case Card3DType.gadgetDamaged:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: const Color(0xFFEF4444).withValues(alpha: 0.4),
            ),
          ),
          child: const Text(
            'RISK/LOSS',
            style: TextStyle(
              color: Color(0xFFEF4444),
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        );

      case Card3DType.mobileReturned:
      case Card3DType.gadgetReturned:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
            ),
          ),
          child: const Text(
            'RETURNED',
            style: TextStyle(
              color: Color(0xFFD97706),
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        );

      case Card3DType.salaryExpense:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: const Color(0xFF6366F1).withValues(alpha: 0.4),
            ),
          ),
          child: const Text(
            'SALARY',
            style: TextStyle(
              color: Color(0xFF6366F1),
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        );

      case Card3DType.officeRentExpense:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF0F766E).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: const Color(0xFF0F766E).withValues(alpha: 0.4),
            ),
          ),
          child: const Text(
            'RENT',
            style: TextStyle(
              color: Color(0xFF0F766E),
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        );

      case Card3DType.shopRentExpense:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFD97706).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: const Color(0xFFD97706).withValues(alpha: 0.4),
            ),
          ),
          child: const Text(
            'SHOP',
            style: TextStyle(
              color: Color(0xFFD97706),
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        );

      case Card3DType.extraCostExpense:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFDB2777).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: const Color(0xFFDB2777).withValues(alpha: 0.4),
            ),
          ),
          child: const Text(
            'EXTRA',
            style: TextStyle(
              color: Color(0xFFDB2777),
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  _CardStyle _getCardStyle(Card3DType type) {
    switch (type) {
      case Card3DType.totalCapital:
        return const _CardStyle(
          bgGradient: [Color(0xFFF8FAFC), Color(0xFFE2E8F0), Color(0xFFCBD5E1)],
          accentColor: Color(0xFF475569),
          borderColor: Color(0xFFCBD5E1),
          shadowColor: Color(0xFF64748B),
        );

      case Card3DType.availableCapital:
        return const _CardStyle(
          bgGradient: [Color(0xFFF0FDFA), Color(0xFFCCFBF1), Color(0xFF99F6E4)],
          accentColor: Color(0xFF0D9488),
          borderColor: Color(0xFF99F6E4),
          shadowColor: Color(0xFF14B8A6),
        );

      case Card3DType.totalInvestment:
        return const _CardStyle(
          bgGradient: [Color(0xFFFFF7ED), Color(0xFFFFEDD5), Color(0xFFFED7AA)],
          accentColor: Color(0xFFEA580C),
          borderColor: Color(0xFFFED7AA),
          shadowColor: Color(0xFFF97316),
        );

      case Card3DType.totalSales:
        return const _CardStyle(
          bgGradient: [Color(0xFFF0F9FF), Color(0xFFE0F2FE), Color(0xFFBAE6FD)],
          accentColor: Color(0xFF0284C7),
          borderColor: Color(0xFFBAE6FD),
          shadowColor: Color(0xFF0EA5E9),
        );

      case Card3DType.unsoldStock:
        return const _CardStyle(
          bgGradient: [Color(0xFFF5F3FF), Color(0xFFEDE9FE), Color(0xFFDDD6FE)],
          accentColor: Color(0xFF7C3AED),
          borderColor: Color(0xFFDDD6FE),
          shadowColor: Color(0xFF8B5CF6),
        );

      case Card3DType.totalProfit:
      case Card3DType.finalProfit:
        return const _CardStyle(
          bgGradient: [Color(0xFFECFDF5), Color(0xFFD1FAE5), Color(0xFFA7F3D0)],
          accentColor: Color(0xFF059669),
          borderColor: Color(0xFFA7F3D0),
          shadowColor: Color(0xFF10B981),
        );

      case Card3DType.totalLoss:
        return const _CardStyle(
          bgGradient: [Color(0xFFFFF1F2), Color(0xFFFFE4E6), Color(0xFFFECDD3)],
          accentColor: Color(0xFFE11D48),
          borderColor: Color(0xFFFECDD3),
          shadowColor: Color(0xFFF43F5E),
        );

      case Card3DType.totalBaki:
        return const _CardStyle(
          bgGradient: [Color(0xFFFFFBEB), Color(0xFFFEF3C7), Color(0xFFFDE68A)],
          accentColor: Color(0xFFD97706),
          borderColor: Color(0xFFFDE68A),
          shadowColor: Color(0xFFF59E0B),
        );

      case Card3DType.damagedStockLoss:
      case Card3DType.mobileDamaged:
      case Card3DType.gadgetDamaged:
        return const _CardStyle(
          bgGradient: [Color(0xFFFFF1F2), Color(0xFFFFE4E6), Color(0xFFFECDD3)],
          accentColor: Color(0xFFDC2626),
          borderColor: Color(0xFFFFC7C7),
          shadowColor: Color(0xFFEF4444),
        );

      case Card3DType.mobileSales:
      case Card3DType.mobileUnits:
        return const _CardStyle(
          bgGradient: [Color(0xFFE0E7FF), Color(0xFFC7D2FE), Color(0xFFA5B4FC)],
          accentColor: Color(0xFF4F46E5),
          borderColor: Color(0xFFC7D2FE),
          shadowColor: Color(0xFF6366F1),
        );

      case Card3DType.mobileProfit:
        return const _CardStyle(
          bgGradient: [Color(0xFFD1FAE5), Color(0xFFA7F3D0), Color(0xFF6EE7B7)],
          accentColor: Color(0xFF059669),
          borderColor: Color(0xFFA7F3D0),
          shadowColor: Color(0xFF10B981),
        );

      case Card3DType.mobileLoss:
        return const _CardStyle(
          bgGradient: [Color(0xFFFFE4E6), Color(0xFFFECDD3), Color(0xFFFDA4AF)],
          accentColor: Color(0xFFE11D48),
          borderColor: Color(0xFFFECDD3),
          shadowColor: Color(0xFFF43F5E),
        );

      case Card3DType.mobileReturned:
      case Card3DType.gadgetReturned:
        return const _CardStyle(
          bgGradient: [Color(0xFFFEF3C7), Color(0xFFFDE68A), Color(0xFFFCD34D)],
          accentColor: Color(0xFFD97706),
          borderColor: Color(0xFFFDE68A),
          shadowColor: Color(0xFFF59E0B),
        );

      case Card3DType.gadgetSales:
      case Card3DType.gadgetUnits:
        return const _CardStyle(
          bgGradient: [Color(0xFFFAE8FF), Color(0xFFF5D0FE), Color(0xFFE879F9)],
          accentColor: Color(0xFFC026D3),
          borderColor: Color(0xFFF5D0FE),
          shadowColor: Color(0xFFD946EF),
        );

      case Card3DType.gadgetProfit:
        return const _CardStyle(
          bgGradient: [Color(0xFFD1FAE5), Color(0xFFA7F3D0), Color(0xFF6EE7B7)],
          accentColor: Color(0xFF059669),
          borderColor: Color(0xFFA7F3D0),
          shadowColor: Color(0xFF10B981),
        );

      case Card3DType.gadgetLoss:
        return const _CardStyle(
          bgGradient: [Color(0xFFFFE4E6), Color(0xFFFECDD3), Color(0xFFFDA4AF)],
          accentColor: Color(0xFFE11D48),
          borderColor: Color(0xFFFECDD3),
          shadowColor: Color(0xFFF43F5E),
        );

      case Card3DType.salaryExpense:
        return const _CardStyle(
          bgGradient: [Color(0xFFEEF2FF), Color(0xFFE0E7FF), Color(0xFFC7D2FE)],
          accentColor: Color(0xFF6366F1),
          borderColor: Color(0xFFC7D2FE),
          shadowColor: Color(0xFF6366F1),
        );

      case Card3DType.officeRentExpense:
        return const _CardStyle(
          bgGradient: [Color(0xFFF0FDFA), Color(0xFFCCFBF1), Color(0xFF99F6E4)],
          accentColor: Color(0xFF0F766E),
          borderColor: Color(0xFF99F6E4),
          shadowColor: Color(0xFF14B8A6),
        );

      case Card3DType.shopRentExpense:
        return const _CardStyle(
          bgGradient: [Color(0xFFFFFBEB), Color(0xFFFEF3C7), Color(0xFFFDE68A)],
          accentColor: Color(0xFFD97706),
          borderColor: Color(0xFFFDE68A),
          shadowColor: Color(0xFFF59E0B),
        );

      case Card3DType.extraCostExpense:
        return const _CardStyle(
          bgGradient: [Color(0xFFFFF1F2), Color(0xFFFFE4E6), Color(0xFFFECDD3)],
          accentColor: Color(0xFFDB2777),
          borderColor: Color(0xFFFECDD3),
          shadowColor: Color(0xFFF43F5E),
        );
    }
  }
}

class _CardStyle {
  final List<Color> bgGradient;
  final Color accentColor;
  final Color borderColor;
  final Color shadowColor;

  const _CardStyle({
    required this.bgGradient,
    required this.accentColor,
    required this.borderColor,
    required this.shadowColor,
  });
}

// ---------------------------------------------------------------------------
// 1. Background Pattern Painter (Waves, Circuit Tracks, Damask, Glows)
// ---------------------------------------------------------------------------
class _CardBackgroundPainter extends CustomPainter {
  final Card3DType type;
  final Color accentColor;

  _CardBackgroundPainter({required this.type, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.35);

    if (type == Card3DType.totalCapital) {
      // Metallic line waveform
      final path = Path();
      path.moveTo(0, size.height * 0.75);
      path.lineTo(size.width * 0.25, size.height * 0.72);
      path.lineTo(size.width * 0.45, size.height * 0.82);
      path.lineTo(size.width * 0.65, size.height * 0.68);
      path.lineTo(size.width * 0.85, size.height * 0.74);
      path.lineTo(size.width, size.height * 0.65);
      canvas.drawPath(path, paint);
    } else if (type == Card3DType.availableCapital) {
      // Circuit board track lines
      final path = Path();
      path.moveTo(size.width * 0.8, 0);
      path.lineTo(size.width * 0.8, size.height * 0.3);
      path.lineTo(size.width * 0.6, size.height * 0.5);
      path.lineTo(size.width * 0.6, size.height);

      path.moveTo(size.width * 0.92, 0);
      path.lineTo(size.width * 0.92, size.height * 0.4);
      path.lineTo(size.width * 0.75, size.height * 0.6);
      canvas.drawPath(path, paint);

      final dotPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = accentColor.withValues(alpha: 0.4);
      canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.3), 2.5, dotPaint);
      canvas.drawCircle(Offset(size.width * 0.6, size.height * 0.5), 2.5, dotPaint);
    } else if (type == Card3DType.totalProfit ||
        type == Card3DType.finalProfit ||
        type == Card3DType.mobileProfit ||
        type == Card3DType.gadgetProfit ||
        type == Card3DType.salaryExpense ||
        type == Card3DType.officeRentExpense ||
        type == Card3DType.shopRentExpense ||
        type == Card3DType.extraCostExpense) {
      // Organic flow curved aura
      final path = Path();
      path.moveTo(0, size.height * 0.3);
      path.quadraticBezierTo(
        size.width * 0.5,
        0,
        size.width,
        size.height * 0.4,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CardBackgroundPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// 2. Centerpiece 3D Skeuomorphic Illustration Painter
// ---------------------------------------------------------------------------
class _CardCenterpiecePainter extends CustomPainter {
  final Card3DType type;
  final Color accentColor;

  _CardCenterpiecePainter({required this.type, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    switch (type) {
      case Card3DType.totalCapital:
        _draw3DSteelSafe(canvas, cx, cy);
        break;

      case Card3DType.availableCapital:
        _draw3DFloatingCashOnChip(canvas, cx, cy);
        break;

      case Card3DType.totalInvestment:
        _draw3DRoseGoldCrystals(canvas, cx, cy);
        break;

      case Card3DType.totalSales:
        _draw3DVintageCashRegister(canvas, cx, cy);
        break;

      case Card3DType.unsoldStock:
        _draw3DStackedWoodenCrates(canvas, cx, cy);
        break;

      case Card3DType.totalProfit:
      case Card3DType.finalProfit:
      case Card3DType.mobileProfit:
      case Card3DType.gadgetProfit:
        _draw3DEmeraldGrowthArrow(canvas, cx, cy);
        break;

      case Card3DType.totalLoss:
      case Card3DType.mobileLoss:
      case Card3DType.gadgetLoss:
        _draw3DCrimsonDownArrow(canvas, cx, cy);
        break;

      case Card3DType.totalBaki:
        _draw3DGoldenLedger(canvas, cx, cy);
        break;

      case Card3DType.damagedStockLoss:
      case Card3DType.mobileDamaged:
      case Card3DType.gadgetDamaged:
        _draw3DDamagedShield(canvas, cx, cy);
        break;

      case Card3DType.mobileSales:
      case Card3DType.mobileUnits:
        _draw3DSmartphone(canvas, cx, cy);
        break;

      case Card3DType.mobileReturned:
      case Card3DType.gadgetReturned:
        _draw3DReturnBox(canvas, cx, cy);
        break;

      case Card3DType.gadgetSales:
      case Card3DType.gadgetUnits:
        _draw3DHeadphones(canvas, cx, cy);
        break;

      case Card3DType.salaryExpense:
        _draw3DSalaryCard(canvas, cx, cy);
        break;

      case Card3DType.officeRentExpense:
        _draw3DOfficeBuilding(canvas, cx, cy);
        break;

      case Card3DType.shopRentExpense:
        _draw3DShopStorefront(canvas, cx, cy);
        break;

      case Card3DType.extraCostExpense:
        _draw3DReceiptAndCoins(canvas, cx, cy);
        break;
    }
  }

  // 1. 3D Steel Vault Safe with Gold Gears
  void _draw3DSteelSafe(Canvas canvas, double cx, double cy) {
    // Drop shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + 24), width: 56, height: 14), shadowPaint);

    // Safe Outer Body (Metallic Bevel)
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy), width: 50, height: 44),
      const Radius.circular(8),
    );
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF64748B), Color(0xFF334155), Color(0xFF1E293B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bodyRect.outerRect);
    canvas.drawRRect(bodyRect, bodyPaint);

    // Chrome Safe Door
    final doorRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx + 2, cy), width: 38, height: 34),
      const Radius.circular(6),
    );
    final doorPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFE2E8F0), Color(0xFF94A3B8), Color(0xFF64748B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(doorRect.outerRect);
    canvas.drawRRect(doorRect, doorPaint);

    // Golden Dial Wheel
    final dialCenter = Offset(cx + 2, cy);
    final goldWheelPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFDF00), Color(0xFFD97706), Color(0xFF92400E)],
      ).createShader(Rect.fromCircle(center: dialCenter, radius: 10));
    canvas.drawCircle(dialCenter, 9, goldWheelPaint);

    // Inner dial cog ring
    final cogPaint = Paint()
      ..color = const Color(0xFFFDE68A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(dialCenter, 6, cogPaint);

    // Wheel spokes
    final spokePaint = Paint()
      ..color = const Color(0xFF78350F)
      ..strokeWidth = 1.5;
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      canvas.drawLine(
        dialCenter,
        Offset(dialCenter.dx + 5 * math.cos(angle), dialCenter.dy + 5 * math.sin(angle)),
        spokePaint,
      );
    }
  }

  // 2. 3D Floating Cash Bundles on Glowing Cyber Microchip
  void _draw3DFloatingCashOnChip(Canvas canvas, double cx, double cy) {
    // Pedestal Chip Base
    final chipRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + 18), width: 56, height: 16),
      const Radius.circular(4),
    );
    final chipPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFE2E8F0), Color(0xFF94A3B8), Color(0xFF475569)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(chipRect.outerRect);
    canvas.drawRRect(chipRect, chipPaint);

    // Glowing Cyan Core
    final glowPaint = Paint()
      ..color = const Color(0xFF2DD4BF).withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy + 14), width: 34, height: 8), glowPaint);

    // Floating Stacks of Banknotes (Isometric layers)
    for (int i = 0; i < 3; i++) {
      final yOff = cy + 4 - (i * 9.0);
      final notePath = Path()
        ..moveTo(cx - 20, yOff)
        ..lineTo(cx, yOff - 6)
        ..lineTo(cx + 20, yOff)
        ..lineTo(cx, yOff + 6)
        ..close();

      final notePaint = Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFF34D399),
            const Color(0xFF059669),
            const Color(0xFF047857),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromCenter(center: Offset(cx, yOff), width: 40, height: 12));

      // Note shadow
      if (i == 0) {
        final noteShadow = Paint()
          ..color = const Color(0xFF0F766E).withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawPath(notePath, noteShadow);
      }

      canvas.drawPath(notePath, notePaint);

      // Note border
      final strokePaint = Paint()
        ..color = const Color(0xFFA7F3D0).withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;
      canvas.drawPath(notePath, strokePaint);
    }
  }

  // 3. 3D Rose-Gold Crystal Gem Clusters
  void _draw3DRoseGoldCrystals(Canvas canvas, double cx, double cy) {
    // Drop shadow
    final shadowPaint = Paint()
      ..color = const Color(0xFF7C2D12).withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + 22), width: 50, height: 12), shadowPaint);

    // Left Small Crystal
    final leftPath = Path()
      ..moveTo(cx - 16, cy + 18)
      ..lineTo(cx - 24, cy + 4)
      ..lineTo(cx - 16, cy - 12)
      ..lineTo(cx - 8, cy + 4)
      ..close();
    final leftPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFED7AA), Color(0xFFFB923C), Color(0xFFC2410C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCenter(center: Offset(cx - 16, cy + 4), width: 16, height: 30));
    canvas.drawPath(leftPath, leftPaint);

    // Right Medium Crystal
    final rightPath = Path()
      ..moveTo(cx + 8, cy + 18)
      ..lineTo(cx + 20, cy + 6)
      ..lineTo(cx + 14, cy - 16)
      ..lineTo(cx + 4, cy + 2)
      ..close();
    final rightPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFEDD5), Color(0xFFFDBA74), Color(0xFF9A3412)],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ).createShader(Rect.fromCenter(center: Offset(cx + 12, cy), width: 16, height: 34));
    canvas.drawPath(rightPath, rightPaint);

    // Center Tall Diamond Crystal
    final centerPath = Path()
      ..moveTo(cx, cy + 20)
      ..lineTo(cx - 10, cy + 6)
      ..lineTo(cx, cy - 24)
      ..lineTo(cx + 10, cy + 6)
      ..close();
    final centerPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFF7ED), Color(0xFFFDBA74), Color(0xFFEA580C)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCenter(center: Offset(cx, cy), width: 20, height: 44));
    canvas.drawPath(centerPath, centerPaint);

    // Specular center facet ridge
    final ridgePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(cx, cy - 24), Offset(cx, cy + 20), ridgePaint);
  }

  // 4. 3D Vintage Brass Cash Register with Receipt
  void _draw3DVintageCashRegister(Canvas canvas, double cx, double cy) {
    // Drop shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + 22), width: 54, height: 12), shadowPaint);

    // Register Base Drawer
    final baseRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + 14), width: 48, height: 16),
      const Radius.circular(4),
    );
    final basePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFD97706), Color(0xFF92400E), Color(0xFF78350F)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(baseRect.outerRect);
    canvas.drawRRect(baseRect, basePaint);

    // Slanted Register Body
    final bodyPath = Path()
      ..moveTo(cx - 20, cy + 6)
      ..lineTo(cx - 14, cy - 14)
      ..lineTo(cx + 14, cy - 14)
      ..lineTo(cx + 20, cy + 6)
      ..close();
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFDE68A), Color(0xFFD97706), Color(0xFFB45309)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCenter(center: Offset(cx, cy - 4), width: 40, height: 20));
    canvas.drawPath(bodyPath, bodyPaint);

    // Top Display Header
    final topRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy - 18), width: 26, height: 10),
      const Radius.circular(3),
    );
    final topPaint = Paint()..color = const Color(0xFF78350F);
    canvas.drawRRect(topRect, topPaint);

    // Curling Receipt Paper
    final paperPath = Path()
      ..moveTo(cx - 4, cy - 18)
      ..quadraticBezierTo(cx - 10, cy - 10, cx - 6, cy - 4)
      ..lineTo(cx + 2, cy - 4)
      ..quadraticBezierTo(cx - 2, cy - 10, cx + 4, cy - 18)
      ..close();
    final paperPaint = Paint()..color = Colors.white;
    canvas.drawPath(paperPath, paperPaint);
  }

  // 5. 3D Stacked Wooden Logistics Crates & Warehouse Pallets
  void _draw3DStackedWoodenCrates(Canvas canvas, double cx, double cy) {
    // Drop shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + 22), width: 56, height: 12), shadowPaint);

    // Base Wooden Pallet
    final palletPaint = Paint()..color = const Color(0xFF9A3412);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 18), width: 50, height: 6), const Radius.circular(2)),
      palletPaint,
    );

    // Bottom Left Large Crate
    _drawIsometricBox(canvas, Offset(cx - 12, cy + 6), 24, 20, const Color(0xFFD97706), const Color(0xFFB45309), const Color(0xFFFDE68A));

    // Bottom Right Medium Crate
    _drawIsometricBox(canvas, Offset(cx + 14, cy + 8), 18, 16, const Color(0xFFB45309), const Color(0xFF92400E), const Color(0xFFFCD34D));

    // Top Center Stacked Crate
    _drawIsometricBox(canvas, Offset(cx - 2, cy - 10), 22, 18, const Color(0xFFF59E0B), const Color(0xFFD97706), const Color(0xFFFEF3C7));
  }

  void _drawIsometricBox(Canvas canvas, Offset center, double w, double h, Color frontColor, Color sideColor, Color topColor) {
    final hw = w / 2;
    final hh = h / 2;

    // Front face
    final frontPath = Path()
      ..moveTo(center.dx - hw, center.dy)
      ..lineTo(center.dx, center.dy + hh * 0.6)
      ..lineTo(center.dx, center.dy + hh * 1.6)
      ..lineTo(center.dx - hw, center.dy + hh)
      ..close();
    canvas.drawPath(frontPath, Paint()..color = frontColor);

    // Right face
    final rightPath = Path()
      ..moveTo(center.dx, center.dy + hh * 0.6)
      ..lineTo(center.dx + hw, center.dy)
      ..lineTo(center.dx + hw, center.dy + hh)
      ..lineTo(center.dx, center.dy + hh * 1.6)
      ..close();
    canvas.drawPath(rightPath, Paint()..color = sideColor);

    // Top face
    final topPath = Path()
      ..moveTo(center.dx, center.dy - hh * 0.4)
      ..lineTo(center.dx + hw, center.dy)
      ..lineTo(center.dx, center.dy + hh * 0.6)
      ..lineTo(center.dx - hw, center.dy)
      ..close();
    canvas.drawPath(topPath, Paint()..color = topColor);
  }

  // 6. 3D Emerald Malachite Glossy Upward Growth Arrow
  void _draw3DEmeraldGrowthArrow(Canvas canvas, double cx, double cy) {
    // Drop shadow
    final shadowPaint = Paint()
      ..color = const Color(0xFF064E3B).withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + 22), width: 50, height: 12), shadowPaint);

    final arrowPath = Path()
      ..moveTo(cx - 26, cy + 14)
      ..lineTo(cx - 10, cy - 2)
      ..lineTo(cx, cy + 6)
      ..lineTo(cx + 18, cy - 14)
      ..lineTo(cx + 14, cy - 22)
      ..lineTo(cx + 28, cy - 20)
      ..lineTo(cx + 26, cy - 6)
      ..lineTo(cx + 22, cy - 10)
      ..lineTo(cx + 2, cy + 12)
      ..lineTo(cx - 10, cy + 4)
      ..lineTo(cx - 24, cy + 20)
      ..close();

    final arrowPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF34D399), Color(0xFF059669), Color(0xFF047857)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCenter(center: Offset(cx, cy), width: 54, height: 44));
    canvas.drawPath(arrowPath, arrowPaint);

    // Polished Golden Bevel Outline
    final goldOutline = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFFBEB), Color(0xFFF59E0B), Color(0xFFB45309)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCenter(center: Offset(cx, cy), width: 54, height: 44))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(arrowPath, goldOutline);
  }

  // 7. 3D Crimson Downward Trend Arrow
  void _draw3DCrimsonDownArrow(Canvas canvas, double cx, double cy) {
    final shadowPaint = Paint()
      ..color = const Color(0xFF881337).withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + 22), width: 50, height: 12), shadowPaint);

    final arrowPath = Path()
      ..moveTo(cx - 26, cy - 14)
      ..lineTo(cx - 10, cy + 2)
      ..lineTo(cx, cy - 6)
      ..lineTo(cx + 18, cy + 14)
      ..lineTo(cx + 14, cy + 22)
      ..lineTo(cx + 28, cy + 20)
      ..lineTo(cx + 26, cy + 6)
      ..lineTo(cx + 22, cy + 10)
      ..lineTo(cx + 2, cy - 12)
      ..lineTo(cx - 10, cy - 4)
      ..lineTo(cx - 24, cy - 20)
      ..close();

    final arrowPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFB7185), Color(0xFFE11D48), Color(0xFF9F1239)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCenter(center: Offset(cx, cy), width: 54, height: 44));
    canvas.drawPath(arrowPath, arrowPaint);

    final outline = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(arrowPath, outline);
  }

  // 8. 3D Golden Ledger & Pending Due Clock
  void _draw3DGoldenLedger(Canvas canvas, double cx, double cy) {
    // Book base
    final bookRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx - 4, cy + 4), width: 40, height: 34),
      const Radius.circular(5),
    );
    final bookPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFBBF24), Color(0xFFD97706), Color(0xFF78350F)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bookRect.outerRect);
    canvas.drawRRect(bookRect, bookPaint);

    // Book spine highlight
    final spinePaint = Paint()..color = const Color(0xFFFEF3C7);
    canvas.drawRect(Rect.fromLTWH(cx - 24, cy - 13, 4, 34), spinePaint);

    // Golden Floating Clock Badge
    final clockCenter = Offset(cx + 14, cy - 6);
    final clockPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFFFDE68A), Color(0xFFF59E0B)],
      ).createShader(Rect.fromCircle(center: clockCenter, radius: 14));
    canvas.drawCircle(clockCenter, 14, clockPaint);

    final clockBorder = Paint()
      ..color = const Color(0xFFB45309)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(clockCenter, 14, clockBorder);

    // Clock hands
    final handPaint = Paint()
      ..color = const Color(0xFF78350F)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(clockCenter, Offset(clockCenter.dx, clockCenter.dy - 7), handPaint);
    canvas.drawLine(clockCenter, Offset(clockCenter.dx + 5, clockCenter.dy), handPaint);
  }

  // 9. 3D Caution Hazard Damaged Shield
  void _draw3DDamagedShield(Canvas canvas, double cx, double cy) {
    final shieldPath = Path()
      ..moveTo(cx, cy - 20)
      ..lineTo(cx + 22, cy - 10)
      ..lineTo(cx + 18, cy + 12)
      ..lineTo(cx, cy + 22)
      ..lineTo(cx - 18, cy + 12)
      ..lineTo(cx - 22, cy - 10)
      ..close();

    final shieldPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFF87171), Color(0xFFDC2626), Color(0xFF991B1B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCenter(center: Offset(cx, cy), width: 44, height: 44));
    canvas.drawPath(shieldPath, shieldPaint);

    // Inner Caution Exclamation
    final markPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx, cy - 10), Offset(cx, cy + 4), markPaint);
    canvas.drawCircle(Offset(cx, cy + 12), 2.2, Paint()..color = Colors.white);
  }

  // 10. 3D Modern Flagship Smartphone
  void _draw3DSmartphone(Canvas canvas, double cx, double cy) {
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + 22), width: 38, height: 10), shadowPaint);

    final phoneRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy), width: 30, height: 46),
      const Radius.circular(7),
    );

    // Phone Frame (Titanium)
    final framePaint = Paint()..color = const Color(0xFF334155);
    canvas.drawRRect(phoneRect, framePaint);

    // Screen with Glossy Reflection
    final screenRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy), width: 26, height: 42),
      const Radius.circular(5),
    );
    final screenPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF6366F1), Color(0xFF3B82F6), Color(0xFF1E1B4B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(screenRect.outerRect);
    canvas.drawRRect(screenRect, screenPaint);

    // Screen dynamic island pill
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy - 17), width: 8, height: 3), const Radius.circular(2)),
      Paint()..color = Colors.black,
    );
  }

  // 11. 3D Return Parcel Box
  void _draw3DReturnBox(Canvas canvas, double cx, double cy) {
    _drawIsometricBox(canvas, Offset(cx, cy + 4), 28, 22, const Color(0xFFF59E0B), const Color(0xFFD97706), const Color(0xFFFEF3C7));

    // Circular glowing return arrow
    final ringPaint = Paint()
      ..color = const Color(0xFFD97706)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx + 8, cy - 10), radius: 10),
      0.5,
      4.5,
      false,
      ringPaint,
    );
  }

  // 12. 3D Studio Headphones & Gadget
  void _draw3DHeadphones(Canvas canvas, double cx, double cy) {
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + 22), width: 44, height: 10), shadowPaint);

    // Headband Arc
    final bandPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFC026D3), Color(0xFF7C3AED), Color(0xFF4F46E5)],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 20))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy - 4), radius: 18), math.pi, math.pi, false, bandPaint);

    // Left Ear Cup
    final leftCup = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx - 18, cy + 4), width: 10, height: 18),
      const Radius.circular(5),
    );
    canvas.drawRRect(leftCup, Paint()..color = const Color(0xFF9333EA));

    // Right Ear Cup
    final rightCup = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx + 18, cy + 4), width: 10, height: 18),
      const Radius.circular(5),
    );
    canvas.drawRRect(rightCup, Paint()..color = const Color(0xFFC026D3));
  }

  // 13. 3D Employee ID / Salary Badge
  void _draw3DSalaryCard(Canvas canvas, double cx, double cy) {
    final shadowPaint = Paint()
      ..color = const Color(0xFF4338CA).withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 22), width: 44, height: 12),
      shadowPaint,
    );

    final lanyardPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF6366F1), Color(0xFF4F46E5), Color(0xFF3730A3)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCenter(center: Offset(cx, cy - 18), width: 14, height: 16))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final strapPath = Path()
      ..moveTo(cx - 6, cy - 24)
      ..lineTo(cx, cy - 14)
      ..lineTo(cx + 6, cy - 24);
    canvas.drawPath(strapPath, lanyardPaint);

    final clipRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy - 14), width: 10, height: 6),
      const Radius.circular(2),
    );
    canvas.drawRRect(clipRect, Paint()..color = const Color(0xFFCBD5E1));

    final cardRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + 3), width: 42, height: 32),
      const Radius.circular(6),
    );
    final cardPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Colors.white, Color(0xFFEEF2FF), Color(0xFFC7D2FE)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(cardRect.outerRect);
    canvas.drawRRect(cardRect, cardPaint);

    final borderPaint = Paint()
      ..color = const Color(0xFF818CF8).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(cardRect, borderPaint);

    final avatarCenter = Offset(cx - 10, cy + 3);
    canvas.drawCircle(avatarCenter, 6, Paint()..color = const Color(0xFF6366F1));
    canvas.drawCircle(
      avatarCenter,
      3,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );

    final linePaint = Paint()
      ..color = const Color(0xFF4F46E5).withValues(alpha: 0.7)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx, cy - 1), Offset(cx + 14, cy - 1), linePaint);
    canvas.drawLine(Offset(cx, cy + 5), Offset(cx + 10, cy + 5), linePaint);
  }

  // 14. 3D Office High-rise Building
  void _draw3DOfficeBuilding(Canvas canvas, double cx, double cy) {
    final shadowPaint = Paint()
      ..color = const Color(0xFF042F2E).withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 22), width: 50, height: 12),
      shadowPaint,
    );

    final leftPath = Path()
      ..moveTo(cx - 16, cy + 18)
      ..lineTo(cx, cy + 22)
      ..lineTo(cx, cy - 16)
      ..lineTo(cx - 16, cy - 20)
      ..close();
    final leftPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF115E59), Color(0xFF042F2E)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCenter(center: Offset(cx - 8, cy), width: 16, height: 40));
    canvas.drawPath(leftPath, leftPaint);

    final rightPath = Path()
      ..moveTo(cx, cy + 22)
      ..lineTo(cx + 16, cy + 18)
      ..lineTo(cx + 16, cy - 20)
      ..lineTo(cx, cy - 16)
      ..close();
    final rightPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF14B8A6), Color(0xFF0F766E)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCenter(center: Offset(cx + 8, cy), width: 16, height: 40));
    canvas.drawPath(rightPath, rightPaint);

    final roofPath = Path()
      ..moveTo(cx, cy - 16)
      ..lineTo(cx + 16, cy - 20)
      ..lineTo(cx, cy - 24)
      ..lineTo(cx - 16, cy - 20)
      ..close();
    final roofPaint = Paint()..color = const Color(0xFF5EEAD4);
    canvas.drawPath(roofPath, roofPaint);

    final winPaint = Paint()
      ..color = const Color(0xFFCCFBF1).withValues(alpha: 0.85)
      ..strokeWidth = 2;
    for (int row = 0; row < 4; row++) {
      final y = cy - 10 + (row * 7.0);
      canvas.drawLine(Offset(cx + 4, y), Offset(cx + 12, y - 1), winPaint);
    }
  }

  // 15. 3D Shop / Storefront
  void _draw3DShopStorefront(Canvas canvas, double cx, double cy) {
    final shadowPaint = Paint()
      ..color = const Color(0xFF78350F).withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 22), width: 52, height: 12),
      shadowPaint,
    );

    final wallRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + 8), width: 44, height: 26),
      const Radius.circular(4),
    );
    final wallPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A), Color(0xFFF59E0B)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(wallRect.outerRect);
    canvas.drawRRect(wallRect, wallPaint);

    final doorRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx + 10, cy + 12), width: 12, height: 18),
      const Radius.circular(2),
    );
    canvas.drawRRect(doorRect, Paint()..color = const Color(0xFF92400E));

    final winRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx - 10, cy + 10), width: 16, height: 14),
      const Radius.circular(2),
    );
    canvas.drawRRect(
      winRect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFFBEB), Color(0xFFFCD34D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(winRect.outerRect),
    );

    final awningPath = Path()
      ..moveTo(cx - 24, cy - 2)
      ..lineTo(cx + 24, cy - 2)
      ..lineTo(cx + 26, cy + 5)
      ..lineTo(cx - 26, cy + 5)
      ..close();
    final awningPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFF59E0B), Color(0xFFD97706), Color(0xFFB45309)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCenter(center: Offset(cx, cy + 2), width: 52, height: 8));
    canvas.drawPath(awningPath, awningPaint);

    final stripePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 3;
    for (int s = -2; s <= 2; s++) {
      final x = cx + (s * 9.0);
      canvas.drawLine(Offset(x, cy - 2), Offset(x, cy + 5), stripePaint);
    }
  }

  // 16. 3D Floating Receipt & Golden Coins
  void _draw3DReceiptAndCoins(Canvas canvas, double cx, double cy) {
    final shadowPaint = Paint()
      ..color = const Color(0xFF831843).withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 22), width: 48, height: 12),
      shadowPaint,
    );

    final receiptPath = Path()
      ..moveTo(cx - 16, cy - 18)
      ..lineTo(cx + 8, cy - 22)
      ..lineTo(cx + 12, cy + 12)
      ..lineTo(cx - 12, cy + 16)
      ..close();
    final receiptPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Colors.white, Color(0xFFFFF1F2), Color(0xFFFECDD3)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCenter(center: Offset(cx, cy), width: 30, height: 38));
    canvas.drawPath(receiptPath, receiptPaint);

    final linePaint = Paint()
      ..color = const Color(0xFFF43F5E).withValues(alpha: 0.6)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx - 10, cy - 12), Offset(cx + 2, cy - 14), linePaint);
    canvas.drawLine(Offset(cx - 10, cy - 6), Offset(cx + 4, cy - 8), linePaint);
    canvas.drawLine(Offset(cx - 10, cy), Offset(cx + 2, cy - 2), linePaint);

    final coinCenter = Offset(cx + 10, cy + 12);
    for (int i = 0; i < 3; i++) {
      final y = coinCenter.dy - (i * 4.0);
      final coinRect = Rect.fromCenter(
        center: Offset(coinCenter.dx, y),
        width: 18,
        height: 8,
      );
      final coinPaint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFDE047), Color(0xFFEAB308), Color(0xFFCA8A04)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(coinRect);
      canvas.drawOval(coinRect, coinPaint);

      final rimPaint = Paint()
        ..color = const Color(0xFFFEF08A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;
      canvas.drawOval(coinRect, rimPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CardCenterpiecePainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// 3. Mini Micro-Widget Custom Painters (Pie Chart, Speedometer Gauge)
// ---------------------------------------------------------------------------
class _PieChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final slices = [
      {'color': const Color(0xFFF97316), 'sweep': 1.8},
      {'color': const Color(0xFF38BDF8), 'sweep': 1.6},
      {'color': const Color(0xFF34D399), 'sweep': 1.4},
      {'color': const Color(0xFFA78BFA), 'sweep': 1.48},
    ];

    double startAngle = 0;
    for (final slice in slices) {
      final paint = Paint()..color = slice['color'] as Color;
      final sweep = slice['sweep'] as double;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        true,
        paint,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) => false;
}

class _GaugeMeterPainter extends CustomPainter {
  final Color color;

  _GaugeMeterPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.85);
    final radius = size.width * 0.45;

    // Arc Track
    final trackPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF34D399), Color(0xFFFBBF24), Color(0xFFEF4444)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), math.pi, math.pi, false, trackPaint);

    // Needle
    final needlePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, Offset(center.dx + 8, center.dy - 9), needlePaint);
  }

  @override
  bool shouldRepaint(covariant _GaugeMeterPainter oldDelegate) => false;
}
