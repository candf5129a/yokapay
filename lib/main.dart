import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const YokaPayApp());

class YokaPayApp extends StatefulWidget {
  const YokaPayApp({super.key});

  @override
  State<YokaPayApp> createState() => _YokaPayAppState();
}

class _YokaPayAppState extends State<YokaPayApp> {
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  bool _dark = false;
  String _accentName = 'Green';
  bool _loaded = false;

  static const Map<String, Color> _accents = {
    'Gold': Color(0xFFB18A36),
    'Silver': Color(0xFF78838A),
    'Blue': Color(0xFF3675B8),
    'Red': Color(0xFFC74D55),
    'Green': Color(0xFF087E68),
  };

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final dark = await _preferences.getBool('yokapay.dark');
    final accent = await _preferences.getString('yokapay.accent');
    if (!mounted) return;
    setState(() {
      _dark = dark ?? false;
      _accentName = _accents.containsKey(accent) ? accent! : 'Green';
      _loaded = true;
    });
  }

  Future<void> _setDark(bool value) async {
    setState(() => _dark = value);
    await _preferences.setBool('yokapay.dark', value);
  }

  Future<void> _setAccent(String value) async {
    if (!_accents.containsKey(value)) return;
    setState(() => _accentName = value);
    await _preferences.setString('yokapay.accent', value);
  }

  ThemeData _theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final accent = _accents[_accentName]!;
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
      surface: dark ? const Color(0xFF171C1B) : Colors.white,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          dark ? const Color(0xFF0D1110) : const Color(0xFFF4F7F5),
      appBarTheme: AppBarTheme(
        backgroundColor:
            dark ? const Color(0xFF0D1110) : const Color(0xFFF4F7F5),
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: scheme.outlineVariant)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: scheme.outlineVariant)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: scheme.primary, width: 1.5)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'YokaPay',
        debugShowCheckedModeBanner: false,
        themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
        theme: _theme(Brightness.light),
        darkTheme: _theme(Brightness.dark),
        home: _loaded
            ? MainNavigation(
                dark: _dark,
                accentName: _accentName,
                accentColors: _accents,
                onSetDark: _setDark,
                onSetAccent: _setAccent,
              )
            : const _LoadingScreen(),
      );
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({
    required this.dark,
    required this.accentName,
    required this.accentColors,
    required this.onSetDark,
    required this.onSetAccent,
    super.key,
  });

  final bool dark;
  final String accentName;
  final Map<String, Color> accentColors;
  final Future<void> Function(bool) onSetDark;
  final Future<void> Function(String) onSetAccent;

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  bool _hideBalance = false;
  bool _themePanelOpen = false;
  bool _holdTriggered = false;
  Timer? _holdTimer;

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  void _startThemeHold(PointerDownEvent _) {
    _holdTriggered = false;
    _holdTimer?.cancel();
    _holdTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _themePanelOpen = true);
      _holdTriggered = true;
    });
  }

  void _endThemeHold(PointerEvent _) => _holdTimer?.cancel();

  Future<void> _themeTap() async {
    if (_holdTriggered) {
      _holdTriggered = false;
      return;
    }
    await widget.onSetDark(!widget.dark);
  }

  void _openWallets() => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => const WalletPage()));

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomePage(
        dark: widget.dark,
        hideBalance: _hideBalance,
        onToggleBalance: () => setState(() => _hideBalance = !_hideBalance),
        onThemeTap: _themeTap,
        onThemePointerDown: _startThemeHold,
        onThemePointerEnd: _endThemeHold,
        onOpenWallets: _openWallets,
        onOpenNotifications: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const NotificationsPage())),
        onOpenPage: _pushPage,
      ),
      const CardsPage(),
      const ActivityPage(),
      const ProfilePage(),
    ];
    return Stack(children: [
      Scaffold(
        body: SafeArea(
            child: IndexedStack(index: _selectedIndex, children: pages)),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) =>
              setState(() => _selectedIndex = index),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home'),
            NavigationDestination(
                icon: Icon(Icons.credit_card_outlined),
                selectedIcon: Icon(Icons.credit_card_rounded),
                label: 'Cards'),
            NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long_rounded),
                label: 'Activity'),
            NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profile'),
          ],
        ),
      ),
      if (_themePanelOpen) _buildThemePanel(context),
    ]);
  }

  Widget _buildThemePanel(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Stack(children: [
      Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _themePanelOpen = false),
          child: ColoredBox(color: Colors.black.withValues(alpha: .42)),
        ),
      ),
      Align(
        alignment: Alignment.centerRight,
        child: SafeArea(
          child: Material(
            color: colors.surface,
            elevation: 18,
            borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(24)),
            child: SizedBox(
              width: MediaQuery.sizeOf(context).width * .82,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
                      child: Row(children: [
                        const Expanded(
                            child: Text('Appearance',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700))),
                        IconButton(
                          tooltip: 'Switch theme and close',
                          onPressed: () async {
                            await widget.onSetDark(!widget.dark);
                            if (mounted)
                              setState(() => _themePanelOpen = false);
                          },
                          icon: Icon(widget.dark
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded),
                        ),
                      ]),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                      child: Text(
                          'Choose a mode and accent color. Your choice is saved on this device.',
                          style: TextStyle(color: colors.onSurfaceVariant)),
                    ),
                    Expanded(
                      child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          children: [
                            const _PanelLabel('Base theme'),
                            const SizedBox(height: 8),
                            _ThemeChoice(
                                label: 'Light',
                                icon: Icons.light_mode_outlined,
                                selected: !widget.dark,
                                onTap: () => widget.onSetDark(false)),
                            _ThemeChoice(
                                label: 'Dark',
                                icon: Icons.dark_mode_outlined,
                                selected: widget.dark,
                                onTap: () => widget.onSetDark(true)),
                            const SizedBox(height: 18),
                            const _PanelLabel('Accent color'),
                            const SizedBox(height: 8),
                            ...widget.accentColors.entries
                                .map((entry) => _AccentChoice(
                                      name: entry.key,
                                      color: entry.value,
                                      selected: widget.accentName == entry.key,
                                      onTap: () =>
                                          widget.onSetAccent(entry.key),
                                    )),
                          ]),
                    ),
                  ]),
            ),
          ),
        ),
      ),
    ]);
  }

  void _pushPage(String page) {
    final Widget screen = switch (page) {
      'Activity' => const ActivityPage(),
      'Transfer' => const TransferPage(),
      'Add money' => const AddMoneyPage(),
      'Convert' => const ConvertPage(),
      'More' => const MorePage(),
      'Notifications' => const NotificationsPage(),
      'Wallets' => const WalletPage(),
      'Contributions' => const ContributionsPage(),
      _ => ServiceInfoPage(title: page),
    };
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }
}

