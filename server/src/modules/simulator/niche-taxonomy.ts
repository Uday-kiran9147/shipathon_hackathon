export type NicheKey =
  | 'tech'
  | 'finance'
  | 'cooking'
  | 'fitness'
  | 'gaming'
  | 'lifestyle'
  | 'education'
  | 'entertainment'
  | 'default';

export interface NicheProfile {
  hookPatterns: string[];
  powerWords: string[];
  requestKeywords: string[];
  retentionHazards: string[];
  authenticityMarkers: string[];
  baseTopicMomentum: number;
}

export const NICHE_TAXONOMY: Record<NicheKey, NicheProfile> = {
  tech: {
    hookPatterns: [
      "I shipped {topic} in {time} and it broke prod.",
      "Every senior dev gets {topic} wrong. Here's proof.",
      "I replaced {tool} with {topic}. The benchmark surprised me.",
      "We went from {bad_metric} to {good_metric} with one refactor.",
    ],
    powerWords: [
      'shipped', 'benchmark', 'refactor', 'broke', 'prod', 'performance',
      'latency', 'scale', 'deprecated', 'exploited', 'leaked', 'regression', 'bottleneck',
    ],
    requestKeywords: [
      'tutorial on', 'how to build', 'can you show', 'deep dive on',
      'walk me through', 'repo link', 'source code', 'github', 'next part',
      'build a', 'how does this work', 'can you explain',
    ],
    retentionHazards: [
      'in this video i will', 'first let me explain', 'before we start',
      'as you can see', "let's begin by", 'today we are going to',
    ],
    authenticityMarkers: [
      'live coding', 'real benchmark', 'actual error', 'production system', 'my codebase',
    ],
    baseTopicMomentum: 8.4,
  },

  finance: {
    hookPatterns: [
      "This one ratio cost me ₹{amount} last year.",
      "{percent}% of investors make this mistake. I was one of them.",
      "I ran the numbers on {topic}. The result shocked me.",
      "The fund manager didn't want you to know this about {topic}.",
    ],
    powerWords: [
      'returns', 'compound', 'mistake', 'loss', 'hidden', 'undervalued',
      'portfolio', 'taxed', 'inflation', 'CAGR', 'risk-adjusted', 'crore', 'lakh',
    ],
    requestKeywords: [
      'which broker', 'how to invest in', 'is it safe to', 'your portfolio',
      'SIP for', 'review of', 'analysis on', 'should i buy',
      'nifty prediction', 'tax on', 'best fund for',
    ],
    retentionHazards: [
      'disclaimer', 'not financial advice', 'before we dive in',
      'today we are going to', "let's start with the basics", 'in this video',
    ],
    authenticityMarkers: [
      'real portfolio', 'my own money', 'actual returns', 'backtested', 'P&L screenshot',
    ],
    baseTopicMomentum: 8.7,
  },

  cooking: {
    hookPatterns: [
      "Every chef does {topic} wrong — including me, until now.",
      "I tested {number} versions of {dish}. This one is different.",
      "The one ingredient that changes everything about {dish}.",
      "Restaurant chefs keep {technique} secret. I'm showing you exactly why.",
    ],
    powerWords: [
      'secret', 'fail', 'mistake', 'perfect', 'tested', 'never', 'wrong',
      'hidden', 'real', 'trick', 'difference', 'crispy', 'authentic',
    ],
    requestKeywords: [
      'recipe for', 'how do you make', 'full recipe', 'ingredients for',
      'cooking time for', 'can you do', 'show us how to', 'what brand',
      'restaurant style', 'without oven', 'substitute for',
    ],
    retentionHazards: [
      'today i will be making', 'welcome back to my kitchen',
      'in this recipe we', 'hi everyone', 'before we start cooking',
    ],
    authenticityMarkers: [
      'tested multiple times', 'family recipe', 'street food style',
      'restaurant technique', 'real measurements',
    ],
    baseTopicMomentum: 8.2,
  },

  fitness: {
    hookPatterns: [
      "I trained {topic} every day for 90 days. Here's what actually happened.",
      "The {exercise} form mistake that's killing your gains.",
      "I tested {program} so you don't have to. Honest results.",
      "What no one tells you about {topic} — the science says otherwise.",
    ],
    powerWords: [
      'mistake', 'gains', 'tested', 'science', 'wrong', 'truth', 'hidden',
      'results', 'real', 'never', 'stopped', 'injury', 'plateau',
    ],
    requestKeywords: [
      'workout plan for', 'how many reps', 'diet for', 'supplement for',
      'is it okay to', 'home workout for', 'beginner routine',
      'how long until', 'what to eat', 'natural or',
    ],
    retentionHazards: [
      'welcome to my channel', "today we're going to", 'in this video i',
      'so before we start', 'first things first',
    ],
    authenticityMarkers: [
      'my own progress', 'before and after', 'real measurements', 'no steroids', 'natural',
    ],
    baseTopicMomentum: 8.5,
  },

  gaming: {
    hookPatterns: [
      "They patched it. The strat still works.",
      "I found a {mechanic} that the devs didn't patch. Here's how.",
      "Going from {rank_low} to {rank_high} using only {topic}.",
      "The meta is wrong about {topic}. Here's the data.",
    ],
    powerWords: [
      'patch', 'meta', 'strat', 'broken', 'op', 'unpatched', 'hidden',
      'glitch', 'exploit', 'rank', 'speedrun', 'one-shot', 'cheese',
    ],
    requestKeywords: [
      'best loadout for', 'what settings do you use', 'controller or keyboard',
      'how to counter', 'clip of', 'tier list for', 'is it worth buying',
      'rank up tips for', 'settings video', 'crosshair settings',
    ],
    retentionHazards: [
      'hey guys welcome back', 'today i am going to show', 'in this video we will',
      'before i start', 'make sure to subscribe',
    ],
    authenticityMarkers: [
      'ranked gameplay', 'no edits', 'raw footage', 'live reaction', 'unscripted',
    ],
    baseTopicMomentum: 8.3,
  },

  lifestyle: {
    hookPatterns: [
      "I deleted all my apps for 30 days. Here's what happened.",
      "I tried living on {budget} for a week.",
      "The habit that completely changed my {morning/sleep/productivity}.",
      "I said no to {thing} for a month. The result surprised everyone.",
    ],
    powerWords: [
      'deleted', 'quit', 'stopped', 'changed', 'honest', 'real', 'truth',
      'actually', 'experiment', 'challenge', 'week', 'days', 'transformed',
    ],
    requestKeywords: [
      'routine for', 'how do you', 'day in the life of', 'what do you use for',
      'morning routine', 'how to balance', 'tips for', 'what camera', 'apartment tour',
    ],
    retentionHazards: [
      'hey guys so', "in today's video", 'welcome back to my channel',
      "i hope you're all doing well", "so today we're going to",
    ],
    authenticityMarkers: [
      'no filter', 'real life', 'unsponsored', 'honest review', 'my actual routine',
    ],
    baseTopicMomentum: 7.9,
  },

  education: {
    hookPatterns: [
      "You were taught {concept} wrong. Here's what the textbook skipped.",
      "The {topic} formula your teacher never explained — but should have.",
      "I explained {concept} to 500 students. One analogy made it click for all of them.",
      "Most explanations of {topic} get this one detail completely wrong.",
    ],
    powerWords: [
      'wrong', 'explained', 'actually', 'simplified', 'truth', 'real', 'never',
      'skipped', 'misunderstood', 'proof', 'intuition', 'formula', 'concept',
    ],
    requestKeywords: [
      'can you explain', 'video on', 'help with', 'struggling with',
      'how does', 'what is', 'difference between', 'solve this',
      'concept of', 'chapter on', 'problems on',
    ],
    retentionHazards: [
      'in this lesson we will', 'today we are going to learn',
      'hello students', "let's start from the beginning", 'firstly',
    ],
    authenticityMarkers: [
      'worked examples', 'real-world application', 'conceptual proof',
      'intuitive explanation', 'common misconception addressed',
    ],
    baseTopicMomentum: 8.6,
  },

  entertainment: {
    hookPatterns: [
      "I tried every viral {trend} so you don't have to.",
      "We ranked {number} {things}. The last one broke us.",
      "I spent {time} doing {challenge}. It was not what I expected.",
      "{topic} but every time I fail, it gets more ridiculous.",
    ],
    powerWords: [
      'viral', 'fail', 'ranked', 'worst', 'best', 'reacted', 'surprising',
      'not what I expected', 'broke', 'impossible', 'challenge', 'hilarious',
    ],
    requestKeywords: [
      'do the', 'react to', 'try', 'rate', 'rank', 'part 2 of',
      'collab with', 'more videos like this', 'behind the scenes', 'bloopers',
    ],
    retentionHazards: [
      "so today we're", 'hey everybody', 'welcome back to the channel',
      "if you haven't already", 'before we get into',
    ],
    authenticityMarkers: [
      'genuine reaction', 'no script', 'raw footage', 'unedited', 'first time',
    ],
    baseTopicMomentum: 7.8,
  },

  default: {
    hookPatterns: [
      "The truth about {topic} that no one talks about.",
      "I tried {topic} for 30 days. Here's what happened.",
      "Everyone gets {topic} wrong. Here's the real answer.",
    ],
    powerWords: [
      'never', 'stop', 'mistake', 'why', 'secret', 'truth', 'real',
      'cost', 'wrong', 'fail', 'hidden', 'shocking', 'formula', 'warning',
      'tested', 'breakdown', 'proven',
    ],
    requestKeywords: [
      'can you make', 'can you do', 'part 2', 'tutorial on', 'deep dive on',
      'more videos like this', 'please explain', 'waiting for part',
    ],
    retentionHazards: ['today', 'in this video', 'hey guys', 'welcome back', 'before we start'],
    authenticityMarkers: ['personal experience', 'real data', 'tested', 'honest opinion'],
    baseTopicMomentum: 8.2,
  },
};

