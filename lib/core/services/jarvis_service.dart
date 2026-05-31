import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:women_safety_app/config/app_config.dart';

class JarvisService {
  JarvisService._();

  static final JarvisService instance = JarvisService._();

  GenerativeModel? _model;
  ChatSession? _chat;
  bool _initialized = false;

  void initializeJarvis({required void Function() onTriggerSOS}) {
    if (_initialized) return;

    try {
      final systemInstruction = Content.system('''
        You are Mitra (Jarvis), a deeply empathetic, protective emotional support mentor and women's safety assistant.
        Your absolute priority is to keep the user calm and safe. Assess their situation dynamically and respond naturally like a caring human companion.
        Keep verbal responses relatively brief, conversational, and deeply reassuring. Answer the user's actual question or concern — do not repeat generic tracking phrases.

        CRITICAL ACTION RULE:
        If the user explicitly states they are in severe danger, being followed, cornered, or explicitly commands you to send an alert or call for help, you must invoke the function 'trigger_emergency_sos'.
      ''');

      final sosFunctionTool = FunctionDeclaration(
        'trigger_emergency_sos',
        'Triggers the emergency contact messaging sequence when the user is in immediate danger or explicitly requests emergency help alerts.',
        Schema.object(properties: {}),
      );

      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: AppConfig.geminiApiKey,
        systemInstruction: systemInstruction,
        tools: [Tool(functionDeclarations: [sosFunctionTool])],
      );

      _chat = _model!.startChat();
      _initialized = true;
      debugPrint('JarvisService: initialized successfully.');
    } catch (e) {
      debugPrint('JarvisService: initialization error: $e');
    }
  }

  /// Sends user text (typed or from voice) to Gemini and returns the model's reply.
  Future<String> sendMessageToJarvis(
    String userText,
    void Function() onTriggerSOS,
  ) async {
    final trimmed = userText.trim();
    if (trimmed.isEmpty) {
      return "I didn't catch that. Could you say it again?";
    }

    if (!_initialized || _chat == null) {
      initializeJarvis(onTriggerSOS: onTriggerSOS);
    }

    final chat = _chat;
    if (chat == null) {
      return "I'm having trouble connecting right now. Please try again in a moment.";
    }

    try {
      final response = await chat.sendMessage(Content.text(trimmed));

      final functionCalls = response.functionCalls.toList();
      if (functionCalls.isNotEmpty) {
        final call = functionCalls.first;
        if (call.name == 'trigger_emergency_sos') {
          onTriggerSOS();
          return response.text?.trim().isNotEmpty == true
              ? response.text!.trim()
              : "Alerting your priority contacts right now! Stay calm — I'm with you.";
        }
      }

      final text = response.text?.trim();
      if (text != null && text.isNotEmpty) {
        return text;
      }

      return "I'm here listening. Tell me what's happening.";
    } catch (e) {
      debugPrint('JarvisService: communication failure: $e');
      return "I'm having a little trouble connecting, but take a deep breath. I'm right here with you.";
    }
  }
}