class HomePage extends StatelessWidget {
  const HomePage({
    required this.dark,
    required this.hideBalance,
    required this.onToggleBalance,
    required this.onThemeTap,
    required this.onThemePointerDown,
    required this.onThemePointerEnd,
    required this.onOpenWallets,
    required this.onOpenNotifications,
    required this.onOpenPage,
    super.key,
  });

  final bool dark;
  final bool hideBalance;
  final VoidCallback onToggleBalance;
  final VoidCallback onThemeTap;
  final void Function(PointerDownEvent) onThemePointerDown;
  final void Function(PointerEvent) onThemePointerEnd;
  final VoidCallback onOpenWallets;
  final VoidCallback onOpenNotifications;
  final void Function(String) onOpenPage;

  static const _services = <_ServiceItem>[
    _ServiceItem('Airtime', Icons.phone_android_rounded),
    _ServiceItem('Data', Icons.wifi_rounded),
    _ServiceItem('Gift cards', Icons.card_giftcard_rounded),
    _ServiceItem('Invite', Icons.group_add_rounded),
    _ServiceItem('Subscriptions', Icons.subscriptions_rounded),
    _ServiceItem('Recharge', Icons.bolt_rounded),
    _ServiceItem('Tuition', Icons.school_rounded),
    _ServiceItem('Betting', Icons.sports_soccer_rounded),
    _ServiceItem('Electricity', Icons.electric_bolt_rounded),
    _ServiceItem('Transport', Icons.directions_bus_rounded),
    _ServiceItem('Shopping', Icons.shopping_bag_rounded),
    _ServiceItem('More services', Icons.grid_view_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textColor = Colors.white;
    return CustomScrollView(slivers: [
      SliverAppBar(
        pinned: true,
        toolbarHeight: 58,
        titleSpacing: 18,
        title: InkWell(
          onTap: onOpenWallets,
          borderRadius: BorderRadius.circular(14),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.account_balance_wallet_rounded,
                  color: Colors.white, size: 21),
            ),
            const SizedBox(width: 9),
            const Text('yokapay',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.5,
                    fontSize: 20)),
          ]),
        ),
        actions: [
          IconButton(
              onPressed: onOpenNotifications,
              tooltip: 'Notifications',
              icon: const Icon(Icons.notifications_none_rounded)),
          Listener(
            onPointerDown: onThemePointerDown,
            onPointerUp: onThemePointerEnd,
            onPointerCancel: onThemePointerEnd,
            child: IconButton(
              tooltip:
                  'Tap to switch light/dark. Hold 3 seconds for theme colors.',
              onPressed: onThemeTap,
              icon: Icon(
                  dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        sliver: SliverList.list(children: [
          const Text('Good morning, Nneka',
              style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.5)),
          const SizedBox(height: 4),
          Text('Here’s your money at a glance.',
              style: TextStyle(color: colors.onSurfaceVariant)),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                colors.primary,
                Color.lerp(colors.primary, const Color(0xFF10A982), .4)!
              ], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                    color: colors.primary.withValues(alpha: .18),
                    blurRadius: 22,
                    offset: const Offset(0, 10))
              ],
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Expanded(
                    child: Text('TOTAL BALANCE',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2))),
                IconButton(
                  onPressed: onToggleBalance,
                  tooltip: hideBalance ? 'Show balance' : 'Hide balance',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                      hideBalance
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: textColor.withValues(alpha: .85),
                      size: 20),
                ),
              ]),
              Text(hideBalance ? '₦ ••••••••' : '₦ 248,500.00',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 29,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -.9)),
              const SizedBox(height: 16),
              Row(children: [
                const Icon(Icons.account_circle_outlined,
                    color: Colors.white70, size: 19),
                const SizedBox(width: 7),
                const Expanded(
                    child: Text('YokaPay account  2034 567 812',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13))),
                IconButton(
                  onPressed: () async {
                    await Clipboard.setData(
                        const ClipboardData(text: '2034567812'));
                    if (context.mounted)
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Demo account number copied')));
                  },
                  tooltip: 'Copy account number',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.copy_rounded,
                      color: Colors.white70, size: 17),
                ),
              ]),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .13),
                    borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  const Icon(Icons.history_rounded,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text('Latest · Market Square',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: .9),
                              fontSize: 12,
                              fontWeight: FontWeight.w600))),
                  Text('− ₦12,400',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ]),
              ),
              const SizedBox(height: 10),
              Text('Demo account · Not connected to a bank',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: .72),
                      fontSize: 10)),
            ]),
          ),
          const SizedBox(height: 22),
          const _SectionTitle('Quick actions'),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: _ActionTile(
                    icon: Icons.arrow_upward_rounded,
                    label: 'Transfer',
                    onTap: () => onOpenPage('Transfer'))),
            const SizedBox(width: 10),
            Expanded(
                child: _ActionTile(
                    icon: Icons.add_rounded,
                    label: 'Add money',
                    onTap: () => onOpenPage('Add money'))),
            const SizedBox(width: 10),
            Expanded(
                child: _ActionTile(
                    icon: Icons.swap_horiz_rounded,
                    label: 'Convert',
                    onTap: () => onOpenPage('Convert'))),
            const SizedBox(width: 10),
            Expanded(
                child: _ActionTile(
                    icon: Icons.grid_view_rounded,
                    label: 'More',
                    onTap: () => onOpenPage('More'))),
          ]),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const _SectionTitle('Services'),
            TextButton(
                onPressed: () => onOpenPage('More'),
                child: const Text('See all')),
          ]),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _services.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisExtent: 91,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8),
            itemBuilder: (context, index) {
              final item = _services[index];
              return _ServiceTile(
                  item: item,
                  onTap: () => onOpenPage(
                      item.label == 'More services' ? 'More' : item.label));
            },
          ),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const _SectionTitle('Recent activity'),
            TextButton(
                onPressed: () => onOpenPage('Activity'),
                child: const Text('History')),
          ]),
          const _ActivityTile(
              icon: Icons.shopping_bag_outlined,
              title: 'Market Square',
              subtitle: 'Today · Card payment · Demo',
              amount: '− ₦ 12,400',
              positive: false),
          const _ActivityTile(
              icon: Icons.call_received_rounded,
              title: 'Transfer received',
              subtitle: 'Yesterday · Sample entry',
              amount: '+ ₦ 35,000',
              positive: true),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
                color: colors.primaryContainer.withValues(alpha: .55),
                borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              Icon(Icons.verified_user_outlined, color: colors.primary),
              const SizedBox(width: 9),
              Expanded(
                  child: Text(
                      'Verify payments in your YokaPay activity. A receipt screenshot is not proof of payment.',
                      style: TextStyle(
                          color: colors.onSurface, fontSize: 12, height: 1.4))),
            ]),
          ),
        ]),
      ),
    ]);
  }
}

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});
  @override
  Widget build(BuildContext context) => _PageScaffold(
        title: 'Your wallets',
        children: [
          const _PageIntro(
              'Hold different currencies separately and choose when to convert.'),
          const SizedBox(height: 16),
          const _WalletTile(
              currency: 'NGN',
              name: 'Nigerian naira',
              amount: '₦ 248,500.00',
              flag: '🇳🇬'),
          const SizedBox(height: 9),
          const _WalletTile(
              currency: 'USD',
              name: 'US dollar',
              amount: '\$ 120.00',
              flag: '🇺🇸'),
          const SizedBox(height: 9),
          const _WalletTile(
              currency: 'GBP',
              name: 'British pound',
              amount: '£ 0.00',
              flag: '🇬🇧'),
          const SizedBox(height: 9),
          const _WalletTile(
              currency: 'EUR', name: 'Euro', amount: '€ 0.00', flag: '🇪🇺'),
          const SizedBox(height: 24),
          const _SectionTitle('Currency and market rates'),
          const SizedBox(height: 10),
          _InfoBanner(
              icon: Icons.info_outline_rounded,
              text:
                  'Indicative demo rates only. Live pricing and currency wallets need a regulated provider connection.'),
          const SizedBox(height: 12),
          const _RateTile(
              pair: 'USD / NGN', value: '₦1,520.00', change: '+0.4%'),
          const _RateTile(
              pair: 'GBP / NGN', value: '₦1,930.00', change: '+0.2%'),
          const _RateTile(
              pair: 'EUR / NGN', value: '₦1,650.00', change: '−0.1%'),
          const SizedBox(height: 16),
          const _SectionTitle('Stock market watch'),
          const SizedBox(height: 8),
          const _RateTile(
              pair: 'NGX All-Share Index',
              value: '105,240.00',
              change: '+0.3%'),
          const _RateTile(pair: 'S&P 500', value: '5,842.10', change: '+0.2%'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute<void>(builder: (_) => const ConvertPage())),
              icon: const Icon(Icons.swap_horiz_rounded),
              label: const Text('Open currency converter')),
        ],
      );
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});
  @override
  Widget build(BuildContext context) => _PageScaffold(
        title: 'Notifications',
        children: const [
          _PageIntro('Updates and reminders for your account.'),
          SizedBox(height: 16),
          _NoticeTile(
              icon: Icons.shield_outlined,
              title: 'Safety reminder',
              body:
                  'Check your YokaPay activity before accepting a payment as complete.',
              time: 'Today · Demo notice'),
          _NoticeTile(
              icon: Icons.currency_exchange_rounded,
              title: 'Currency watch',
              body:
                  'Your saved demo watchlist has sample rates. Live market data is not connected.',
              time: 'Yesterday · Demo notice'),
          _NoticeTile(
              icon: Icons.savings_outlined,
              title: 'Group pot update',
              body:
                  'A sample contribution is scheduled to unlock on its goal date.',
              time: '2 days ago · Demo notice'),
        ],
      );
}

