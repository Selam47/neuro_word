import 'package:cloud_firestore/cloud_firestore.dart';

class RefineryResult {
  const RefineryResult({
    required this.deletedCount,
    required this.updatedCount,
    this.errors = const [],
  });

  final int deletedCount;
  final int updatedCount;
  final List<String> errors;

  @override
  String toString() =>
      'RefineryResult(deleted: $deletedCount, updated: $updatedCount, errors: ${errors.length})';
}

class RefineryService {
  final _firestore = FirebaseFirestore.instance;
  static const _collection = 'words';
  static const _batchSize = 499;

  static const Set<String> _garbageWords = {
    'zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight',
    'nine', 'ten', 'eleven', 'twelve', 'thirteen', 'fourteen', 'fifteen',
    'sixteen', 'seventeen', 'eighteen', 'nineteen', 'twenty', 'thirty',
    'forty', 'fifty', 'sixty', 'seventy', 'eighty', 'ninety', 'hundred',
    'thousand', 'million', 'billion', 'trillion',
    'first', 'second', 'third', 'fourth', 'fifth', 'sixth', 'seventh',
    'eighth', 'ninth', 'tenth', 'eleventh', 'twelfth', 'hundredth',
    'thousandth', 'millionth',
    'a', 'an', 'the',
    'and', 'or', 'but', 'nor', 'yet',
    'if', 'since', 'unless', 'although', 'though', 'whereas',
    'in', 'on', 'at', 'to', 'for', 'of', 'with', 'by', 'from', 'into',
    'onto', 'out', 'up', 'down', 'over', 'under', 'through', 'about',
    'between', 'among', 'around', 'before', 'after', 'above', 'below',
    'near', 'beside', 'behind', 'beyond', 'despite', 'during', 'except',
    'off', 'per', 'plus', 'than', 'toward', 'towards', 'upon', 'via',
    'within', 'without', 'along', 'across', 'against',
    'i', 'me', 'my', 'mine', 'myself', 'you', 'your', 'yours', 'yourself',
    'he', 'him', 'his', 'himself', 'she', 'her', 'hers', 'herself',
    'it', 'its', 'itself', 'we', 'us', 'our', 'ours', 'ourselves',
    'they', 'them', 'their', 'theirs', 'themselves',
    'this', 'that', 'these', 'those',
    'who', 'whom', 'whose', 'what', 'which', 'where', 'when', 'why', 'how',
    'be', 'am', 'is', 'are', 'was', 'were', 'been', 'being',
    'have', 'has', 'had', 'having', 'do', 'does', 'did',
    'will', 'would', 'shall', 'should', 'may', 'might', 'can', 'could', 'must',
    'hello', 'hi', 'hey', 'bye', 'goodbye', 'ok', 'okay', 'yes', 'no',
    'please', 'thanks', 'thank', 'sorry', 'excuse', 'welcome', 'farewell',
    'congratulations', 'cheers', 'greetings',
    'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday',
    'january', 'february', 'april', 'june', 'july', 'august',
    'september', 'october', 'november', 'december',
    'etc', 'ie', 'eg', 'vs', 'mr', 'mrs', 'ms', 'dr', 'prof',
    'also', 'very', 'just', 'not', 'only', 'even', 'both', 'all',
    'each', 'every', 'any', 'some', 'much', 'many', 'more', 'most',
    'other', 'another', 'such', 'same', 'own', 'already', 'again',
    'never', 'always', 'often', 'still', 'too', 'as', 'while',
  };

