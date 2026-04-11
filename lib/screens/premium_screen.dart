import 'package:datedash/services/profile_service.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:datedash/services/payment_service.dart';
import 'package:datedash/models/payment_operator_model.dart';
import 'package:datedash/providers/profile_provider.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

class PremiumScreen extends StatefulWidget {
  final int initialTab;
  const PremiumScreen({super.key, this.initialTab = 0});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;
  bool _isMonthly = true;
  int _currentPlanIndex = 1; // Default to 'Premium' (Index 1)
  final PaymentService _paymentService = PaymentService();

  final List<String> proFeatures = [
    'Meet new friends',
    'Extended Filter',
    'Looking For',
    'See everyone\'s online status',
    'Rewind',
    '2x more profile views',
    'Unlimited likes',
    'See all your matches',
    'Unlimited messages',
    'Unlimited voice calls',
  ];

  final List<String> premiumFeatures = [
    'All Pro features',
    'Unlimited video calls',
    'See missed matches',
    '1 free profile boost per week',
  ];

  final List<String> eliteFeatures = [
    'All Pro and Premium features',
    '2 free profile boosts',
    'Get 2000 free credits',
    'Hide your age on profile',
    'Green card',
    'Lock your profile',
    'Unlimited chat requests',
    'See who likes and match instantly',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    // ViewportFraction < 1 lets adjacent cards peek out at the edges
    _pageController = PageController(viewportFraction: 0.95, initialPage: 1);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Force a dark premium look or enhance the dark mode
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0D0D11) : const Color(0xFFF7F7F9);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSubscriptionsTab(isDark),
                  _buildCreditsTab(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 4),
          // Custom TabBar Container
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.03),
              borderRadius: BorderRadius.circular(19),
              border:
                  Border.all(color: isDark ? Colors.white12 : Colors.black12),
            ),
            padding: const EdgeInsets.all(2),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isDark
                      ? []
                      : [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2))
                        ]),
              labelColor: isDark ? Colors.white : Colors.black,
              unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
              labelStyle:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Subscriptions'),
                Tab(text: 'Credits'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionsTab(bool isDark) {
    return Column(
      children: [
        // Billing Toggle
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildModernToggle(
                title: 'Weekly',
                isSelected: !_isMonthly,
                onTap: () => setState(() => _isMonthly = false),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildModernToggle(
                title: 'Monthly',
                isSelected: _isMonthly,
                onTap: () => setState(() => _isMonthly = true),
                isDark: isDark,
              ),
            ],
          ),
        ),

        // Clean PageView
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (idx) {
              setState(() => _currentPlanIndex = idx);
            },
            itemCount: 3,
            itemBuilder: (context, index) {
              return Opacity(
                opacity: index == _currentPlanIndex ? 1.0 : 0.7,
                child: _getPlanCardForIndex(index, isDark),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Simple Page Indicator dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 8,
              width: index == _currentPlanIndex ? 24 : 8,
              decoration: BoxDecoration(
                color: index == _currentPlanIndex
                    ? const Color(0xFFFF4D85)
                    : (isDark ? Colors.white24 : Colors.black12),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildModernToggle(
      {required String title,
      required bool isSelected,
      required VoidCallback onTap,
      required bool isDark}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF4D85) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF4D85)
                : (isDark ? Colors.white24 : Colors.black12),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: const Color(0xFFFF4D85).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ]
              : [],
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white54 : Colors.black54),
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _getPlanCardForIndex(int index, bool isDark) {
    if (index == 0) {
      return _buildPremiumGlassCard(
        title: 'PRO',
        weeklyPrice: '5,000',
        monthlyPrice: '10,000',
        features: proFeatures,
        accentColor: const Color(0xFF4FC3F7),
        icon: Iconsax.flash5,
        isDark: isDark,
      );
    } else if (index == 1) {
      return _buildPremiumGlassCard(
        title: 'PREMIUM',
        weeklyPrice: '7,000',
        monthlyPrice: '15,000',
        features: premiumFeatures,
        accentColor: const Color(0xFFFF4D85),
        icon: Iconsax.star5,
        isPopular: true,
        isDark: isDark,
      );
    } else {
      return _buildPremiumGlassCard(
        title: 'ELITE',
        weeklyPrice: '10,000',
        monthlyPrice: '30,000',
        features: eliteFeatures,
        accentColor: const Color(0xFFB388FF),
        icon: Iconsax.crown5,
        isDark: isDark,
      );
    }
  }

  Widget _buildPremiumGlassCard({
    required String title,
    required String weeklyPrice,
    required String monthlyPrice,
    required List<String> features,
    required Color accentColor,
    required IconData icon,
    required bool isDark,
    bool isPopular = false,
  }) {
    final price = _isMonthly ? monthlyPrice : weeklyPrice;
    final period = _isMonthly ? 'month' : 'week';
    final themePink = const Color(0xFFFF4D85);
    final themePinkLight = const Color(0xFFFF8EBD);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: isPopular
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [themePink, themePink.withOpacity(0.8)],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.white.withOpacity(0.12),
                        Colors.white.withOpacity(0.05),
                      ]
                    : [
                        Colors.white,
                        Colors.white.withOpacity(0.9),
                      ],
              ),
        border: Border.all(
          color: isPopular
              ? Colors.white.withOpacity(0.3)
              : (isDark ? Colors.white12 : Colors.black12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isPopular
                ? themePink.withOpacity(0.4)
                : (isDark ? Colors.black45 : Colors.black.withOpacity(0.05)),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            // Decorative elements for the most popular card
            if (isPopular)
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        themePinkLight.withOpacity(0.4),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isPopular
                              ? Colors.white.withOpacity(0.2)
                              : accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          icon,
                          color: isPopular ? Colors.white : accentColor,
                          size: 24,
                        ),
                      ),
                      if (isPopular)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'MOST POPULAR',
                            style: TextStyle(
                              color: themePink,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: isPopular
                          ? Colors.white
                          : (isDark ? Colors.white : Colors.black87),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$price',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: isPopular
                              ? Colors.white
                              : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'MWK/$period',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isPopular
                              ? Colors.white70
                              : (isDark ? Colors.white60 : Colors.black54),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      children: features.map((feature) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Icon(
                                Iconsax.tick_circle,
                                color: isPopular ? Colors.white : accentColor,
                                size: 18,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  feature,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: isPopular
                                        ? Colors.white.withOpacity(0.9)
                                        : (isDark
                                            ? Colors.white70
                                            : Colors.black87),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => _showPaymentSheet(
                        context,
                        title: title,
                        price: double.parse(price.replaceAll(',', '')),
                        type: 'subscription',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isPopular
                            ? Colors.white
                            : (isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.black87),
                        foregroundColor: isPopular ? themePink : Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Choose Plan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditsTab(bool isDark) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Modern Balance Card
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              Colors.white.withOpacity(0.08),
                              Colors.white.withOpacity(0.02)
                            ]
                          : [
                              const Color(0xFFFFB300).withOpacity(0.1),
                              const Color(0xFFFFB300).withOpacity(0.05)
                            ],
                    ),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: isDark
                          ? Colors.white12
                          : const Color(0xFFFFB300).withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB300).withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Iconsax.wallet_3,
                            size: 32, color: Color(0xFFFFB300)),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'AVAILABLE BALANCE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white60 : Colors.black54,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Consumer<ProfileProvider>(
                            builder: (context, provider, _) {
                              return Text(
                                '${provider.userProfile?.credits ?? 0}',
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFFFB300),
                                  height: 1.1,
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 6),
                            child: Text(
                              'CREDITS',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFFFB300),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Purchase Credits',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: 60 + MediaQuery.of(context).padding.bottom,
          ),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            delegate: SliverChildListDelegate([
              _buildCreditGlassBundle(500, isDark),
              _buildCreditGlassBundle(1000, isDark, isPopular: true),
              _buildCreditGlassBundle(5000, isDark),
              _buildCreditGlassBundle(10000, isDark),
              _buildCreditGlassBundle(20000, isDark),
              _buildCreditGlassBundle(50000, isDark, bonus: '10,000 FREE'),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildCreditGlassBundle(int amount, bool isDark,
      {bool isPopular = false, String? bonus}) {
    final themePink = const Color(0xFFFF4D85);

    return Container(
      decoration: BoxDecoration(
        color: isPopular
            ? themePink
            : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isPopular
              ? Colors.white.withOpacity(0.3)
              : (isDark ? Colors.white12 : Colors.black.withOpacity(0.05)),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isPopular
                ? themePink.withOpacity(0.3)
                : (isDark ? Colors.black45 : Colors.black.withOpacity(0.05)),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isPopular
                          ? Colors.white.withOpacity(0.2)
                          : const Color(0xFFFFB300).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Iconsax.coin5,
                      size: 28,
                      color: isPopular ? Colors.white : const Color(0xFFFFB300),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$amount',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: isPopular
                          ? Colors.white
                          : (isDark ? Colors.white : Colors.black87),
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    'Credits',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isPopular
                          ? Colors.white70
                          : (isDark ? Colors.white54 : Colors.black54),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isPopular
                          ? Colors.white
                          : (isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black87),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ElevatedButton(
                      onPressed: () => _showPaymentSheet(
                        context,
                        title: '$amount Credits',
                        price: amount.toDouble(),
                        type: 'credits',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        'MK ${amount}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isPopular ? themePink : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isPopular && bonus == null)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: Text(
                    'BEST VALUE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: themePink,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            if (bonus != null)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: const BoxDecoration(
                    color: Color(0xFF00E676),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: Text(
                    bonus,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showPaymentSheet(
    BuildContext context, {
    required String title,
    required double price,
    required String type,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _PaymentSheetContent(
          title: title,
          price: price,
          type: type,
          paymentService: _paymentService,
          isMonthly: _isMonthly,
        );
      },
    );
  }
}

class _PaymentSheetContent extends StatefulWidget {
  final String title;
  final double price;
  final String type;
  final PaymentService paymentService;
  final bool isMonthly;

  const _PaymentSheetContent({
    required this.title,
    required this.price,
    required this.type,
    required this.paymentService,
    required this.isMonthly,
  });

  @override
  State<_PaymentSheetContent> createState() => _PaymentSheetContentState();
}

class _PaymentSheetContentState extends State<_PaymentSheetContent> {
  int _step = 0; // 0: Operator, 1: Phone, 2: Processing, 3: Success, 4: Error
  PaymentOperator? _selectedOperator;
  final TextEditingController _phoneController = TextEditingController();
  final ProfileService _profileService = ProfileService();
  String _errorMsg = '';
  String _txRef = '';
  String? _txDocId; // Track the Firestore document ID
  bool _isVerifying = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _startPayment() async {
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);
    final user = profileProvider.userProfile;
    if (user == null) return;

    setState(() {
      _step = 2; // Processing
      _errorMsg = '';
    });

    try {
      // 1. Generate unique 32-bit integer reference
      // Unix timestamp in seconds currently fits in int32 (~1.7B < 2.1B)
      final int uniqueRef = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // 2. Initialize
      final responseData = await widget.paymentService.initializePayment(
        mobile: _phoneController.text.trim(),
        amount: widget.price,
        email: profileProvider.currentUser?.email ?? 'user@datedash.com',
        operatorId: _selectedOperator!.refId,
        txRef: uniqueRef,
        firstName: user.firstName,
        lastName: '',
      );

      // CRITICAL: charge_id is the key for verification polling
      // ref_id is the secondary reference
      _txRef = (responseData['charge_id'] ?? responseData['ref_id'] ?? '')
          .toString();

      if (_txRef.isEmpty) {
        throw Exception('Invalid transaction record received from PayChangu');
      }

      // 3. Save PENDING transaction to Firestore immediately
      _txDocId = await _profileService.saveTransaction({
        'uid': profileProvider.currentUser!.uid,
        'txRef': uniqueRef, // Our generated integer reference
        'charge_id': _txRef, // PayChangu's tracking ID
        'amount': widget.price,
        'status': 'pending',
        'type': widget.type,
        'plan': widget.type == 'subscription' ? widget.title : null,
        'creditAmount': widget.type == 'credits'
            ? int.parse(widget.title.split(' ')[0])
            : null,
        'operator': _selectedOperator!.shortCode,
        'initResponse': responseData,
      });

      // 4. Start Verification Loop
      _verifyPaymentStatus();
    } catch (e) {
      if (mounted) {
        setState(() {
          _step = 4;
          _errorMsg = e.toString();
        });
      }
    }
  }

  Future<void> _verifyPaymentStatus() async {
    if (_isVerifying) return;
    _isVerifying = true;

    int attempts = 0;
    const maxAttempts = 15; // Verify for ~45 seconds

    while (attempts < maxAttempts && mounted) {
      try {
        final result = await widget.paymentService.verifyPayment(_txRef);
        // Top level status "successful" or "success", inner status "success"
        final topStatus = result['status']?.toString().toLowerCase();
        final innerStatus = result['data']?['status']?.toString().toLowerCase();

        if (topStatus == 'successful' ||
            topStatus == 'success' ||
            innerStatus == 'success') {
          // Success! Update Firestore document status
          if (_txDocId != null) {
            await _profileService.updateTransactionStatus(_txDocId!, 'success');
          }
          await _handleSuccess();
          if (mounted) setState(() => _step = 3);
          return;
        } else if (topStatus == 'failed' || innerStatus == 'failed') {
          // Update Firestore for failure if possible
          if (_txDocId != null) {
            await _profileService.updateTransactionStatus(_txDocId!, 'failed');
          }
          if (mounted) {
            setState(() {
              _step = 4;
              _errorMsg = result['message'] ?? 'Payment failed';
            });
          }
          return;
        }
      } catch (e) {
        debugPrint('Verification attempt failed: $e');
      }

      attempts++;
      await Future.delayed(const Duration(seconds: 3));
    }

    if (mounted) {
      setState(() {
        _step = 4;
        _errorMsg =
            'Timeout: Payment verification is taking too long. Please check your balance or contact support.';
      });
    }
  }

  Future<void> _handleSuccess() async {
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);
    final uid = profileProvider.currentUser?.uid;
    if (uid == null) return;

    // Transaction is now updated in _verifyPaymentStatus
    // We just handle the profile updates here

    // Update user profile
    if (widget.type == 'subscription') {
      await _profileService.updatePremiumStatus(
          uid, widget.title, widget.isMonthly);
    } else {
      final amount = int.parse(widget.title.split(' ')[0]);
      await _profileService.addCredits(uid, amount);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E24) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.5 : 0.1),
            blurRadius: 20,
            spreadRadius: 5,
          )
        ],
      ),
      padding: EdgeInsets.fromLTRB(
          24, 12, 24, 32 + MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Column(
              key: ValueKey<int>(_step),
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 16),
                if (_step == 0) _buildOperatorSelection(isDark),
                if (_step == 1) _buildPhoneInput(isDark),
                if (_step == 2) _buildProcessing(isDark),
                if (_step == 3) _buildSuccess(isDark),
                if (_step == 4) _buildError(isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOperatorSelection(bool isDark) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Text(
          'Select Payment Method',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose your preferred mobile money operator',
          style: TextStyle(
              fontSize: 14, color: isDark ? Colors.white54 : Colors.black54),
        ),
        const SizedBox(height: 24),
        FutureBuilder<List<PaymentOperator>>(
          future: widget.paymentService.getMobileOperators(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF4D85))),
              );
            } else if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text('Failed to load operators.',
                      style: TextStyle(color: Colors.red.shade300)),
                ),
              );
            } else if (snapshot.hasData) {
              return Column(
                children: snapshot.data!.map((op) {
                  final bool isAirtel = op.shortCode == 'airtel';
                  final Color opColor =
                      isAirtel ? Colors.red : const Color(0xFF00C853);

                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedOperator = op;
                      _step = 1;
                    }),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.black.withOpacity(0.05)),
                        boxShadow: [
                          BoxShadow(
                            color: opColor.withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                                border: Border.all(
                                    color: opColor.withOpacity(0.2), width: 2),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Image.asset(
                                  'assets/images/${op.shortCode}.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      Icon(Iconsax.wallet_35, color: opColor),
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    op.name,
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87),
                                  ),
                                  Text(
                                    '${op.supportedCountry?.name ?? 'Malawi'} • ${op.supportedCountry?.currency ?? 'MWK'}',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: isDark
                                            ? Colors.white54
                                            : Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: opColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Iconsax.arrow_right_3,
                                  size: 18, color: opColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildPhoneInput(bool isDark) {
    Color opColor = _selectedOperator!.shortCode == 'airtel'
        ? Colors.red
        : const Color(0xFF00C853);
    return Column(
      children: [
        const SizedBox(height: 12),
        Text(
          'Confirm Details',
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black87),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        )
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset(
                          'assets/images/${_selectedOperator!.shortCode}.png',
                          fit: BoxFit.contain),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title.toUpperCase(),
                            style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                color: Color(0xFFFF4D85),
                                letterSpacing: 1.2)),
                        Text('${_selectedOperator!.name} Payment',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color:
                                    isDark ? Colors.white70 : Colors.black54)),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Divider(height: 1),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Amount to Pay',
                      style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black54)),
                  Text('${widget.price.toInt()} MWK',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : Colors.black87)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(
              fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 18),
          decoration: InputDecoration(
            labelText: 'Mobile Number',
            labelStyle: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.normal, letterSpacing: 0),
            hintText: _selectedOperator?.shortCode == 'airtel'
                ? '09xxxxxxx'
                : '08xxxxxxx',
            prefixIcon: Icon(Iconsax.mobile5, color: opColor),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: opColor, width: 2)),
            filled: true,
            fillColor: isDark ? Colors.black26 : Colors.grey.shade100,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          height: 58,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF4D85), Color(0xFFFF8EBD)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF4D85).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () {
              if (_phoneController.text.length < 9) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Please enter a valid number')));
                return;
              }
              _startPayment();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Confirm & Pay',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ),
        ),
        TextButton(
          onPressed: () => setState(() => _step = 0),
          child: const Text('Change payment method'),
        ),
      ],
    );
  }

  Widget _buildProcessing(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const _PulsingLogo(),
          const SizedBox(height: 32),
          Text(
            'Securely Processing...',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black87),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Confirm the payment prompt on your device. This may take a few seconds.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white38 : Colors.black45,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Iconsax.tick_circle5,
                size: 80, color: Colors.greenAccent),
          ),
          const SizedBox(height: 32),
          const Text(
            'Payment Successful!',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Text(
            'High five! Your ${widget.title} is now active and ready to go.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white54 : Colors.black54,
                height: 1.5),
          ),
          const SizedBox(height: 40),
          Container(
            width: double.infinity,
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF4D85), Color(0xFFFF8EBD)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF4D85).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Done!',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Iconsax.danger5, size: 80, color: Colors.redAccent),
          ),
          const SizedBox(height: 32),
          const Text(
            'Payment Failed',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Text(
            _errorMsg,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.redAccent.withOpacity(0.8),
                fontSize: 16,
                height: 1.5),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton(
              onPressed: () => setState(() => _step = 1),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isDark ? Colors.white.withOpacity(0.05) : Colors.black12,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Try Again',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingLogo extends StatefulWidget {
  const _PulsingLogo();

  @override
  State<_PulsingLogo> createState() => _PulsingLogoState();
}

class _PulsingLogoState extends State<_PulsingLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFFFF4D85), Color(0xFFFF8EBD)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF4D85).withOpacity(0.4),
              blurRadius: 30,
              spreadRadius: 10,
            ),
          ],
        ),
        child: const Icon(Iconsax.receipt_2, color: Colors.white, size: 40),
      ),
    );
  }
}