class TransferPage extends StatefulWidget {
  const TransferPage({super.key});
  @override
  State<TransferPage> createState() => _TransferPageState();
}

class _TransferPageState extends State<TransferPage> {
  String _kind = 'YokaPay';
  final _recipient = TextEditingController();
  final _amount = TextEditingController();
  String _bank = 'Choose bank';
  @override
  void dispose() {
    _recipient.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _PageScaffold(
        title: 'Transfer',
        children: [
          const _PageIntro(
              'Choose where the transfer is going. No money moves in this prototype.'),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                  value: 'YokaPay',
                  label: Text('YokaPay'),
                  icon: Icon(Icons.account_balance_wallet_outlined)),
              ButtonSegment(
                  value: 'Other bank',
                  label: Text('Other bank'),
                  icon: Icon(Icons.account_balance_outlined)),
            ],
            selected: {_kind},
            onSelectionChanged: (value) => setState(() => _kind = value.first),
          ),
          const SizedBox(height: 18),
          if (_kind == 'Other bank') ...[
            DropdownButtonFormField<String>(
              initialValue: _bank,
              decoration: const InputDecoration(labelText: 'Destination bank'),
              items: const ['Choose bank', 'Demo Bank A', 'Demo Bank B']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) =>
                  setState(() => _bank = value ?? 'Choose bank'),
            ),
            const SizedBox(height: 12),
            TextField(
                controller: _recipient,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Account number',
                    prefixIcon: Icon(Icons.numbers_rounded))),
          ] else
            TextField(
                controller: _recipient,
                decoration: const InputDecoration(
                    labelText: 'YokaPay tag or account number',
                    prefixIcon: Icon(Icons.alternate_email_rounded))),
          const SizedBox(height: 12),
          TextField(
              controller: _amount,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: Icon(Icons.payments_outlined),
                  prefixText: '₦ ')),
          const SizedBox(height: 16),
          const _InfoBanner(
              icon: Icons.lock_outline_rounded,
              text:
                  'Real transfers require identity checks, a licensed payment partner, and a secure backend. This screen does not send money.'),
          const SizedBox(height: 20),
          FilledButton(
              onPressed: () => _showDemoDialog(context, 'Transfer preview',
                  'Demo preview only. No transfer was submitted and no money moved.'),
              child: const Text('Review demo transfer')),
        ],
      );
}