  static const Set<String> _awlWords = {
    'analysis', 'analyze', 'analytical', 'approach', 'area', 'assess',
    'assessment', 'assume', 'assumption', 'authority', 'available',
    'availability', 'benefit', 'concept', 'conceptual', 'consist',
    'consistent', 'consistency', 'context', 'contextual', 'contract',
    'create', 'creation', 'creative', 'creativity', 'data', 'define',
    'definition', 'definitive', 'derive', 'derivation', 'distribute',
    'distribution', 'economy', 'economic', 'economics', 'economical',
    'environment', 'environmental', 'establish', 'establishment',
    'estimate', 'estimation', 'evidence', 'evidential', 'export',
    'factor', 'finance', 'financial', 'financially', 'formula',
    'function', 'functional', 'identify', 'identification', 'income',
    'indicate', 'indication', 'indicator', 'individual', 'individually',
    'interpret', 'interpretation', 'involve', 'involvement', 'issue',
    'legal', 'legislation', 'legislative', 'legislate', 'major',
    'method', 'methodology', 'methodological', 'occur', 'occurrence',
    'percent', 'percentage', 'period', 'periodic', 'policy', 'principle',
    'procedure', 'process', 'require', 'requirement', 'research',
    'researcher', 'respond', 'response', 'responsible', 'responsibility',
    'role', 'section', 'significant', 'significance', 'significantly',
    'similar', 'similarity', 'source', 'specific', 'specification',
    'specifically', 'structure', 'structural', 'theory', 'theoretical',
    'theoretically', 'vary', 'variation', 'variable',
    'achieve', 'achievement', 'acknowledge', 'affect', 'appropriate',
    'appropriately', 'aspect', 'assist', 'assistance', 'category',
    'chapter', 'commission', 'community', 'complex', 'complexity',
    'conclude', 'conclusion', 'conflict', 'consult', 'consultation',
    'contact', 'culture', 'cultural', 'design', 'distinction', 'distinct',
    'element', 'evaluate', 'evaluation', 'feature', 'focus',
    'illustrate', 'illustration', 'impact', 'institute', 'institution',
    'institutional', 'logic', 'logical', 'maintain', 'maintenance',
    'normal', 'normally', 'obtain', 'participate', 'participation',
    'perceive', 'perception', 'positive', 'positively', 'potential',
    'potentially', 'previous', 'previously', 'primary', 'primarily',
    'purchase', 'range', 'region', 'regional', 'regulate', 'regulation',
    'regulatory', 'relevant', 'relevance', 'reside', 'residence',
    'resident', 'resource', 'restrict', 'restriction', 'secure',
    'security', 'seek', 'select', 'selection', 'site', 'strategy',
    'strategic', 'strategically', 'survey', 'tradition', 'traditional',
    'transfer',
    'alternative', 'circumstance', 'comment', 'compensate', 'compensation',
    'component', 'consent', 'considerable', 'considerably', 'constant',
    'constantly', 'construct', 'construction', 'constructive', 'consume',
    'consumption', 'credit', 'demonstrate', 'demonstration', 'document',
    'documentation', 'dominate', 'dominance', 'emphasis', 'emphasize',
    'ensure', 'exclude', 'exclusion', 'exclusive', 'framework', 'fund',
    'fundamental', 'imply', 'implication', 'initial', 'initially',
    'instance', 'interact', 'interaction', 'interactive', 'justify',
    'justification', 'layer', 'link', 'location', 'maximize', 'minor',
    'negate', 'negation', 'outcome', 'partner', 'philosophy',
    'philosophical', 'physical', 'physically', 'proportion', 'proportional',
    'publish', 'publication', 'react', 'reaction', 'register',
    'rely', 'reliance', 'reliable', 'scheme', 'sequence', 'sequential',
    'shift', 'specify', 'sufficient', 'sufficiently', 'task', 'technical',
    'technically', 'technique', 'technology', 'technological', 'valid',
    'validity', 'volume',
    'access', 'adequate', 'adequately', 'annual', 'annually', 'apparent',
    'apparently', 'approximate', 'approximately', 'attitude', 'attribute',
    'civil', 'code', 'commit', 'commitment', 'communicate', 'communication',
    'concentrate', 'concentration', 'confer', 'conference', 'contrast',
    'cycle', 'debate', 'dimension', 'domestic', 'emerge', 'emergence',
    'error', 'ethnic', 'ethnicity', 'goal', 'grant', 'hypothesis',
    'hypothetical', 'implement', 'implementation', 'impose', 'integrate',
    'integration', 'internal', 'investigate', 'investigation', 'label',
    'mechanism', 'obvious', 'obviously', 'occupy', 'option', 'output',
    'overall', 'parallel', 'parameter', 'phase', 'predict', 'prediction',
    'predictable', 'principal', 'prior', 'professional', 'professionally',
    'project', 'promote', 'promotion', 'resolve', 'retain', 'retention',
    'series', 'status', 'stress', 'subsequent', 'subsequently', 'summary',
    'undertake',
    'abandon', 'adapt', 'adaptation', 'aggregate', 'allocate', 'allocation',
    'alter', 'alteration', 'amend', 'amendment', 'anticipate', 'anticipation',
    'articulate', 'assemble', 'bias', 'capable', 'capacity', 'challenge',
    'chart', 'comprehensive', 'compute', 'computation', 'conform',
    'conformity', 'coordinate', 'coordination', 'core', 'decline',
    'discrete', 'facilitate', 'facilitation', 'generate', 'generation',
    'implicit', 'incorporate', 'incorporation', 'inherent', 'inherently',
    'insight', 'minimize', 'minimization', 'network', 'notion', 'objective',
    'objectively', 'orient', 'orientation', 'perspective', 'prohibit',
    'prohibition', 'prospect', 'qualitative', 'rational', 'rationale',
    'recover', 'recovery', 'sphere', 'submit', 'submission', 'supplement',
    'supplementary', 'suspend', 'suspension', 'target', 'terminate',
    'termination', 'theme', 'transmit', 'transmission', 'ultimate',
    'ultimately', 'unique', 'uniquely', 'vision',
    'abstract', 'accurate', 'accuracy', 'acquire', 'acquisition',
    'administrate', 'administration', 'administrative', 'ambiguous',
    'ambiguity', 'assert', 'assertion', 'coherent', 'coherence', 'coincide',
    'coincidence', 'comply', 'compliance', 'comprehend', 'comprehension',
    'conceal', 'concurrent', 'conduct', 'confine', 'constrain', 'constraint',
    'controversial', 'controversy', 'convince', 'conviction', 'deduce',
    'deduction', 'depict', 'depiction', 'discriminate', 'discrimination',
    'elaborate', 'equivalence', 'equivalent', 'eventually', 'exceed',
    'exhibit', 'explicit', 'explicitly', 'exploit', 'exploration', 'expose',
    'exposure', 'extensive', 'extensively', 'fluctuate', 'fluctuation',
    'global', 'globally', 'guarantee', 'hierarchy', 'highlight', 'incident',
    'infer', 'inference', 'inspect', 'inspection', 'intense', 'intensity',
    'intermediate', 'intervene', 'intervention', 'intrinsic', 'manifest',
    'manipulate', 'manipulation', 'mitigate', 'mitigation', 'modify',
    'modification', 'monitor', 'monitoring', 'norms', 'obscure',
    'omit', 'omission', 'persist', 'persistent', 'persistently',
    'plausible', 'plausibility', 'precise', 'precision', 'prominent',
    'prominence', 'quantitative', 'rationalize', 'reinforce', 'reinforcement',
    'scrutinize', 'scrutiny', 'stabilize', 'stability', 'statistics',
    'statistical', 'substantial', 'substantially', 'trigger', 'undermine',
    'utilize', 'utilization', 'verify', 'verification', 'virtually',
    'widespread',
  };

