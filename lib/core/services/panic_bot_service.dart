/// Panic chatbot service with rule-based keyword detection
/// No LLM, no training, offline capable
class PanicBotResponse {
  final String message;
  final String category; // 'calm', 'instruction', 'info', 'urgent'

  PanicBotResponse({required this.message, required this.category});
}

/// Rule-based panic chatbot - detects keywords and provides guidance
class PanicBotService {
  const PanicBotService();

  /// Handle text input and return appropriate response
  PanicBotResponse handleText(String input) {
    final text = input.toLowerCase().trim();

    if (text.isEmpty) {
      return PanicBotResponse(
        message:
            'I\'m here for you. Tell me what\'s happening so I can guide you.',
        category: 'info',
      );
    }

    // Extract keywords
    final Set<String> tokens = text.split(RegExp(r'[\s,\.!?]+')).toSet();

    // Check for key phrases
    final bool mentionsFollow = _containsKeyword(tokens, [
      'follow',
      'following',
      'stalking',
      'stalker',
      'trailing',
      'behind',
    ]);

    final bool mentionsDanger = _containsKeyword(tokens, [
      'danger',
      'dangerous',
      'attack',
      'attacked',
      'kidnap',
      'kidnapping',
      'harass',
      'harassment',
      'threat',
      'threaten',
      'hurt',
      'violence',
    ]);

    final bool mentionsScared = _containsKeyword(tokens, [
      'scared',
      'afraid',
      'fear',
      'panic',
      'anxious',
      'worried',
      'nervous',
    ]);

    final bool mentionsHelp = _containsKeyword(tokens, [
      'help',
      'sos',
      'emergency',
      'assist',
      'rescue',
    ]);

    final bool mentionsAlone = _containsKeyword(tokens, [
      'alone',
      'isolated',
      'nobody',
      'no one',
    ]);

    // Priority: immediate danger
    if (mentionsDanger || (mentionsHelp && mentionsScared)) {
      return PanicBotResponse(
        message:
            'You are not alone. If you are in immediate danger:\n\n'
            '• Try to move to a safer, more visible place if possible\n'
            '• Press the SOS button in the app and call your trusted contact or local emergency number\n'
            '• Keep your phone charged and in your hand\n'
            '• Avoid confrontation; your safety comes first\n'
            '• If possible, go to a public place like a shop, café, or police station',
        category: 'urgent',
      );
    }

    // Someone following
    if (mentionsFollow) {
      return PanicBotResponse(
        message:
            'It sounds like someone may be following you. Stay calm.\n\n'
            '• Move towards a crowded, well-lit area such as a shop, café, or police station\n'
            '• If possible, call a trusted contact and keep them on the line\n'
            '• Do not go straight home if you suspect you are being followed\n'
            '• Change direction or cross the street to confirm if they are following\n'
            '• Be ready to use the SOS features in the app if you feel unsafe',
        category: 'instruction',
      );
    }

    // Feeling scared/anxious
    if (mentionsScared) {
      return PanicBotResponse(
        message:
            'I understand you are feeling scared. Your feelings are valid.\n\n'
            '• Take a deep breath in for 4 seconds, hold for 4 seconds, and exhale for 4 seconds. Repeat 3 times\n'
            '• If you can, move to a place where you feel slightly safer\n'
            '• Consider informing a trusted friend or family member about where you are\n'
            '• You can use the emergency contacts in the app if the situation worsens\n'
            '• Remember: you have tools available - SOS button, emergency contacts, and location sharing',
        category: 'calm',
      );
    }

    // Alone/isolated
    if (mentionsAlone) {
      return PanicBotResponse(
        message:
            'Feeling alone can be difficult. You have support available.\n\n'
            '• Share your location with someone you trust using the app\n'
            '• Consider calling a friend or family member\n'
            '• If you feel unsafe, use the SOS or Emergency alert features\n'
            '• Move to a more populated area if possible\n'
            '• Keep your phone charged and accessible',
        category: 'info',
      );
    }

    // General help request
    if (mentionsHelp) {
      return PanicBotResponse(
        message:
            'I\'m here to guide you. If this is an emergency, consider using the SOS or Emergency alert features in the app.\n\n'
            '• Share your location with someone you trust\n'
            '• Stay aware of your surroundings\n'
            '• If possible, avoid isolated areas\n'
            '• Keep your emergency contacts updated and accessible\n'
            '• Trust your instincts - if something feels wrong, take action',
        category: 'instruction',
      );
    }

    // Default supportive response
    return PanicBotResponse(
      message:
          'Thank you for sharing. I\'m here to support you.\n\n'
          'You can tell me if you feel:\n'
          '• Followed or stalked\n'
          '• In danger or threatened\n'
          '• Scared or anxious\n'
          '• Alone or isolated\n\n'
          'I will suggest steps to help you stay safer. If you feel unsafe right now, consider using the SOS features or contacting someone you trust.',
      category: 'info',
    );
  }

  /// Handle voice input transcript (same logic as text)
  PanicBotResponse handleVoiceTranscript(String transcript) {
    return handleText(transcript);
  }

  /// Check if tokens contain any of the keywords
  bool _containsKeyword(Set<String> tokens, List<String> keywords) {
    for (final keyword in keywords) {
      if (tokens.contains(keyword)) return true;
      // Also check if any token contains the keyword as substring
      for (final token in tokens) {
        if (token.contains(keyword) || keyword.contains(token)) {
          return true;
        }
      }
    }
    return false;
  }
}