export function detectNicheKey(niche: string): NicheKey {
  const lower = niche.toLowerCase();
  if (/\b(software|coding|programming|developer|tech|react|node|python|javascript|typescript|database|api|backend|frontend|cloud|devops|kubernetes|docker|ai|machine.?learning|ml|system.?design)\b/.test(lower)) return 'tech';
  if (/\b(finance|investing|stocks|mutual.?fund|crypto|trading|money|wealth|portfolio|nifty|sensex|sip|returns|market|demat|zerodha|groww)\b/.test(lower)) return 'finance';
  if (/\b(cooking|recipe|food|chef|kitchen|baking|cuisine|dish|meal|ingredient|restaurant|street.?food)\b/.test(lower)) return 'cooking';
  if (/\b(fitness|workout|gym|exercise|health|diet|nutrition|weight|muscle|cardio|yoga|strength|calisthenics)\b/.test(lower)) return 'fitness';
  if (/\b(gaming|game|gamer|esports|playthrough|speedrun|minecraft|fortnite|valorant|pc.?gaming|console|fps|rpg)\b/.test(lower)) return 'gaming';
  if (/\b(lifestyle|vlog|daily|routine|productivity|minimalism|travel|fashion|beauty|personal|morning|aesthetic)\b/.test(lower)) return 'lifestyle';
  if (/\b(education|learn|teach|study|school|math|science|physics|chemistry|biology|history|lecture|exam|tutor)\b/.test(lower)) return 'education';
  if (/\b(entertainment|comedy|prank|reaction|challenge|fun|funny|meme|skit|roast|sketch)\b/.test(lower)) return 'entertainment';
  return 'default';
}