class AddMoneyPage extends StatelessWidget {
  const AddMoneyPage({super.key});
  @override
  Widget build(BuildContext context) => _PageScaffold(
        title: 'Add money',
        children: [
          const _PageIntro(
              'Add funds through a supported provider when one is connected.'),
          const SizedBox(height: 16),
          const _FeatureCard(
              icon: Icons.account_balance_outlined,
              title: 'Bank transfer',
              subtitle: 'Demo account details · no deposits are accepted'),
          const SizedBox(height: 10),
          const _FeatureCard(
              icon: Icons.credit_card_outlined,
              title: 'Debit card',
              subtitle:
                  'Card funding will be available after a payment partner is connected'),
          const SizedBox(height: 24),
          const _SectionTitle('Save together'),
          const SizedBox(height: 8),
          const _PageIntro(
              'Create a goal with contributors, a planned release date, and transparent early-withdrawal approval rules.'),
          const SizedBox(height: 12),
          Card(
              child: ListTile(
                  leading: const Icon(Icons.groups_rounded),
                  title: const Text('Group contribution pot'),
                  subtitle: const Text(
                      'Lock date, contribution record, and member approvals'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                          builder: (_) => const ContributionsPage())))),
        ],
      );
}

class ContributionsPage extends StatelessWidget {
  const ContributionsPage({super.key});
  @override
  Widget build(BuildContext context) => _PageScaffold(
        title: 'Group contribution',
        children: [
          const _PageIntro(
              'A shared goal with clear dates and member approval rules.'),
          const SizedBox(height: 14),
          const _FeatureCard(
              icon: Icons.savings_rounded,
              title: 'Laptop savings',
              subtitle: '₦180,000 of ₦300,000 · Demo contribution record'),
          const SizedBox(height: 12),
          const _KeyValueRow(label: 'Planned release', value: '30 June 2027'),
          const _KeyValueRow(label: 'Contributors', value: '3 members'),
          const _KeyValueRow(
              label: 'Early withdrawal',
              value: 'Identity check + majority approval'),
          const SizedBox(height: 12),
          const _InfoBanner(
              icon: Icons.verified_user_outlined,
              text:
                  'No identity documents are collected in this prototype. Real savings custody and early release require a regulated provider and clear member consent.'),
          const SizedBox(height: 18),
          const _SectionTitle('Early access votes'),
          const SizedBox(height: 8),
          const _VoteProgress(approved: 2, total: 3),
          const SizedBox(height: 16),
          OutlinedButton.icon(
              onPressed: () => _showDemoDialog(context, 'Early access request',
                  'Demo only. A real request would require identity verification and approval from at least half of eligible contributors.'),
              icon: const Icon(Icons.lock_open_rounded),
              label: const Text('Request early access')),
          const SizedBox(height: 8),
          FilledButton(
              onPressed: () => _showDemoDialog(context, 'Create a goal',
                  'Goal setup is a visual demo. Contributions are not held and no funds are locked.'),
              child: const Text('Set up a contribution goal')),
        ],
      );
}

