import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:clean_catalogue_app/models/user_model.dart';
import 'package:clean_catalogue_app/models/catalogue_model.dart';
import 'package:clean_catalogue_app/models/catalogue_scores_model.dart';

Future<List<Catalogue>?> getCatalogues({required String userID}) async {
  await dotenv.load(fileName: ".env");

  try {
    final url = Uri.parse(dotenv.env['GET_CATALOGUES_URL']! + userID);

    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    final response = await http.get(
      url,
      headers: headers,
    );

    debugPrint(response.body);
    debugPrint(response.statusCode.toString());

    if (response.statusCode == 404) {
      return null;
    } else if (response.statusCode == 200) {
      final parsedResponse = jsonDecode(response.body) as Map<String, dynamic>;
      final userData = parsedResponse['catalogues'] as List<dynamic>;

      final catalogues = <Catalogue>[];

      for (final response in userData) {
        final catalogue = Catalogue(
          name: response['catalogue_name'],
          date: DateTime.now(),
          catalogueID: response['_id'],
          images: <ImageObject>[],
          result: CatalogueScores(
            areaOfImprovement: response['areaOfImprovement'],
            productDescriptions: response['ProductDescriptions'],
            brandConsistency: response['BrandConsistency'],
            contactInformationAndCallToAction:
                response['ContactInformationAndCallToAction'],
            discountsAndPromotions: response['DiscountsAndPromotions'],
            layoutAndDesign: response['LayoutAndDesign'],
            legalCompliance: response['LegalCompliance'],
            pricingInformation: response['PricingInformation'],
            productImages: response['ProductImages'],
            typosAndGrammar: response['TyposAndGrammar'],
          ),
          description: response['catalogue_description'],
        );

        for (final image in response['imageUrl']) {
          catalogue.images.add(
            ImageObject(
              name: image['image_name'],
              imageUrl: image['image_url'],
            ),
          );
        }

        catalogues.add(catalogue);
      }

      return catalogues;
    }
  } catch (error) {
    debugPrint(error.toString());
    debugPrint("Error fetching catalogues.");
    throw Error();
  }

  return null;
}

Future<UserModel?> createUser(
    {required String name,
    required String email,
    required String authID}) async {
  await dotenv.load(fileName: ".env");
  UserModel? currUser;

  try {
    final url = Uri.parse(dotenv.env['CREATE_USER_URL']!);

    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      'name': name,
      'email': email,
      'authID': authID,
    });

    final response = await http.post(
      url,
      headers: headers,
      body: body,
    );

    if (response.statusCode == 201) {
      debugPrint('User created successfully!');

      final parsedResponse = jsonDecode(response.body) as Map<String, dynamic>;
      final userData = parsedResponse['data'] as Map<String, dynamic>;

      currUser = UserModel(
        userID: userData['authID'],
        username: userData['name'],
        email: userData['email'],
      );
    } else if (response.statusCode == 400) {
      debugPrint('User found successfully!');

      final catalogues = await getCatalogues(userID: authID);

      final parsedResponse = jsonDecode(response.body) as Map<String, dynamic>;
      final userData = parsedResponse['data'] as Map<String, dynamic>;

      if (catalogues == null) {
        currUser = UserModel(
          userID: userData['authID'],
          username: userData['name'],
          email: userData['email'],
        );
      } else {
        currUser = UserModel(
          userID: userData['authID'],
          username: userData['name'],
          email: userData['email'],
          catalogues: catalogues,
        );
      }
    }

    return currUser;
  } catch (error) {
    debugPrint("Error signing in, please try again later.");
    throw Error();
  }
}

Future<CatalogueScores?> scanCatalogue(
    {required List<ImageObject> images,
    required String catalogueName,
    required String? catalogueDescription,
    required UserModel currUser}) async {
  await dotenv.load(fileName: ".env");
  CatalogueScores catalogueScores;
  try {
    final url = Uri.parse(dotenv.env['SCAN_CATALOGUE_URL']!);

    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    final imageObjectsData = images
        .map((image) => {
              'image_name': image.name,
              'image_url': image.imageUrl,
            })
        .toList();

    final body = jsonEncode({
      'userId': currUser.userID,
      'catalogue_name': catalogueName,
      'catalogue_description': catalogueDescription,
      'images': imageObjectsData,
    });

    final response = await http.post(
      url,
      headers: headers,
      body: body,
    );

    final responseJson = jsonDecode(response.body) as Map<String, dynamic>;
    final catalogueData = responseJson['catalogue'] as Map<String, dynamic>;

    debugPrint(catalogueData.toString());

    final productDescriptionsScore = catalogueData['ProductDescriptions'];
    final pricingInformationScore = catalogueData['PricingInformation'];
    final brandConsistency = catalogueData['BrandConsistency'];
    final productImages = catalogueData['ProductImages'];
    final layoutAndDesign = catalogueData['LayoutAndDesign'];
    final discountsAndPromotions = catalogueData['DiscountsAndPromotions'];
    final contactInformationAndCallToAction =
        catalogueData['ContactInformationAndCallToAction'];
    final typosAndGrammar = catalogueData['TyposAndGrammar'];
    final legalCompliance = catalogueData['LegalCompliance'];
    final areaOfImprovement = catalogueData['areaOfImprovement'];

    catalogueScores = CatalogueScores(
      productDescriptions: productDescriptionsScore,
      pricingInformation: pricingInformationScore,
      brandConsistency: brandConsistency,
      productImages: productImages,
      contactInformationAndCallToAction: contactInformationAndCallToAction,
      discountsAndPromotions: discountsAndPromotions,
      layoutAndDesign: layoutAndDesign,
      legalCompliance: legalCompliance,
      typosAndGrammar: typosAndGrammar,
      areaOfImprovement: areaOfImprovement,
    );
  } catch (error) {
    debugPrint("Error scanning catalogue.");
    throw Error();
  }

  return catalogueScores;
}
