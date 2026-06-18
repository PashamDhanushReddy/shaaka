import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';


Color _base(BuildContext ctx) =>
    Theme.of(ctx).brightness == Brightness.dark
        ? const Color(0xFF252525)
        : const Color(0xFFE4E4E4);

Color _highlight(BuildContext ctx) =>
    Theme.of(ctx).brightness == Brightness.dark
        ? const Color(0xFF505050)
        : const Color(0xFFFFFFFF);

Color _card(BuildContext ctx) =>
    Theme.of(ctx).brightness == Brightness.dark
        ? const Color(0xFF1E1E1E)
        : Colors.white;


class _Shimmer extends StatelessWidget {
  final Widget child;
  const _Shimmer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: _base(context),
      highlightColor: _highlight(context),
      period: const Duration(milliseconds: 1000),
      child: child,
    );
  }
}


class _Stagger extends StatefulWidget {
  final int index;
  final Widget child;
  const _Stagger({required this.index, required this.child});

  @override
  State<_Stagger> createState() => _StaggerState();
}

class _StaggerState extends State<_Stagger>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..forward();
    final curve = CurvedAnimation(
      parent: _c,
      curve: Interval(
        (widget.index * 0.07).clamp(0.0, 0.5),
        1.0,
        curve: Curves.easeOutCubic,
      ),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(curve);
    _slide =
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
            .animate(curve);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _fade,
        child: SlideTransition(position: _slide, child: widget.child),
      );
}


class _R extends StatelessWidget {
  final double? w;
  final double h;
  final double r;

  const _R({this.w, required this.h, this.r = 6});

  @override
  Widget build(BuildContext context) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: _base(context), // solid — shimmer will colour it
          borderRadius: BorderRadius.circular(r),
        ),
      );
}

class _Circle extends StatelessWidget {
  final double size;
  const _Circle({required this.size});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: _base(context), shape: BoxShape.circle),
      );
}


class ProductCardShimmer extends StatelessWidget {
  const ProductCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Container(
        decoration: BoxDecoration(
          color: _card(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: _R(w: double.infinity, h: double.infinity, r: 12),
            ),
            const SizedBox(height: 8),
            _R(w: double.infinity, h: 12, r: 5),
            const SizedBox(height: 5),
            _R(w: 80, h: 12, r: 5),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _R(w: 56, h: 14, r: 5),
                _Circle(size: 24),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


class ProductGridShimmer extends StatelessWidget {
  final int itemCount;
  const ProductGridShimmer({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(12),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.68,
          crossAxisSpacing: 10,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (_, i) => _Stagger(index: i, child: const ProductCardShimmer()),
          childCount: itemCount,
        ),
      ),
    );
  }
}


class StoreShimmer extends StatelessWidget {
  const StoreShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: _Shimmer(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              height: 50,
              decoration: BoxDecoration(
                color: _base(context),
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _Shimmer(
            child: Container(
              height: 220,
              margin: const EdgeInsets.only(bottom: 20),
              color: _base(context),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _Shimmer(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: _R(w: 170, h: 18, r: 6),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(4, (i) {
                return Expanded(
                  child: _Stagger(
                    index: i,
                    child: _Shimmer(
                      child: Container(
                        height: 88,
                        margin: EdgeInsets.only(right: i < 3 ? 10 : 0),
                        decoration: BoxDecoration(
                          color: _base(context),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        SliverToBoxAdapter(
          child: _Shimmer(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: _R(w: 140, h: 18, r: 6),
            ),
          ),
        ),
        const ProductGridShimmer(itemCount: 6),
      ],
    );
  }
}


class OrderListShimmer extends StatelessWidget {
  final int itemCount;
  const OrderListShimmer({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: itemCount,
      itemBuilder: (context, index) => _Stagger(
        index: index,
        child: _Shimmer(
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _card(context),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _R(w: 80, h: 80, r: 10),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _R(w: double.infinity, h: 14, r: 5),
                      const SizedBox(height: 6),
                      _R(w: 130, h: 12, r: 5),
                      const SizedBox(height: 12),
                      _R(w: 88, h: 24, r: 12),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _Circle(size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class CartItemShimmer extends StatelessWidget {
  final int index;
  const CartItemShimmer({super.key, this.index = 0});

  @override
  Widget build(BuildContext context) {
    return _Stagger(
      index: index,
      child: _Shimmer(
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _card(context),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _R(w: 74, h: 74, r: 12),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _R(w: double.infinity, h: 14, r: 5),
                    const SizedBox(height: 6),
                    _R(w: 90, h: 12, r: 5),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _R(w: 30, h: 30, r: 8),
                        const SizedBox(width: 10),
                        _R(w: 26, h: 14, r: 4),
                        const SizedBox(width: 10),
                        _R(w: 30, h: 30, r: 8),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _Circle(size: 34),
            ],
          ),
        ),
      ),
    );
  }
}


class WishlistShimmer extends StatelessWidget {
  const WishlistShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(14),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: 6,
      itemBuilder: (_, i) =>
          _Stagger(index: i, child: const ProductCardShimmer()),
    );
  }
}


class ProfileShimmer extends StatelessWidget {
  const ProfileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), elevation: 0),
      body: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        child: _Shimmer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              Center(
                child: SizedBox(
                  width: 130,
                  height: 130,
                  child: Stack(
                    children: [
                      _Circle(size: 120),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _base(context),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Theme.of(context).scaffoldBackgroundColor,
                                width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _R(w: 150, h: 15, r: 6),
                    const SizedBox(height: 7),
                    _R(w: 80, h: 11, r: 12),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              _card(context,
                header: 180,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _field(context, iconWidth: 20),
                    const SizedBox(height: 14),
                    _field(context, iconWidth: 20),
                    const SizedBox(height: 14),
                    _field(context, iconWidth: 20),
                    const SizedBox(height: 14),
                    Row(children: [
                      _R(w: 80, h: 13, r: 5),
                      const SizedBox(width: 10),
                      _R(w: 70, h: 24, r: 12),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              _card(context,
                header: 90,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _field(context, iconWidth: 0, labelWidth: 220),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: _field(context, iconWidth: 0, labelWidth: 80)),
                        const SizedBox(width: 12),
                        Expanded(child: _field(context, iconWidth: 0, labelWidth: 80)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _field(context, iconWidth: 0, labelWidth: 160),
                    const SizedBox(height: 14),
                    _field(context, iconWidth: 0, labelWidth: 120),
                    const SizedBox(height: 14),
                    _R(w: double.infinity, h: 44, r: 10),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(child: _R(h: 48, r: 14)),
                  const SizedBox(width: 12),
                  Expanded(child: _R(h: 48, r: 14)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Card with a header line and a divider.
  Widget _card(BuildContext ctx,
      {required double header, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(ctx).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _R(w: header, h: 15, r: 6),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  /// A TextFormField-shaped placeholder.
  Widget _field(BuildContext ctx,
      {required double iconWidth, double? labelWidth}) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _base(ctx),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(ctx).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.07),
        ),
      ),
      child: Row(
        children: [
          if (iconWidth > 0) ...[
            Container(
              width: iconWidth,
              height: iconWidth,
              decoration: BoxDecoration(
                color: Theme.of(ctx).brightness == Brightness.dark
                    ? const Color(0xFF3A3A3A)
                    : const Color(0xFFCCCCCC),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: _R(h: 11, r: 4),
          ),
        ],
      ),
    );
  }
}