class ConvertPage extends StatefulWidget {
  const ConvertPage({super.key});
  @override
  State<ConvertPage> createState() => _ConvertPageState();
}

class _ConvertPageState extends State<ConvertPage> {
  final _amount = TextEditingController(text: '100');
  String _from = 'USD';
  String _to = 'NGN';
  static const _rates = <String, double>{
    'USD/NGN': 1520,
    'GBP/NGN': 1930,
    'EUR/NGN': 1650,
    'NGN/USD': 1 / 1520,
    'NGN/GBP': 1 / 1930,
    'NGN/EUR': 1 / 1650,
    'USD/GBP': .79,
    'GBP/USD': 1.27,
    'EUR/USD': 1.08,
    'USD/EUR': .93,
    'EUR/GBP': .85,
    'GBP/EUR': 1.18
  };
  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  double get _rate => _rates['$_from/$_to'] ?? 1;
  double get _converted => (double.tryParse(_amount.text) ?? 0) * _rate;

  @override
  Widget build(BuildContext context) => _PageScaffold(
        title: 'Convert currency',
        children: [
          const _PageIntro(
              'Compare an indicative rate before choosing when to convert.'),
          const SizedBox(height: 16),
          TextField(
              controller: _amount,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                  labelText: 'You convert', prefixText: '$_from  ')),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: DropdownButtonFormField<String>(
                    initialValue: _from,
                    decoration: const InputDecoration(labelText: 'From'),
                    items: const ['NGN', 'USD', 'GBP', 'EUR']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => _from = v ?? _from))),
            IconButton(
                onPressed: () => setState(() {
                      final old = _from;
                      _from = _to;
                      _to = old;
                    }),
                icon: const Icon(Icons.swap_horiz_rounded),
                tooltip: 'Swap currencies'),
            Expanded(
                child: DropdownButtonFormField<String>(
                    initialValue: _to,
                    decoration: const InputDecoration(labelText: 'To'),
                    items: const ['NGN', 'USD', 'GBP', 'EUR']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => _to = v ?? _to))),
          ]),
          const SizedBox(height: 16),
          Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: .65),
                  borderRadius: BorderRadius.circular(18)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Estimated receive amount',
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                    const SizedBox(height: 5),
                    Text('${_to} ${_converted.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 26, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(
                        'Demo rate: 1 $_from = ${_rate.toStringAsFixed(4)} $_to',
                        style: const TextStyle(fontSize: 12)),
                  ])),
          const SizedBox(height: 12),
          const _InfoBanner(
              icon: Icons.query_stats_rounded,
              text:
                  'Rates shown are sample values for the calculator. Live prices, fees, and execution are not connected.'),
          const SizedBox(height: 18),
          FilledButton(
              onPressed: () => _showDemoDialog(
                  context,
                  'Conversion not submitted',
                  'This is an estimate only. No currency was exchanged.'),
              child: const Text('Review demo estimate')),
        ],
      );
}