  static const Set<String> _oxford5000Words = {
    'accomplish', 'accomplishment', 'accumulate', 'accumulation',
    'acute', 'advocate', 'aesthetic', 'aesthetics', 'aftermath', 'agenda',
    'ambition', 'ambitious', 'amplify', 'analogy', 'anxiety', 'anxious',
    'aspire', 'aspiration', 'attain', 'attainment', 'authentic',
    'authenticity', 'autonomy', 'autonomous', 'benchmark', 'bold',
    'breakthrough', 'burden', 'captivate', 'catastrophe', 'catastrophic',
    'chronic', 'clarity', 'classify', 'collaborate', 'collaboration',
    'commence', 'compelling', 'competence', 'competent', 'comprise',
    'concise', 'confront', 'consequence', 'consequent', 'contemporary',
    'continuum', 'contradict', 'contradiction', 'correlation', 'credible',
    'crucial', 'cultivate', 'cynical', 'cynicism', 'decisive', 'dedication',
    'deliberate', 'dilemma', 'discipline', 'discourse', 'disrupt',
    'disruption', 'diverse', 'diversity', 'dominant', 'dynamic', 'dynamics',
    'eliminate', 'elite', 'empathy', 'empower', 'encompass', 'enforce',
    'enormous', 'enterprise', 'ethical', 'ethics', 'evolve', 'evolution',
    'exception', 'exceptional', 'execute', 'execution', 'flexible',
    'flexibility', 'formulate', 'foundation', 'generic', 'inevitable',
    'inevitably', 'infinite', 'inform', 'infrastructure', 'initiate',
    'initiative', 'innovative', 'inspiration', 'invoke', 'knowledgeable',
    'legitimate', 'momentum', 'motivate', 'motivation', 'navigate',
    'normalize', 'overcome', 'paradigm', 'phenomenon', 'prioritize',
    'proactive', 'profound', 'progressive', 'psychology', 'resilience',
    'resilient', 'retrieve', 'robust', 'streamline', 'synthesize',
    'systematic', 'tactical', 'tangible', 'threshold', 'transform',
    'transformation', 'transition', 'unprecedented', 'validate', 'visualize',
    'vulnerable',
  };

