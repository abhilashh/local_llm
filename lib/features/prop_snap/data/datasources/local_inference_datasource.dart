import 'dart:io';
import 'package:flutter_gemma/core/api/flutter_gemma.dart';
import 'package:flutter_gemma/core/message.dart';
import 'package:flutter_gemma/core/model.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/constants/model_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/listing_result_model.dart';
import 'ollama_datasource.dart';

const _localPrompts = {
  ListingType.listing: '''You are an expert real estate copywriter.
Based on the following property description, write a compelling professional listing.

Property details: {description}

Include:
- An engaging opening headline
- Key features from the description
- Lifestyle appeal for potential buyers or renters
- A strong closing call-to-action

Keep the tone warm, professional, and concise (200–300 words).''',

  ListingType.social: '''You are a real estate social media expert.
Based on the following property description, write 3 social media captions.

Property details: {description}

Format your response as:

📸 Instagram:
[caption with emojis, 2–3 sentences, relevant hashtags]

📘 Facebook:
[slightly longer caption, 3–4 sentences, conversational tone]

🐦 Twitter/X:
[punchy single sentence under 280 characters with 2–3 hashtags]''',

  ListingType.airbnb: '''You are an Airbnb Superhost writing high-converting listings.
Based on the following property description, write an Airbnb listing.

Property details: {description}

Include:
- A catchy listing title (max 50 characters)
- "The Space" section
- "Guest Access" section
- "The Neighbourhood" section
- "Getting Around" section

Keep it friendly, detailed, and guest-focused (250–350 words total).''',

  ListingType.faq: '''You are a real estate expert preparing sellers for buyer questions.
Based on the following property description, generate a FAQ a buyer or renter might ask.

Property details: {description}

Generate 6–8 questions and answers. Format each as:
Q: [question]
A: [answer]''',
};

class LocalInferenceDataSourceImpl implements InferenceDataSource {
  const LocalInferenceDataSourceImpl();

  Future<String> _resolvedModelPath() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/${ModelConstants.modelFileName}';
    if (!await File(path).exists()) {
      throw const ServerException(
        'Model file not found. Go to Settings and download the model first.',
      );
    }
    return path;
  }

  @override
  Future<ListingResultModel> generateListing({
    required ListingType type,
    List<String> base64Images = const [],
    String? textDescription,
  }) async {
    if (textDescription == null || textDescription.trim().isEmpty) {
      throw const ServerException('Please enter a property description for on-device generation.');
    }

    final modelPath = await _resolvedModelPath();

    // Register the local file as the active model
    await FlutterGemma.installModel(modelType: ModelType.gemmaIt)
        .fromFile(modelPath)
        .install();

    final model = await FlutterGemma.getActiveModel(maxTokens: 1024);
    final session = await model.createSession();

    try {
      final prompt = _localPrompts[type]!.replaceAll('{description}', textDescription.trim());
      await session.addQueryChunk(Message.text(text: prompt, isUser: true));
      final response = await session.getResponse();

      if (response.trim().isEmpty) {
        throw const ServerException('Model returned an empty response.');
      }

      return ListingResultModel(description: response.trim(), generatedAt: DateTime.now(), type: type);
    } finally {
      await session.close();
    }
  }
}