class MorePage extends StatelessWidget {
  const MorePage({super.key});
  static const groups = <_ServiceGroup>[
    _ServiceGroup('Everyday', [
      _ServiceItem('Airtime', Icons.phone_android_rounded),
      _ServiceItem('Mobile data', Icons.wifi_rounded),
      _ServiceItem('Subscriptions', Icons.subscriptions_rounded),
      _ServiceItem('Recharge', Icons.bolt_rounded),
    ]),
    _ServiceGroup('Bills and learning', [
      _ServiceItem('Tuition payment', Icons.school_rounded),
      _ServiceItem('Electricity', Icons.electric_bolt_rounded),
      _ServiceItem('Internet', Icons.router_rounded),
      _ServiceItem('Government services', Icons.account_balance_rounded),
    ]),
    _ServiceGroup('Shopping and travel', [
      _ServiceItem('Gift cards', Icons.card_giftcard_rounded),
      _ServiceItem('Shopping', Icons.shopping_bag_rounded),
      _ServiceItem('Transport and tolls', Icons.directions_bus_rounded),
      _ServiceItem('Travel', Icons.flight_takeoff_rounded),
    ]),
    _ServiceGroup('Finance and account', [
      _ServiceItem('BVN verification', Icons.verified_user_outlined),
      _ServiceItem('Group contributions', Icons.groups_rounded),
      _ServiceItem('Currency wallets', Icons.wallet_rounded),
      _ServiceItem('Virtual cards', Icons.credit_card_rounded),
    ]),
  ];

  @override
  Widget build(BuildContext context) => _PageScaffold(
        title: 'More services',
        children: [
          const _PageIntro(
              'Explore services. Some options are previews until YokaPay connects to licensed providers.'),
          const SizedBox(height: 16),
          for (final group in groups) ...[
            _SectionTitle(group.title),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: group.items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisExtent: 106,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8),
              itemBuilder: (context, index) {
                final item = group.items[index];
                return _ServiceTile(
                    item: item,
                    onTap: () {
                      if (item.label == 'Currency wallets') {
                        Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                                builder: (_) => const WalletPage()));
                      } else if (item.label == 'Group contributions') {
                        Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                                builder: (_) => const ContributionsPage()));
                      } else {
                        Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                                builder: (_) =>
                                    ServiceInfoPage(title: item.label)));
                      }
                    });
              },
            ),
            const SizedBox(height: 18),
          ],
        ],
      );
}

class CardsPage extends StatefulWidget {
  const CardsPage({super.key});
  @override
  State<CardsPage> createState() => _CardsPageState();
}

class _CardsPageState extends State<CardsPage> {
  String _design = 'Artist';
  @override
  Widget build(BuildContext context) => _PageScaffold(
        title: 'Yoka cards',
        children: [
          const _PageIntro(
              'Explore virtual card concepts for online shopping, gifts, and transit.'),
          const SizedBox(height: 16),
          Container(
            height: 205,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Theme.of(context).colorScheme.primary,
                  const Color(0xFF152D4B)
                ]),
                borderRadius: BorderRadius.circular(24)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.account_balance_wallet_rounded,
                    color: Colors.white),
                const SizedBox(width: 8),
                const Text('YOKAPAY',
                    style: TextStyle(
                        color: Colors.white,
                        letterSpacing: 1.3,
                        fontWeight: FontWeight.w700)),
                const Spacer(),
                const Icon(Icons.contactless_rounded, color: Colors.white70)
              ]),
              const Spacer(),
              const Text('••••  ••••  ••••  2084',
                  style: TextStyle(
                      color: Colors.white, fontSize: 19, letterSpacing: 1.4)),
              const SizedBox(height: 13),
              Row(children: [
                Text(_design.toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 11, letterSpacing: 1)),
                const Spacer(),
                const Text('DEMO CARD',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 10, letterSpacing: 1))
              ]),
            ]),
          ),
          const SizedBox(height: 10),
          const _InfoBanner(
              icon: Icons.info_outline_rounded,
              text:
                  'Illustration only. No card number is issued and this card cannot make purchases or transit payments.'),
          const SizedBox(height: 20),
          const _SectionTitle('Choose a look'),
          const SizedBox(height: 10),
          Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['Artist', 'Gamer', 'Travel', 'Minimal']
                  .map((e) => ChoiceChip(
                      label: Text(e),
                      selected: _design == e,
                      onSelected: (_) => setState(() => _design = e)))
                  .toList()),
          const SizedBox(height: 22),
          const _SectionTitle('Yoka gift cards'),
          const SizedBox(height: 8),
          const _FeatureCard(
              icon: Icons.card_giftcard_rounded,
              title: 'Create a gift card',
              subtitle:
                  'Design and gifting flow preview · no redeemable value'),
          const SizedBox(height: 12),
          const _FeatureCard(
              icon: Icons.directions_bus_rounded,
              title: 'Tap to ride',
              subtitle:
                  'Transit card concept · requires a supported transport partner'),
          const SizedBox(height: 16),
          FilledButton(
              onPressed: () => _showDemoDialog(context, 'Card preview',
                  'Card design saved for this screen only. No payment card was issued.'),
              child: const Text('Preview this design')),
        ],
      );
}

