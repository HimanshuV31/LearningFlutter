import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AIService {
  // Singleton instance
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  // Secure storage for API keys
  final _secureStorage = const FlutterSecureStorage();

  // Base URLs
  static const String _openAIUrl = 'https://api.openai.com/v1/chat/completions';
  static const String _geminiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  // API Keys
  String? _openAIKey;
  String? _geminiKey;

  // Initialize API keys
  Future<void> initializeKeys({String? openAIKey, String? geminiKey}) async {
    try {
      if (openAIKey != null) {
        await _secureStorage.write(key: 'openai_key', value: openAIKey);
        _openAIKey = openAIKey;
      }
      if (geminiKey != null) {
        await _secureStorage.write(key: 'gemini_key', value: geminiKey);
        _geminiKey = geminiKey;
      }
      debugPrint("✅ AI Service keys initialized successfully");
    } catch (e) {
      debugPrint("❌ Error initializing keys: $e");
      // Fallback: store in memory temporarily
      _geminiKey = geminiKey;
      _openAIKey = openAIKey;
    }
  }

  // Load keys from secure storage
  Future<void> _loadKeys() async {
    try {
      _openAIKey ??= await _secureStorage.read(key: 'openai_key');
      _geminiKey ??= await _secureStorage.read(key: 'gemini_key');
    } catch (e) {
      debugPrint("❌ Error loading keys from secure storage: $e");
    }
  }

  // Main summarization function
  Future<Map<String, String>> summarizeText(
      String content, {
        AIProvider provider = AIProvider.gemini,
      }) async {
    await _loadKeys();

    if (content.trim().isEmpty) {
      throw AIServiceException('Content cannot be empty');
    }

    try {
      switch (provider) {
        case AIProvider.openAI:
          return await _callOpenAI(content);
        case AIProvider.gemini:
          return await _callGemini(content);
        default:
          throw AIServiceException('Unsupported AI provider');
      }
    } catch (e) {
      throw AIServiceException('Failed to generate summary: ${e.toString()}');
    }
  }

  // OpenAI implementation
  Future<Map<String, String>> _callOpenAI(String content) async {
    if (_openAIKey == null) {
      throw AIServiceException('OpenAI API key not configured');
    }

    final response = await http.post(
      Uri.parse(_openAIUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_openAIKey',
      },
      body: jsonEncode({
        'model': 'gpt-4',
        'messages': [
          {
            'role': 'system',
            'content': _openAISystemPrompt(),
          },
          {
            'role': 'user',
            'content': _openAIUserPrompt(content),
          },
        ],
        'max_tokens': 300, // ✅ REDUCED: For concise summaries
        'temperature': 0.3,
        'response_format': {'type': 'json_object'},
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final jsonResponse = jsonDecode(data['choices'][0]['message']['content']);
      return {
        'title': _cleanText(jsonResponse['title']?.toString() ?? 'Untitled Summary'),
        'summary': _cleanText(jsonResponse['summary']?.toString() ?? 'Summary not available'),
      };
    } else {
      throw AIServiceException('OpenAI API error: ${response.statusCode} - ${response.body}');
    }
  }

  // Gemini implementation
  Future<Map<String, String>> _callGemini(String content) async {
    if (_geminiKey == null) {
      throw AIServiceException('Gemini API key not configured');
    }

    final prompt = _geminiPromptText(content);

    final response = await http.post(
      Uri.parse('$_geminiUrl?key=$_geminiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {
                'text': prompt,
              },
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.3,
          'maxOutputTokens': 350, // ✅ REDUCED: For concise summaries
          'stopSequences': [],
        },
      }),
    );

    debugPrint("🔍 Gemini Response Status: ${response.statusCode}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['candidates'] != null && data['candidates'].isNotEmpty) {
        final responseText = data['candidates'][0]['content']['parts'][0]['text'].toString().trim();
        debugPrint("🔍 Raw Gemini Response: $responseText");

        return _parseGeminiResponse(responseText);
      } else {
        throw AIServiceException('No response generated from Gemini');
      }
    } else {
      throw AIServiceException('Gemini API error: ${response.statusCode} - ${response.body}');
    }
  }

  // ✅ ENHANCED: Better Gemini response parsing with aggressive JSON cleaning
  Map<String, String> _parseGeminiResponse(String responseText) {
    debugPrint("🔍 Parsing response: $responseText");

    try {
      // Step 1: Remove all markdown formatting and code blocks
      String cleanedResponse = responseText
          .replaceAll('```', '')
          .replaceAll('`', '')
          .trim();

          debugPrint("🔍 After basic cleaning: $cleanedResponse");

      // Step 2: Try to find JSON content between braces
      RegExp jsonRegex = RegExp(r'\{[^{}]*"title"[^{}]*"summary"[^{}]*\}', multiLine: true, dotAll: true);
      Match? jsonMatch = jsonRegex.firstMatch(cleanedResponse);

      if (jsonMatch != null) {
        cleanedResponse = jsonMatch.group(0)!;
        debugPrint("🔍 Extracted JSON: $cleanedResponse");
      }

      // Step 3: Try to parse as JSON
      final jsonResponse = jsonDecode(cleanedResponse);

      if (jsonResponse is Map<String, dynamic>) {
        final title = _cleanText(jsonResponse['title']?.toString() ?? 'AI Generated Summary');
        final summary = _cleanText(jsonResponse['summary']?.toString() ?? 'Summary not available');

        debugPrint("✅ Successfully parsed - Title: $title");
        debugPrint("✅ Successfully parsed - Summary length: ${summary.length} chars");

        return {
          'title': title,
          'summary': summary,
        };
      }
    } catch (e) {
      debugPrint("❌ JSON parsing failed: $e");
      // Fallback to text parsing
    }

    // Fallback: Try to extract title and summary from plain text
    return _extractFromPlainText(responseText);
  }

  // Extract title and summary from plain text response
  Map<String, String> _extractFromPlainText(String responseText) {
    // Clean the response text first
    String cleanedText = responseText
        .replaceAll('```', '')
        .replaceAll('`', '')
        .trim();

        final lines = cleanedText.split('\n').where((line) => line.trim().isNotEmpty).toList();

    String title = 'AI Generated Summary';
    String summary = cleanedText;

    // Look for title and summary patterns
    String titlePattern = '';
    String summaryPattern = '';
    bool foundTitle = false;
    bool foundSummary = false;

    for (String line in lines) {
      String trimmedLine = line.trim();

      if (trimmedLine.toLowerCase().contains('"title"') ||
          trimmedLine.toLowerCase().contains('title:')) {
        // Extract title
        titlePattern = trimmedLine
            .replaceAll(RegExp(r'"title"\s*:\s*"?'), '')
            .replaceAll(RegExp(r'"?\s*,?\s*$'), '')
            .replaceAll('"', '')
            .trim();
        if (titlePattern.isNotEmpty && titlePattern.length < 100) {
          title = titlePattern;
          foundTitle = true;
        }
      }

      if (trimmedLine.toLowerCase().contains('"summary"') ||
          trimmedLine.toLowerCase().contains('summary:')) {
        // Extract summary start
        summaryPattern = trimmedLine
            .replaceAll(RegExp(r'"summary"\s*:\s*"?'), '')
            .replaceAll('"', '')
            .trim();
        foundSummary = true;
      } else if (foundSummary && !foundTitle) {
        // Continue building summary
        summaryPattern += ' ' + trimmedLine.replaceAll('"', '').trim();
      }
    }

    if (summaryPattern.isNotEmpty) {
      summary = summaryPattern.replaceAll(RegExp(r'\s+'), ' ').trim();
    }

    return {
      'title': _cleanText(title),
      'summary': _cleanText(summary.isNotEmpty ? summary : cleanedText),
    };
  }

  // ✅ ENHANCED: More aggressive text cleaning
  String _cleanText(String text) {
    return text
        .replaceAll('```', '')
        .replaceAll('`', '')
        .replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'$1') // Remove markdown bold
        .replaceAll(RegExp(r'\*(.+?)\*'), r'$1')     // Remove markdown italic
        .replaceAll(RegExp(r'#{1,6}\s*'), '')        // Remove markdown headers
        .replaceAll(RegExp(r'[{}"]'), '')            // Remove JSON formatting chars
        .replaceAll('title:', '')                     // Remove field labels
        .replaceAll('summary:', '')
        .replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n') // Clean multiple newlines
        .replaceAll(RegExp(r'\s+'), ' ')             // Normalize whitespace
        .trim();
    }

  // ✅ OPTIMIZED: Concise OpenAI system prompt focused on brevity
  String _openAISystemPrompt() {
    return """
You are a professional note summarization expert. Create concise, impactful summaries that capture essential information without unnecessary detail.

CRITICAL REQUIREMENTS:
- BREVITY: Keep summaries under 100 words, focus on key insights only
- CLARITY: Use simple, clear language without jargon
- FORMAT: Respond ONLY with valid JSON: {"title": "Brief title (4-8 words)", "summary": "Concise summary (2-3 sentences maximum)"}
- NO MARKDOWN: Use plain text only, no **, *, #, or other formatting

QUALITY STANDARDS:
✓ Extract only the most important points
✓ Eliminate redundancy and filler words
✓ Focus on actionable insights and key conclusions
✓ Use active voice and direct language
✓ Ensure summary is self-contained and valuable""";
  }

  String _openAIUserPrompt(String content) {
    return """
Analyze this content and create a brief, impactful summary:

$content

Respond with JSON containing a short title and concise summary (under 100 words total). Focus on the most essential information only.""";
  }

  // ✅ OPTIMIZED: Concise Gemini prompt for minimal but impactful summaries
  String _geminiPromptText(String content) {
    return """
You are an expert at creating concise, high-impact summaries. Your task is to analyze content and extract only the most essential information.

STRICT REQUIREMENTS:
- Keep summary under 80 words
- Title should be 4-8 words maximum
- Focus on key insights and actionable information only
- Use simple, clear language
- No redundancy or filler content

RESPONSE FORMAT (EXACT):
{
  "title": "Brief, descriptive title (4-8 words)",
  "summary": "Concise summary highlighting only the most important points in 2-3 sentences maximum. Focus on key insights and actionable information."
}

CONTENT TO ANALYZE:
$content

Provide your response as clean JSON only, focusing on brevity and impact.""";
  }
}

// Enums and exceptions
enum AIProvider { openAI, gemini }

class AIServiceException implements Exception {
  final String message;
  AIServiceException(this.message);

  @override
  String toString() => 'AIServiceException: $message';
}
