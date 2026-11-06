import 'package:cached_network_image/cached_network_image.dart';
import 'package:dailyanimelist/screens/contentdetailedscreen.dart';
import 'package:dailyanimelist/main.dart';
import 'package:dailyanimelist/api/maluser.dart';
import 'package:dailyanimelist/features/ameo/ameo_client.dart';
import 'package:dailyanimelist/generated/l10n.dart';
import 'package:dailyanimelist/user/user.dart';
import 'package:dailyanimelist/user/hompagepref.dart';
import 'package:dailyanimelist/util/responsive_helper.dart';
import 'package:dailyanimelist/widgets/loading/loadingcard.dart';
import 'package:dailyanimelist/widgets/shimmecolor.dart';
import 'package:dailyanimelist/widgets/user/contentlistwidget.dart';
import 'package:dal_commons/dal_commons.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Isolated Ameo/Sprout client and UI; legacy DailyAL recommendation code is untouched.
class AmeoRecommendationSection extends StatefulWidget {
  final String? title;

  const AmeoRecommendationSection({Key? key, this.title}) : super(key: key);

  @override
  State<AmeoRecommendationSection> createState() => _AmeoRecommendationSectionState();
}

class _AmeoRecommendationSectionState extends State<AmeoRecommendationSection> {
  List<AmeoAnime> items = const [];
  String username = '';
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    MalUser.listStatusRevision.addListener(_onListStatusChanged);
    load();
  }

  void _onListStatusChanged() {
    if (mounted) load();
  }

  @override
  void dispose() {
    MalUser.listStatusRevision.removeListener(_onListStatusChanged);
    super.dispose();
  }

  Future<void> load({bool force = false}) async {
    final prefs = await SharedPreferences.getInstance();
    username = await resolveAmeoUsername(prefs);
    if (username.isEmpty) {
      if (mounted) setState(() { loading = false; });
      return;
    }
    if (mounted) setState(() { loading = items.isEmpty; error = null; });
    try {
      final result = await AmeoClient().recommend(username, AmeoSettings.fromPrefs(prefs), force: force);
      if (mounted) setState(() { items = result; loading = false; error = result.isEmpty ? S.current.Ameo_No_Results : null; });
    } catch (_) {
      if (mounted) setState(() { loading = false; error = S.current.Ameo_Load_Failed; });
    }
  }

  Future<void> openSettings() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AmeoRecommendationPage()));
    load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tile = tileMap.tryAt(user.pref.homePageTileSize)!;
    final cardHeight = tile.containerHeight;
    final cardWidth = cardHeight * (2 / 3);
    final horizontalPadding =
        ResponsiveHelper.isTabletOrLarger(context) ? 0.0 : 15.0;
    final animeNodes = items
        .take(12)
        .map((item) => item.dailyAlNode)
        .whereType<BaseNode>()
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 15),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.title ?? S.current.Ameo_Recommendations,
                  style: theme.textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: S.current.Ameo_All_Recommendations_Settings,
                onPressed: openSettings,
                icon: const Icon(Icons.arrow_forward),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        if (username.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: OutlinedButton.icon(
              onPressed: openSettings,
              icon: const Icon(Icons.tune),
              label: Text(S.current.Ameo_Configure_Username),
            ),
          )
        else if (loading)
          ShimmerColor(
            Container(
              height: cardHeight,
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                itemCount: 10,
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) =>
                    LoadingCard(height: cardHeight, width: cardWidth),
              ),
            ),
          )
        else if (animeNodes.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Row(
              children: [
                Expanded(child: Text(error ?? S.current.Ameo_No_Recommendations_Yet)),
                IconButton(
                  onPressed: () => load(force: true),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          )
        else
          horizontalList(
            category: 'anime',
            items: animeNodes,
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Text(
            S.current.Ameo_Powered_By,
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}


class AmeoRecommendationPage extends StatefulWidget {
  const AmeoRecommendationPage({Key? key}) : super(key: key);
  @override
  State<AmeoRecommendationPage> createState() => _AmeoRecommendationPageState();
}
class _AmeoRecommendationPageState extends State<AmeoRecommendationPage> {
  final usernameController = TextEditingController();
  AmeoSettings settings = const AmeoSettings();
  List<AmeoAnime> items = const [];
  bool loading = false;
  String? error;
  String? technicalLog;
  @override
  void initState() {
    super.initState();
    MalUser.listStatusRevision.addListener(_onListStatusChanged);
    initialize();
  }

  void _onListStatusChanged() {
    if (mounted && usernameController.text.trim().isNotEmpty) {
      refresh(force: false);
    }
  }

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final resolvedUsername = await resolveAmeoUsername(prefs);
    if (!mounted) return;
    usernameController.text = resolvedUsername;
    settings = AmeoSettings.fromPrefs(prefs);
    setState(() {});
    if (resolvedUsername.trim().isNotEmpty) refresh(force: false);
  }
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ameo_username', usernameController.text.trim());
    await settings.save(prefs);
  }
  Future<void> refresh({bool force = true}) async {
    final name = usernameController.text.trim();
    if (name.isEmpty) {
      setState(() { loading = false; error = S.current.Ameo_Username_Missing; technicalLog = 'phase=validation\nreason=empty_username\nprofile_auto_detected=${user.status == AuthStatus.AUTHENTICATED}'; items = const []; });
      return;
    }
    await save();
    if (!mounted) return;
    setState(() { loading = true; error = null; technicalLog = null; });
    try {
      final result = await AmeoClient().recommend(name, settings, force: force);
      if (!mounted) return;
      setState(() {
        items = result; loading = false;
        if (result.isEmpty) { error = S.current.Ameo_No_Displayable_Results; technicalLog = 'phase=decode\nrecommendation_count=0'; }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { loading = false; error = S.current.Ameo_Request_Failed; technicalLog = e is AmeoRequestException ? e.diagnostics : 'phase=ui\nexception_type=${e.runtimeType}\nmessage=${safeAmeoError(e.toString())}'; });
    }
  }
  Future<void> _openSettings() async {
    var draftUsername = usernameController.text;
    var draftSettings = settings;
    final applied = await showModalBottomSheet<bool>(
      context: context, isScrollControlled: true, useSafeArea: true, showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            (() {
              final media = MediaQuery.of(context);
              final keyboardInset = media.viewInsets.bottom;
              final navigationInset = media.viewPadding.bottom;
              return (keyboardInset > navigationInset ? keyboardInset : navigationInset) + 20;
            })(),
          ),
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(S.current.Ameo_Settings, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextFormField(key: ValueKey(draftUsername), initialValue: draftUsername, autocorrect: false,
              decoration: InputDecoration(labelText: S.current.Ameo_Username_Label, helperText: S.current.Ameo_Username_Helper, border: const OutlineInputBorder()),
              onChanged: (value) => draftUsername = value),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: draftSettings.model,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: S.current.Ameo_Model_Label,
                helperText: S.current.Ameo_Model_Helper,
                border: const OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: '2026-logq', child: Text('Aug. 2026 · LogQ (default)')),
                DropdownMenuItem(value: '2026-rc', child: Text('Aug. 2026 · Release candidate')),
                DropdownMenuItem(value: '2025-jax', child: Text('2025 · JAX')),
                DropdownMenuItem(value: 'legacy', child: Text('Legacy · 2023')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setSheetState(() => draftSettings = draftSettings.copyWith(model: value));
                }
              },
            ),
            SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(S.current.Ameo_Extra_Seasons), value: draftSettings.includeExtraSeasons, onChanged: (v) => setSheetState(() => draftSettings = draftSettings.copyWith(includeExtraSeasons: v))),
            SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(S.current.Ameo_Movies), value: draftSettings.includeMovies, onChanged: (v) => setSheetState(() => draftSettings = draftSettings.copyWith(includeMovies: v))),
            SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(S.current.Ameo_ONA_OVA_Specials), value: draftSettings.includeONAsOVAspecials, onChanged: (v) => setSheetState(() => draftSettings = draftSettings.copyWith(includeONAsOVAspecials: v))),
            SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(S.current.Ameo_Music_Anime), value: draftSettings.includeMusic, onChanged: (v) => setSheetState(() => draftSettings = draftSettings.copyWith(includeMusic: v))),
            SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(S.current.Ameo_Filter_PTW), value: draftSettings.filterPlanToWatch, onChanged: (v) => setSheetState(() => draftSettings = draftSettings.copyWith(filterPlanToWatch: v))),
            if (draftSettings.model == 'legacy')
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(S.current.Ameo_Legacy_Model_Note),
              ),
            Text('${S.current.Ameo_Logit_Weight}: ${draftSettings.logitWeight.toStringAsFixed(2)}'),
            Slider(value: draftSettings.logitWeight, min: 0, max: 1, divisions: 100, onChanged: draftSettings.model == 'legacy' ? null : (v) => setSheetState(() => draftSettings = draftSettings.copyWith(logitWeight: v))),
            Text('${S.current.Ameo_Niche_Boost}: ${draftSettings.nicheBoostFactor.toStringAsFixed(2)}'),
            Slider(value: draftSettings.nicheBoostFactor, min: 0, max: 1, divisions: 100, onChanged: draftSettings.model == 'legacy' ? null : (v) => setSheetState(() => draftSettings = draftSettings.copyWith(nicheBoostFactor: v))),
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () { usernameController.text = draftUsername.trim(); settings = draftSettings; Navigator.of(sheetContext).pop(true); }, icon: const Icon(Icons.check), label: Text(S.current.Ameo_Apply_Settings))),
          ])),
        ),
      ),
    );
    if (applied == true && mounted) { await save(); await refresh(); }
  }
  Future<void> _copyTechnicalLog() async {
    if (technicalLog == null) return;
    await Clipboard.setData(ClipboardData(text: technicalLog!));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.current.Ameo_Log_Copied)));
  }
  @override
  void dispose() {
    MalUser.listStatusRevision.removeListener(_onListStatusChanged);
    usernameController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(S.current.Ameo_Recommendations), actions: [
      IconButton(tooltip: S.current.Ameo_Settings, onPressed: _openSettings, icon: const Icon(Icons.settings_outlined)),
      IconButton(tooltip: S.current.Ameo_Reload, onPressed: loading ? null : () => refresh(), icon: const Icon(Icons.refresh)),
      IconButton(tooltip: 'Ameo', onPressed: () => launchUrl(Uri.parse('https://anime.ameo.dev/'), mode: LaunchMode.externalApplication), icon: const Icon(Icons.open_in_new)),
    ]),
    body: ListView(padding: const EdgeInsets.symmetric(vertical: 8), children: [
      if (loading) const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
      if (error != null) Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          if (technicalLog != null) ExpansionTile(tilePadding: EdgeInsets.zero, title: Text(S.current.Ameo_Technical_Details), children: [
            SelectableText(technicalLog!, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'monospace')),
            Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: _copyTechnicalLog, icon: const Icon(Icons.copy), label: Text(S.current.Ameo_Copy_Log))),
          ]),
          Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: loading ? null : () => refresh(), icon: const Icon(Icons.refresh), label: Text(S.current.Retry))),
        ])))),
      if (!loading && items.isEmpty && error == null) Padding(padding: const EdgeInsets.all(20), child: Text(S.current.Ameo_Add_Username_Hint)),
      for (var i = 0; i < items.length; i++) _AmeoRecommendationEntry(key: ValueKey(items[i].id), anime: items[i], index: i),
      const SizedBox(height: 20),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(S.current.Ameo_Powered_By_Desc)),
    ]),
  );
}