class ActivityPage extends StatelessWidget {
  const ActivityPage({super.key});
  @override
  Widget build(BuildContext context) => _PageScaffold(
        title: 'Activity',
        children: [
          const _PageIntro(
              'Your transaction timeline and YokaPay partner discoveries.'),
          const SizedBox(height: 18),
          const _SectionTitle('Recent transactions'),
          const SizedBox(height: 8),
          const _ActivityTile(
              icon: Icons.shopping_bag_outlined,
              title: 'Market Square',
              subtitle: 'Today · Card payment · Demo',
              amount: '− ₦ 12,400',
              positive: false),
          const _ActivityTile(
              icon: Icons.call_received_rounded,
              title: 'Transfer received',
              subtitle: 'Yesterday · Sample entry',
              amount: '+ ₦ 35,000',
              positive: true),
          const _ActivityTile(
              icon: Icons.phone_android_rounded,
              title: 'Airtime purchase',
              subtitle: 'Monday · Sample entry',
              amount: '− ₦ 1,000',
              positive: false),
          const SizedBox(height: 20),
          const _SectionTitle('Partner offers'),
          const SizedBox(height: 7),
          const _InfoBanner(
              icon: Icons.campaign_outlined,
              text:
                  'Partner placements are not connected. These are clearly labeled placeholders, not real endorsements.'),
          const SizedBox(height: 10),
          const _OfferCard(
              title: 'Everyday essentials',
              category: 'Sample sponsored placement',
              icon: Icons.shopping_basket_outlined),
          const _OfferCard(
              title: 'Weekend city rides',
              category: 'Sample sponsored placement',
              icon: Icons.directions_bus_outlined),
          const _OfferCard(
              title: 'Learning and skills',
              category: 'Sample sponsored placement',
              icon: Icons.menu_book_outlined),
        ],
      );
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) => _PageScaffold(
        title: 'Profile',
        children: [
          const _FeatureCard(
              icon: Icons.person_outline_rounded,
              title: 'Amara Nneka Okafor',
              subtitle: 'Demo profile · details are not verified'),
          const SizedBox(height: 14),
          const _PageIntro(
              'Account settings and help will be connected as YokaPay’s secure services are built.'),
          const SizedBox(height: 14),
          const _FeatureCard(
              icon: Icons.security_rounded,
              title: 'Security and privacy',
              subtitle: 'Passkeys, device checks, and recovery design'),
          const _FeatureCard(
              icon: Icons.help_outline_rounded,
              title: 'Help and support',
              subtitle: 'Support channels are not connected in this prototype'),
          const _FeatureCard(
              icon: Icons.language_rounded,
              title: 'Language and region',
              subtitle: 'Choose settings when launch markets are confirmed'),
        ],
      );
}

class ServiceInfoPage extends StatelessWidget {
  const ServiceInfoPage({required this.title, super.key});
  final String title;
  @override
  Widget build(BuildContext context) => _PageScaffold(
        title: title,
        children: [
          const _PageIntro(
              'This service is a preview and is not connected to a provider.'),
          const SizedBox(height: 16),
          _InfoBanner(
              icon: title.contains('BVN')
                  ? Icons.verified_user_outlined
                  : Icons.construction_rounded,
              text: title.contains('BVN')
                  ? 'BVN checks need an approved identity-verification partner. Do not enter your BVN in this prototype.'
                  : 'Provider onboarding, pricing, and security review are needed before this service can be enabled.'),
        ],
      );
}

class _PageScaffold extends StatelessWidget {
  const _PageScaffold({required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: Text(title,
                style: const TextStyle(fontWeight: FontWeight.w700))),
        body: SafeArea(
            child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: children)),
      );
}

class _PageIntro extends StatelessWidget {
  const _PageIntro(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.45));
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Text(title,
      style: const TextStyle(
          fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -.2));
}

