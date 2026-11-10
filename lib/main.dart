import 'package:flutter/material.dart';

void main() => runApp(const YokaPayApp());

class YokaPayApp extends StatefulWidget {
  const YokaPayApp({super.key});

  @override
  State<YokaPayApp> createState() => _YokaPayAppState();
}

class _YokaPayAppState extends State<YokaPayApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() => setState(() {
        _themeMode = _themeMode == ThemeMode.light
            ? ThemeMode.dark
            : ThemeMode.light;
      });

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'YokaPay',
        debugShowCheckedModeBanner: false,
        themeMode: _themeMode,
        theme: _buildTheme(Brightness.light),
        darkTheme: _buildTheme(Brightness.dark),
        home: HomeScreen(onToggleTheme: _toggleTheme),
      );

  ThemeData _buildTheme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF087E68),
      brightness: brightness,
      surface: dark ? const Color(0xFF151A19) : Colors.white,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark ? const Color(0xFF0E1211) : const Color(0xFFF5F7F6),
      appBarTheme: AppBarTheme(
        backgroundColor: dark ? const Color(0xFF0E1211) : const Color(0xFFF5F7F6),
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.onToggleTheme, super.key});

  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: colors.primary, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Text('yokapay', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        ]),
        actions: [
          IconButton(onPressed: onToggleTheme, tooltip: 'Switch theme', icon: const Icon(Icons.contrast_rounded)),
          IconButton(onPressed: () {}, tooltip: 'Notifications', icon: const Icon(Icons.notifications_none_rounded)),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            const Text('Good morning, Amara', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.4)),
            const SizedBox(height: 4),
            Text('Here’s your money at a glance.', style: TextStyle(color: colors.onSurfaceVariant)),
            const SizedBox(height: 20),
            _BalanceCard(onToggleTheme: onToggleTheme),
            const SizedBox(height: 22),
            const _SectionTitle('Quick actions'),
            const SizedBox(height: 12),
            Row(children: const [
              Expanded(child: _ActionTile(icon: Icons.arrow_upward_rounded, label: 'Transfer')),
              SizedBox(width: 10),
              Expanded(child: _ActionTile(icon: Icons.add_rounded, label: 'Add money')),
              SizedBox(width: 10),
              Expanded(child: _ActionTile(icon: Icons.swap_horiz_rounded, label: 'Convert')),
              SizedBox(width: 10),
              Expanded(child: _ActionTile(icon: Icons.grid_view_rounded, label: 'More')),
            ]),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const _SectionTitle('Your wallets'),
              TextButton(onPressed: () {}, child: const Text('See all')),
            ]),
            const SizedBox(height: 4),
            const _WalletTile(currency: 'NGN', name: 'Nigerian naira', amount: '₦ 248,500.00', flag: '🇳🇬'),
            const SizedBox(height: 8),
            const _WalletTile(currency: 'USD', name: 'US dollar', amount: '\$ 120.00', flag: '🇺🇸'),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const _SectionTitle('Recent activity'),
              TextButton(onPressed: () {}, child: const Text('History')),
            ]),
            const _ActivityTile(icon: Icons.shopping_bag_outlined, title: 'Market Square', subtitle: 'Today · Card payment', amount: '− ₦ 12,400', positive: false),
            const _ActivityTile(icon: Icons.call_received_rounded, title: 'Transfer received', subtitle: 'Yesterday · Verified in YokaPay', amount: '+ ₦ 35,000', positive: true),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: colors.primaryContainer.withValues(alpha: .55), borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                Icon(Icons.verified_user_outlined, color: colors.primary),
                const SizedBox(width: 10),
                Expanded(child: Text('Always verify payments in your YokaPay activity. A receipt screenshot is not proof of payment.', style: TextStyle(color: colors.onSurface, fontSize: 12, height: 1.4))),
              ]),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.credit_card_outlined), label: 'Cards'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Activity'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.onToggleTheme});
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF086B5C), Color(0xFF0B9474)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFF087E68).withValues(alpha: .2), blurRadius: 22, offset: const Offset(0, 10))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('TOTAL BALANCE', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
          const Spacer(),
          IconButton(onPressed: onToggleTheme, visualDensity: VisualDensity.compact, icon: const Icon(Icons.visibility_outlined, color: Colors.white70, size: 20)),
        ]),
        const Text('₦ 248,500.00', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w700, letterSpacing: -1)),
        const SizedBox(height: 18),
        Row(children: [
          _BalanceAction(icon: Icons.arrow_upward_rounded, label: 'Send'),
          const SizedBox(width: 10),
          _BalanceAction(icon: Icons.add_rounded, label: 'Add money'),
          const Spacer(),
          const Icon(Icons.shield_outlined, color: Colors.white70, size: 18),
          const SizedBox(width: 5),
          const Text('Protected', style: TextStyle(color: Colors.white70, fontSize: 12)),
        ]),
      ]),
    );
  }
}

class _BalanceAction extends StatelessWidget {
  const _BalanceAction({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: () {},
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white38), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9)),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -.2));
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(children: [
      Container(height: 54, width: 58, decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(17)), child: Icon(icon, color: colors.primary, size: 24)),
      const SizedBox(height: 7),
      Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
    ]);
  }
}

class _WalletTile extends StatelessWidget {
  const _WalletTile({required this.currency, required this.name, required this.amount, required this.flag});
  final String currency, name, amount, flag;
  @override
  Widget build(BuildContext context) => Card(child: ListTile(
        leading: CircleAvatar(backgroundColor: Theme.of(context).colorScheme.primaryContainer, child: Text(flag)),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('$currency wallet · Held in $currency', style: const TextStyle(fontSize: 12)),
        trailing: Text(amount, style: const TextStyle(fontWeight: FontWeight.w700)),
      ));
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.icon, required this.title, required this.subtitle, required this.amount, required this.positive});
  final IconData icon;
  final String title, subtitle, amount;
  final bool positive;
  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(backgroundColor: Theme.of(context).colorScheme.surface, child: Icon(icon, size: 20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
        trailing: Text(amount, style: TextStyle(fontWeight: FontWeight.w700, color: positive ? Theme.of(context).colorScheme.primary : null, fontSize: 13)),
      );
}
