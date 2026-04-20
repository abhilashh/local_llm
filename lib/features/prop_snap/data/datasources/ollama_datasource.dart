import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/errors/exceptions.dart';
import '../models/listing_result_model.dart';

enum ListingType { listing, social, airbnb, faq }

// Prompts used by the remote (Ollama) path — image-based
const remotePrompts = {
  ListingType.listing: '''You are a world-class real estate marketing expert and luxury copywriter. 
Your goal is to stop the scroll and captivate potential buyers instantly.

Analyze the provided property photo(s) and write a high-converting listing description. 
Do not simply list features; evoke a feeling. Sell the lifestyle and the dream.

Structure your response exactly like this:

1. **The Hook:** A magnetic, clever headline (under 10 words) that captures the property's soul.
2. **The Story (200 words):** A compelling narrative that flows naturally. Weave in the following:
   - Atmosphere: Mention natural light, flow, and ambiance.
   - Finishes: Describe textures (e.g., "quartz countertops," "hardwood floors") visible in the image.
   - Lifestyle: Who lives here? (e.g., "Perfect for the remote professional," "A sanctuary for growing families").
3. **Key Highlights:** 3 bullet points using emojis (✨ 🛏️ 🍳) for the top selling points.
4. **The Closer:** A strong call to action that creates urgency.

Tone: Sophisticated, warm, and aspirational.
Output: Use Markdown formatting (Bold, Italics) to make it readable.
''',

  ListingType.social: '''You are a real estate social media expert.
Analyze the provided property photo(s) and write 3 short social media captions for this property.

Format your response as:

📸 Instagram:
[caption with emojis, 2–3 sentences, relevant hashtags]

📘 Facebook:
[slightly longer caption, 3–4 sentences, conversational tone]

🐦 Twitter/X:
[punchy single sentence under 280 characters with 2–3 hashtags]''',

  ListingType.airbnb: '''You are an Airbnb Superhost with years of experience writing high-converting listings.
Analyze the provided property photo(s) and write an Airbnb listing description.

Include:
- A catchy listing title (max 50 characters)
- "The Space" section: describe the property warmly for guests
- "Guest Access" section: what guests can use
- "The Neighbourhood" section: infer likely location vibe from the photos
- "Getting Around" section: brief note on transport/accessibility

Keep it friendly, detailed, and guest-focused (250–350 words total).''',

  ListingType.faq: '''You are a real estate expert helping sellers prepare for buyer questions.
Analyze the provided property photo(s) and generate a FAQ a buyer or renter might ask about this property.

Generate 6–8 questions and answers based on what is visible in the photos.

Format each as:
Q: [question]
A: [answer]

Base answers only on what can be reasonably inferred from the photos. Be honest and helpful.''',
};

abstract interface class InferenceDataSource {
  Future<ListingResultModel> generateListing({
    required ListingType type,
    List<String> base64Images,
    String? textDescription,
  });
}

class OllamaDataSourceImpl implements InferenceDataSource {
  final http.Client _client;
  final String ollamaUrl;
  final String model;

  const OllamaDataSourceImpl({
    required http.Client client,
    required this.ollamaUrl,
    required this.model,
  }) : _client = client;

  @override
  Future<ListingResultModel> generateListing({
    required ListingType type,
    List<String> base64Images = const [],
    String? textDescription,
  }) async {
    final uri = Uri.parse('$ollamaUrl/api/generate');
    final body = jsonEncode({
      'model': model,
      'prompt': remotePrompts[type],
      'images': base64Images,
      'stream': false,
    });

    try {
      final response = await _client
          .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(minutes: 3));

      if (response.statusCode != 200) {
        throw ServerException('Ollama returned ${response.statusCode}: ${response.body}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return ListingResultModel.fromOllamaResponse(json, type);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        'Could not reach Ollama at $ollamaUrl. Make sure it is running and reachable on your network. ($e)',
      );
    }
  }
}