class _ActionTile extends StatelessWidget {
  const _ActionTile(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
        button: true,
        label: label,
        child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Column(children: [
              Container(
                  height: 56,
                  width: 60,
                  decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(18)),
                  child: Icon(icon, color: colors.primary, size: 24)),
              const SizedBox(height: 7),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600)),
            ])));
  }
}

class _ServiceItem {
  const _ServiceItem(this.label, this.icon);
  final String label;
  final IconData icon;
}

class _ServiceGroup {
  const _ServiceGroup(this.title, this.items);
  final String title;
  final List<_ServiceItem> items;
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.item, required this.onTap});
  final _ServiceItem item;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(16)),
              child: Icon(item.icon, color: colors.primary, size: 22)),
          const SizedBox(height: 6),
          Text(item.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 10.5, fontWeight: FontWeight.w600, height: 1.1)),
        ]));
  }
}

class _WalletTile extends StatelessWidget {
  const _WalletTile(
      {required this.currency,
      required this.name,
      required this.amount,
      required this.flag});
  final String currency, name, amount, flag;
  @override
  Widget build(BuildContext context) => Card(
          child: ListTile(
        leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(flag)),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('$currency wallet · Held in $currency',
            style: const TextStyle(fontSize: 12)),
        trailing: Text(amount,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
      ));
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.amount,
      required this.positive});
  final IconData icon;
  final String title, subtitle, amount;
  final bool positive;
  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            child: Icon(icon, size: 20)),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
        trailing: Text(amount,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: positive ? Theme.of(context).colorScheme.primary : null,
                fontSize: 12)),
      );
}

class _RateTile extends StatelessWidget {
  const _RateTile(
      {required this.pair, required this.value, required this.change});
  final String pair, value, change;
  @override
  Widget build(BuildContext context) => Card(
      child: ListTile(
          title:
              Text(pair, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: const Text('Indicative sample'),
          trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(value,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(change,
                    style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.primary))
              ])));
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
            color: colors.primaryContainer.withValues(alpha: .55),
            borderRadius: BorderRadius.circular(15)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: colors.primary, size: 20),
          const SizedBox(width: 9),
          Expanded(
              child: Text(text,
                  style: TextStyle(
                      color: colors.onSurface, fontSize: 12, height: 1.4)))
        ]));
  }
}

class _NoticeTile extends StatelessWidget {
  const _NoticeTile(
      {required this.icon,
      required this.title,
      required this.body,
      required this.time});
  final IconData icon;
  final String title, body, time;
  @override
  Widget build(BuildContext context) => Card(
      margin: const EdgeInsets.only(bottom: 9),
      child: ListTile(
          isThreeLine: true,
          leading: CircleAvatar(child: Icon(icon)),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text('$body\n$time')));
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard(
      {required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Card(
      child: ListTile(
          leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(icon, color: Theme.of(context).colorScheme.primary)),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle)));
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(children: [
        Expanded(
            child: Text(label,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant))),
        Text(value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w600))
      ]));
}

class _VoteProgress extends StatelessWidget {
  const _VoteProgress({required this.approved, required this.total});
  final int approved, total;
  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
          padding: const EdgeInsets.all(15),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$approved of $total members approved · Demo vote',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            LinearProgressIndicator(
                value: approved / total,
                minHeight: 7,
                borderRadius: BorderRadius.circular(8)),
            const SizedBox(height: 6),
            const Text('At least half of eligible members must approve.',
                style: TextStyle(fontSize: 11))
          ])));
}

class _OfferCard extends StatelessWidget {
  const _OfferCard(
      {required this.title, required this.category, required this.icon});
  final String title, category;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(
      child: ListTile(
          leading: CircleAvatar(child: Icon(icon)),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(category),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => _showDemoDialog(context, title,
              'Placeholder offer only. No real company is partnered with YokaPay yet.')));
}

class _PanelLabel extends StatelessWidget {
  const _PanelLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(text.toUpperCase(),
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: .8)));
}

class _ThemeChoice extends StatelessWidget {
  const _ThemeChoice(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.onTap});
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: selected
          ? Icon(Icons.check_circle_rounded,
              color: Theme.of(context).colorScheme.primary)
          : null,
      selected: selected,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)));
}

class _AccentChoice extends StatelessWidget {
  const _AccentChoice(
      {required this.name,
      required this.color,
      required this.selected,
      required this.onTap});
  final String name;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
      leading: CircleAvatar(backgroundColor: color, radius: 14),
      title: Text(name),
      trailing: selected
          ? Icon(Icons.check_circle_rounded,
              color: Theme.of(context).colorScheme.primary)
          : null,
      selected: selected,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)));
}

void _showDemoDialog(BuildContext context, String title, String body) {
  showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
              title: Text(title),
              content: Text(body),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Got it'))
              ]));
}