class _AmeoRecommendationEntry extends StatefulWidget {
  final AmeoAnime anime; final int index;
  const _AmeoRecommendationEntry({Key? key, required this.anime, required this.index}) : super(key: key);
  @override State<_AmeoRecommendationEntry> createState() => _AmeoRecommendationEntryState();
}
class _AmeoRecommendationEntryState extends State<_AmeoRecommendationEntry> {
  bool expanded = false;
  @override
  Widget build(BuildContext context) {
    final anime = widget.anime;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (anime.dailyAlNode != null)
        ContentAllWidget(
          dynContent: anime.dailyAlNode,
          myListStatus: listStatus(anime.dailyAlNode, 'anime'),
          index: widget.index,
          category: 'anime',
          aspectRatio: 2.35,
          imageAspectRatio: .6,
          showImage: true,
          showEdit: true,
          showStatus: true,
          updateCacheOnEdit: true,
          onContentUpdate: () {},
          showBackgroundImage: false,
        )
      else
        ListTile(
          leading: SizedBox(width: 60, child: anime.image.isEmpty ? const Icon(Icons.movie_outlined) : CachedNetworkImage(imageUrl: anime.image, fit: BoxFit.cover)),
          title: Text(anime.title),
          subtitle: anime.score == null ? null : Text('${S.current.Ameo_Predicted_Score}: ${anime.score!.toStringAsFixed(3)}'),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ContentDetailedScreen(id: anime.id))),
        ),
      if (anime.score != null || anime.contributors.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 12, top: 2, bottom: 4),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 0,
            children: [
              if (anime.score != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.auto_awesome, size: 14, color: Theme.of(context).colorScheme.onSecondaryContainer),
                    const SizedBox(width: 5),
                    Text('${S.current.Ameo_Predicted_Score} ${anime.score!.toStringAsFixed(3)}', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.onSecondaryContainer)),
                  ]),
                ),
              if (anime.contributors.isNotEmpty)
                TextButton.icon(
                  onPressed: () => setState(() => expanded = !expanded),
                  icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
                  label: Text(expanded ? S.current.Ameo_Hide_Reason : S.current.Ameo_Why_Recommended),
                ),
            ],
          ),
        ),
      if (expanded && anime.contributors.isNotEmpty)
        Padding(padding: const EdgeInsets.only(left: 16, right: 12, bottom: 6), child: Column(children: [
        Container(width: double.infinity, margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(.4), borderRadius: BorderRadius.circular(10)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(S.current.Ameo_Recommended_Because, style: Theme.of(context).textTheme.titleSmall),
          for (final source in anime.contributors) ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: const Icon(Icons.movie_filter_outlined), title: Text(source.title), subtitle: source.ratingDelta != null ? Text('${S.current.Ameo_Contribution}: ${source.ratingDelta!.toStringAsFixed(3)}') : (source.userRating == null ? null : Text('${S.current.Ameo_Your_Rating}: ${source.userRating}')), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ContentDetailedScreen(id: source.id)))),
        ])),
      ])),
      const Divider(height: 1),
    ]);
  }
}
