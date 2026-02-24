
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:nexentis_ai/bloc/cubit/search_state.dart';
class SearchCubit  extends Cubit<SearchState>{
  SearchCubit() : super(SearchInitialState());

  //events
  void getSearchResponse({required String query}) async{

  emit(SearchLoadingState()); 

  String apiKey = "AIzaSyB8QstIIKpv2GtrJYMJc_ppK4VfXXZooDY";
  String url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent?key=$apiKey";
 
  Map<String, dynamic> bodyParams = 
    {
    "contents": [
      {
        "parts": [
          {
            "text": query 
          }
        ]
      }
    ]

  };

  var response = await http.post(Uri.parse(url), body: jsonEncode(bodyParams));
  if (response.statusCode == 200){
    print(response.body);
    var data = jsonDecode(response.body);
    var res =  data['candidates'][0]['content']['parts'][0]['text']; 
    emit(SearchLoadedState(res: res));
    
  } else {
    var error = ("Error: ${response.statusCode}");
    emit(SearchErrorState(error: error));
  }
  }

}