  static bool isGarbage(String word) {
    final cleaned = word.toLowerCase().trim();
    if (cleaned.isEmpty) return true;
    if (RegExp(r'^\d+$').hasMatch(cleaned)) return true;
    return _garbageWords.contains(cleaned);
  }

  static String classifySource(String word) {
    final cleaned = word.toLowerCase().trim();
    if (_awlWords.contains(cleaned)) return 'awl';
    if (_oxford5000Words.contains(cleaned)) return 'oxford_5000';
    return 'oxford_3000';
  }

  static int computeWeight(String word, String level) {
    final source = classifySource(word);
    switch (source) {
      case 'awl':
        switch (level) {
          case 'A1': return 3;
          case 'A2': return 4;
          case 'B1': return 6;
          case 'B2': return 8;
          case 'C1': return 10;
          default: return 4;
        }
      case 'oxford_5000':
        switch (level) {
          case 'A1': return 2;
          case 'A2': return 3;
          case 'B1': return 5;
          case 'B2': return 7;
          case 'C1': return 8;
          default: return 3;
        }
      default:
        switch (level) {
          case 'A1': return 1;
          case 'A2': return 2;
          case 'B1': return 3;
          case 'B2': return 5;
          case 'C1': return 6;
          default: return 1;
        }
    }
  }

  Future<RefineryResult> purgeGarbageWords() async {
    int deletedCount = 0;
    final errors = <String>[];
    bool hasMore = true;
    DocumentSnapshot? lastDoc;

    while (hasMore) {
      try {
        Query query = _firestore.collection(_collection).limit(_batchSize);
        if (lastDoc != null) {
          query = query.startAfterDocument(lastDoc);
        }
        final snapshot = await query.get();
        if (snapshot.docs.isEmpty) {
          hasMore = false;
          break;
        }

        final toDelete = snapshot.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final en = (data['en'] as String? ??
                  data['english'] as String? ??
                  '')
              .toLowerCase()
              .trim();
          return isGarbage(en);
        }).toList();

        if (toDelete.isNotEmpty) {
          final batch = _firestore.batch();
          for (final doc in toDelete) {
            batch.delete(doc.reference);
            deletedCount++;
          }
          await batch.commit();
        }

        if (snapshot.docs.length < _batchSize) {
          hasMore = false;
        } else {
          lastDoc = snapshot.docs.last;
        }
      } catch (e) {
        errors.add('purge_error: $e');
        hasMore = false;
      }
    }

    return RefineryResult(
      deletedCount: deletedCount,
      updatedCount: 0,
      errors: errors,
    );
  }

  Future<RefineryResult> patchDifficultyWeights() async {
    int updatedCount = 0;
    final errors = <String>[];
    bool hasMore = true;
    DocumentSnapshot? lastDoc;

    while (hasMore) {
      try {
        Query query = _firestore.collection(_collection).limit(_batchSize);
        if (lastDoc != null) {
          query = query.startAfterDocument(lastDoc);
        }
        final snapshot = await query.get();
        if (snapshot.docs.isEmpty) {
          hasMore = false;
          break;
        }

        final batch = _firestore.batch();
        int batchOps = 0;

        for (final doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final en = (data['en'] as String? ??
                  data['english'] as String? ??
                  '')
              .toLowerCase()
              .trim();
          final level =
              data['level'] as String? ?? data['cefr'] as String? ?? 'A1';

          if (en.isEmpty) continue;

          final newSource = classifySource(en);
          final newWeight = computeWeight(en, level);
          final currentSource = data['source'] as String?;
          final currentWeight = (data['difficultyWeight'] as num?)?.toInt();

          if (currentSource != newSource || currentWeight != newWeight) {
            batch.update(doc.reference, {
              'source': newSource,
              'difficultyWeight': newWeight,
            });
            batchOps++;
            updatedCount++;
          }
        }

        if (batchOps > 0) await batch.commit();

        if (snapshot.docs.length < _batchSize) {
          hasMore = false;
        } else {
          lastDoc = snapshot.docs.last;
        }
      } catch (e) {
        errors.add('patch_error: $e');
        hasMore = false;
      }
    }

    return RefineryResult(
      deletedCount: 0,
      updatedCount: updatedCount,
      errors: errors,
    );
  }

  Future<RefineryResult> runFullRefinery() async {
    final purge = await purgeGarbageWords();
    final patch = await patchDifficultyWeights();
    return RefineryResult(
      deletedCount: purge.deletedCount,
      updatedCount: patch.updatedCount,
      errors: [...purge.errors, ...patch.errors],
    );
  }
}
